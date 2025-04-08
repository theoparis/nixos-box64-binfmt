# nixos-box64-binfmt
> [!NOTE]  
> This is in the most alpha version imaginable

Uses box64 to run x86_64 and i368 binaries in nixOS. Creates a proper FHS environment and can register binfmt entries to automatically run x86 binaries.
It provides its own `box64-bleeding-edge` package, with the bleeding edge changes and box32 support to run 32bit software (like `steam`) as well.

## How to install with flakes
**todo:** make this better

Tmp Basic skeleton:

```nix
# flake inputs
box64-binfmt = {
    #inputs.nixpkgs.follows = "nixpkgs"; # leave uncommented to use a pinned version of nixpkgs
    url = "github:Yeshey/box64-binfmt/main";
};
```

```nix
  outputs = {
    box64-binfmt,
    [...]
```

```nix
# then import
imports = [
    inputs.box64-binfmt.nixosModules.default
]
```
Activate with:
```nix
box64-binfmt.enable = true;

```

## Usage

Any `x86` binary you try to run will be ran with box64 in an FHS environment automatically. You can also invoke box64 in the fhs environment directly with `box64-fhs` or `box64-fhs-bash` for bash scripts, or use `steam-fhs` to get in the fhs environment

Right now you need an x86 machine to compile the wanted binary and send it to the aarch64 computer:
```sh
# from x86_64 machine:
> nix-shell -p steamcmd --run "whereis steamcmd"
steamcmd: /nix/store/v15z11yh9j1i76ql016xd02fpa32rfxk-steamcmd-20180104/bin/steamcmd
> nix copy --to ssh://root<aarch64 server ip> /nix/store/v15z11yh9j1i76ql016xd02fpa32rfxk-steamcmd-20180104/bin/steamcmd

# from aarch64 or arm (or riskV) PC
> box64-bashx86-wrapper /nix/store/v15z11yh9j1i76ql016xd02fpa32rfxk-steamcmd-20180104/bin/steamcmd
Steam>
```

#### Todo
- GitHub action to auto update box64 according to the latest commits?
- Proper README
- Mechanism to install packages from other architectures, like `steam`, `steamcmd`, even when not supported? Maybe with `quemu`? Maybe under `pkgs.x86.<pkg>` if possible.
- better name for bleeding edge `box64-bleeding-edge` that has box32 support built in, document it is installed and user can use.
- make `ox64-fhs-bash` and `box64-fhs` be the same thing, just detect if it's a bash script to run or not
- `steam` is still not launching, see [this issue](https://github.com/ptitSeb/box64/issues/2478) to track it
