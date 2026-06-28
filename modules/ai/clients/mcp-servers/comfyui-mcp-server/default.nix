{
  config.substrate.modules.ai.clients.mcp-servers.comfyui-mcp-server = {
    tags = [
      "ai:clients"
      "ai:image"
      "gui"
    ];

    homeManager =
      { config, ... }:
      let
        svc = config.hdwlinux.services.comfy-ui-mcp;
      in
      {
        hdwlinux.ai.clients.mcpServers.comfyui.http.url = "http://${svc.host}:${toString svc.port}/mcp";
      };
  };
}
