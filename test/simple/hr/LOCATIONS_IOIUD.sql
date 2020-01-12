CREATE OR REPLACE EDITIONABLE TRIGGER "TESTS"."LOCATIONS_IOIUD"
  INSTEAD OF INSERT OR UPDATE OR DELETE
  ON "LOCATIONS_DML_V"
  FOR EACH ROW
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0.2"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-12 20:36:08"
   * generated_by="OGOBRECHT"
   */
BEGIN
  IF INSERTING THEN
    "LOCATIONS_API".create_row (
      p_location_id    => :new."LOCATION_ID" /*PK*/,
      p_street_address => :new."STREET_ADDRESS",
      p_postal_code    => :new."POSTAL_CODE",
      p_city           => :new."CITY",
      p_state_province => :new."STATE_PROVINCE",
      p_country_id     => :new."COUNTRY_ID" /*FK*/ );
  ELSIF UPDATING THEN
    "LOCATIONS_API".update_row (
      p_location_id    => :new."LOCATION_ID" /*PK*/,
      p_street_address => :new."STREET_ADDRESS",
      p_postal_code    => :new."POSTAL_CODE",
      p_city           => :new."CITY",
      p_state_province => :new."STATE_PROVINCE",
      p_country_id     => :new."COUNTRY_ID" /*FK*/ );
  ELSIF DELETING THEN
    raise_application_error (-20000, 'Deletion of a row is not allowed.');
  END IF;
END "LOCATIONS_IOIUD";
/
ALTER TRIGGER "TESTS"."LOCATIONS_IOIUD" ENABLE;

