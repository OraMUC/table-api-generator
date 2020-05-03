set define off feedback off serveroutput on
whenever sqlerror exit sql.sqlcode rollback

prompt
prompt Test github.com/OraMUC/table-api-generator
prompt ============================================================

prompt Create log table
@create_log_table.sql

prompt Compile package test_om_tapigen (spec)
@TEST_OM_TAPIGEN.pks
show errors

prompt Compile package test_om_tapigen (body)
@TEST_OM_TAPIGEN.pkb
show errors

prompt RUN TESTS
execute ut.run('test_om_tapigen');

prompt ============================================================
prompt Tests Done
prompt