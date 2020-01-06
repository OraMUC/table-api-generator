CREATE OR REPLACE FORCE EDITIONABLE VIEW "HR"."LOCATIONS_DML_V" AS
SELECT "LOCATION_ID" /*PK*/,
       "STREET_ADDRESS",
       "POSTAL_CODE",
       "CITY",
       "STATE_PROVINCE",
       "COUNTRY_ID" /*FK*/
  FROM LOCATIONS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.7.0"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-03 22:14:27"
   * generated_by="DATA-ABC\INFO"
   */
    ;

