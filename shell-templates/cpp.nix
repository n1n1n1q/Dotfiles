{
  description = "C++ Development with Nix in 2023";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"
      ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            boost
            catch2
            cmake
            clang
          ];
        };
      };
    };
}