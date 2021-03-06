{ pkgs, mysql-src, rocksdb-src, version }:

with pkgs;
with gcc9Stdenv;
let
  rocksdb = mkDerivation rec {
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
  self = mkDerivation rec {
    inherit version;
    pname = "mysql";

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

      "-DCOMPILATION_COMMENT_SERVER="
      "-DCOMPILATION_COMMENT="
      "-DINSTALL_DOCDIR=share/mysql/docs"
      "-DINSTALL_DOCREADMEDIR=share/mysql"
      "-DINSTALL_INCLUDEDIR=include/mysql"
      "-DINSTALL_INFODIR=share/mysql/docs"
      "-DINSTALL_MANDIR=share/man"
      "-DINSTALL_MYSQLSHAREDIR=share/mysql"
      "-DINSTALL_MYSQLTESTDIR="
      "-DINSTALL_PLUGINDIR=lib/mysql/plugin"
      "-DINSTALL_SHAREDIR=share/mysql"
      "-DINSTALL_SUPPORTFILESDIR=share/mysql"
      "-DMYSQL_DATADIR=/var/mysql"
      "-DMYSQL_UNIX_ADDR=/run/mysqld/mysqld.sock"

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
in
self
