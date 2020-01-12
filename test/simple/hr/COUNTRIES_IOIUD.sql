CREATE OR REPLACE EDITIONABLE TRIGGER "TESTS"."COUNTRIES_IOIUD"
  INSTEAD OF INSERT OR UPDATE OR DELETE
  ON "COUNTRIES_DML_V"
  FOR EACH ROW
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0.2"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-12 20:35:52"
   * generated_by="OGOBRECHT"
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
ALTER TRIGGER "TESTS"."COUNTRIES_IOIUD" ENABLE;

