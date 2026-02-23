{
  description = "Nix package for Mapping Tools using osu-stable Wine prefix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-gaming }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              permittedInsecurePackages = [
                # Required by Mapset Verifier's bundled .NET 5 backend.
                "openssl-1.1.1w"
              ];
            };
            overlays = [ nix-gaming.overlays.default ];
          };
          mapping-tools = pkgs.callPackage ./pkgs/mapping-tools {
            # Match nix-gaming osu-stable runtime stack by default.
            location = "$HOME/.osu";
            useUmu = true;
            wine = pkgs.wine-osu;
            winetricks = pkgs.winetricks-git;
            kdialog = pkgs.kdePackages.kdialog;
            xdotool = pkgs.xdotool;
            umu-launcher-git = pkgs.umu-launcher-git;
            proton-osu-bin = pkgs.proton-osu-bin;
          };
          mapset-verifier = pkgs.callPackage ./pkgs/mapset-verifier { };
          mapset-verifier-git-backend = pkgs.callPackage ./pkgs/mapset-verifier-git/backend.nix { };
          mapset-verifier-git = pkgs.callPackage ./pkgs/mapset-verifier-git {
            backend = mapset-verifier-git-backend;
          };
        in {
          inherit mapping-tools;
          inherit mapset-verifier;
          inherit mapset-verifier-git-backend;
          inherit mapset-verifier-git;
          default = mapping-tools;
        });
    };
}
