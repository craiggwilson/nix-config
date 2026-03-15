{
  config.substrate.modules.filesystems.envfs = {
    tags = [ "filesystem:envfs" ];

    nixos = {
      # Provides /usr/bin and /bin via FUSE, resolving executables based on
      # the calling process's PATH. Required for shebangs (e.g. #!/usr/bin/env)
      # to work in direnv-managed shells without a full FHS environment.
      services.envfs.enable = true;
    };
  };
}
