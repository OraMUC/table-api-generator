echo off
set NLS_LANG=AMERICAN_AMERICA.AL32UTF8
echo exit | sqlplus tests/oracle@localhost:1521/xepdb1 @drop-objects-hr.sql
