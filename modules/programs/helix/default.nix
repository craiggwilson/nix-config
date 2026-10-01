{
  config.substrate.modules.programs.helix = {
    tags = [ "programming" ];

    homeManager =
      { config, ... }:
      {
        programs.helix = {
          enable = true;
          defaultEditor = true;

          settings = {
            theme = "hdwlinux";

            editor = {
              color-modes = true;
              cursorline = true;
              line-number = "relative";
              mouse = false;
              soft-wrap.enable = true;
              true-color = true;

              statusline = {
                left = [
                  "mode"
                  "spinner"
                  "file-name"
                  "file-modification-indicator"
                ];
                center = [ "diagnostics" ];
                right = [
                  "selections"
                  "position"
                  "file-type"
                ];
              };
            };

            keys.normal = { };
          };

        };
      };
  };
}
