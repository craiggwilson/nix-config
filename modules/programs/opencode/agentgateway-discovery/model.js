const DEFAULT_CONTEXT = 200_000;
const DEFAULT_OUTPUT = 32_000;

const FORMAT_PACKAGES = {
  completions: "@opencode/ai/providers/openai-compatible",
  responses: "@opencode/ai/providers/openai-compatible/responses",
};

function positiveInteger(value) {
  return Number.isSafeInteger(value) && value > 0 ? value : undefined;
}

function stringArray(value, fallback) {
  return Array.isArray(value) ? value.filter((item) => typeof item === "string") : fallback;
}

function supportsParameter(model, ...names) {
  return Array.isArray(model.supported_parameters) && names.some((name) => model.supported_parameters.includes(name));
}

export function mapAgentGatewayModel(model) {
  if (!model || typeof model.id !== "string" || !model.id.trim()) return undefined;

  const architecture = model.architecture ?? {};
  const reported = model.capabilities ?? {};
  const context = positiveInteger(model.context_window) ?? positiveInteger(model.context_length) ?? DEFAULT_CONTEXT;
  const input = positiveInteger(model.max_input_tokens);
  const output = positiveInteger(model.max_tokens) ?? Math.min(context, DEFAULT_OUTPUT);
  const inputModalities = stringArray(architecture.input_modalities, ["text"]);
  const outputModalities = stringArray(architecture.output_modalities, ["text"]);
  const tools = typeof reported.tools === "boolean" ? reported.tools : supportsParameter(model, "tools", "tool_choice");
  const temperature = typeof reported.temperature === "boolean"
    ? reported.temperature
    : supportsParameter(model, "temperature") ? true : undefined;
  const reasoning = typeof reported.reasoning === "boolean"
    ? reported.reasoning
    : supportsParameter(model, "reasoning", "reasoning_effort");

  return {
    id: model.id,
    modelID: model.id,
    name: typeof model.name === "string" && model.name.trim() ? model.name : model.id,
    capabilities: {
      tools,
      input: inputModalities,
      output: outputModalities,
      ...(temperature !== undefined ? { temperature } : {}),
    },
    ...(reasoning ? { compatibility: { reasoningField: "reasoning_content" } } : {}),
    limit: {
      context,
      ...(input ? { input } : {}),
      output,
    },
    time: {
      released: typeof model.created === "number" && Number.isFinite(model.created) ? model.created * 1000 : 0,
    },
  };
}

function providerID(owner) {
  const suffix = owner.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "unknown";
  return `agentgateway-${suffix}`;
}

export function groupAgentGatewayModel(model, configuredGroups = [], defaultPackage) {
  if (!model || typeof model.id !== "string" || !model.id.trim()) return undefined;

  const owner = typeof model.owned_by === "string" && model.owned_by.trim()
    ? model.owned_by.trim()
    : "unknown";
  const config = configuredGroups.find((group) => group.ownedBy === owner)
    ?? configuredGroups.find((group) => typeof group.modelIdPrefix === "string" && model.id.startsWith(group.modelIdPrefix))
    ?? {};
  const modelIdPrefix = typeof config.modelIdPrefix === "string" && model.id.startsWith(config.modelIdPrefix)
    ? config.modelIdPrefix
    : `${owner}/`;
  const formatPackage = FORMAT_PACKAGES[config.clientFormat];

  return {
    id: typeof config.id === "string" && config.id ? config.id : providerID(owner),
    modelID: model.id.startsWith(modelIdPrefix) ? model.id.slice(modelIdPrefix.length) : model.id,
    name: typeof config.name === "string" && config.name ? config.name : `AgentGateway - ${owner}`,
    owner,
    package: typeof config.package === "string" ? config.package : formatPackage ?? defaultPackage,
    routeModelID: model.id,
  };
}
