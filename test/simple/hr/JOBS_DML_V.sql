CREATE OR REPLACE FORCE EDITIONABLE VIEW "HR"."JOBS_DML_V" AS
SELECT "JOB_ID" /*PK*/,
       "JOB_TITLE",
       "MIN_SALARY",
       "MAX_SALARY"
  FROM JOBS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.7.0"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-03 21:39:44"
   * generated_by="DATA-ABC\INFO"
   */
    ;

