CREATE OR REPLACE FORCE VIEW "TEST"."LOCATIONS_DML_V" AS
SELECT "LOCATION_ID" /*PK*/,
       "STREET_ADDRESS",
       "POSTAL_CODE",
       "CITY",
       "STATE_PROVINCE",
       "COUNTRY_ID" /*FK*/
  FROM LOCATIONS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0"
   * generator_action="COMPILE_API"
   * generated_at="2018-12-20 19:43:13"
   * generated_by="OGOBRECHT"
   */
    ;

