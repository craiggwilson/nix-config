{
  config.substrate.modules.boot.systemd = {
    tags = [ "boot:systemd" ];
    nixos = { pkgs, ... }: {
      boot = {
        consoleLogLevel = 3;

        initrd = {
          systemd = {
            enable = true;
          };
          verbose = false;
        };

        kernelParams = [
          "acpi_backlight=native"
          "boot.shell_on_fail"
          "fbcon=nodefer"
          "logo.nologo"
          "splash"
          "quiet"
          "loglevel=3"
          "rd.systemd.show_status=auto"
          "rd.udev.log_level=3"
          "systemd.show_status=auto"
          "udev.log_level=3"
        ];

        loader = {
          efi = {
            canTouchEfiVariables = true;
            efiSysMountPoint = "/boot";
          };

          systemd-boot = {
            enable = true;
            configurationLimit = 20;
          };
        };

        plymouth = {
          enable = true;
          logo = ./nixos.png;
          theme = "catppuccin-mocha";
          themePackages = [
            (pkgs.catppuccin-plymouth.override {
              variant = "mocha";
            })
          ];
        };
      };
    };
  };
}

