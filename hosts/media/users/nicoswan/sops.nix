# home level sops. see hosts/common/optional/sops.nix for hosts level

{
  inputs,
  config,
  ...
}:
let
  secretsDirectory = toString inputs.nix-secrets;
  secretsFile = "${secretsDirectory}/secrets.yaml";
  homeDirectory = config.home.homeDirectory;
in
{

  sops.age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";
  sops.defaultSopsFile = secretsFile;
  sops.validateSopsFiles = true;

}
