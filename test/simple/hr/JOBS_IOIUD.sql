CREATE OR REPLACE TRIGGER "TEST"."JOBS_IOIUD"
  INSTEAD OF INSERT OR UPDATE OR DELETE
  ON "JOBS_DML_V"
  FOR EACH ROW
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0"
   * generator_action="COMPILE_API"
   * generated_at="2018-12-20 19:43:14"
   * generated_by="OGOBRECHT"
   */
BEGIN
  IF INSERTING THEN
    "JOBS_API".create_row (
      p_job_id     => :new."JOB_ID" /*PK*/,
      p_job_title  => :new."JOB_TITLE",
      p_min_salary => :new."MIN_SALARY",
      p_max_salary => :new."MAX_SALARY" );
  ELSIF UPDATING THEN
    "JOBS_API".update_row (
      p_job_id     => :new."JOB_ID" /*PK*/,
      p_job_title  => :new."JOB_TITLE",
      p_min_salary => :new."MIN_SALARY",
      p_max_salary => :new."MAX_SALARY" );
  ELSIF DELETING THEN
    raise_application_error (-20000, 'Deletion of a row is not allowed.');
  END IF;
END "JOBS_IOIUD";
/
ALTER TRIGGER "TEST"."JOBS_IOIUD" ENABLE;

