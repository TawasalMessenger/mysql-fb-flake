# Install

## Global installation for NixOS

/etc/nixos/configuration.nix:

```nix
{
# ...
  imports = [
    (import (fetchTarball {
      url = "https://github.com/TawasalMessenger/mysql-fb-flake/archive/prod8-202009.1.tar.gz";
      sha256 = "0ff0xn0q9n78wm5g6ymf7j5p78hqy02fb6rsswa0z3rxifianbwr";
    })).nixosModule
  ];
  services.mysql.enable = true;
# ...
}
```
