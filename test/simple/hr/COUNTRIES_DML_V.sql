CREATE OR REPLACE FORCE VIEW "TEST"."COUNTRIES_DML_V" AS
SELECT "COUNTRY_ID" /*PK*/,
       "COUNTRY_NAME",
       "REGION_ID" /*FK*/
  FROM COUNTRIES
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0"
   * generator_action="COMPILE_API"
   * generated_at="2018-12-20 19:43:11"
   * generated_by="OGOBRECHT"
   */
    ;

