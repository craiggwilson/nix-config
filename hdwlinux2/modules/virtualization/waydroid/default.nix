{
  config.substrate.modules.virtualization.waydroid = {
    tags = [ "virtualization:waydroid" ];
    nixos = {
      virtualisation.waydroid.enable = true;
    };
  };
}

