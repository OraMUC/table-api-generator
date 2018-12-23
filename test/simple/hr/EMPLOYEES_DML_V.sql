CREATE OR REPLACE FORCE VIEW "TEST"."EMPLOYEES_DML_V" AS
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
   * generator_version="0.5.0"
   * generator_action="COMPILE_API"
   * generated_at="2018-12-20 19:43:15"
   * generated_by="OGOBRECHT"
   */
    ;

