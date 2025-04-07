{
  description = "Box64 Binfmt NixOS Module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachSystem [
      "aarch64-linux"
      "riscv64-linux"
    ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        # Packages
        packages.${system}.mybox64 = pkgs.callPackage ./mybox64.nix { };

        # NixOS modules
        #nixosModules.box64-binfmt = import ./default.nix inputs;

        # DevShell etc. if needed
      }
    ) // {
      nixosModules = {
        default = import ./default.nix;
      };
      #nixosModules.box64-binfmt = import ./default.nix inputs; 
    };
}
