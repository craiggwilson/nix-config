function integrationRecords(value) {
  if (Array.isArray(value)) return value;
  return value && Array.isArray(value.data) ? value.data : [];
}

function requestedIntegration(provider, settings) {
  const configured = settings.authIntegration;
  if (typeof configured === "string" && configured.trim()) return configured.trim();
  return provider.integrationID || provider.id;
}

async function integrationIDs(integration, requested) {
  if (typeof requested !== "string" || !requested) return [];

  try {
    const records = integrationRecords(await integration.list());
    const named = records.find((item) =>
      typeof item?.name === "string" && item.name.toLowerCase() === requested.toLowerCase(),
    );
    const identified = records.find((item) => item?.id === requested);
    return [...new Set([identified?.id, named?.id, requested].filter((value) => typeof value === "string"))];
  } catch {
    return [requested];
  }
}

export async function resolveAgentGatewayAuth(provider, ctx, settings = provider.settings?.modelsDiscovery ?? {}) {
  const headers = new Headers();
  for (const [name, value] of Object.entries(provider.headers ?? {})) {
    if (typeof value === "string") headers.set(name, value);
  }

  const requested = requestedIntegration(provider, settings);
  const ids = await integrationIDs(ctx.integration ?? {}, requested);
  let integrationID = typeof settings.authIntegration === "string" && settings.authIntegration.trim()
    ? ids[0] ?? settings.authIntegration.trim()
    : provider.integrationID;

  if (headers.get("authorization")?.trim()) return { headers, integrationID };
  headers.delete("authorization");

  const apiKey = provider.settings?.apiKey;
  if (typeof apiKey === "string" && apiKey.trim()) {
    headers.set("authorization", `Bearer ${apiKey.trim()}`);
    return { headers, integrationID };
  }

  const integration = ctx.integration;
  if (!integration?.connection?.active || !integration?.connection?.resolve) return { headers, integrationID };

  for (const id of ids) {
    try {
      const connection = await integration.connection.active(id);
      if (!connection) continue;
      integrationID = id;

      if (connection.type === "env" && typeof connection.name === "string") {
        const value = process.env[connection.name];
        if (typeof value === "string" && value.trim()) {
          headers.set("authorization", `Bearer ${value.trim()}`);
          return { headers, integrationID };
        }
      }

      const credential = await integration.connection.resolve(connection);
      const value = credential?.type === "oauth" ? credential.access : credential?.type === "key" ? credential.key : undefined;
      if (typeof value === "string" && value.trim()) {
        headers.set("authorization", `Bearer ${value.trim()}`);
        return { headers, integrationID };
      }
    } catch {
      // Another configured integration may still provide the active credential.
    }
  }

  return { headers, integrationID };
}
