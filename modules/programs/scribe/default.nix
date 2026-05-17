{
  config.substrate.modules.programs.scribe = {

    homeManager =
      { pkgs, ... }:
      {
        programs.scribe = {
          enable = true;
          enableCuda = true;
          package = pkgs.scribe.scribe.override {
            cudaCapability = "8.6";
          };

          whisperModels = [
            "base.en"
            "medium.en"
          ];

          diarizationModels = [
            "wespeaker-resnet34"
            "silero-vad"
          ];

          settings.capture = {
            defaults = {
              model = "medium.en";
              preview_model = "base.en";
            };

            profiles = [
              {
                name = "dictate";
                sources = [
                  {
                    source = "default:input";
                    label = "Me";
                  }
                ];
              }
              {
                name = "meeting";
                diarize = true;
                output = "transcript";
                save_audio = true;
                timestamps = true;
                preview = true;
                sources = [
                  {
                    source = "default:input";
                    label = "Me";
                  }
                  {
                    source = "Firefox";
                    label = "Others";
                  }
                ];
              }
            ];
          };
        };
      };
  };
}
