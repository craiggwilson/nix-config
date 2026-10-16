{
  config.substrate.modules.programs.kube-cli = {
    provides = [ "profiles:work" ];
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
