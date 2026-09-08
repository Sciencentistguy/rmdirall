{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    fenix,
    ...
  }:
    {
      overlay = final: prev: {
        rmdirall = self.packages.${prev.system}.default;
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        config.allowUnfree = true;
        inherit system;
      };
      fenixStable = fenix.packages.${system}.stable;
      rustToolchain = fenixStable.toolchain;
      rustPlatform = pkgs.makeRustPlatform {
        cargo = rustToolchain;
        rustc = rustToolchain;
      };

      rmdirall = {
        rustPlatform,
        lib,
        pkg-config,
        sqlite,
      }:
        rustPlatform.buildRustPackage {
          name = "rmdirall";
          src = lib.cleanSource ./.;

          cargoLock.lockFile = ./Cargo.lock;

          nativeBuildInputs = [
            pkg-config
            rustPlatform.bindgenHook
          ];

          buildInputs = with pkgs; (
            [
              rustPlatform.bindgenHook
            ]
            ++ lib.optionals (stdenv.isDarwin) [
              libiconv
            ]
          );

          meta = with lib; {
            license = licenses.mpl20;
            homepage = "https://github.com/Sciencentistguy/rmdirall";
            platforms = platforms.all;
          };
        };
    in rec {
      packages.rmdirall = pkgs.callPackage rmdirall {
        inherit rustPlatform;
      };

      packages.default = self.packages.${system}.rmdirall;

      devShells.default = pkgs.mkShell {
        inputsFrom = [
          packages.rmdirall
        ];
        RUST_SRC_PATH = "${fenixStable.rust-src}/lib/rustlib/src/rust/library";
      };
    });
}
