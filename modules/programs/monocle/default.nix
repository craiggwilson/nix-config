{
  config.substrate.modules.programs.monocle = {
    tags = [ "ai:clients" ];

    homeManager =
      { pkgs, ... }:
      let
        monocle = pkgs.hdwlinux.monocle;
      in
      {
        home.packages = [ monocle ];

        hdwlinux.ai.clients.skills = {
          get-feedback = "${monocle.src}/skills/get-feedback";
          get-feedback-wait = "${monocle.src}/skills/get-feedback-wait";
          review-plan = "${monocle.src}/skills/review-plan";
          review-plan-wait = "${monocle.src}/skills/review-plan-wait";
        };
      };
  };
}
