set define off feedback off serveroutput on
whenever sqlerror exit sql.sqlcode rollback

prompt
prompt Install github.com/OraMUC/table-api-generator
prompt ============================================================

prompt Set compiler flags
declare
  v_db_version varchar2(10);
begin
  select replace(regexp_substr(min(version), '\d+\.\d+'), '.', null) as db_version
    into v_db_version
    from product_component_version
   where product like 'Oracle Database%';
  if to_number(v_db_version) < 121 then
    raise_application_error (-20000, 'Unsupported DB version detected: Sorry, you need to have 12.1 or higher for our table API generator :-(');
  end if;
  if to_number(v_db_version) >= 180 then
    execute immediate q'[
      select replace(regexp_substr(min(version_full), '\d+\.\d+'), '.', null) as db_version
        from product_component_version
       where product like 'Oracle Database%' ]'
      into v_db_version;
  end if;
  -- Show unset compiler flags as errors (results for example in errors like "PLW-06003: unknown inquiry directive '$$DB_VERSION'")
  execute immediate q'[alter session set plsql_warnings = 'ENABLE:6003']';
  -- Finally set compiler flags
  execute immediate replace(
    q'[alter session set plsql_ccflags = 'db_version:#DB_VERSION#']',
    '#DB_VERSION#',
    v_db_version);
end;
/

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
