{
  pkgs,
  ...
}:

pkgs.buildGoModule {
  name = "fern";

  src = builtins.fetchGit {
    url = "ssh://git@github.com/10gen/fern";
    ref = "main";
    rev = "fccd9a18da5c43b74f43cdc2f8dbe53db145dfa8";
  };

  vendorHash = "sha256-ZIHUcfZ3atmkxgR7+ODz3hehg4E6FK+ZcNv0E0tmXyc=";

  subPackages = [ "." ];

  meta = {
    mainProgram = "fern";
    description = "Fern - Build and run services within a multi-process ecosystem.";
    homepage = "https://github.com/10gen/fern";
  };
}
