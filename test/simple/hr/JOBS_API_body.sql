CREATE OR REPLACE PACKAGE BODY "TEST"."JOBS_API" IS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0"
   * generator_action="COMPILE_API"
   * generated_at="2018-12-20 19:43:14"
   * generated_by="OGOBRECHT"
   */

  FUNCTION row_exists (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE /*PK*/ )
  RETURN BOOLEAN
  IS
    v_return BOOLEAN := FALSE;
    v_dummy  PLS_INTEGER;
    CURSOR   cur_bool IS
      SELECT 1
        FROM "JOBS"
       WHERE "JOB_ID" = p_job_id;
  BEGIN
    OPEN cur_bool;
    FETCH cur_bool INTO v_dummy;
    IF cur_bool%FOUND THEN
      v_return := TRUE;
    END IF;
    CLOSE cur_bool;
    RETURN v_return;
  END;

  FUNCTION row_exists_yn (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE /*PK*/ )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN CASE WHEN row_exists( p_job_id => p_job_id )
             THEN 'Y'
             ELSE 'N'
           END;
  END;

  FUNCTION create_row (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE     DEFAULT NULL /*PK*/,
    p_job_title  IN "JOBS"."JOB_TITLE"%TYPE  ,
    p_min_salary IN "JOBS"."MIN_SALARY"%TYPE DEFAULT NULL,
    p_max_salary IN "JOBS"."MAX_SALARY"%TYPE DEFAULT NULL )
  RETURN "JOBS"."JOB_ID"%TYPE IS
    v_return "JOBS"."JOB_ID"%TYPE;
  BEGIN
    INSERT INTO "JOBS" (
      "JOB_ID" /*PK*/,
      "JOB_TITLE",
      "MIN_SALARY",
      "MAX_SALARY" )
    VALUES (
      p_job_id,
      p_job_title,
      p_min_salary,
      p_max_salary )
    RETURN
      "JOB_ID"
    INTO v_return;
    RETURN v_return;
  END create_row;

  PROCEDURE create_row (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE     DEFAULT NULL /*PK*/,
    p_job_title  IN "JOBS"."JOB_TITLE"%TYPE  ,
    p_min_salary IN "JOBS"."MIN_SALARY"%TYPE DEFAULT NULL,
    p_max_salary IN "JOBS"."MAX_SALARY"%TYPE DEFAULT NULL )
  IS
    v_return "JOBS"."JOB_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_job_id     => p_job_id /*PK*/,
      p_job_title  => p_job_title,
      p_min_salary => p_min_salary,
      p_max_salary => p_max_salary );
  END create_row;

  FUNCTION create_row (
    p_row        IN "JOBS"%ROWTYPE )
  RETURN "JOBS"."JOB_ID"%TYPE IS
    v_return "JOBS"."JOB_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_job_id     => p_row."JOB_ID" /*PK*/,
      p_job_title  => p_row."JOB_TITLE",
      p_min_salary => p_row."MIN_SALARY",
      p_max_salary => p_row."MAX_SALARY" );
    RETURN v_return;
  END create_row;

  PROCEDURE create_row (
    p_row        IN "JOBS"%ROWTYPE )
  IS
    v_return "JOBS"."JOB_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_job_id     => p_row."JOB_ID" /*PK*/,
      p_job_title  => p_row."JOB_TITLE",
      p_min_salary => p_row."MIN_SALARY",
      p_max_salary => p_row."MAX_SALARY" );
  END create_row;

  FUNCTION read_row (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE /*PK*/ )
  RETURN "JOBS"%ROWTYPE IS
    v_row "JOBS"%ROWTYPE;
    CURSOR cur_row IS
      SELECT *
        FROM "JOBS"
       WHERE "JOB_ID" = p_job_id;
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_row;
    CLOSE cur_row;
    RETURN v_row;
  END read_row;

  PROCEDURE update_row (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE DEFAULT NULL /*PK*/,
    p_job_title  IN "JOBS"."JOB_TITLE"%TYPE,
    p_min_salary IN "JOBS"."MIN_SALARY"%TYPE,
    p_max_salary IN "JOBS"."MAX_SALARY"%TYPE )
  IS
    v_row   "JOBS"%ROWTYPE;

  BEGIN
    IF row_exists ( p_job_id => p_job_id ) THEN
      v_row := read_row ( p_job_id => p_job_id );
      -- update only, if the column values really differ
      IF v_row."JOB_TITLE" <> p_job_title
      OR COALESCE(v_row."MIN_SALARY", -999999999999999.999999999999999) <> COALESCE(p_min_salary, -999999999999999.999999999999999)
      OR COALESCE(v_row."MAX_SALARY", -999999999999999.999999999999999) <> COALESCE(p_max_salary, -999999999999999.999999999999999)

      THEN
        UPDATE JOBS
           SET "JOB_TITLE"  = p_job_title,
               "MIN_SALARY" = p_min_salary,
               "MAX_SALARY" = p_max_salary
         WHERE "JOB_ID" = p_job_id;
      END IF;
    END IF;
  END update_row;

  PROCEDURE update_row (
    p_row        IN "JOBS"%ROWTYPE )
  IS
  BEGIN
    update_row(
      p_job_id     => p_row."JOB_ID" /*PK*/,
      p_job_title  => p_row."JOB_TITLE",
      p_min_salary => p_row."MIN_SALARY",
      p_max_salary => p_row."MAX_SALARY" );
  END update_row;

  FUNCTION create_or_update_row (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE DEFAULT NULL /*PK*/,
    p_job_title  IN "JOBS"."JOB_TITLE"%TYPE,
    p_min_salary IN "JOBS"."MIN_SALARY"%TYPE,
    p_max_salary IN "JOBS"."MAX_SALARY"%TYPE )
  RETURN "JOBS"."JOB_ID"%TYPE IS
    v_return "JOBS"."JOB_ID"%TYPE;
  BEGIN
    IF row_exists( p_job_id => p_job_id ) THEN
      update_row(
        p_job_id     => p_job_id /*PK*/,
        p_job_title  => p_job_title,
        p_min_salary => p_min_salary,
        p_max_salary => p_max_salary );
      v_return := read_row ( p_job_id => p_job_id )."JOB_ID";
    ELSE
      v_return := create_row (
        p_job_id     => p_job_id /*PK*/,
        p_job_title  => p_job_title,
        p_min_salary => p_min_salary,
        p_max_salary => p_max_salary );
    END IF;
    RETURN v_return;
  END create_or_update_row;

  PROCEDURE create_or_update_row (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE DEFAULT NULL /*PK*/,
    p_job_title  IN "JOBS"."JOB_TITLE"%TYPE,
    p_min_salary IN "JOBS"."MIN_SALARY"%TYPE,
    p_max_salary IN "JOBS"."MAX_SALARY"%TYPE )
  IS
    v_return "JOBS"."JOB_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_job_id     => p_job_id /*PK*/,
      p_job_title  => p_job_title,
      p_min_salary => p_min_salary,
      p_max_salary => p_max_salary );
  END create_or_update_row;

  FUNCTION create_or_update_row (
    p_row        IN "JOBS"%ROWTYPE )
  RETURN "JOBS"."JOB_ID"%TYPE IS
    v_return "JOBS"."JOB_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_job_id     => p_row."JOB_ID" /*PK*/,
      p_job_title  => p_row."JOB_TITLE",
      p_min_salary => p_row."MIN_SALARY",
      p_max_salary => p_row."MAX_SALARY" );
    RETURN v_return;
  END create_or_update_row;

  PROCEDURE create_or_update_row (
    p_row        IN "JOBS"%ROWTYPE )
  IS
    v_return "JOBS"."JOB_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_job_id     => p_row."JOB_ID" /*PK*/,
      p_job_title  => p_row."JOB_TITLE",
      p_min_salary => p_row."MIN_SALARY",
      p_max_salary => p_row."MAX_SALARY" );
  END create_or_update_row;

  FUNCTION get_a_row
  RETURN "JOBS"%ROWTYPE IS
    v_row "JOBS"%ROWTYPE;
  BEGIN
    v_row."JOB_ID"     := substr(sys_guid(),1,10) /*PK*/;
    v_row."JOB_TITLE"  := substr(sys_guid(),1,35);
    v_row."MIN_SALARY" := round(dbms_random.value(0,999999),0);
    v_row."MAX_SALARY" := round(dbms_random.value(0,999999),0);
    return v_row;
  END get_a_row;

  FUNCTION create_a_row (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE     DEFAULT get_a_row()."JOB_ID" /*PK*/,
    p_job_title  IN "JOBS"."JOB_TITLE"%TYPE  DEFAULT get_a_row()."JOB_TITLE",
    p_min_salary IN "JOBS"."MIN_SALARY"%TYPE DEFAULT get_a_row()."MIN_SALARY",
    p_max_salary IN "JOBS"."MAX_SALARY"%TYPE DEFAULT get_a_row()."MAX_SALARY" )
  RETURN "JOBS"."JOB_ID"%TYPE IS
    v_return "JOBS"."JOB_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_job_id     => p_job_id /*PK*/,
      p_job_title  => p_job_title,
      p_min_salary => p_min_salary,
      p_max_salary => p_max_salary );
    RETURN v_return;
  END create_a_row;

  PROCEDURE create_a_row (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE     DEFAULT get_a_row()."JOB_ID" /*PK*/,
    p_job_title  IN "JOBS"."JOB_TITLE"%TYPE  DEFAULT get_a_row()."JOB_TITLE",
    p_min_salary IN "JOBS"."MIN_SALARY"%TYPE DEFAULT get_a_row()."MIN_SALARY",
    p_max_salary IN "JOBS"."MAX_SALARY"%TYPE DEFAULT get_a_row()."MAX_SALARY" )
  IS
    v_return "JOBS"."JOB_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_job_id     => p_job_id /*PK*/,
      p_job_title  => p_job_title,
      p_min_salary => p_min_salary,
      p_max_salary => p_max_salary );
  END create_a_row;

  FUNCTION read_a_row
  RETURN "JOBS"%ROWTYPE IS
    v_row  "JOBS"%ROWTYPE;
    CURSOR cur_row IS SELECT * FROM JOBS;
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_row;
    CLOSE cur_row;
    RETURN v_row;
  END read_a_row;

END "JOBS_API";
/

