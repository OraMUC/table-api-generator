CREATE OR REPLACE FORCE VIEW "TEST"."JOBS_DML_V" AS
SELECT "JOB_ID" /*PK*/,
       "JOB_TITLE",
       "MIN_SALARY",
       "MAX_SALARY"
  FROM JOBS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0"
   * generator_action="COMPILE_API"
   * generated_at="2018-12-20 19:43:14"
   * generated_by="OGOBRECHT"
   */
    ;

