{ lib, pkgs, inputs, config, ... }:
{
  programs = {
    gh-dash.settings = lib.mkIf config.hdwlinux.features.gh.enable {
      prSections = [
        {
          title = "My Pull Requests";
          filters = "is:open author:@me";
        } 
        {
          title = "Needs My Review";
          filters = "is:open review-requested:@me -author:@me";
        } 
        {
          title = "Involved";
          filters = "is:open involves:@me -review-requested:@me -author:@me -repo:mongodb/mongo-csharp-driver -repo:bdeleonardis1/parquet-go";
        } 
        {
          title = "mongohouse";
          filters = "is:open repo:10gen/mongohouse -author:@me -review-requested:@me -involves:@me";
          limit = 50;
        } 
        {
          title = "mongoast";
          filters = "is:open repo:10gen/mongoast -author:@me -review-requested:@me -involves:@me";
        }
      ];
      defaults = {
          prsLimit = 20;
          issuesLimit = 20;
          preview = {
          open = true;
          width = 60;
        };
      };
      repoPaths = {
        "10gen/*" = "${config.home.homeDirectory}/Projects/github.com/10gen/*";
        "craiggwilson/*" = "${config.home.homeDirectory}/Projects/github.com/craiggwilson/*";
      };
    };
  };
}
