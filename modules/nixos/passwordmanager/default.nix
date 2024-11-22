{
  lib,
  config,
  ...
}:
{
  options.hdwlinux.passwordmanager = {
    enable = lib.mkOption {
      description = "Whether to enable a password manager.";
      type = lib.types.bool;
      default = (builtins.elem "cli" config.hdwlinux.features.tags);
    };
  };
}
