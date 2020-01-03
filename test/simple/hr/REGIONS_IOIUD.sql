CREATE OR REPLACE EDITIONABLE TRIGGER "HR"."REGIONS_IOIUD"
  INSTEAD OF INSERT OR UPDATE OR DELETE
  ON "REGIONS_DML_V"
  FOR EACH ROW
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.7.0"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-03 21:39:44"
   * generated_by="DATA-ABC\INFO"
   */
BEGIN
  IF INSERTING THEN
    "REGIONS_API".create_row (
      p_region_id   => :new."REGION_ID" /*PK*/,
      p_region_name => :new."REGION_NAME" );
  ELSIF UPDATING THEN
    "REGIONS_API".update_row (
      p_region_id   => :new."REGION_ID" /*PK*/,
      p_region_name => :new."REGION_NAME" );
  ELSIF DELETING THEN
    raise_application_error (-20000, 'Deletion of a row is not allowed.');
  END IF;
END "REGIONS_IOIUD";
/
ALTER TRIGGER "HR"."REGIONS_IOIUD" ENABLE;

