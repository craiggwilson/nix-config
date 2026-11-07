# Synology services

This directory contains configuration for applications running in Synology
Container Manager. It is intentionally separate from `modules/`: these are
not NixOS modules, and Synology itself is not managed by NixOS.

Each application is a Synology stack. A stack has its own generated
`compose.yaml` and managed configuration files. `synology-deploy` selects a
stack by name, copies it to the NAS, and runs it with Docker Compose over SSH.

The stacks are `agentgateway`, `certificates`, `homeassistant`, `keycloak`,
`paperless`, and `yuvomi`.

The deployment expects the Synology `docker` SMB share to be mounted locally
at `$HOME/mnt/synology/docker`. Set `SYNOLOGY_MOUNT` to use another mount
point.

The runtime directory `/volume3/docker/homeassistant` is a new installation.
The previous installation is intentionally left untouched in
`homeassistant_old`.

## Deploy

From a machine with Nix, SSH access to the NAS, and a working `docker compose`
command on Synology:

```bash
nix run .#synology-deploy -- synology homeassistant
```

An alternate remote directory can be supplied as the third argument. The
default for the `homeassistant` stack is `/volume3/docker/homeassistant`.

### Yuvomi and Paperless

Both new stacks keep their application data under `/volume3/docker/<stack>`.
Their secrets are resolved from the local SecretSpec/1Password configuration
during deployment; no manually maintained `.env` file is needed:

```bash
mkdir -p "$HOME/mnt/synology/docker/yuvomi" "$HOME/mnt/synology/docker/paperless"
```

Create these 1Password items once, if they do not already exist:

- `Craig/Yuvomi`: `session_secret`, `db_encryption_key`
- `Craig/Paperless`: `postgres_password`, `secret_key`

Keep the Yuvomi database encryption key backed up in 1Password; losing it makes
the encrypted database unrecoverable. Deployment materializes protected secret
files under each stack's `secrets/` directory and refreshes them on every
deployment.

Deploy them with:

```bash
nix run .#synology-deploy -- synology yuvomi
nix run .#synology-deploy -- synology paperless
```

Deployment is deliberately non-destructive: existing managed files are compared
first, missing files are added, and deployment stops instead of overwriting any
existing file that differs from the Nix-generated version. Secret files are the
exception: they are intentionally refreshed from SecretSpec on each deploy.

Yuvomi listens on port `3000`; Paperless-ngx listens on port `8010`. After
creating the Paperless admin account, configure Yuvomi’s Documents module to
use Paperless at `http://synology:8010` (or the NAS hostname/IP reachable from
the Yuvomi container) and create the Paperless API token requested by Yuvomi.
Put both services behind the existing HTTPS reverse-proxy setup before using
them outside the LAN. Yuvomi’s private-network DMS access is enabled because
Paperless is a local service.

### Keycloak

Identity provider for the homelab at `https://auth.wilsonfamilyhq.com`
(port `8080` on the NAS, realm `wilsonfamilyhq.com`). It issues tokens for
agentgateway (OpenCode traffic and the agentgateway admin UI); see its module
in `modules/homelab/` for the secrets. Data lives in `/volume3/docker/keycloak/pgdata`.

```bash
nix run .#synology-deploy -- synology keycloak
```

The stack needs one 1Password item (`KEYCLOAK_ENV`: `POSTGRES_PASSWORD`,
`KC_BOOTSTRAP_ADMIN_PASSWORD`, and any other Keycloak env values). Clients
defined in the realm: `opencode` (CLI/login to agentgateway) and
`agentgateway-ui` (admin UI).

### Agentgateway

LLM/MCP proxy at `https://agents.wilsonfamilyhq.com` (port `4000`). It fronts
the OpenCode Go subscription (`opencode-go/*` models) against Keycloak-backed
OIDC; OpenCode authenticates with the `opencode-keycloak-auth` plugin, and the
`agentgateway-ui` client protects the admin UI.

```bash
nix run .#synology-deploy -- synology agentgateway
```

Secrets: `AGENTGATEWAY_OIDC_ENV` (OIDC client credentials for the inbound
Keycloak integration) and `AGENTGATEWAY_OPENCODE_GO_API_KEY` (OpenCode Go API
key), both in the 1Password item(s) referenced by `modules/homelab/`.

The gateway reads its model catalog from
`/volume3/docker/agentgateway/config/opencode-go-models.json`. Regenerate it
after opencode-go publishes new models: the upstream `models` response states
each model's wire format in `api` (`chat-completions`, `responses`,
`messages`, `generate-content`), and the script routes on that field into the
matching `opencode-go/*` provider (an unknown `api` kind fails the refresh):

```bash
nix run .#synology-agentgateway-refresh-catalog
```

`config.yaml` routes one provider and wire format per upstream endpoint:
`opencode-go/openai` (completions, `/inference/go/openai/v1`),
`opencode-go/openai-responses` (responses, same base),
`opencode-go/anthropic` (messages, `/inference/go/anthropic/v1`), and
`opencode-go/google` (generateContent, `/inference/go/google` — the gateway
renders `/v1beta/models/{model}:generateContent` itself). Providers advertise
only the formats their upstream serves, and the gateway converts between the
inbound wire format and the target provider's format per request (limitations
live in agentgateway's conversion table; notably Completions cannot reach
responses-only providers, which is why OpenCode's plugin config maps the
`opencode-go/openai-responses` group to the Responses package). The upstream
requires an `x-opencode-session` request header for affinity; OpenCode sends
one on every model request and the gateway forwards it, but external scripts
against the gateway's LLM routes must set it themselves.

`config.yaml` restarts are only needed when the file changes (the gateway
watches the catalog files):

```bash
ssh -tt synology 'sudo /usr/local/bin/docker compose -f /volume3/docker/agentgateway/compose.yaml restart agentgateway'
```

From OpenCode the opencode-go models appear grouped by their upstream API
format, for example `agentgateway-opencode-go/<model>`,
`agentgateway-opencode-go-anthropic/<model>`,
`agentgateway-opencode-go-responses/<model>`, and
`agentgateway-opencode-go-google/<model>`.

Virtual models ("tiers") are defined in `config.yaml` under
`llm.virtualModels` and appear as `agentgateway-virtual/<tier>`; personal
OpenCode aliases point at them 1:1 in
`modules/ai/clients/models/default.nix`. Named after what they cost/choose,
not what they are: `smart`, `balanced`, `coding`, `fast`, `free`. Each is a
failover chain (priority order) so the underlying model can be swapped or
degraded without touching OpenCode. Chain target routing follows agentgateway's
conversion table: targets must be completable from OpenCode's Completions wire
format (completions + anthropic-messages + generateContent routes are fine);
responses-only providers (`opencode-go/openai-responses`, Copilot GPT/Grok) are
not convertible and cannot join a tier chain.

Known limitation: the google group fails on agentic (tool-bearing) requests.
OpenCode's zod tool schemas emit `exclusiveMinimum`, agentgateway's
Gemini schema allowlist (ported from litellm) passes the key through, and the
Gemini API proto rejects it; agentgateway's code still has this list at head.
Plain text requests converted to generateContent work. The proper fix —
remapping the exclusive bounds like `gemini-json-schema.ts` does in OpenCode's
own Gemini protocol — belongs upstream in agentgateway.

#### GitHub Copilot

The `config.yaml` (`copilot/*` model) routes requests whose model is
`copilot/<model>` to `api.githubcopilot.com`. All LLM traffic to the gateway —
including Copilot-routed requests — still requires a Keycloak JWT, so the
Keycloak identity stays the front door. Keycloak cannot issue GitHub tokens,
so the outbound Copilot credential is a GitHub OAuth token supplied through
the environment: agentgateway discovers `GH_COPILOT_TOKEN` (or the `gh` CLI
config files; no environment means no credential). agentgateway never obtains
or refreshes the token, so refresh it manually:

```bash
# On a host with the gh CLI. Use the OAuth device flow (gho_... token);
# personal access tokens (`ghp_...`) are rejected by the Copilot API.
gh auth login
gh auth token
```

Store the token in 1Password (Homelab vault, `agentgateway` item,
`github_copilot_token` field). Deployment then injects it as `GH_COPILOT_TOKEN`
into the container through the agentgateway OIDC environment file. After
changing the token or `config.yaml`, redeploy and restart:

```bash
nix run .#synology-deploy -- synology agentgateway
ssh -tt synology 'sudo /usr/local/bin/docker compose -f /volume3/docker/agentgateway/compose.yaml restart agentgateway'
```

The gateway reads the Copilot model listing (and costs, grafted from
agentgateway's upstream catalog) from
`/volume3/docker/agentgateway/config/copilot-models.json`. Regenerate it after
Copilot adds models:

```bash
nix run .#synology-agentgateway-refresh-copilot-catalog
```

From OpenCode the models appear as `agentgateway/copilot/<model>` (for
example `agentgateway/copilot/claude-sonnet-5.5`).

### Certificates

Not a container stack: it manages the Namecheap DNS-01 ACME secret files
(`ACME_NAMECHEAP_*`) and the `issue-global.sh` / `renew.sh` scripts that
Synology's acme.sh setup sources. `lifecycle = false` means deploy skips the
fetch/docker-compose steps. It also provides a helper to pull the
`*.wilsonfamilyhq.com` certificate and private key off the NAS (for example,
for UniFi controller upload):

```bash
nix run .#synology-certificates-download
```

### Home Assistant

The Home Assistant data directory is deliberately left on the NAS. Nix
manages the container definition, but does not replace mutable application
state such as Home Assistant's database and runtime-generated files.

The initial `configuration.yaml` is also generated by Nix. The deployment
updates the files managed by the selected stack, but does not use `--delete`.
It will not remove application data or configuration files that are not part
of the stack definition. For example, `scripts.yaml` currently remains
NAS-managed until we deliberately move it into Nix.

## Pulling configuration from Synology

Home Assistant can edit YAML files and UI-managed state while it is running.
Pull selected configuration files into the repository before committing them:

```bash
nix run .#synology-pull -- \
  homeassistant \
  synology/stacks/homeassistant/files
```

The pull command excludes runtime state, the recorder database, logs, secrets,
and the old custom-components directory. It does not delete files from the
repository. Review the result before committing it.

To add another application, add a file under `synology/stacks/` and register it
in the `stacks` attribute in `synology/default.nix`. The file should provide a
`compose` attribute and may provide a `files` attribute containing managed
configuration files.

Secrets are not included here; add them only through the private/secrets
workflow once the first integrations require them.

## Initial device onboarding

The old installation contained these useful devices and integrations:

- three Roku devices: Game Room, Master Bedroom, and Living Room;
- the Lennox iComfort S30 upstairs thermostat through HomeKit Controller;
- the Synology NAS and Brother HL-L2380DW printer;
- Pi-hole;
- Govee H6050 Office Desk Lamp and H6199 Game Room TV Lights.

These should be added from **Settings → Devices & services** after the clean
instance starts. Their old Home Assistant IDs are not reused. Roku and several
LAN integrations should be discovered automatically because the container uses
host networking. The thermostat may require its HomeKit pairing code. The old
Govee custom component is not copied; try the current built-in Govee local
integration instead.
