set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
prompt 

prompt Reset session regarding compiled om_tapigen...
@test-reset-session.sql;

prompt Generate API...
@test-generate-api.sql;

prompt Insert 10 rows...
@test-insert-10-rows.sql;

prompt Export API to files...
@test-export-api-to-file.sql

set define on verify on feedback on
prompt Done :-)
