_: {
  compose.services.agentgateway = {
    container_name = "agentgateway";
    environment = {
      ISSUER_URL = "https://auth.wilsonfamilyhq.com/realms/wilsonfamilyhq.com";
      REDIRECT_URI = "https://agents.wilsonfamilyhq.com/oauth/callback";
      RUST_LOG = "debug";
      UI_CLIENT_ID = "agentgateway-ui";
    };
    env_file = [ "/volume3/docker/agentgateway/secrets/oidc.env" ];
    extra_hosts = [ "auth.wilsonfamilyhq.com:192.168.100.50" ];
    image = "cr.agentgateway.dev/agentgateway:v1.7.0";
    ports = [ "4000:4000" ];
    restart = "unless-stopped";
    volumes = [
      "/volume3/docker/agentgateway/config:/config"
    ];
  };

  directories = [
    "config"
    "secrets"
  ];

  secrets = {
    "secrets/oidc.env" = "AGENTGATEWAY_OIDC_ENV";
  };

  commands.refresh-copilot-catalog =
    { pkgs, ... }:
    pkgs.writeShellApplication {
      name = "synology-agentgateway-refresh-copilot-catalog";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.curl
        pkgs.jq
        pkgs.secretspec
      ];
      text = ''
        if [[ -z ''${SECRETSPEC_FILE:-} || ! -r "$SECRETSPEC_FILE" ]]; then
          echo "SecretSpec manifest is unavailable." >&2
          exit 1
        fi

        mountRoot="''${SYNOLOGY_MOUNT:-$HOME/mnt/synology/docker}"
        catalogDirectory="$mountRoot/agentgateway/config"
        catalogFile="$catalogDirectory/copilot-models.json"
        modelsUrl="''${COPILOT_MODELS_URL:-https://api.githubcopilot.com/models}"
        baseCatalogUrl="''${AGENTGATEWAY_BASE_CATALOG_URL:-https://agentgateway.dev/model-catalog}"

        if [[ ! -d "$catalogDirectory" ]]; then
          echo "agentgateway config directory is not available: $catalogDirectory" >&2
          echo "Mount the Synology docker share or set SYNOLOGY_MOUNT." >&2
          exit 1
        fi

        umask 077
        curlConfig=$(mktemp)
        responseFile=$(mktemp)
        baseFile=$(mktemp)
        outputFile=$(mktemp "$catalogFile.XXXXXX")
        trap 'rm -f "$curlConfig" "$responseFile" "$baseFile" "$outputFile"' EXIT

        copilotToken=$(secretspec get AGENTGATEWAY_GITHUB_COPILOT_TOKEN \
          --file "$SECRETSPEC_FILE" \
          --reason "Refresh the agentgateway GitHub Copilot model catalog")
        printf 'header = "Authorization: Bearer %s"\n' "$copilotToken" > "$curlConfig"

        curl --config "$curlConfig" \
          --fail-with-body \
          --silent \
          --show-error \
          --retry 3 \
          "$modelsUrl" > "$responseFile"

        # Pricing is not in the Copilot models response; graft rates, release
        # dates, and tags from the agentgateway upstream catalog when
        # reachable. A failed (or rate-limited) upstream fetch yields a
        # catalog without costs instead of failing the whole refresh.
        curl --fail --location --silent --show-error \
          "$baseCatalogUrl" > "$baseFile" \
          || echo "Upstream agentgateway catalog unavailable; continuing without rates." >&2

        jq --exit-status \
          --slurpfile base "$baseFile" \
          '
          def strip_nulls:
            if type == "object" then
              with_entries(select(.value != null) | .value |= strip_nulls)
            elif type == "array" then map(strip_nulls)
            else . end;

          .data
          | if type == "array" then . else error("GitHub Copilot models response has no data array") end
          | map(select(.capabilities?.type == "chat"))
          | reduce .[] as $model ({providers: {}};
            (($model.capabilities.limits.vision.supported_media_types // [])
              | (if type == "string" then [.] else . end)
              | map(if test("image") then "image" elif test("pdf") then "pdf" else . end)
              | (["text"] + .)
              | unique) as $inputModalities
            | .providers.copilot.models //= {}
            | .providers.copilot.models[$model.id] = ({
                name: ($model.name // $model.id),
                released: ($base[0]?.providers?.copilot?.models?[$model.id]?.released // null),
                rates: ($base[0]?.providers?.copilot?.models?[$model.id]?.rates // null),
                tags: ($base[0]?.providers?.copilot?.models?[$model.id]?.tags // []),
                limits: {
                  context: $model.capabilities.limits.max_context_window_tokens,
                  output: $model.capabilities.limits.max_output_tokens,
                },
                modalities: {
                  input: $inputModalities,
                  output: ["text"],
                },
                capabilities: {
                  toolCall: ($model.capabilities.supports.tool_calls // false),
                  reasoning: ($model.capabilities.supports.reasoning_effort != null),
                  structuredOutput: ($model.capabilities.supports.structured_outputs // false),
                  temperature: true,
                },
                reasoning: (
                  if $model.capabilities.supports.reasoning_effort != null then
                    { effort: $model.capabilities.supports.reasoning_effort }
                  else null end
                ),
              } | strip_nulls)
          )
        ' "$responseFile" > "$outputFile"

        jq -r '.providers.copilot.models | length' "$outputFile"
        jq -r '[.providers.copilot.models[] | select(.rates.input != null)] | length' "$outputFile"

        chmod 644 "$outputFile"
        mv -f "$outputFile" "$catalogFile"
        echo "Wrote catalog to $catalogFile"
      '';
    };

  commands.refresh-catalog =
    { pkgs, ... }:
    pkgs.writeShellApplication {
      name = "synology-agentgateway-refresh-catalog";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.curl
        pkgs.jq
        pkgs.secretspec
      ];
      text = ''
        if [[ -z ''${SECRETSPEC_FILE:-} || ! -r "$SECRETSPEC_FILE" ]]; then
          echo "SecretSpec manifest is unavailable." >&2
          exit 1
        fi

        mountRoot="''${SYNOLOGY_MOUNT:-$HOME/mnt/synology/docker}"
        catalogDirectory="$mountRoot/agentgateway/config"
        catalogFile="$catalogDirectory/opencode-go-models.json"
        modelsUrl="''${OPENCODE_GO_MODELS_URL:-https://opencode.ai/inference/go/v1/models}"

        if [[ ! -d "$catalogDirectory" ]]; then
          echo "agentgateway config directory is not available: $catalogDirectory" >&2
          echo "Mount the Synology docker share or set SYNOLOGY_MOUNT." >&2
          exit 1
        fi

        umask 077
        curlConfig=$(mktemp)
        responseFile=$(mktemp)
        outputFile=$(mktemp "$catalogFile.XXXXXX")
        trap 'rm -f "$curlConfig" "$responseFile" "$outputFile"' EXIT

        apiKey=$(secretspec get AGENTGATEWAY_OPENCODE_GO_API_KEY \
          --file "$SECRETSPEC_FILE" \
          --reason "Refresh the agentgateway OpenCode Go model catalog")
        printf 'header = "Authorization: Bearer %s"\n' "$apiKey" > "$curlConfig"

        curl --config "$curlConfig" \
          --fail-with-body \
          --silent \
          --show-error \
          --retry 3 \
          "$modelsUrl" > "$responseFile"

        jq --exit-status '
          # The upstream models response carries each model's wire format in `api`
          # (keys: chat-completions | responses | messages | generate-content). Route by
          # that instead of id prefixes so new models land in the right provider by default.
          # Provider names must match the gateway llm.providers entries in config.yaml.
          def route($kind):
            if $kind == "chat-completions" then
              {provider: "opencode-go/openai", tag: "openai_completions"}
            elif $kind == "responses" then
              {provider: "opencode-go/openai-responses", tag: "openai_responses"}
            elif $kind == "messages" then
              {provider: "opencode-go/anthropic", tag: "anthropic_messages"}
            elif $kind == "generate-content" then
              {provider: "opencode-go/google", tag: "vertex_gemini"}
            else error("unknown upstream api type: \($kind)") end;

          # Class names (text/image/audio/video/file) rather than upstream MIME types;
          # OpenCode matches input modalities with prefix checks.
          def modality:
            if startswith("image/") then "image"
            elif startswith("audio/") then "audio"
            elif startswith("video/") then "video"
            elif . == "application/pdf" then "file"
            else . end;

          # Rates are micro-dollars per token, which equals the upstream $/M
          # price; agentgateway reads these as strings for cost tracking.
          # shortcut: time-of-day multipliers from the upstream
          # payload are dropped; upgrade when per-hour tracking is needed.
          def rate($price):
            if $price != null then ($price | tostring) else null end;

          def strip_nulls:
            if type == "object" then
              with_entries(select(.value != null) | .value |= strip_nulls)
            elif type == "array" then map(strip_nulls)
            else . end;

          .data
          | if type == "array" then . else error("OpenCode models response has no data array") end
          | reduce .[] as $model ({providers: {}};
              ($model.api // error("\($model.id): upstream response has no api field") | keys[0]) as $kind
              | route($kind) as $route
              | .providers[$route.provider].models //= {}
              | .providers[$route.provider].models[$model.id] = ({
                  name: ($model.name // $model.id),
                  released: $model.release_date,
                  rates: {
                    input: rate($model.cost?.text?.input?.price),
                    output: rate($model.cost?.text?.output?.price),
                    cacheRead: rate($model.cost?.text?.cache?.read),
                  },
                  tags: [$route.tag],
                  limits: {
                    context: $model.limit?.context,
                    output: $model.limit?.output,
                  },
                  modalities: {
                    input: ($model.modalities?.input // ["text"] | map(modality) | unique),
                    output: ($model.modalities?.output // ["text"] | map(modality) | unique),
                  },
                  capabilities: {
                    toolCall: $model.capabilities?.tools?.supported,
                    reasoning: $model.capabilities?.reasoning?.supported,
                    structuredOutput: $model.capabilities?.structured_output,
                    temperature: $model.capabilities?.temperature,
                  }
                } | strip_nulls)
            )
        ' "$responseFile" > "$outputFile"

        jq --exit-status '
          .providers["opencode-go/openai"].models //= {}
          | .providers["opencode-go/openai-responses"].models //= {}
          | .providers["opencode-go/anthropic"].models //= {}
          | .providers["opencode-go/google"].models //= {}
        ' "$outputFile" > "$outputFile.normalized"
        mv -f "$outputFile.normalized" "$outputFile"

        jq -r '
          .providers | to_entries[] | "\(.key): \(.value.models | length) models"
        ' "$outputFile"

        chmod 644 "$outputFile"
        mv -f "$outputFile" "$catalogFile"
        echo "Wrote catalog to $catalogFile"
      '';
    };
}
