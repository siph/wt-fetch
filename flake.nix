{
  description = "Cached and opinionated fetcher for `wttr`";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {

        packages = rec {
          wt-fetch = pkgs.stdenv.mkDerivation rec {
            inherit system;
            name = "wt_fetch";
            pname = "wt-fetch";
            src = ./.;
            nativeBuildInputs = with pkgs; [ nushell makeWrapper ];
            installPhase = ''
              mkdir -p $out/bin
              mkdir -p $out/nu
              cp ${name}.nu $out/nu/${pname}.nu
              makeWrapper ${pkgs.nushell}/bin/nu $out/bin/${pname} \
                --add-flags "$out/nu/${pname}.nu"
            '';
          };
          default = wt-fetch;
        };

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
