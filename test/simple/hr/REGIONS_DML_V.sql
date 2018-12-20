CREATE OR REPLACE FORCE VIEW "TEST"."REGIONS_DML_V" AS
SELECT "REGION_ID" /*PK*/,
       "REGION_NAME"
  FROM REGIONS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0"
   * generator_action="COMPILE_API"
   * generated_at="2018-12-20 19:43:13"
   * generated_by="OGOBRECHT"
   */
    ;

