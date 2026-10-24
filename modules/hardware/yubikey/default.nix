{
  config.substrate.modules.hardware.yubikey = {
    tags = [ "core:security:yubikey" ];
    nixos =
      {
        lib,
        pkgs,
        hasTag,
        ...
      }:
      {
        environment.systemPackages = [
          pkgs.yubikey-manager
        ]
        ++ lib.optionals (hasTag "desktop") [
          pkgs.yubioath-flutter
        ];
      };
  };
}
