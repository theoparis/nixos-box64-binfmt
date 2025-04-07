final: prev: let
  x86Pkgs = import (final.path) {
    system = "x86_64-linux";
    config.allowUnfree = true;
    # Explicitly disable i686 to prevent accidental inclusion
    config.allowUnsupportedSystem = false; 
  };
in {
  x86 = x86Pkgs // {
    steam-run = x86Pkgs.steam-run;
  };
}