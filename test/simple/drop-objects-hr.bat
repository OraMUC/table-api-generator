echo off
set NLS_LANG=AMERICAN_AMERICA.AL32UTF8
echo exit | sqlplus test/oracle@localhost:1521/xe @drop-objects-hr.sql
