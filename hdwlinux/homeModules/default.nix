{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.hdwlinux;
in
{
  options.hdwlinux = lib.hdwlinux.sharedOptions // {
    mcpServers = lib.mkOption {
      description = "Options to set the mcp servers.";
      type = lib.types.attrsOf lib.hdwlinux.types.mcpServer;
      default = { };
    };
  };

  config = {
    lib.hdwlinux = {
      mkEnableOption =
        name: default:
        lib.mkOption {
          description = "Whether to enable ${name}";
          type = lib.hdwlinux.types.tags cfg.tags;
          default = default;
        };
    };
  };
}
