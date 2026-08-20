{
  pkgs,
  ...
}:

pkgs.buildGoModule {
  name = "fern";

  src = builtins.fetchGit {
    url = "ssh://git@github.com/10gen/fern";
    ref = "v2.38.1";
    rev = "ff51c489440f6e4e4767a02de31a3ee19dbac370";
  };

  vendorHash = "sha256-B9kRQMR6X5NbykYZokJhtI/hOXi04OfQI2IOIbJp+mw=";

  subPackages = [ "." ];

  meta = {
    mainProgram = "fern";
    description = "Fern - Build and run services within a multi-process ecosystem.";
    homepage = "https://github.com/10gen/fern";
  };
}
