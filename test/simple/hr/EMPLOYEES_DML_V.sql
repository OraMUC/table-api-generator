CREATE OR REPLACE FORCE VIEW "HR"."EMPLOYEES_DML_V" AS
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
   * generator_version="0.5.0_b4"
   * generator_action="COMPILE_API"
   * generated_at="2018-02-05 20:26:38"
   * generated_by="DECAF4"
   */
    ;

