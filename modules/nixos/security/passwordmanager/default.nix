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
      default = (builtins.elem "cli" config.hdwlinux.features.tags);
    };
  };
}
