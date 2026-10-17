{
  config.substrate.modules.virtualization.waydroid = {
    provides = [ "virtualization:waydroid" ];
    nixos = {
      virtualisation.waydroid.enable = true;
    };
  };
}
