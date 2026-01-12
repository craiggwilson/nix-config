{
  config.substrate.modules.locations.raeford.monitors = {
    tags = [ "raeford" ];

    generic = {
      hdwlinux.hardware.monitors = {
        office-main = {
          vendor = "Samsung Electric Company";
          model = "Odyssey G95C";
          serial = "HNTY500018";
          mode = "5120x1440@59.977Hz";
          scale = 1.0;
        };

        office-top = {
          vendor = "Dell Inc.";
          model = "DELL S2721DGF";
          serial = "DSWSR83";
          mode = "2560x1440@59.951Hz";
          scale = 1.0;
        };

        portable = {
          vendor = "Ancor Communications Inc";
          model = "MB169B+      ";
          serial = "AIC1643";
          mode = "1920x1080@60.01Hz";
          scale = 1.0;
          displaylink = true;
        };
      };
    };
  };
}
