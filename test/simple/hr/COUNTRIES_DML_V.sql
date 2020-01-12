CREATE OR REPLACE FORCE EDITIONABLE VIEW "TESTS"."COUNTRIES_DML_V" AS
SELECT "COUNTRY_ID" /*PK*/,
       "COUNTRY_NAME",
       "REGION_ID" /*FK*/
  FROM COUNTRIES
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0.2"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-12 20:35:52"
   * generated_by="OGOBRECHT"
   */
    ;

