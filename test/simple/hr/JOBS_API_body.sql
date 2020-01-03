
  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HR"."JOBS_API" IS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.7.0"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-03 22:14:28"
   * generated_by="DATA-ABC\INFO"
   */

  g_bulk_limit     PLS_INTEGER := 10000;
  g_bulk_completed BOOLEAN := FALSE;

  FUNCTION bulk_is_complete
    RETURN BOOLEAN
  IS
  BEGIN
    RETURN g_bulk_completed;
  END bulk_is_complete;

  PROCEDURE set_bulk_limit(p_bulk_limit IN PLS_INTEGER)
  IS
  BEGIN
    g_bulk_limit := p_bulk_limit;
  END set_bulk_limit;

  FUNCTION get_bulk_limit
    RETURN PLS_INTEGER
  IS
  BEGIN
    RETURN g_bulk_limit;
  END get_bulk_limit;

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

  FUNCTION create_rows(p_rows_tab IN t_rows_tab)
    RETURN t_rows_tab IS
    v_return t_rows_tab;
  BEGIN
    v_return := p_rows_tab;

    FORALL i IN INDICES OF p_rows_tab
      INSERT INTO "JOBS" (
      "JOB_ID" /*PK*/,
      "JOB_TITLE",
      "MIN_SALARY",
      "MAX_SALARY" )
      VALUES (
      v_return(i)."JOB_ID",
        v_return(i)."JOB_TITLE",
        v_return(i)."MIN_SALARY",
        v_return(i)."MAX_SALARY" );

    RETURN v_return;
  END create_rows;

  PROCEDURE create_rows(p_rows_tab IN t_rows_tab)
  IS
    v_return t_rows_tab;
  BEGIN
    v_return := create_rows(p_rows_tab => p_rows_tab);
  END create_rows;

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

  FUNCTION read_rows(p_ref_cursor IN t_strong_ref_cursor)
    RETURN t_rows_tab
  IS
    v_return t_rows_tab;
  BEGIN
    IF (p_ref_cursor%ISOPEN)
    THEN
      g_bulk_completed := FALSE;

      FETCH p_ref_cursor BULK COLLECT INTO v_return LIMIT g_bulk_limit;

      IF (v_return.COUNT < g_bulk_limit)
      THEN
        g_bulk_completed := TRUE;
      END IF;
    END IF;

    RETURN v_return;
  END read_rows;

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

  PROCEDURE update_rows(p_rows_tab IN t_rows_tab)
  IS
  BEGIN
    FORALL i IN INDICES OF p_rows_tab
        UPDATE JOBS
           SET "JOB_TITLE"  = p_rows_tab(i)."JOB_TITLE",
               "MIN_SALARY" = p_rows_tab(i)."MIN_SALARY",
               "MAX_SALARY" = p_rows_tab(i)."MAX_SALARY"
         WHERE "JOB_ID" = p_rows_tab(i)."JOB_ID";
  END update_rows;

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

