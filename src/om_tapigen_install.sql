set define off feedback off
whenever sqlerror exit sql.sqlcode rollback
whenever oserror exit 1 rollback

prompt
prompt Install  github.com/OraMUC/table-api-generator
prompt ============================================================

prompt Compile package om_tapigen (spec)
@OM_TAPIGEN.pks
show errors

prompt Compile package om_tapigen (body)
@OM_TAPIGEN.pkb
show errors

prompt Compile package om_tapigen_oddgen wrapper (spec)
@OM_TAPIGEN_ODDGEN_WRAPPER.pks
show errors

prompt Compile package om_tapigen_oddgen wrapper (body)
@OM_TAPIGEN_ODDGEN_WRAPPER.pkb
show errors

prompt ============================================================
prompt Installation Done
prompt
prompt Don't forget to create a private or public synonym, 
prompt if you installed in a central tools schema. Also see
prompt https://github.com/OraMUC/table-api-generator/blob/master/docs/getting-started.md
prompt
