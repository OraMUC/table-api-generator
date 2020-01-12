echo off
set NLS_LANG=AMERICAN_AMERICA.AL32UTF8
cd ..\..\
echo exit | sqlplus tests/oracle@localhost:1521/xepdb1 @om_tapigen_install.sql
cd test\simple
