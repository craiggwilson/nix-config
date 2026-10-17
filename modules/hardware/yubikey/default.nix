{
  config.substrate.modules.hardware.yubikey = {
    provides = [ "hardware:yubikey" ];
    nixos =
      {
        lib,
        pkgs,
        hasCapability,
        ...
      }:
      {
        environment.systemPackages = [
          pkgs.yubikey-manager
        ]
        ++ lib.optionals (hasCapability "gui") [
          pkgs.yubioath-flutter
        ];
      };
  };
}
