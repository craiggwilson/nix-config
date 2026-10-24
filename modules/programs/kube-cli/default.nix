{
  config.substrate.modules.programs.kube-cli = {
    tags = [
      "user:craig"
      "profile:work"
    ];

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
