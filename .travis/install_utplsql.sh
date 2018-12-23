#!/bin/bash

set -ev

cd $UTPLSQL_DIR/source

sqlplus -S -L / AS SYSDBA @install_headless.sql

sqlplus -L -S / AS SYSDBA <<SQL
grant select any dictionary to ut3;
exit
SQL
