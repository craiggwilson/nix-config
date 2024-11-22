{
  lib,
  ...
}:
{
  options.hdwlinux.features = {
    tags = lib.mkOption {
      description = "The tags for features enablement.";
      type = (lib.types.listOf lib.types.str);
      default = [ ];
    };
  };
}
