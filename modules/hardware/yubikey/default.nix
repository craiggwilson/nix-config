{
  config.substrate.modules.hardware.yubikey = {
    tags = [ "yubikey" ];
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
        ++ lib.optionals (hasTag "gui") [
          pkgs.yubioath-flutter
        ];
      };
  };
}
