{
  config.substrate.modules.programs.helix = {
    tags = [ "programming" ];

    homeManager =
      { config, ... }:
      let
        colors = config.hdwlinux.theme.colors.hexWithHashtag;
      in
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
                left = [ "mode" "spinner" "file-name" "file-modification-indicator" ];
                center = [ "diagnostics" ];
                right = [ "selections" "position" "file-type" ];
              };
            };

            keys.normal = { };
          };

          themes.hdwlinux = {
            attribute = colors.base0A;
            comment = {
              fg = colors.base04;
              modifiers = [ "italic" ];
            };
            constant = colors.base09;
            "constant.numeric" = colors.base09;
            "constant.character.escape" = colors.base0C;
            diagnostic = colors.base08;
            "diagnostic.error" = colors.base08;
            "diagnostic.warning" = colors.base0A;
            "diagnostic.info" = colors.base0C;
            "diagnostic.hint" = colors.base0D;
            error = colors.base08;
            hint = colors.base0D;
            keyword = colors.base0E;
            "keyword.control" = colors.base0E;
            "keyword.directive" = colors.base0E;
            label = colors.base0D;
            "markup.bold" = {
              fg = colors.base05;
              modifiers = [ "bold" ];
            };
            "markup.heading" = colors.base07;
            "markup.italic" = {
              fg = colors.base05;
              modifiers = [ "italic" ];
            };
            "markup.link.text" = colors.base0D;
            "markup.link.url" = {
              fg = colors.base0C;
              modifiers = [ "underlined" ];
            };
            "markup.list" = colors.base0E;
            "markup.quote" = colors.base04;
            "markup.raw" = colors.base0B;
            operator = colors.base0F;
            option = colors.base0D;
            prompt = colors.base0B;
            selection = {
              bg = colors.base02;
              fg = colors.base05;
            };
            special = colors.base0C;
            string = colors.base0B;
            "string.regexp" = colors.base0C;
            "string.special" = colors.base0D;
            tag = colors.base0E;
            "ui.background" = {
              fg = colors.base05;
              bg = colors.base00;
            };
            "ui.bufferline" = {
              fg = colors.base04;
              bg = colors.base01;
            };
            "ui.bufferline.active" = {
              fg = colors.base00;
              bg = colors.base07;
              modifiers = [ "bold" ];
            };
            "ui.cursor" = {
              fg = colors.base00;
              bg = colors.base07;
            };
            "ui.cursor.insert" = {
              fg = colors.base00;
              bg = colors.base0B;
            };
            "ui.cursor.match" = {
              fg = colors.base00;
              bg = colors.base0A;
            };
            "ui.cursor.normal" = {
              fg = colors.base00;
              bg = colors.base07;
            };
            "ui.cursor.select" = {
              fg = colors.base00;
              bg = colors.base0E;
            };
            "ui.gutter" = {
              fg = colors.base04;
              bg = colors.base01;
            };
            "ui.gutter.selected" = {
              fg = colors.base07;
              bg = colors.base01;
            };
            "ui.help" = {
              fg = colors.base05;
              bg = colors.base01;
            };
            "ui.linenr" = {
              fg = colors.base04;
              bg = colors.base01;
            };
            "ui.linenr.selected" = {
              fg = colors.base07;
              bg = colors.base01;
            };
            "ui.menu" = {
              fg = colors.base05;
              bg = colors.base01;
            };
            "ui.menu.selected" = {
              fg = colors.base00;
              bg = colors.base07;
            };
            "ui.popup" = {
              fg = colors.base05;
              bg = colors.base01;
            };
            "ui.selection" = {
              fg = colors.base05;
              bg = colors.base02;
            };
            "ui.selection.primary" = {
              fg = colors.base05;
              bg = colors.base03;
            };
            "ui.statusline" = {
              fg = colors.base05;
              bg = colors.base01;
            };
            "ui.statusline.inactive" = {
              fg = colors.base04;
              bg = colors.base01;
            };
            "ui.statusline.insert" = {
              fg = colors.base00;
              bg = colors.base0B;
            };
            "ui.statusline.normal" = {
              fg = colors.base00;
              bg = colors.base07;
            };
            "ui.statusline.select" = {
              fg = colors.base00;
              bg = colors.base0E;
            };
            "ui.text" = colors.base05;
            "ui.text.focus" = colors.base07;
            "ui.virtual" = colors.base03;
            "ui.virtual.indent-guide" = colors.base02;
            "ui.virtual.ruler" = colors.base02;
            warning = colors.base0A;
          };
        };
      };
  };
}
