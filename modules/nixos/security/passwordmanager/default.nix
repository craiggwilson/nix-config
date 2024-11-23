{
  config,
  lib,
  ...
}:
{
  options.hdwlinux.security.passwordmanager = {
    enable = lib.mkOption {
      description = "Whether to enable the password manager.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "passwordmanager" config.hdwlinux.features.tags);
    };
  };
}
