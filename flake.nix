{
  description = "Simple cli weather fetching app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {

        packages = { };

        checks = {
          nushell-tests = pkgs.stdenv.mkDerivation {
            inherit system;
            name = "nushell tests";
            src = ./.;
            nativeBuildInputs = with pkgs; [ nushell ];
            buildPhase = ''
              nu run_tests.nu
            '';
            installPhase = ''
              mkdir -p $out
            '';
          };
        };

        devShells = {
          default = with pkgs; mkShell {
            nativeBuildInputs = [ nushell ];
          };
        };
      };
    };
}
