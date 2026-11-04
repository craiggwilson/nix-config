_: {
  compose.services = { };

  lifecycle = false;

  directories = [ "secrets" ];

  files = {
    "issue-global.sh" = builtins.readFile ./certificates/files/issue-global.sh;
    "renew.sh" = builtins.readFile ./certificates/files/renew.sh;
  };

  secrets = {
    "secrets/namecheap_api_key" = "ACME_NAMECHEAP_API_KEY";
    "secrets/namecheap_source_ip" = "ACME_NAMECHEAP_SOURCE_IP";
    "secrets/namecheap_username" = "ACME_NAMECHEAP_USERNAME";
  };
}
