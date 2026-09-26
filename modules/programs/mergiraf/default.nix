{
  config.substrate.modules.programs.mergiraf = {
    tags = [ "programming" ];

    perUser =
      { pkgs, ... }:
      {
        packages = [ pkgs.mergiraf ];

        hdwlinux.programs.git.configFragments = [
          {
            merge = {
              # home-manager's programs.git.settings from this module used
              # camelCase conflictStyle; git treats keys case-insensitively.
              conflictStyle = "zdiff3";
              mergiraf = {
                name = "mergiraf";
                driver = "mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P";
              };
            };
          }
        ];
      };
  };
}
