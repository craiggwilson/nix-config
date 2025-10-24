{ lib, ... }:
{
  options = {
    assertions = lib.mkOption {
      description = "A list of assertions to check against in order for the evaluation to succeed.";
      default.value = [ ];
      type = lib.types.listOf (
        lib.types.submoduleWith {
          shorthandOnlyDefinesConfig = true;
          modules = [
            {
              options = {
                assertion = lib.mkOption {
                  description = "The assertion to check against.";
                  type = lib.types.bool;
                };

                message = lib.mkOption {
                  description = "The message to display if the assertion fails.";
                  type = lib.types.string;
                };
              };
            }
          ];
        }
      );
    };
  };
}
