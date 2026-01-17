{ lib, pkgs, ... }:
pkgs.buildGoModule rec {
  pname = "slack-mcp-server";
  version = "1.1.28";

  src = pkgs.fetchFromGitHub {
    owner = "korotovsky";
    repo = "slack-mcp-server";
    rev = "v${version}";
    sha256 = "sha256-tA0JzWaMtYF0DC5xUm+hGAVEPvxBTMLau5lrhOQU9gU=";
  };

  subPackages = [ "cmd/slack-mcp-server" ];

  vendorHash = "sha256-CEg7OHriwCD1XM4lOCNcIPiMXnHuerramWp4//9roOo=";

  meta = {
    mainProgram = "slack-mcp-server";
    description = "MCP server for Slack workspaces with Stdio, SSE and HTTP transports";
    homepage = "https://github.com/korotovsky/slack-mcp-server";
    license = lib.licenses.mit;
  };
}

