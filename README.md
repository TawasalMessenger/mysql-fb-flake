# Install

## Global installation for NixOS

/etc/nixos/configuration.nix:

```nix
{
# ...
  imports = [
    (import (fetchTarball {
      url = "https://github.com/TawasalMessenger/mysql-fb-flake/archive/prod8-202009.tar.gz";
      sha256 = "";
    })).nixosModule
  ];
  services.mysql.enable = true;
# ...
}
```
