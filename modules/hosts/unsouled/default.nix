{ inputs, ... }:
let
  hostname = "unsouled";
  diskoConfig = import ./_disko.nix;
in
{
  substrate.hosts.${hostname} = {
    system = "x86_64-linux";
    # Host-local facts: the identity, the machine model, and the location.
    # Modules require these instead of re-claiming them.
    provides = [
      "host:${hostname}"
      "hardware:model:dell-xps-15-9520"
      "location:raeford"
    ];
    nixpkgsConfig.cudaSupport = true;
    users = [ "craig@work" ];
    tags = [
      "host:${hostname}"
    ];

    requires = [
      "host:${hostname}"

      # Hardware model: provided by the dell-xps-15-9520 module. The leaves
      # are named here (and on unsouled's analogue) because capability
      # requires filter rather than pull — the model module never joins if
      # the roots do not name what it concretely configures.
      "hardware:model:dell-xps-15-9520"
      "hardware:audio"
      "hardware:bluetooth"
      "hardware:camera"
      "hardware:graphics"
      "hardware:graphics:cuda"
      "hardware:graphics:nvidia"
      "hardware:laptop"
      "hardware:monitors"
      "hardware:networking"
      "hardware:thunderbolt"

      # System services local to this machine.
      "boot:systemd"
      "hardware:printing"
      "hardware:scanning"

      # Core: minimal cross-class utilities and interfaces, named
      # specifically (there is no bare-core sweep or aggregator; matching
      # is exact, wildcards explicit).
      "core:home"
      "core:interfaces"
      "core:nix"
      "core:networking"
      "core:session"
      "core:ssh"
      "core:systemd"
      "core:utils"
      "core:xdg"

      # Platform maintenance lives in the hardware domain, not core.
      "hardware:firmware"
      "hardware:power"
      "hardware:storage"
    ];
  };

  substrate.modules.hosts.${hostname} = {
    tags = [ "host:${hostname}" ];
    provides = [ "host:${hostname}" ];
    nixos =
      { pkgs, ... }:
      {
        imports = [
          inputs.disko.nixosModules.disko
          diskoConfig
        ];

        boot.kernelPackages = pkgs.linuxPackages_6_18;

        hdwlinux.theme.system = "catppuccin";
        system.stateVersion = "23.05";
      };
  };
}
