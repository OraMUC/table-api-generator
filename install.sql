set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
whenever oserror exit 1 rollback

prompt
prompt
prompt Install github.com/OraMUC/table-api-generator
prompt ====================================================
prompt - Package OM_TAPIGEN
@OM_TAPIGEN.pks
@OM_TAPIGEN.pkb
prompt - Package OM_TAPIGEN_ODDGEN_WRAPPER
@OM_TAPIGEN_ODDGEN_WRAPPER.pks
@OM_TAPIGEN_ODDGEN_WRAPPER.pkb
prompt ====================================================
prompt Done :-)
prompt
prompt Don't forget to create a private or public synonym, 
prompt if you installed in a central tools schema. Also see
prompt https://github.com/OraMUC/table-api-generator/blob/master/docs/getting-started.md
prompt
prompt
