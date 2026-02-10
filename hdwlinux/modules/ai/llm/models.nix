{
  config.substrate.modules.ai.llm = {
    tags = [ "ai:llm" ];

    homeManager =
      { lib, ... }:
      let
        hfFile =
          {
            repo,
            name,
            sha256,
          }:
          {
            inherit name sha256;
            url = "https://huggingface.co/${repo}/resolve/main/${name}?download=true";
          };

        hfSingleGGUF =
          { name, sha256 }:
          let
            # org/repo-GGUF:quant
            parts = lib.split "/|-GGUF:" name;
            org = lib.elemAt parts 0;
            repo = lib.elemAt parts 2;
            quant = lib.elemAt parts 4;
          in
          hfFile {
            inherit sha256;
            repo = "${org}/${repo}";
            name = "${repo}-${quant}.gguf";
          };
      in
      {
        config.hdwlinux.ai.llm.models = {
          "Llama-3.1-8B-Instruct-Q4_0" = {
            type = "gguf";
            settings = {
              opencode = {
                name = "Llama 3.1 8B Q8 60K";
                reasoning = false;
                tool_call = true;
                limit = {
                  context = 32000;
                  output = 8192;
                };
              };
              llama-cpp = {
                ot = ".ffn_.*_exps.=CPU";
                ctx-size = 32000;
                n-gpu-layers = 33;
                flash-attn = false;

                temp = 0.6;
                top-p = 0.9;
                top-k = 40;
                repeat-penalty = 1.1;

                mlock = true;
                mmap = true;
              };
            };
            files = [
              (hfSingleGGUF {
                name = "unsloth/Llama-3.1-8B-Instruct-GGUF:Q4_0";
                sha256 = "sha256-iOLGACRZ+JLXfH5eIZho7wilfE6SNUxycar2T0erDqo=";
              })
            ];
          };
          "Qwen3-Coder-30B-A3B-Instruct-Q4_K_M" = {
            type = "gguf";
            settings = {
              opencode = {
                name = "Qwen3-Coder 30B Q4 32K";
                reasoning = false;
                tool_call = true;
                limit = {
                  context = 60000;
                  output = 8192;
                };
              };
              llama-cpp = {
                ot = ".ffn_.*_exps.=CPU";
                ctx-size = 60000;
                n-gpu-layers = 49;
                flash-attn = true;

                temp = 0.7;
                top-p = 0.8;
                top-k = 20;
                repeat-penalty = 1.05;

                mlock = true;
                mmap = true;
              };
            };
            files = [
              (hfSingleGGUF {
                name = "unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q4_K_M";
                sha256 = "sha256-+tw+X41Cv36JSnhbBQguR9ruTfJmgDiYF+IJMFbwiK0=";
              })
            ];
          };
        };
      };
  };
}
