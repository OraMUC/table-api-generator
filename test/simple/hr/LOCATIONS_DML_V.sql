CREATE OR REPLACE FORCE VIEW "HR"."LOCATIONS_DML_V" AS
SELECT "LOCATION_ID" /*PK*/,
       "STREET_ADDRESS",
       "POSTAL_CODE",
       "CITY",
       "STATE_PROVINCE",
       "COUNTRY_ID" /*FK*/
  FROM LOCATIONS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0_b4"
   * generator_action="COMPILE_API"
   * generated_at="2018-02-05 20:26:40"
   * generated_by="DECAF4"
   */
    ;

