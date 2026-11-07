import { Model, Plugin, Provider } from "@opencode/plugin";
import { resolveAgentGatewayAuth } from "./auth.js";
import { groupAgentGatewayModel, mapAgentGatewayModel } from "./model.js";

const PROVIDER_ID = "agentgateway";
const REFRESH_EVENTS = new Set([
  "config.updated",
  "credential.updated",
  "credential.switched",
  "integration.updated",
  "provider.updated",
]);

function providerRecords(value) {
  const entries = Array.isArray(value) ? value : Array.isArray(value?.data) ? value.data : [];
  return entries.map((entry) => entry?.provider && typeof entry.provider === "object" ? entry.provider : entry);
}

async function findProvider(ctx) {
  try {
    return providerRecords(await ctx.provider.list()).find((provider) => provider?.id === PROVIDER_ID);
  } catch {
    return undefined;
  }
}

export default Plugin.define({
  id: "opencode.agentgateway-discovery",
  async setup(ctx) {
    const providerID = Provider.ID.make(PROVIDER_ID);
    const abort = new AbortController();
    let inventory = new Map();
    let dynamicIntegrationID;
    let refreshing;
    let refreshPending = false;
    const discoverySettings = ctx.options ?? {};

    await ctx.provider.transform((editor) => {
      for (const { group, models } of inventory.values()) {
        const groupProviderID = Provider.ID.make(group.id);
        const definition = editor.get(providerID);
        const source = definition?.provider ?? definition;
        if (!source) continue;

        const settings = { ...source.settings };
        const info = {
          ...Provider.Info.empty(groupProviderID),
          name: group.name,
          package: group.package,
          settings,
          headers: source.headers,
          integrationID: dynamicIntegrationID ?? source.integrationID,
          activation: "enabled",
        };

        if (!editor.get(groupProviderID)) editor.add({ info, models: [] });
        else editor.update(groupProviderID, (draft) => Object.assign(draft, info));

        const existing = [...(editor.get(groupProviderID)?.models.values() ?? [])];
        const ids = new Set(existing.map((model) => String(model.id)));
        editor.models.set(groupProviderID, [
          ...existing,
          ...models.filter((model) => !ids.has(String(model.id))),
        ]);
      }
    });

    const refreshOnce = async () => {
      const provider = await findProvider(ctx);
      const configuredGroups = discoverySettings.providerGroups;
      if (!Array.isArray(configuredGroups)) return;
      const baseURL = provider?.settings?.baseURL;
      if (typeof baseURL !== "string" || !URL.canParse(baseURL)) return;

      try {
        const auth = await resolveAgentGatewayAuth(provider, ctx, discoverySettings);
        dynamicIntegrationID = auth.integrationID;
        const headers = auth.headers;
        headers.set("accept", "application/json");
        const endpoint = new URL("models", `${baseURL.replace(/\/+$/, "")}/`);
        const response = await fetch(endpoint, { headers, signal: AbortSignal.timeout(5000) });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);

        const payload = await response.json();
        if (!Array.isArray(payload?.data)) throw new Error("expected a data array in the model-list response");

        const groups = new Map();
        for (const raw of payload.data) {
          const group = groupAgentGatewayModel(raw, configuredGroups, provider.package);
          if (!group) continue;
          const mapped = mapAgentGatewayModel(raw);
          if (!mapped) continue;
          const groupProviderID = Provider.ID.make(group.id);
          const id = Model.ID.make(group.modelID);
          const model = Object.assign(Model.Info.default(groupProviderID, id), mapped, {
            id,
            modelID: Model.ID.make(raw.id),
            providerID: groupProviderID,
          });
          const state = groups.get(group.id) ?? { group, models: new Map() };
          state.models.set(group.modelID, model);
          groups.set(group.id, state);
        }

        const nextInventory = new Map([...groups].map(([id, state]) => [
          id,
          { group: state.group, models: [...state.models.values()] },
        ]));
        const changed = JSON.stringify(nextInventory) !== JSON.stringify(inventory);
        inventory = nextInventory;
        if (changed) await ctx.provider.reload();
      } catch (error) {
        const detail = error instanceof Error ? error.message : String(error);
        console.warn(`[opencode-agentgateway-discovery] refresh failed: ${detail}`);
      }
    };

    const refresh = () => {
      if (refreshing) {
        refreshPending = true;
        return refreshing;
      }
      refreshing = (async () => {
        do {
          refreshPending = false;
          await refreshOnce();
        } while (refreshPending && !abort.signal.aborted);
      })().finally(() => {
        refreshing = undefined;
      });
      return refreshing;
    };

    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({ signal: abort.signal })) {
          if (REFRESH_EVENTS.has(event.type)) void refresh();
        }
      } catch {
        if (!abort.signal.aborted) console.warn("[opencode-agentgateway-discovery] event listener stopped");
      }
    })();

    await refresh();
    return () => abort.abort();
  },
});
