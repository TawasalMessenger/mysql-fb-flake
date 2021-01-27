{
  description = "MySQL FB (RocksDB) flake";

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
      mkApp = drv: {
        type = "app";
        program = "${drv.pname or drv.name}${drv.passthru.exePath}";
      };
      derivation = { inherit mysql-fb; };
    in
    with pkgs; rec {
      packages.${system} = derivation;
      defaultPackage.${system} = mysql-fb;
      apps.${system}.mysql-fb = mkApp { drv = mysql-fb; };
      defaultApp.${system} = apps.mysql-fb;
      legacyPackages.${system} = extend overlay;
      devShell.${system} = callPackage ./shell.nix derivation;
      nixosModule = {
        # imports = [
        #   ./configuration.nix
        # ];
        nixpkgs.overlays = [ overlay ];
        services.mysql.package = lib.mkDefault mysql-fb;
      };
      overlay = final: prev: derivation;
    };
}
