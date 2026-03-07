{
  config.substrate.modules.programs.kube-cli = {
    tags = [ "users:craig:work" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          kubectl
          kubectx
          kubernetes-helm
        ];
      };
  };
}

