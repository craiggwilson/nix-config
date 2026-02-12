{
  config.substrate.modules.users.craig.confluence = {
    tags = [ "users:craig:work" ];
    homeManager = {
      hdwlinux.security.secrets.entries.confluenceAccessToken = {
        reference = "op://Work/Confluence/personal-access-token";
      };
    };
  };
}

