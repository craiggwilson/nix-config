{
  config.substrate.types = {
    file =
      lib:
      lib.types.submodule (
        { config, ... }:
        {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "The filename.";
            };
            sha256 = lib.mkOption {
              type = lib.types.str;
              description = "The hash of the file content.";
            };
            type = lib.mkOption {
              type = lib.types.enum [ "huggingface" ];
              default = "huggingface";
              description = "Source type for the file download. Extensible with new types.";
            };
            repo = lib.mkOption {
              type = lib.types.str;
              description = "HuggingFace repository (org/name).";
            };
            subdir = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Optional subdirectory within the repo for split files.";
            };
            url = lib.mkOption {
              type = lib.types.str;
              readOnly = true;
              description = "Computed download URL built from the source type and its fields.";
            };
          };
          config = {
            url =
              "https://huggingface.co/${config.repo}/resolve/main"
              + lib.optionalString (config.subdir != null) "/split_files/${config.subdir}"
              + "/${config.name}?download=true";
          };
        }
      );
  };
}
