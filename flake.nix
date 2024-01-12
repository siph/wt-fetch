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

        packages = with pkgs; rec {
          wt-fetch = stdenv.mkDerivation rec {
            inherit system;
            name = "wt_fetch";
            pname = "wt-fetch";
            src = ./.;
            nativeBuildInputs = [ nushell makeWrapper ];
            installPhase = ''
              mkdir -p $out/bin
              mkdir -p $out/share/${name}
              cp ./${name}.nu $out/share/${name}
              makeWrapper ${nushell}/bin/nu $out/bin/${name} \
                --add-flags "$out/share/${name}/${name}.nu"
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
