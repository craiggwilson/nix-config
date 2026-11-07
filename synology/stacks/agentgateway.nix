let
  modelClassifications = {
    anthropic = [
      "claude-"
      "minimax-m3"
      "qwen3.7-"
      "qwen3.8-"
    ];
    google = [ "gemini-" ];
    openaiResponses = [
      "gpt-"
      "grok-"
      "muse-spark-"
    ];
  };
in
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

        jq --exit-status \
          --argjson classifications '${builtins.toJSON modelClassifications}' \
          '
          def has_prefix($prefixes):
            . as $model | any($prefixes[]; . as $prefix | $model | startswith($prefix));

          def classify:
            if has_prefix($classifications.anthropic) then
              {provider: "opencode-go/anthropic", tag: "anthropic_messages"}
            elif has_prefix($classifications.google) then
              {provider: "opencode-go/google", tag: null}
            elif has_prefix($classifications.openaiResponses) then
              {provider: "opencode-go/openai-responses", tag: "openai_responses"}
            else
              {provider: "opencode-go/openai", tag: "openai_completions"}
            end;

          .data
          | if type == "array" then . else error("OpenCode models response has no data array") end
          | reduce .[] as $model ({providers: {}};
            ($model.id | classify) as $classification
            | .providers[$classification.provider].models //= {}
            | .providers[$classification.provider].models[$model.id] = {
                name: ($model.name // $model.id),
                tags: (if $classification.tag == null then [] else [$classification.tag] end)
              }
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
