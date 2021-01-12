{
  description = "MySQL FB (RocksDB) flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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

  outputs = { self, nixpkgs, flake-compat, rocksdb-src, mysql-src }: {
    defaultPackage.x86_64-linux =
      with import nixpkgs { system = "x86_64-linux"; };
      let
        stdenv = gcc9Stdenv;
        rocksdb = stdenv.mkDerivation rec {
          name = "rocksdb";

          src = rocksdb-src;

          nativeBuildInputs = [ cmake ninja ];
          buildInputs = [ lz4 zlib zstd jemalloc liburing numactl tbb ];

          cmakeFlags = [
            "-DPORTABLE=0"
            "-DFAIL_ON_WARNINGS=YES"
            "-DFORCE_SSE42=1"
            "-DUSE_RTTI=1"
            "-DWITH_BENCHMARK_TOOLS=0"
            "-DWITH_BZ2=0"
            "-DWITH_GFLAGS=0"
            "-DWITH_JEMALLOC=1"
            "-DWITH_JNI=0"
            "-DWITH_LZ4=1"
            "-DWITH_NUMA=1"
            "-DWITH_SNAPPY=0"
            "-DWITH_TBB=1"
            "-DWITH_TESTS=1"
            "-DWITH_TOOLS=0"
            "-DWITH_ZLIB=1"
            "-DWITH_ZSTD=1"
          ];

          NIX_CFLAGS_COMPILE = "-DLIBURING -DROCKSDB_IOURING_PRESENT -Wno-error=deprecated-copy -Wno-error=pessimizing-move";
          NIX_LDFLAGS = "-luring";
        };
      in
      stdenv.mkDerivation rec {
        name = "mysql";

        src = mysql-src;

        nativeBuildInputs = [ bison cmake pkgconfig rpcsvc-proto makeWrapper ];
        buildInputs = [
          icu
          libedit
          libevent
          ncurses
          openssl
          re2
          readline
          zlib
          lz4
          numactl
          libtirpc

          bash
          boost169
          coreutils
          gnumake
          libaio
          perl
          protobuf3_6
          rocksdb
          zstd
        ];

        outputs = [ "out" "static" ];

        cmakeFlags = [
          "-DCMAKE_BUILD_TYPE=Release"
          "-DBUILD_CONFIG=mysql_release"
          "-DFEATURE_SET=community"
          "-DHAVE_EXTERNAL_ROCKSDB=ON"
          "-DROCKSDB_SRC_PATH=${rocksdb-src}"
          "-DWITH_SYSTEM_LIBS=ON"
          "-DWITH_LZ4=system"
          "-DWITH_ZSTD=system"
          "-DWITH_NUMA=ON"
          "-DCMAKE_SKIP_BUILD_RPATH=OFF" # To run libmysql/libmysql_api_test during build.
          "-DWITH_UNIT_TESTS=OFF"

          "-DMYSQL_UNIX_ADDR=/run/mysqld/mysqld.sock"
          "-DMYSQL_DATADIR=/var/lib/mysql"
          "-DINSTALL_INFODIR=share/mysql/docs"
          "-DINSTALL_MANDIR=share/man"
          "-DINSTALL_PLUGINDIR=lib/mysql/plugin"
          "-DINSTALL_INCLUDEDIR=include/mysql"
          "-DINSTALL_DOCREADMEDIR=share/mysql"
          "-DINSTALL_SUPPORTFILESDIR=share/mysql"
          "-DINSTALL_MYSQLSHAREDIR=share/mysql"
          "-DINSTALL_MYSQLTESTDIR="
          "-DINSTALL_DOCDIR=share/mysql/docs"
          "-DINSTALL_SHAREDIR=share/mysql"

          "-DMYSQL_GITHASH=${mysql-src.rev}"
          "-DMYSQL_GITDATE=${mysql-src.lastModifiedDate}"
          "-DROCKSDB_GITHASH=${rocksdb-src.rev}"
          "-DROCKSDB_GITDATE=${rocksdb-src.lastModifiedDate}"
        ];

        NIX_LDFLAGS = "-lrocksdb";

        enableParallelBuilding = true;

        preBuild = ''
          patchShebangs .
        '';

        postInstall = ''
          moveToOutput "lib/*.a" $static
          ln -s libmysqlclient.so $out/lib/libmysqlclient_r.so
          chmod go-w $out
        '';

        passthru = {
          client = self;
          connector-c = self;
          server = self;
          mysqlVersion = "8.0";
        };
      };
  };
}
