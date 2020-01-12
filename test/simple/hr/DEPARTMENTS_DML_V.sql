CREATE OR REPLACE FORCE EDITIONABLE VIEW "TESTS"."DEPARTMENTS_DML_V" AS
SELECT "DEPARTMENT_ID" /*PK*/,
       "DEPARTMENT_NAME",
       "MANAGER_ID" /*FK*/,
       "LOCATION_ID" /*FK*/
  FROM DEPARTMENTS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0.2"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-12 20:36:01"
   * generated_by="OGOBRECHT"
   */
    ;

