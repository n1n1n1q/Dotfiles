{
  description = "NixOS config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bbrShell.url = "github:n1n1n1q/bbrShell";
    # bbrShell.url = "path:/home/oleh/bbrShell";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    bbrShell.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      bbrShell,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      # homeConfigurations."oleh" = home-manager.lib.homeManagerConfiguration {
      #   pkgs = import nixpkgs {
      #     inherit system;
      #     overlays = [
      #       inputs.bbrShell.overlay
      #     ];
      #   };
      #   extraSpecialArgs = {
      #     inherit system;
      #     inherit inputs;
      #   };
      # };
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.overlays = [ inputs.bbrShell.overlay ]; }
          ./hosts/default/configuration.nix
        ];
      };
    };
}
