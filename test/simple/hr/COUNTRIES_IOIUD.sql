CREATE OR REPLACE EDITIONABLE TRIGGER "HR"."COUNTRIES_IOIUD"
  INSTEAD OF INSERT OR UPDATE OR DELETE
  ON "COUNTRIES_DML_V"
  FOR EACH ROW
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.7.0"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-03 22:14:26"
   * generated_by="DATA-ABC\INFO"
   */
BEGIN
  IF INSERTING THEN
    "COUNTRIES_API".create_row (
      p_country_id   => :new."COUNTRY_ID" /*PK*/,
      p_country_name => :new."COUNTRY_NAME",
      p_region_id    => :new."REGION_ID" /*FK*/ );
  ELSIF UPDATING THEN
    "COUNTRIES_API".update_row (
      p_country_id   => :new."COUNTRY_ID" /*PK*/,
      p_country_name => :new."COUNTRY_NAME",
      p_region_id    => :new."REGION_ID" /*FK*/ );
  ELSIF DELETING THEN
    raise_application_error (-20000, 'Deletion of a row is not allowed.');
  END IF;
END "COUNTRIES_IOIUD";
/
ALTER TRIGGER "HR"."COUNTRIES_IOIUD" ENABLE;

