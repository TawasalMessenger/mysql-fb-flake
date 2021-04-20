{
  description = "MySQL (MyRocks) flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    rocksdb-src = {
      url = "github:facebook/rocksdb/12b78e40bdba980f3692fd2018cc905eef2127f8";
      flake = false;
    };
    mysql-src = {
      url = "github:facebook/mysql-5.6/fb-prod8-202009";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-compat, rocksdb-src, mysql-src }:
    let
      sources = with builtins; (fromJSON (readFile ./flake.lock)).nodes;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mysql-fb = import ./build.nix {
        inherit pkgs rocksdb-src mysql-src;
        version = sources.mysql-src.original.ref;
      };
      derivation = { inherit mysql-fb; };
    in
    with pkgs; rec {
      packages.${system} = derivation;
      defaultPackage.${system} = mysql-fb;
      legacyPackages.${system} = extend overlay;
      devShell.${system} = pkgs.mkShell {
        name = "mysql-fb-env";
        buildInputs = [ mysql-fb ];
      };
      nixosModule = {
        nixpkgs.overlays = [ overlay ];
        services.mysql.package = lib.mkDefault mysql-fb;
      };
      overlay = final: prev: derivation;
    };
}
