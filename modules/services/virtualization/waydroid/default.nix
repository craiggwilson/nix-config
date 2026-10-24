{
  config.substrate.modules.services.virtualization.waydroid = {
    tags = [ "capability:virtualization:waydroid" ];
    nixos = {
      virtualisation.waydroid.enable = true;
    };
  };
}
