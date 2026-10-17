{
  config.substrate.modules.programs.kube-cli = {
    provides = [
      "programs:kube-cli"
      "profiles:work"
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
