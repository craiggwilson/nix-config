{
  config.substrate.modules.programs.kube-cli = {
    tags = [ "profile:cloud-infrastructure" ];

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
