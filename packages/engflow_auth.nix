{
  substrate.packages.engflow_auth =
    {
      pkgs,
      ...
    }:

    pkgs.buildGoModule {
      name = "engflow_auth";

      src = builtins.fetchGit {
        url = "ssh://git@github.com/EngFlow/auth.git";
        ref = "v0.0.14";
        rev = "394a6159959cf83a24dd735e5d06b3b4c728da0e";
      };

      vendorHash = "sha256-lub4IVkSLhy5qkxgjINKb+Xmq8SYPxJaHa3acukPwNE=";

      subPackages = [ "./cmd/engflow_auth" ];

      meta = {
        mainProgram = "engflow_auth";
        description = "Engflow Auth - automatically obtain and securely store EngFlow authentication credentials";
        homepage = "https://github.com/EngFlow/auth";
      };
    };
}
