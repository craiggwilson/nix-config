{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.programs.btop;
in
{
  options.hdwlinux.programs.btop = {
    enable = lib.hdwlinux.mkEnableOption "btop" true;
  };

  config = lib.mkIf cfg.enable {
    programs.btop = {
      enable = true;
      settings = {
        color_theme = "hdwlinux.theme";
        theme_background = false;
        temp_scale = "fahrenheit";
      };
    };

    xdg.configFile."btop/themes/hdwlinux.theme".text = lib.mkIf config.hdwlinux.theme.enable ''
      # Main background, empty for terminal default, need to be empty if you want transparent background
      theme[main_bg]="${config.hdwlinux.theme.colors.withHashtag.base00}";

      # Main text color
      theme[main_fg]="${config.hdwlinux.theme.colors.withHashtag.base05}"

      # Title color for boxes
      theme[title]="${config.hdwlinux.theme.colors.withHashtag.base05}"

      # Highlight color for keyboard shortcuts
      theme[hi_fg]="${config.hdwlinux.theme.colors.withHashtag.base0D}"

      # Background color of selected item in processes box
      theme[selected_bg]="${config.hdwlinux.theme.colors.withHashtag.base03}"

      # Foreground color of selected item in processes box
      theme[selected_fg]="${config.hdwlinux.theme.colors.withHashtag.base0D}"

      # Color of inactive/disabled text
      theme[inactive_fg]="${config.hdwlinux.theme.colors.withHashtag.base02}"

      # Color of text appearing on top of graphs, i.e uptime and current network graph scaling
      theme[graph_text]="${config.hdwlinux.theme.colors.withHashtag.base06}"

      # Background color of the percentage meters
      theme[meter_bg]="${config.hdwlinux.theme.colors.withHashtag.base03}"

      # Misc colors for processes box including mini cpu graphs, details memory graph and details status text
      theme[proc_misc]="${config.hdwlinux.theme.colors.withHashtag.base06}"

      # CPU, Memory, Network, Proc box outline colors
      theme[cpu_box]="${config.hdwlinux.theme.colors.withHashtag.base0E}" 
      theme[mem_box]="${config.hdwlinux.theme.colors.withHashtag.base0B}" 
      theme[net_box]="${config.hdwlinux.theme.colors.withHashtag.base09}" 
      theme[proc_box]="${config.hdwlinux.theme.colors.withHashtag.base0D}"

      # Box divider line and small boxes line color
      theme[div_line]="${config.hdwlinux.theme.colors.withHashtag.base02}"

      # Temperature graph color
      theme[temp_start]="${config.hdwlinux.theme.colors.withHashtag.base0B}"
      theme[temp_mid]="${config.hdwlinux.theme.colors.withHashtag.base0A}"
      theme[temp_end]="${config.hdwlinux.theme.colors.withHashtag.base08}"

      # CPU graph colors
      theme[cpu_start]="${config.hdwlinux.theme.colors.withHashtag.base0C}"
      theme[cpu_mid]="${config.hdwlinux.theme.colors.withHashtag.base0D}"
      theme[cpu_end]="${config.hdwlinux.theme.colors.withHashtag.base07}"

      # Mem/Disk free meter
      theme[free_start]="${config.hdwlinux.theme.colors.withHashtag.base0E}"
      theme[free_mid]="${config.hdwlinux.theme.colors.withHashtag.base07}"
      theme[free_end]="${config.hdwlinux.theme.colors.withHashtag.base0D}"

      # Mem/Disk cached meter
      theme[cached_start]="${config.hdwlinux.theme.colors.withHashtag.base0D}"
      theme[cached_mid]="${config.hdwlinux.theme.colors.withHashtag.base0D}"
      theme[cached_end]="${config.hdwlinux.theme.colors.withHashtag.base07}"

      # Mem/Disk available meter
      theme[available_start]="${config.hdwlinux.theme.colors.withHashtag.base09}"
      theme[available_mid]="${config.hdwlinux.theme.colors.withHashtag.base08}"
      theme[available_end]="${config.hdwlinux.theme.colors.withHashtag.base08}"

      # Mem/Disk used meter
      theme[used_start]="${config.hdwlinux.theme.colors.withHashtag.base0B}"
      theme[used_mid]="${config.hdwlinux.theme.colors.withHashtag.base0C}"
      theme[used_end]="${config.hdwlinux.theme.colors.withHashtag.base0D}"

      # Download graph colors
      theme[download_start]="${config.hdwlinux.theme.colors.withHashtag.base09}"
      theme[download_mid]="${config.hdwlinux.theme.colors.withHashtag.base08}"
      theme[download_end]="${config.hdwlinux.theme.colors.withHashtag.base08}"

      # Upload graph colors
      theme[upload_start]="${config.hdwlinux.theme.colors.withHashtag.base0B}"
      theme[upload_mid]="${config.hdwlinux.theme.colors.withHashtag.base0C}"
      theme[upload_end]="${config.hdwlinux.theme.colors.withHashtag.base0D}"

      # Process box color gradient for threads, mem and cpu usage
      theme[process_start]="${config.hdwlinux.theme.colors.withHashtag.base0D}"
      theme[process_mid]="${config.hdwlinux.theme.colors.withHashtag.base07}"
      theme[process_end]="${config.hdwlinux.theme.colors.withHashtag.base0E}"
    '';
  };
}
