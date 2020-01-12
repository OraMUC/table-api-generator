CREATE OR REPLACE FORCE EDITIONABLE VIEW "TESTS"."EMPLOYEES_DML_V" AS
SELECT "EMPLOYEE_ID" /*PK*/,
       "FIRST_NAME",
       "LAST_NAME",
       "EMAIL" /*UK*/,
       "PHONE_NUMBER",
       "HIRE_DATE",
       "JOB_ID" /*FK*/,
       "SALARY",
       "COMMISSION_PCT",
       "MANAGER_ID" /*FK*/,
       "DEPARTMENT_ID" /*FK*/
  FROM EMPLOYEES
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0.2"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-12 20:36:29"
   * generated_by="OGOBRECHT"
   */
    ;

