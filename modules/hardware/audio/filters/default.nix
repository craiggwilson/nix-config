{ lib, ... }:

let
  inherit (lib) map mkIf optionals;

  # One software-dsp rule per microphone. WirePlumber 0.5 removed the classic
  # `rules`/`filter-chain` action; `node.software-dsp.rules` is the current
  # mechanism. When the matched node appears, `create-filter` loads a
  # filter-chain that publishes a *parallel* virtual source fed by an FFT
  # denoiser. The raw mic is never hidden or modified, so it stays available
  # for production use.
  ruleForMic = mic: {
    matches = [
      { "node.name" = mic; }
    ];
    actions = {
      "create-filter" = {
        "filter-graph" = {
          "node.description" = "${mic} (Noise Suppressed)";
          "media.name" = "${mic} (Noise Suppressed)";
          "filter.graph" = {
            nodes = [
              {
                # ffmpeg's FFT denoiser, run inside PipeWire's filter-chain.
                # plugin must be "filtergraph": the ffmpeg plugin factory
                # rejects any other value with -EINVAL at load time.
                # nr is noise reduction in dB (0.01–97): 20 dB lifts laptop
                # fan noise off speech without the musical artifacts that
                # appear above ~30.
                # Explicit stereo pads keep the filter on the mic's two
                # channels; ffmpeg's auto-named pads would collapse to one.
                type = "ffmpeg";
                name = "denoiser";
                plugin = "filtergraph";
                label = "[in_stereo]afftdn=nr=20[out_stereo]";
              }
            ];
          };
          "capture.props" = {
            "node.name" = "capture.${mic}";
            # Suspend the filter when no client is using the virtual source.
            "node.passive" = true;
            # Pin this filter's input to the exact mic it was created for so
            # it never silently follows the default source.
            "node.target" = mic;
            # ffmpeg's filtergraph is not real-time safe (it allocates while
            # running). The filter-chain module only propagates a fixed key
            # list from the module args to the nodes, so this has to be set
            # per-node here, not at the top level.
            "node.async" = "true";
          };
          "playback.props" = {
            "node.name" = "${mic}.ns";
            "media.class" = "Audio/Source";
          };
        };
      };
    };
  };
in
{
  config.substrate.modules.hardware.audio.filters = {
    tags = [ "capability:audio" ];

    generic =
      { lib, ... }:
      {
        options.hdwlinux.hardware.audio.noiseSuppression.enable = lib.mkOption {
          description = "Whether to expose noise-suppressed virtual sources for the configured microphones.";
          type = lib.types.bool;
          default = false;
        };
        options.hdwlinux.hardware.audio.noiseSuppression.mics = lib.mkOption {
          description = "PipeWire microphone node names (see `wpctl status`) to expose as noise-suppressed virtual sources. The raw mic remains available.";
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "alsa_input.pci-0000_00_1f.3.analog-stereo" ];
        };
      };

    nixos =
      { config, ... }:
      let
        cfg = config.hdwlinux.hardware.audio.noiseSuppression;
        rules = optionals (cfg.enable && cfg.mics != [ ]) (map ruleForMic cfg.mics);
      in
      mkIf (rules != [ ]) {
        services.pipewire.wireplumber.extraConfig."10-noise-suppression" = {
          # node.software-dsp is not enabled by the default `main` profile.
          "wireplumber.profiles" = {
            main = {
              "node.software-dsp" = "required";
            };
          };
          "node.software-dsp.rules" = rules;
        };
      };
  };
}
