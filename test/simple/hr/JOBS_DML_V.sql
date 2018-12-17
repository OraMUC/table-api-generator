CREATE OR REPLACE FORCE VIEW "HR"."JOBS_DML_V" AS
SELECT "JOB_ID" /*PK*/,
       "JOB_TITLE",
       "MIN_SALARY",
       "MAX_SALARY"
  FROM JOBS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0_b4"
   * generator_action="COMPILE_API"
   * generated_at="2018-02-05 20:26:39"
   * generated_by="DECAF4"
   */
    ;

