CREATE OR REPLACE TRIGGER "HR"."EMPLOYEES_IOIUD"
  INSTEAD OF INSERT OR UPDATE OR DELETE
  ON "EMPLOYEES_DML_V"
  FOR EACH ROW
BEGIN
  IF INSERTING THEN
    "EMPLOYEES_API".create_row (
      p_employee_id    => :new."EMPLOYEE_ID",
      p_first_name     => :new."FIRST_NAME",
      p_last_name      => :new."LAST_NAME",
      p_email          => :new."EMAIL",
      p_phone_number   => :new."PHONE_NUMBER",
      p_hire_date      => :new."HIRE_DATE",
      p_job_id         => :new."JOB_ID",
      p_salary         => :new."SALARY",
      p_commission_pct => :new."COMMISSION_PCT",
      p_manager_id     => :new."MANAGER_ID",
      p_department_id  => :new."DEPARTMENT_ID" );
  ELSIF UPDATING THEN
    "EMPLOYEES_API".update_row (
      p_employee_id    => :new."EMPLOYEE_ID",
      p_first_name     => :new."FIRST_NAME",
      p_last_name      => :new."LAST_NAME",
      p_email          => :new."EMAIL",
      p_phone_number   => :new."PHONE_NUMBER",
      p_hire_date      => :new."HIRE_DATE",
      p_job_id         => :new."JOB_ID",
      p_salary         => :new."SALARY",
      p_commission_pct => :new."COMMISSION_PCT",
      p_manager_id     => :new."MANAGER_ID",
      p_department_id  => :new."DEPARTMENT_ID" );
  ELSIF DELETING THEN
    raise_application_error (-20000, 'Deletion of a row is not allowed.');
  END IF;
END "EMPLOYEES_IOIUD";
/
ALTER TRIGGER "HR"."EMPLOYEES_IOIUD" ENABLE;

