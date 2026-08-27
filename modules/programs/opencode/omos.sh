# Starts opencode with an explicit loopback port so oh-my-opencode-slim can
# attach subagent panes from the multiplexer. opencode's default (port 0)
# exposes no TCP listener for `opencode attach`.
set -eu

port=""

for arg in "$@"; do
  case "$arg" in
    --port=*)
      port="${arg#--port=}"
      break
      ;;
  esac
done

if [ -z "$port" ]; then
  pick_next=
  for arg in "$@"; do
    if [ -n "$pick_next" ]; then
      port="$arg"
      break
    elif [ "$arg" = "--port" ]; then
      pick_next=1
    fi
  done
fi

if [ -n "$port" ]; then
  OPENCODE_PORT="$port" exec opencode "$@"
fi

# Explicit ports collide across multiple instances; ask the OS for a free one
port="$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')" || exit 1
OPENCODE_PORT="$port" exec opencode --port "$port" "$@"