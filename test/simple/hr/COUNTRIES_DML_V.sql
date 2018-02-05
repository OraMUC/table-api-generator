CREATE OR REPLACE FORCE VIEW "HR"."COUNTRIES_DML_V" AS
SELECT "COUNTRY_ID" /*PK*/,
       "COUNTRY_NAME",
       "REGION_ID" /*FK*/
  FROM COUNTRIES
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0_b4"
   * generator_action="COMPILE_API"
   * generated_at="2018-02-05 20:26:37"
   * generated_by="DECAF4"
   */
    ;

