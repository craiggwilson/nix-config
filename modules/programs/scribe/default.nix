{
  config.substrate.modules.programs.scribe = {
    tags = [ "dictation" ];

    homeManager = {
      programs.scribe = {
        enable = true;

        whisperModels = [
          {
            name = "base.en";
            filename = "ggml-base.en.bin";
            url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin";
            hash = "sha256-oDd5yG3zMjB19eeWyyzlAp8A7Ihp7uP9+4l6/jbG0AI=";
          }
        ];

        diarizationModels = [
          {
            name = "wespeaker-resnet34";
            filename = "wespeaker_resnet34.onnx";
            url = "https://huggingface.co/Wespeaker/wespeaker-voxceleb-resnet34/resolve/ff1ac5bca8ef11e90662b879aa923979e0bd277b/voxceleb_resnet34.onnx";
            hash = "sha256-n+plFteta/CnbHaJ9aSbZdMw+tbd6WyRu0Q1/7/gVqE=";
          }
          {
            name = "silero-vad";
            filename = "silero_vad.onnx";
            url = "https://github.com/snakers4/silero-vad/raw/7e30209a3e901f9842f81b225f3e93d8199902b1/src/silero_vad/data/silero_vad.onnx";
            hash = "sha256-GhU6IvRQnikqlOZ9b5uF6N6yW0mIaCt+F0xlJ52HiOM=";
          }
        ];
      };
    };
  };
}
