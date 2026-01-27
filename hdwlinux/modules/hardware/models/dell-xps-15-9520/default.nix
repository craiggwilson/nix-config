{ inputs, ... }:
{
  config.substrate.modules.hardware.models.dell-xps-15-9520 = {
    tags = [ "hardware:dell-xps-15-9520" ];

    generic = {
      hdwlinux.hardware = {
        audio.soundcard = {
          busId = "00:1f.3";
          path = "/dev/snd/controlC0";
        };
        graphics = {
          card = {
            busId = "00:02.0";
            path = "/dev/dri/card1";
          };
          nvidia.card = {
            busId = "01:00.0";
            path = "/dev/dri/card0";
          };
        };
        monitors.laptop = {
          vendor = "LG Display";
          model = "0x06B3";
          mode = "1920x1200@59.95Hz";
          scale = 1.0;
        };
        outputProfiles.laptop = {
          outputs.laptop = {
            enable = true;
            position = "0,0";
          };
        };
      };
    };

    nixos =
      { pkgs, lib, ... }:
      {
        imports = [
          inputs.nixos-hardware.nixosModules.dell-xps-15-9520-nvidia
        ];

        boot = {
          initrd = {
            availableKernelModules = [
              "xhci_pci"
              "vmd"
              "nvme"
              "usb_storage"
              "sd_mod"
              "rtsx_pci_sdmmc"
            ];
            kernelModules = [ ];
          };
          kernelModules = [ "kvm-intel" ];
          kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
          kernel.sysctl = {
            "fs.inotify.max_user_watches" = "1048576";
          };
        };

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

        services = {
          auto-cpufreq = {
            enable = true;
            settings = {
              battery = {
                governor = "powersave";
                turbo = "never";
              };
              charger = {
                governor = "performance";
                turbo = "auto";
              };
            };
          };

          thermald.enable = true;

          # TLP for battery threshold management only.
          # CPU frequency management is handled by auto-cpufreq.
          tlp = {
            enable = true;
            settings = {
              # Battery charge thresholds for Dell laptops.
              # Dell supports: start 50-95, stop 55-100
              # Hardware enforces start = stop - 5
              START_CHARGE_THRESH_BAT0 = 55;
              STOP_CHARGE_THRESH_BAT0 = 60;

              # Restore thresholds when AC is unplugged (after tlp fullcharge)
              RESTORE_THRESHOLDS_ON_BAT = 1;

              # Disable TLP's CPU management to avoid conflict with auto-cpufreq.
              CPU_SCALING_GOVERNOR_ON_AC = "";
              CPU_SCALING_GOVERNOR_ON_BAT = "";
              CPU_ENERGY_PERF_POLICY_ON_AC = "";
              CPU_ENERGY_PERF_POLICY_ON_BAT = "";

              # Disable other power management that might conflict
              RUNTIME_PM_ON_AC = "";
              RUNTIME_PM_ON_BAT = "";
            };
          };
        };
      };

    homeManager =
      { pkgs, ... }:
      {
        hdwlinux.programs.hdwlinux = {
          runtimeInputs = [ pkgs.tlp ];
          subcommands.battery = {
            # TLP profiles mapped to match system76-power naming
            # Dell supports: start 50-95, stop 55-100 (hardware enforces start = stop - 5)
            set-profile = ''
              profile="$1"
              case "$profile" in
                max_lifespan)
                  sudo tlp setcharge 55 60
                  echo "Set profile: max_lifespan (55-60%)"
                  ;;
                balanced)
                  sudo tlp setcharge 75 80
                  echo "Set profile: balanced (75-80%)"
                  ;;
                full_charge)
                  sudo tlp fullcharge
                  echo "Set profile: full_charge (charging to 100%)"
                  ;;
                *)
                  echo "Available profiles: max_lifespan, balanced, full_charge"
                  echo ""
                  echo "  max_lifespan  - Charge 55-60% (best for always plugged in)"
                  echo "  balanced      - Charge 75-80% (good balance)"
                  echo "  full_charge   - Charge to 100% (for travel)"
                  exit 1
                  ;;
              esac
            '';
            "*" = "sudo tlp-stat -b";
          };
        };
      };
  };
}
