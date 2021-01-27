# Install

## Global installation for NixOS

/etc/nixos/configuration.nix:

```nix
{
# ...
  imports = [
    (import (fetchTarball {
      url = "https://github.com/TawasalMessenger/mysql-fb-flake/archive/prod8-202009.tar.gz";
      sha256 = "1srlc9p1hmkvmab9wg26x33sspz2ak8822l6ly2pi35q6q182ljk";
    })).nixosModule
  ];
  services.mysql.enable = true;
# ...
}
```
