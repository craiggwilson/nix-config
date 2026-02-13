# Default paths
HM_TOKEN_PATH="${XDG_CONFIG_HOME}/opnix/token"
NIXOS_TOKEN_PATH="/etc/opnix-token"

scope="home-manager"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope|-s)
      scope="$2"
      shift 2
      ;;
    *)
      echo "Error: Unknown argument '$1'" >&2
      echo "Usage: hdwlinux secrets set-token [--scope <home-manager|nixos>]" >&2
      exit 1
      ;;
  esac
done

if [[ "$scope" != "home-manager" && "$scope" != "nixos" ]]; then
  echo "Error: Invalid scope '$scope'. Must be 'home-manager' or 'nixos'." >&2
  exit 1
fi

if [[ "$scope" == "nixos" ]]; then
  token_path="$NIXOS_TOKEN_PATH"
else
  token_path="$HM_TOKEN_PATH"
fi

# Read token from stdin (never from command line to avoid history)
echo "Enter token (input hidden):"
read -rs token
echo

if [[ -z "$token" ]]; then
  echo "Error: No token provided." >&2
  exit 1
fi

# Create directory if needed
token_dir=$(dirname "$token_path")

if [[ "$scope" == "nixos" ]]; then
  sudo mkdir -p "$token_dir"
  echo "$token" | sudo tee "$token_path" > /dev/null
  sudo chmod 600 "$token_path"
  echo "Token written to $token_path (nixos scope)"
else
  mkdir -p "$token_dir"
  echo "$token" > "$token_path"
  chmod 600 "$token_path"
  echo "Token written to $token_path (home-manager scope)"
fi

