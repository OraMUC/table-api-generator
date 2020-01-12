CREATE OR REPLACE FORCE EDITIONABLE VIEW "TESTS"."LOCATIONS_DML_V" AS
SELECT "LOCATION_ID" /*PK*/,
       "STREET_ADDRESS",
       "POSTAL_CODE",
       "CITY",
       "STATE_PROVINCE",
       "COUNTRY_ID" /*FK*/
  FROM LOCATIONS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0.2"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-12 20:36:08"
   * generated_by="OGOBRECHT"
   */
    ;

