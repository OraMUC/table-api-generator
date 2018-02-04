CREATE OR REPLACE TRIGGER "HR"."COUNTRIES_IOIUD"
  INSTEAD OF INSERT OR UPDATE OR DELETE
  ON "COUNTRIES_DML_V"
  FOR EACH ROW
BEGIN
  IF INSERTING THEN
    "COUNTRIES_API".create_row (
      p_country_id   => :new."COUNTRY_ID",
      p_country_name => :new."COUNTRY_NAME",
      p_region_id    => :new."REGION_ID" );
  ELSIF UPDATING THEN
    "COUNTRIES_API".update_row (
      p_country_id   => :new."COUNTRY_ID",
      p_country_name => :new."COUNTRY_NAME",
      p_region_id    => :new."REGION_ID" );
  ELSIF DELETING THEN
    raise_application_error (-20000, 'Deletion of a row is not allowed.');
  END IF;
END "COUNTRIES_IOIUD";
/
ALTER TRIGGER "HR"."COUNTRIES_IOIUD" ENABLE;

