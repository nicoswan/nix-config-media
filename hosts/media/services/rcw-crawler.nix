{ inputs, ... }:
{
  imports = [
    inputs.rcw-crawler.nixosModules.default
  ];

  services.rcw-crawler = {
    enable = true;
    qdrantUrl = "http://127.0.0.1:6334";
    serverPort = 3050;

    # If you use sops-nix to manage secrets (QDRANT_API_KEY and OPENAI_API_KEY):
    # environmentFile = config.sops.secrets."services/rcw-crawler/env".path;
  };

  # To define the secret in sops.nix:
  # sops.secrets."services/rcw-crawler/env" = {
  #   restartUnits = [ "rcw-crawler.service" ];
  # };
}
