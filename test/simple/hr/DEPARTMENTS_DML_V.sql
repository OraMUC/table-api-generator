CREATE OR REPLACE FORCE EDITIONABLE VIEW "HR"."DEPARTMENTS_DML_V" AS
SELECT "DEPARTMENT_ID" /*PK*/,
       "DEPARTMENT_NAME",
       "MANAGER_ID" /*FK*/,
       "LOCATION_ID" /*FK*/
  FROM DEPARTMENTS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.7.0"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-03 21:39:42"
   * generated_by="DATA-ABC\INFO"
   */
    ;

