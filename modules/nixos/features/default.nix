{
  lib,
  ...
}:
{
  options.hdwlinux.features = {
    tags = lib.hdwlinux.mkOpt (lib.types.listOf lib.types.str) [ ] "The tags for features enablement.";
  };
}
