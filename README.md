# mapping-tools-nix

Nix package for [Mapping Tools](https://mappingtools.github.io/) on Linux.

This package is intended to share the same Wine prefix as `osu-stable` from [`nix-gaming`](https://github.com/fufexan/nix-gaming) (`$HOME/.osu`).

## Home Manager setup

If you install both `mapping-tools` and `osu-stable` through Home Manager, make sure `osu-stable` uses:

- `protonVerbs = [ "runinprefix" ];`

Using `waitforexitandrun` can break shared-prefix behavior with Mapping Tools.

### 1) Add flake inputs

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";

    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mapping-tools-nix = {
      url = "github:ekisu/mapping-tools-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-gaming.follows = "nix-gaming";
    };
  };
}
```

### 2) Configure Home Manager

```nix
{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.mapping-tools-nix.packages.${pkgs.system}.mapping-tools

    (inputs.nix-gaming.packages.${pkgs.system}.osu-stable.override {
      protonVerbs = [ "runinprefix" ];
    })
  ];
}
```

### 3) Apply and run

```bash
home-manager switch
mapping-tools # Or open from your main menu
```

## Notes

- Default Wine prefix: `$HOME/.osu`.
- First run installs required runtime components in the prefix.
- If setup is blocked, close `osu-stable` and launch Mapping Tools again.
