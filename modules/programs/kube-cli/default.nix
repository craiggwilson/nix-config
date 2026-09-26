{
  config.substrate.modules.programs.kube-cli = {
    tags = [ "users:craig:work" ];

    perUser =
      { pkgs, ... }:
      {
        packages = with pkgs; [
          kubectl
          kubectx
          kubernetes-helm
        ];
      };
  };
}

