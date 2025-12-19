{
  config,
  lib,
  ...
}:

{
  users.craig = {
    name = "craig";
    fullName = "Craig Wilson";
    email = "craiggwilson@gmail.com";
    type = "admin";

    modules.homeManager = [

    ];

    modules.nixos = [

    ];
  };
}
