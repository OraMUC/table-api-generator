set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
whenever oserror exit 1 rollback

prompt
prompt Uninstall github.com/OraMUC/table-api-generator
prompt ============================================================
prompt Drop packages OM_TAPIGEN and OM_TAPIGEN_ODDGEN_WRAPPER
BEGIN
  FOR i IN (
    SELECT
      *
    FROM
      user_objects
    WHERE
      object_type = 'PACKAGE'
      AND object_name IN (
        'OM_TAPIGEN_ODDGEN_WRAPPER',
        'OM_TAPIGEN'
      )
  ) LOOP
    EXECUTE IMMEDIATE 'drop package ' || i.object_name;
  END LOOP;
END;
/
prompt ============================================================
prompt Uninstallation Done
prompt
prompt Don't forget to delete private or public synonyms, 
prompt if you installed in a central tools schema. Also see
prompt https://github.com/OraMUC/table-api-generator/blob/master/docs/getting-started.md
prompt
