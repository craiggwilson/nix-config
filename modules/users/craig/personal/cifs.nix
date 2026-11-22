{
  config.substrate.modules.users.craig.personal.cifs = {
    tags = [
      "location:raeford"
      "capability:filesystem:cifs"
      "user:craig:personal"
    ];

    nixos =
      {
        config,
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
        hdwlinux.filesystems.cifs.mounts = [
          (mount "docker" "docker")
          (mount "games" "games")
          (mount "music" "music")
          (mount "photos" "photo")
        ];
      };
  };
}
