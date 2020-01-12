CREATE OR REPLACE FORCE EDITIONABLE VIEW "TESTS"."JOBS_DML_V" AS
SELECT "JOB_ID" /*PK*/,
       "JOB_TITLE",
       "MIN_SALARY",
       "MAX_SALARY"
  FROM JOBS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0.2"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-12 20:36:21"
   * generated_by="OGOBRECHT"
   */
    ;

