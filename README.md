# Install

## Global installation for NixOS

/etc/nixos/configuration.nix:

```nix
let
  mysql-fb = import (fetchTarball {
    url = "https://github.com/TimothyKlim/mysql-fb-flake/archive/483181b59a792df0439cb0b971b3ea0f34394f3a.tar.gz";
    sha256 = "1sxx8hjvhbixkkz5y813mahcglrlm0l8hfm6wql1srqv8wn1fa39";
  }) {};
# ...
in
{
# ...
  services.mysql.package = mysql-fb;
# ...
}
```
