CREATE OR REPLACE FORCE VIEW "TEST"."DEPARTMENTS_DML_V" AS
SELECT "DEPARTMENT_ID" /*PK*/,
       "DEPARTMENT_NAME",
       "MANAGER_ID" /*FK*/,
       "LOCATION_ID" /*FK*/
  FROM DEPARTMENTS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0"
   * generator_action="COMPILE_API"
   * generated_at="2018-12-20 19:43:12"
   * generated_by="OGOBRECHT"
   */
    ;

