{ ... }:
let
  hostname = "wintersteel";
  diskoConfig = import ./_disko.nix;
in
{
  substrate.hosts.${hostname} = {
    # The GB10 is an ARM64 Grace Blackwell system, not an x86_64 PC.
    system = "aarch64-linux";
    nixpkgsConfig = {
      allowUnfree = true;
      cudaCapabilities = [
        "12.0"
        "12.1"
      ];
      cudaSupport = true;
    };
    users = [ "craig@server" ];
    tags = [
      "host:${hostname}"
      "capability:cuda"
      "core:networking:tailscale"
      "hardware:dell-pro-max-gb10"
      "service:ai:llm"
    ];
  };

  substrate.modules.hosts.${hostname} = {
    tags = [ "host:${hostname}" ];

    nixos =
      { lib, ... }:
      {
        imports = [ diskoConfig ];

        # Substrate supplies the package set with the same CUDA settings above;
        # hide the DGX module's duplicate nixpkgs.config definitions from NixOS's
        # externally-created-package-set assertion.
        nixpkgs.config = lib.mkForce { };

        hdwlinux.theme.system = "catppuccin";

        # Home Manager renamed this mode from `sdSwitch` to `sd-switch`.
        home-manager.users.craig.systemd.user.startServices = lib.mkForce "sd-switch";
        home-manager.users.craig.hdwlinux.services.llama-cpp.host = "0.0.0.0";

        networking.firewall.allowedTCPPorts = [ 9292 ];
        users.users.craig.linger = true;
        security.sudo.wheelNeedsPassword = false;
        services.openssh.settings.PermitRootLogin = "no";
        system.stateVersion = "26.05";
      };
  };
}
