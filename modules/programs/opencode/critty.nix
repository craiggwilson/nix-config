{
  config.substrate.modules.programs.opencode.critty = {
    tags = [ "profile:ai" ];

    homeManager =
      {
        lib,
        pkgs,
        ...
      }:
      {
        home.packages = [ pkgs.hdwlinux.critty ];

        # Critty's OpenCode command opens its review TUI in a Herdr tab when
        # launched from a Herdr terminal. Its installer preserves changed files
        # unless --force is requested.
        home.activation.crittyOpenCode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${lib.getExe pkgs.hdwlinux.critty} install --user opencode
        '';
      };
  };
}
