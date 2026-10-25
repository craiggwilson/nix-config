{ ... }:
let
  hostname = "soulsmith";
  diskoConfig = import ./_disko.nix;
in
{
  substrate.hosts.${hostname} = {
    # Raspberry Pi 4 is supported through the 64-bit ARM image path.
    system = "aarch64-linux";
    users = [ "craig@server" ];
    tags = [
      "host:${hostname}"
      "core:base"
      "core:networking:tailscale"
      "core:ssh"
      "hardware:raspberry-pi-4"
      "role:server"
    ];
  };

  substrate.modules.hosts.${hostname} = {
    tags = [ "host:${hostname}" ];

    nixos = {
      imports = [ diskoConfig ];

      system.stateVersion = "26.05";
    };
  };
}
