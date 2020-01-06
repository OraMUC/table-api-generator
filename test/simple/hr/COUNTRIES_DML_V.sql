CREATE OR REPLACE FORCE EDITIONABLE VIEW "HR"."COUNTRIES_DML_V" AS
SELECT "COUNTRY_ID" /*PK*/,
       "COUNTRY_NAME",
       "REGION_ID" /*FK*/
  FROM COUNTRIES
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.7.0"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-03 22:14:26"
   * generated_by="DATA-ABC\INFO"
   */
    ;

