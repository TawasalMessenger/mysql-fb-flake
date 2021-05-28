{
  description = "MySQL (MyRocks) flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rocksdb-src = {
      url = "github:facebook/rocksdb/0f8c041ea7bb458caa5ec0dbeef9fa42d0b97482";
      flake = false;
    };
    mysql-src = {
      type = "git";
      url = "https://github.com/facebook/mysql-5.6";
      ref = "refs/tags/percona-202102";
      submodules = true;
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, rocksdb-src, mysql-src }:
    let
      sources = with builtins; (fromJSON (readFile ./flake.lock)).nodes;
      version = "8.0.20"; # sources.mysql-src.original.ref;
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        mysql-fb = import ./build.nix {
          inherit pkgs rocksdb-src mysql-src version;
        };
        mysql-fb-app = flake-utils.lib.mkApp { drv = mysql-fb; };
        derivation = { inherit mysql-fb; };
      in
      with pkgs; rec {
        packages = derivation;
        defaultPackage = mysql-fb;
        apps.mysql-fb = mysql-fb-app;
        defaultApp = mysql-fb-app;
        legacyPackages = extend overlay;
        devShell = pkgs.mkShell {
          name = "mysql-fb-env";
          buildInputs = [ mysql-fb ];
        };
        nixosModule = {
          nixpkgs.overlays = [ overlay ];
          services.mysql.package = lib.mkDefault mysql-fb;
        };
        overlay = final: prev: derivation;
      });
}
