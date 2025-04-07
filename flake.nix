{
  description = "Box64 Binfmt NixOS Module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, ... }@inputs: let
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
    
  in {
    packages = eachSystem (system: {
      default = self.packages.${system}.mybox64;
      mybox64 = (pkgsFor system).callPackage ./mybox64.nix {
        hello-x86_64 = if (pkgsFor system).stdenv.hostPlatform.isx86_64 then
          (pkgsFor system).hello
        else
          (pkgsFor system).pkgsCross.gnu64.hello;
      };
    });

    nixosModules.default = import ./default.nix {
      inherit inputs x86pkgs;
      self = self; # Required for accessing packages in default.nix
    };
  };
}