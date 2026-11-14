{
  # Declared here, not in the user module, so hosts without the cifs capability
  # never reference the cifs mount option.
  config.substrate.modules.locations.raeford.cifs = {
    tags = [
      "location:raeford"
      "capability:filesystem:cifs"
      "user:craig"
    ];

    nixos =
      {
        config,
        hasTag,
        lib,
        ...
      }:
      let
        name = "craig";
        synologyCredentialsFile = config.secretspec.entries.synologyCifsCredentials.file.path;
        mount = share: remote: {
          group = "users";
          local = "/home/${name}/mnt/synology/${share}";
          remote = "//synology.${config.hdwlinux.networking.domain}/${remote}";
          owner = name;
          credentialsFile = synologyCredentialsFile;
          username = "craiggwilson";
        };
      in
      {
        hdwlinux.filesystems.cifs.mounts =
          (lib.optionals (hasTag "profile:personal") [
            (mount "docker" "docker")
            (mount "games" "games")
            (mount "music" "music")
            (mount "photos" "photo")
          ])
          ++ (lib.optionals (hasTag "profile:personal" || hasTag "profile:work") [
            (mount "home" "home")
          ]);
      };
  };
}
