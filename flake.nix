{
  description = "Box64 Binfmt NixOS Module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgsx86.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgsx86, ... }@inputs: let
    lib = nixpkgs.lib;
    supportedSystems = [ "aarch64-linux" "riscv64-linux" ];
    eachSystem = f: lib.genAttrs supportedSystems (system: f system);
    
    # Package sets for supported systems
    pkgsFor = system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    
    # Special x86 package set (not in supportedSystems)
    x86pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    
    overlay = final: prev: {
      x86 = import nixpkgsx86 {
        system = "x86_64-linux";
        config.allowUnfree = true;
        config.allowUnsupportedSystem = true;
      };
    };

  in {
    packages = eachSystem (system: {
      default = self.packages.${system}.box64-bleeding-edge;
      box64-bleeding-edge = (pkgsFor system).callPackage ./box64-bleeding-edge.nix {
        hello-x86_64 = if (pkgsFor system).stdenv.hostPlatform.isx86_64 then
          (pkgsFor system).hello
        else
          (pkgsFor system).pkgsCross.gnu64.hello;
      };
    });

    overlays = {
      default = overlay;
    };

    nixosModules.default = import ./default.nix {
      inherit inputs x86pkgs;
      self = self; # Required for accessing packages in default.nix
    };
  };
}