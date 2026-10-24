{ inputs, ... }:
{
  config.substrate.modules.hardware.models.dell-pro-max-gb10 = {
    tags = [ "hardware:dell-pro-max-gb10" ];

    nixos =
      { ... }:
      {
        imports = [
          inputs.dgx-spark.nixosModules.dgx-spark
        ];

        hardware.dgx-spark = {
          enable = true;
          # Keep the NVIDIA kernel: it is the supported path for Ethernet and
          # full GB10 GPU support. Revisit this only after testing the box.
          useNvidiaKernel = true;
        };
      };
  };
}
