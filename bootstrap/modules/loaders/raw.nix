{ lib, ... }:
{
  config = {
    loaders.raw = {
      settings = {
        type = lib.types.attrs;
        default = { };
      };

      load = input: input.src;
    };
  };
}
