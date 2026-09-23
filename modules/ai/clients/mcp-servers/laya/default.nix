{
  config.substrate.modules.ai.clients.mcp-servers.laya = {
    tags = [
      "ai:clients"
    ];

    homeManager =
      { lib, pkgs, ... }:
      let
        port = 8787;
        layaMcp = pkgs.hdwlinux.laya-mcp;
      in
      {
        # Warm sidecar: the 421M checkpoint costs ~10s to load, and harnesses
        # spawn one stdio MCP server per session, so the model lives here once
        # and the stdio servers stay thin proxies (--sidecar).
        systemd.user.services.laya-serve = {
          Unit = {
            Description = "Laya System 1 decision model sidecar";
            Documentation = "https://github.com/PerryLink/laya-mcp";
          };
          Service = {
            # max-len sits far below the 8192-position encoder on purpose: needle
            # retrieval measured on this sidecar is solid only for evidence in the
            # first ~1k tokens (front-position holds P>0.95 at any size; middle
            # and tail collapse to coin-flip by 1.5k). A bigger budget would let
            # states fit that look answered but aren't read; oversized states cut
            # front-kept and report `truncated`. ~36ms worst case on GPU.
            # head_max-len keeps options at their full 48-token render.
            ExecStart = "${lib.getExe layaMcp} serve --model english --device cuda --max-len 1024 --head-max-len 1024 --port ${toString port}";
            Restart = "on-failure";
            RestartSec = 10;
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
        };

        hdwlinux.ai.clients.mcpServers.laya.stdio = {
          command = lib.getExe layaMcp;
          args = [
            "mcp"
            "--sidecar"
            "http://127.0.0.1:${toString port}"
          ];
        };

        # Usage policy ships with the tools it governs; clients render it into
        # their rules dir (opencode loads every rule, claude-code on demand).
        hdwlinux.ai.clients.rules.laya = {
          description = "When and how to use the laya_* System-1 decision tools (triage, routing, gating)";
          loadMode = "auto";
          prompt = ./rule.md;
        };
      };
  };
}
