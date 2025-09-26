{
  description = "How the clouds are made";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) [
            "vault"
          ];
      };
    in rec {
      apps = {
        check = flake-utils.lib.mkApp { drv = packages.check; };
      };
      devShells.eks = pkgs.mkShell {
        buildInputs = [pkgs.awscli pkgs.opentofu pkgs.kubectl];
      };
      formatter = pkgs.alejandra;
      packages = {
        check = pkgs.writeShellApplication {
          name = "byoc-check";
          runtimeInputs = [pkgs.opentofu pkgs.docker-compose];
          text = ''
            pushd eks
            tofu init -backend=false
            tofu validate
            popd && pushd docker
            docker compose -f docker-compose.yml --env-file secrets-example.env --env-file .env config -q
          '';
        };
      };
    });
}
