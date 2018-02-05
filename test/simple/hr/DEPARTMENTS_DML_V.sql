CREATE OR REPLACE FORCE VIEW "HR"."DEPARTMENTS_DML_V" AS
SELECT "DEPARTMENT_ID" /*PK*/,
       "DEPARTMENT_NAME",
       "MANAGER_ID" /*FK*/,
       "LOCATION_ID" /*FK*/
  FROM DEPARTMENTS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0_b4"
   * generator_action="COMPILE_API"
   * generated_at="2018-02-05 20:26:38"
   * generated_by="DECAF4"
   */
    ;

