{
  config.substrate.modules.services.xembed-sni-proxy = {
    provides = [
      "services:xembed-sni-proxy"
      "gui"
    ];
    requires = [ "gui" ];
    homeManager = {
      systemd.user.services.xembed-sni-proxy.Unit.ConditionEnvironment = "WAYLAND_DISPLAY";

      services.xembed-sni-proxy = {
        enable = true;
      };
    };
  };
}
