{
  config,
  lib,
  pkgs,
  flake,
  ...
}:

let
  cfg = config.hdwlinux.programs.hdwlinux;
  user = config.hdwlinux.user.name;
in
{
  options.hdwlinux.programs.hdwlinux = {
    enable = lib.hdwlinux.mkEnableOption "hdwlinux" true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
        name = "hdwlinux";
        runtimeInputs = [
          pkgs.nix
          pkgs.nix-output-monitor
          pkgs.nvd
          pkgs.system76-power
        ];
        subcommands = {
          battery = {
            set-profile = "system76-power charge-thresholds --profile \"$@\"";
            "*" = "system76-power charge-thresholds";
          };
          build = {
            remote = ''
              hostname="$1"
              shift
              git -C ${flake} add -A . && sudo nixos-rebuild build --flake "${flake}#$hostname" "$@"
            '';
            "*" = ''git -C ${flake} add -A . && sudo nixos-rebuild build --flake ${flake} "$@"'';
          };
          config = "git -C ${flake} \"$@\"";
          develop = ''
            name="$1";
            shift;
            nix develop "${flake}#$name" -c "$SHELL" "$@";
          '';
          firmware = {
            update = "sudo system76-firmware-cli schedule";
          };
          flake = {
            update = "nix flake update --flake ${flake} \"$@\"";
            "*" = "echo ${flake}";
          };
          generations = {
            delete-older-than = "nix-collect-garbage --delete-older-than \"$@\"";
            diff = {
              newest = ''nvd diff "$(find /nix/var/nix/profiles/system-*-link | tail -2)"'';
              "*" = ''nvd diff "/nix/var/nix/profiles/system-$1-link" "/nix/var/nix/profiles/system-$2-link"'';
            };
            diff-closures = {
              newest = ''nix store diff-closures "$(find /nix/var/nix/profiles/system-*-link | tail -2)"'';
              "*" =
                ''nix store diff-closures "/nix/var/nix/profiles/system-$1-link" "/nix/var/nix/profiles/system-$2-link"'';
            };
            list = "nixos-rebuild list-generations \"$@\"";
          };
          packages = {
            list = "nvd list";
            run = ''
              name="$1";
              shift;
              nix run "nixpkgs#$name" -- "$@";
            '';
            shell = "nix-shell --command \"$SHELL\" -p \"$@\"";
            why-depends = "nix why-depends /run/current-system \"nixpkgs#$1\"";
          };
          switch = {
            remote = ''
              hostname="$1"
              addr="$2"
              shift 2
              git -C ${flake} add -A . && nixos-rebuild switch --flake "${flake}#$hostname" --target-host "${user}@$addr" --sudo "$@" --ask-sudo-password |& nom
            '';
            "*" = ''git -C ${flake} add -A . && sudo nixos-rebuild switch --flake ${flake} "$@" |& nom'';
          };
          wifi = {
            connect = "nmcli connection up \"$@\"";
            disconnect = ''
              active="$(nmcli -t -f active,ssid dev wifi | rg '^yes' | cut -d: -f2)"
              nmcli connection down "$active"
            '';
            off = "nmcli radio wifi off";
            on = "nmcli radio wifi on";
            "*" = ''
              status="$(nmcli radio wifi)"
              if [[ "$status" == 'disabled' ]]; then
                echo "disabled"
              else
                nmcli connection show
              fi
            '';
          };
        };
      })
    ];
  };
}
