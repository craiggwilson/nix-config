{ lib }:
let
  filesDirectory = ./homeassistant/files;
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

  directories = [ "themes" ];

  files = lib.mapAttrs (fileName: _: builtins.readFile (filesDirectory + "/${fileName}")) (
    lib.filterAttrs (_: fileType: fileType == "regular") (builtins.readDir filesDirectory)
  );
}
