{
  description = "Box64 Binfmt NixOS Module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, ... }: let
    lib = nixpkgs.lib;
    systems = [ "aarch64-linux" "riscv64-linux" ];
    
    x86Overlay = final: prev: {
        x86 = import nixpkgs {
          system = "x86_64-linux";
          config = prev.config // {
            allowUnsupportedSystem = true;
            permittedInsecurePackages = prev.config.permittedInsecurePackages or [];
          };
        };
      };

    pkgsFor = system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.allowUnsupportedSystem = true;
    };

  in {
    overlays.default = x86Overlay;

    packages = lib.genAttrs systems (system: {
      default = self.packages.${system}.box64-bleeding-edge;
      box64-bleeding-edge = (pkgsFor system).callPackage ./box64-bleeding-edge.nix {
        hello-x86_64 = if (pkgsFor system).stdenv.hostPlatform.isx86_64 then
          (pkgsFor system).hello
        else
          (pkgsFor system).pkgsCross.gnu64.hello;
      };
    });

    nixosModules.default = { config, pkgs, ... }: {
      imports = [ (import ./default.nix { inherit self; }) ];
    };
  };
}