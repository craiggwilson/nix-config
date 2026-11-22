# AI client configuration

## Purpose

Define the shared AI-client configuration contract and the OpenCode rendering behavior that consumes it. This baseline covers client-neutral definitions, model routing, tool permissions, and secret-aware MCP configuration; it does not guarantee external provider availability or authentication success.

## Requirements

### Requirement: Shared client definitions

The configuration SHALL expose agents, commands, MCP servers, rules, skills, scheduled tasks, and tool permissions as typed client options. MCP transports SHALL distinguish stdio from HTTP.

#### Scenario: Shared client schema and permissions

- WHEN no client definitions are supplied
- THEN collections without definitions remain empty, and the AI profile contributes its shared tool permission rules even without client-specific overrides

#### Scenario: Invalid client definition

- WHEN a definition omits a required typed field or uses an unsupported MCP transport shape
- THEN module evaluation rejects the definition

### Requirement: Model aliases resolve through declared providers

The model configuration SHALL accept only the aliases `analysis`, `balanced`, `code-review`, `coding`, `fast`, `orchestration`, `research`, and `writing`. Each alias SHALL have a non-empty ordered list referencing configured providers; the first entry SHALL be primary and later entries SHALL be fallbacks.

#### Scenario: Valid alias with fallback models

- WHEN an allowed alias contains multiple models from configured providers
- THEN the entries remain in their declared order with the first entry primary

#### Scenario: Invalid alias configuration

- WHEN an alias name is unsupported, its model list is empty, or it references an unknown provider
- THEN evaluation fails with the corresponding alias or provider assertion

### Requirement: Provider credentials remain references

Provider authentication SHALL identify credentials by environment-variable name. OpenCode SHALL render that reference without embedding the credential value, and SHALL omit providers that are built-in or have no base URL.

#### Scenario: Render a custom provider with credential reference

- WHEN a non-built-in provider has a base URL and an auth reference
- THEN its OpenCode provider configuration uses the declared header and prefix with an environment reference

#### Scenario: Do not render an inapplicable custom provider

- WHEN a provider is built-in or has no base URL
- THEN it is omitted from OpenCode's custom provider map

### Requirement: MCP secrets are adapted per client capability

The shared configuration SHALL expose unique MCP secret names and a read-only secret-free server subset. Generic `programs.mcp` SHALL receive only that subset. OpenCode SHALL render secret references, load required materialized values at launch, and omit `context7-mcp` from its server map.

#### Scenario: Configure a secret-free MCP server

- WHEN a server has no secret-bearing headers
- THEN it is included in the generic MCP server map and can be rendered by OpenCode

#### Scenario: Exclude a secret-bearing server from generic MCP integration

- WHEN a server header references a secret
- THEN the server is absent from `mcpServersWithoutSecrets` and generic `programs.mcp`, while OpenCode represents the value as an environment reference

#### Scenario: Missing materialized OpenCode MCP secret

- WHEN OpenCode starts with a required secret file missing or empty
- THEN its launcher reports the missing secret file and exits instead of starting without the credential

#### Scenario: Shared Context7 server

- WHEN OpenCode builds its MCP server map
- THEN it omits `context7-mcp` from that map

### Requirement: Tool permissions preserve intent when rendered

Tool permissions SHALL support `allow`, `ask`, and `deny`, globally or per resource pattern. OpenCode SHALL emit action/resource/effect entries, map `bash`, `task`, and `write` to `shell`, `subagent`, and `edit`, and order wildcard resources before specific ones.

#### Scenario: Render a global and a pattern-specific permission

- WHEN permissions include a global action and per-resource rules
- THEN OpenCode receives corresponding action/resource/effect entries with wildcard rules before specific rules

#### Scenario: Translate renamed actions

- WHEN permissions use `bash`, `task`, or `write`
- THEN OpenCode receives `shell`, `subagent`, or `edit`, respectively

## Sources

- Shared client schemas and defaults: [client option types](../../../modules/ai/clients/default.nix#L13-L79), [task and MCP types](../../../modules/ai/clients/default.nix#L82-L273), [client options](../../../modules/ai/clients/default.nix#L276-L352)
- Model aliases and validation: [alias definitions and assertions](../../../modules/ai/clients/models/default.nix#L8-L17) · [provider/alias schema and checks](../../../modules/ai/clients/models/default.nix#L19-L155) · [OpenCode resolution](../../../modules/programs/opencode/default.nix#L16-L28)
- Provider credentials: [provider schema](../../../modules/ai/clients/models/default.nix#L19-L86) · [OpenCode rendering](../../../modules/programs/opencode/default.nix#L99-L125)
- MCP secret filtering and integration: [secret reference type](../../../modules/ai/clients/default.nix#L163-L191) · [derived options](../../../modules/ai/clients/default.nix#L295-L319) · [generic integration](../../../modules/ai/clients/default.nix#L355-L379) · [OpenCode rendering and startup](../../../modules/programs/opencode/default.nix#L137-L220)
- Tool permission types and rendering: [shared types](../../../modules/ai/clients/default.nix#L13-L19) · [OpenCode translation](../../../modules/programs/opencode/default.nix#L29-L78)
