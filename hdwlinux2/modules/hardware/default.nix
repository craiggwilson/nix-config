{ lib, ... }:
{
  config.substrate.types.pcicard = lib.types.submodule {
    options = {
      busId = lib.mkOption {
        description = "The PCI bus id. You can find it using lspci.";
        type = lib.types.strMatching "([0-9a-f]{1,3}[\:][0-9a-f]{1,2}[\.][0-9a-f])?";
        example = "01:00.0";
        default = "";
      };
      path = lib.mkOption {
        description = "The path to the card.";
        type = lib.types.str;
        default = "";
      };
    };
  };
}

