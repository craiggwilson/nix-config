let
  configuration = ''
    # Keep the initial instance intentionally small. Integrations and
    # automations are added through Home Assistant and versioned here once
    # they have been selected deliberately.
    default_config:

    homeassistant:
      name: Home
      country: US
      currency: USD
      time_zone: America/New_York
      unit_system: us_customary
  '';
in
{
  compose.services.homeassistant = {
    container_name = "homeassistant";
    environment.TZ = "America/New_York";
    image = "ghcr.io/home-assistant/home-assistant:stable";
    network_mode = "host";
    restart = "unless-stopped";
    stop_grace_period = "60s";
    volumes = [
      "/volume3/docker/homeassistant:/config"
      "/etc/localtime:/etc/localtime:ro"
    ];
  };

  files."configuration.yaml" = configuration;
}
