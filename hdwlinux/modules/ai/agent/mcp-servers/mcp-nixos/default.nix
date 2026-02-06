{
  # Temporarily disabled due to dependency conflict:
  # mcp-nixos requires fastmcp 2.12.5 which needs mcp<1.17.0
  # but nixpkgs has mcp 1.25.0
  # See: https://github.com/NixOS/nixpkgs/issues/XXXXX
  #
  config.substrate.modules.programs.mcp-nixos = {
    tags = [
      "programming"
      "ai:mcp"
    ];

    homeManager =
      { pkgs, ... }:
      {
        hdwlinux.ai.agent.mcpServers.nixos.stdio = {
          command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
          args = [ ];
        };
      };
  };
}
