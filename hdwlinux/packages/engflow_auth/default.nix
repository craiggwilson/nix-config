{
  pkgs,
  ...
}:

pkgs.buildGoModule {
  name = "engflow_auth";

  src = builtins.fetchGit {
    url = "ssh://git@github.com/EngFlow/auth.git";
    ref = "v0.0.13";
    rev = "ffc364db401afaafd1ed111bf94a829505902896";
  };

  vendorHash = "sha256-fVtoonsRNN7DbbRs9UGnpdF2ktYAzUD5au1tsrhyfOA=";

  subPackages = [ "./cmd/engflow_auth" ];

  meta = {
    mainProgram = "engflow_auth";
    description = "Engflow Auth - automatically obtain and securely store EngFlow authentication credentials";
    homepage = "https://github.com/EngFlow/auth";
  };
}
