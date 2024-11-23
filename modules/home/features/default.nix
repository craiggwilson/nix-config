{
  lib,
  ...
}:
{
  options.hdwlinux.features = {
    tags = lib.mkOption {
      description = "Tags used to identify feature enablement.";
      type = lib.hdwlinux.tags;
      default = [ ];
    };
  };
}
