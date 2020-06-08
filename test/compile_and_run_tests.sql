--https://stackoverflow.com/questions/27543873/sqlplus-conditional-execution-with-variable-from-query
set define on verify off feedback off serveroutput on linesize 300
whenever sqlerror exit sql.sqlcode rollback

prompt
prompt Test github.com/OraMUC/table-api-generator
prompt ============================================================
@create_log_table.sql
@TEST_OM_TAPIGEN.pks
@TEST_OM_TAPIGEN.pkb
@run_performance_tests.sql TAG_TENANT_VISIBLE 10
@run_unit_tests.sql
--@view_columns_array.sql
prompt ============================================================
prompt Tests Done
prompt