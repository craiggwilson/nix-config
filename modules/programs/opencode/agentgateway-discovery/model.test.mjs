import assert from "node:assert/strict";
import test from "node:test";
import { resolveAgentGatewayAuth } from "./auth.js";
import { groupAgentGatewayModel, mapAgentGatewayModel } from "./model.js";

test("maps AgentGateway limits, modalities, and capabilities", () => {
  const model = mapAgentGatewayModel({
    architecture: { input_modalities: ["text", "image", "file"], output_modalities: ["text"] },
    capabilities: { reasoning: true, temperature: false, tools: true },
    context_window: 328_000,
    created: 1_798_000_000,
    id: "copilot/claude-sonnet-5.5",
    max_input_tokens: 200_000,
    max_tokens: 128_000,
    name: "Claude Sonnet 5.5",
  });

  assert.deepEqual(model, {
    capabilities: {
      input: ["text", "image", "file"],
      output: ["text"],
      temperature: false,
      tools: true,
    },
    compatibility: { reasoningField: "reasoning_content" },
    id: "copilot/claude-sonnet-5.5",
    limit: { context: 328_000, input: 200_000, output: 128_000 },
    modelID: "copilot/claude-sonnet-5.5",
    name: "Claude Sonnet 5.5",
    time: { released: 1_798_000_000_000 },
  });
});

test("uses the context_length alias and conservative capability defaults", () => {
  const model = mapAgentGatewayModel({
    context_length: 96_000,
    id: "opencode-go/openai/example",
    max_tokens: 8_000,
    supported_parameters: ["tools"],
  });

  assert.equal(model.limit.context, 96_000);
  assert.equal(model.limit.output, 8_000);
  assert.equal(model.capabilities.tools, true);
  assert.equal(model.capabilities.temperature, undefined);
  assert.deepEqual(model.capabilities.input, ["text"]);
});

test("rejects records without a nonempty model ID", () => {
  assert.equal(mapAgentGatewayModel({ id: "  " }), undefined);
  assert.equal(mapAgentGatewayModel(null), undefined);
});

test("groups by AgentGateway owned_by and preserves the route model ID", () => {
  assert.deepEqual(groupAgentGatewayModel({ id: "copilot/claude-sonnet-5.5", owned_by: "copilot" }, [
    {
      ownedBy: "copilot",
      id: "agentgateway-copilot",
      name: "AgentGateway - Copilot",
      modelIdPrefix: "copilot/",
      clientFormat: "responses",
    },
  ], "@opencode/ai/providers/openai-compatible"), {
    id: "agentgateway-copilot",
    modelID: "claude-sonnet-5.5",
    name: "AgentGateway - Copilot",
    package: "@opencode/ai/providers/openai-compatible/responses",
    owner: "copilot",
    routeModelID: "copilot/claude-sonnet-5.5",
  });
  assert.deepEqual(groupAgentGatewayModel({ id: "opencode-go/openai/qwen3.8-max", owned_by: "custom" }, [
    {
      id: "agentgateway-opencode-go",
      name: "AgentGateway - OpenCode Go",
      modelIdPrefix: "opencode-go/openai/",
      clientFormat: "completions",
    },
  ], "@opencode/ai/providers/openai-compatible"), {
    id: "agentgateway-opencode-go",
    modelID: "qwen3.8-max",
    name: "AgentGateway - OpenCode Go",
    package: "@opencode/ai/providers/openai-compatible",
    owner: "custom",
    routeModelID: "opencode-go/openai/qwen3.8-max",
  });
});

test("uses owned_by when no explicit group rule matches the model ID", () => {
  const group = groupAgentGatewayModel({ id: "deployment-123", owned_by: "new-vendor" });

  assert.equal(group.id, "agentgateway-new-vendor");
  assert.equal(group.name, "AgentGateway - new-vendor");
  assert.equal(group.modelID, "deployment-123");
});

test("resolves OAuth credentials by integration display name", async () => {
  const ctx = {
    integration: {
      list: async () => ({ data: [{ id: "work-sso", name: "Work SSO" }] }),
      connection: {
        active: async (id) => id === "work-sso" ? { id, type: "oauth" } : undefined,
        resolve: async () => ({ type: "oauth", access: "test-access-token" }),
      },
    },
  };
  const provider = { id: "agentgateway" };

  const auth = await resolveAgentGatewayAuth(provider, ctx, { authIntegration: "Work SSO" });
  assert.equal(auth.headers.get("authorization"), "Bearer test-access-token");
  assert.equal(auth.integrationID, "work-sso");
});

test("uses configured API-key auth when present", async () => {
  const auth = await resolveAgentGatewayAuth(
    { id: "agentgateway", settings: { apiKey: "test-api-key" } },
    {},
  );

  assert.equal(auth.headers.get("authorization"), "Bearer test-api-key");
});

test("uses the provider integration ID when no override is configured", async () => {
  const ctx = {
    integration: {
      list: async () => ({ data: [{ id: "gateway-auth", name: "Gateway OAuth" }] }),
      connection: {
        active: async (id) => id === "gateway-auth" ? { id } : undefined,
        resolve: async () => ({ type: "key", key: "test-key" }),
      },
    },
  };
  const provider = { id: "agentgateway", integrationID: "gateway-auth", settings: {} };

  const auth = await resolveAgentGatewayAuth(provider, ctx);
  assert.equal(auth.headers.get("authorization"), "Bearer test-key");
  assert.equal(auth.integrationID, "gateway-auth");
});
