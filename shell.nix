{ mkShell, mysql-fb }:

mkShell {
  name = "mysql-fb-env";

  buildInputs = [ mysql-fb ];
}
