
  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HR"."DEPARTMENTS_API" IS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.7.0"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-03 22:14:26"
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
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE /*PK*/ )
  RETURN BOOLEAN
  IS
    v_return BOOLEAN := FALSE;
    v_dummy  PLS_INTEGER;
    CURSOR   cur_bool IS
      SELECT 1
        FROM "DEPARTMENTS"
       WHERE "DEPARTMENT_ID" = p_department_id;
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
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE /*PK*/ )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN CASE WHEN row_exists( p_department_id => p_department_id )
             THEN 'Y'
             ELSE 'N'
           END;
  END;

  FUNCTION create_row (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE   DEFAULT NULL /*PK*/,
    p_department_name IN "DEPARTMENTS"."DEPARTMENT_NAME"%TYPE ,
    p_manager_id      IN "DEPARTMENTS"."MANAGER_ID"%TYPE      DEFAULT NULL /*FK*/,
    p_location_id     IN "DEPARTMENTS"."LOCATION_ID"%TYPE     DEFAULT NULL /*FK*/ )
  RETURN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE IS
    v_return "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;
  BEGIN
    INSERT INTO "DEPARTMENTS" (
      "DEPARTMENT_ID" /*PK*/,
      "DEPARTMENT_NAME",
      "MANAGER_ID" /*FK*/,
      "LOCATION_ID" /*FK*/ )
    VALUES (
      COALESCE( p_department_id, "DEPARTMENTS_SEQ".nextval ),
      p_department_name,
      p_manager_id,
      p_location_id )
    RETURN
      "DEPARTMENT_ID"
    INTO v_return;
    RETURN v_return;
  END create_row;

  PROCEDURE create_row (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE   DEFAULT NULL /*PK*/,
    p_department_name IN "DEPARTMENTS"."DEPARTMENT_NAME"%TYPE ,
    p_manager_id      IN "DEPARTMENTS"."MANAGER_ID"%TYPE      DEFAULT NULL /*FK*/,
    p_location_id     IN "DEPARTMENTS"."LOCATION_ID"%TYPE     DEFAULT NULL /*FK*/ )
  IS
    v_return "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_department_id   => p_department_id /*PK*/,
      p_department_name => p_department_name,
      p_manager_id      => p_manager_id /*FK*/,
      p_location_id     => p_location_id /*FK*/ );
  END create_row;

  FUNCTION create_row (
    p_row             IN "DEPARTMENTS"%ROWTYPE )
  RETURN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE IS
    v_return "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_department_id   => p_row."DEPARTMENT_ID" /*PK*/,
      p_department_name => p_row."DEPARTMENT_NAME",
      p_manager_id      => p_row."MANAGER_ID" /*FK*/,
      p_location_id     => p_row."LOCATION_ID" /*FK*/ );
    RETURN v_return;
  END create_row;

  PROCEDURE create_row (
    p_row             IN "DEPARTMENTS"%ROWTYPE )
  IS
    v_return "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_department_id   => p_row."DEPARTMENT_ID" /*PK*/,
      p_department_name => p_row."DEPARTMENT_NAME",
      p_manager_id      => p_row."MANAGER_ID" /*FK*/,
      p_location_id     => p_row."LOCATION_ID" /*FK*/ );
  END create_row;

  FUNCTION create_rows(p_rows_tab IN t_rows_tab)
    RETURN t_rows_tab IS
    v_return t_rows_tab;
  BEGIN
    v_return := p_rows_tab;

    FOR i IN 1 .. v_return.COUNT
    LOOP
      v_return(i)."DEPARTMENT_ID" := COALESCE(v_return(i)."DEPARTMENT_ID", "DEPARTMENTS_SEQ".NEXTVAL);
    END LOOP;

    FORALL i IN INDICES OF p_rows_tab
      INSERT INTO "DEPARTMENTS" (
      "DEPARTMENT_ID" /*PK*/,
      "DEPARTMENT_NAME",
      "MANAGER_ID" /*FK*/,
      "LOCATION_ID" /*FK*/ )
      VALUES (
      v_return(i)."DEPARTMENT_ID",
        v_return(i)."DEPARTMENT_NAME",
        v_return(i)."MANAGER_ID",
        v_return(i)."LOCATION_ID" );

    RETURN v_return;
  END create_rows;

  PROCEDURE create_rows(p_rows_tab IN t_rows_tab)
  IS
    v_return t_rows_tab;
  BEGIN
    v_return := create_rows(p_rows_tab => p_rows_tab);
  END create_rows;

  FUNCTION read_row (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE /*PK*/ )
  RETURN "DEPARTMENTS"%ROWTYPE IS
    v_row "DEPARTMENTS"%ROWTYPE;
    CURSOR cur_row IS
      SELECT *
        FROM "DEPARTMENTS"
       WHERE "DEPARTMENT_ID" = p_department_id;
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
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE DEFAULT NULL /*PK*/,
    p_department_name IN "DEPARTMENTS"."DEPARTMENT_NAME"%TYPE,
    p_manager_id      IN "DEPARTMENTS"."MANAGER_ID"%TYPE /*FK*/,
    p_location_id     IN "DEPARTMENTS"."LOCATION_ID"%TYPE /*FK*/ )
  IS
    v_row   "DEPARTMENTS"%ROWTYPE;

  BEGIN
    IF row_exists ( p_department_id => p_department_id ) THEN
      v_row := read_row ( p_department_id => p_department_id );
      -- update only, if the column values really differ
      IF v_row."DEPARTMENT_NAME" <> p_department_name
      OR COALESCE(v_row."MANAGER_ID", -999999999999999.999999999999999) <> COALESCE(p_manager_id, -999999999999999.999999999999999)
      OR COALESCE(v_row."LOCATION_ID", -999999999999999.999999999999999) <> COALESCE(p_location_id, -999999999999999.999999999999999)

      THEN
        UPDATE DEPARTMENTS
           SET "DEPARTMENT_NAME" = p_department_name,
               "MANAGER_ID"      = p_manager_id /*FK*/,
               "LOCATION_ID"     = p_location_id /*FK*/
         WHERE "DEPARTMENT_ID" = p_department_id;
      END IF;
    END IF;
  END update_row;

  PROCEDURE update_row (
    p_row             IN "DEPARTMENTS"%ROWTYPE )
  IS
  BEGIN
    update_row(
      p_department_id   => p_row."DEPARTMENT_ID" /*PK*/,
      p_department_name => p_row."DEPARTMENT_NAME",
      p_manager_id      => p_row."MANAGER_ID" /*FK*/,
      p_location_id     => p_row."LOCATION_ID" /*FK*/ );
  END update_row;

  PROCEDURE update_rows(p_rows_tab IN t_rows_tab)
  IS
  BEGIN
    FORALL i IN INDICES OF p_rows_tab
        UPDATE DEPARTMENTS
           SET "DEPARTMENT_NAME" = p_rows_tab(i)."DEPARTMENT_NAME",
               "MANAGER_ID"      = p_rows_tab(i)."MANAGER_ID" /*FK*/,
               "LOCATION_ID"     = p_rows_tab(i)."LOCATION_ID" /*FK*/
         WHERE "DEPARTMENT_ID" = p_rows_tab(i)."DEPARTMENT_ID";
  END update_rows;

  FUNCTION create_or_update_row (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE DEFAULT NULL /*PK*/,
    p_department_name IN "DEPARTMENTS"."DEPARTMENT_NAME"%TYPE,
    p_manager_id      IN "DEPARTMENTS"."MANAGER_ID"%TYPE /*FK*/,
    p_location_id     IN "DEPARTMENTS"."LOCATION_ID"%TYPE /*FK*/ )
  RETURN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE IS
    v_return "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;
  BEGIN
    IF row_exists( p_department_id => p_department_id ) THEN
      update_row(
        p_department_id   => p_department_id /*PK*/,
        p_department_name => p_department_name,
        p_manager_id      => p_manager_id /*FK*/,
        p_location_id     => p_location_id /*FK*/ );
      v_return := read_row ( p_department_id => p_department_id )."DEPARTMENT_ID";
    ELSE
      v_return := create_row (
        p_department_id   => p_department_id /*PK*/,
        p_department_name => p_department_name,
        p_manager_id      => p_manager_id /*FK*/,
        p_location_id     => p_location_id /*FK*/ );
    END IF;
    RETURN v_return;
  END create_or_update_row;

  PROCEDURE create_or_update_row (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE DEFAULT NULL /*PK*/,
    p_department_name IN "DEPARTMENTS"."DEPARTMENT_NAME"%TYPE,
    p_manager_id      IN "DEPARTMENTS"."MANAGER_ID"%TYPE /*FK*/,
    p_location_id     IN "DEPARTMENTS"."LOCATION_ID"%TYPE /*FK*/ )
  IS
    v_return "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_department_id   => p_department_id /*PK*/,
      p_department_name => p_department_name,
      p_manager_id      => p_manager_id /*FK*/,
      p_location_id     => p_location_id /*FK*/ );
  END create_or_update_row;

  FUNCTION create_or_update_row (
    p_row             IN "DEPARTMENTS"%ROWTYPE )
  RETURN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE IS
    v_return "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_department_id   => p_row."DEPARTMENT_ID" /*PK*/,
      p_department_name => p_row."DEPARTMENT_NAME",
      p_manager_id      => p_row."MANAGER_ID" /*FK*/,
      p_location_id     => p_row."LOCATION_ID" /*FK*/ );
    RETURN v_return;
  END create_or_update_row;

  PROCEDURE create_or_update_row (
    p_row             IN "DEPARTMENTS"%ROWTYPE )
  IS
    v_return "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_department_id   => p_row."DEPARTMENT_ID" /*PK*/,
      p_department_name => p_row."DEPARTMENT_NAME",
      p_manager_id      => p_row."MANAGER_ID" /*FK*/,
      p_location_id     => p_row."LOCATION_ID" /*FK*/ );
  END create_or_update_row;

  FUNCTION get_a_row
  RETURN "DEPARTMENTS"%ROWTYPE IS
    v_row "DEPARTMENTS"%ROWTYPE;
  BEGIN
    v_row."DEPARTMENT_ID"   := "DEPARTMENTS_SEQ".nextval /*PK*/;
    v_row."DEPARTMENT_NAME" := substr(sys_guid(),1,30);
    return v_row;
  END get_a_row;

  FUNCTION create_a_row (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE   DEFAULT get_a_row()."DEPARTMENT_ID" /*PK*/,
    p_department_name IN "DEPARTMENTS"."DEPARTMENT_NAME"%TYPE DEFAULT get_a_row()."DEPARTMENT_NAME",
    p_manager_id      IN "DEPARTMENTS"."MANAGER_ID"%TYPE      DEFAULT get_a_row()."MANAGER_ID" /*FK*/,
    p_location_id     IN "DEPARTMENTS"."LOCATION_ID"%TYPE     DEFAULT get_a_row()."LOCATION_ID" /*FK*/ )
  RETURN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE IS
    v_return "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_department_id   => p_department_id /*PK*/,
      p_department_name => p_department_name,
      p_manager_id      => p_manager_id /*FK*/,
      p_location_id     => p_location_id /*FK*/ );
    RETURN v_return;
  END create_a_row;

  PROCEDURE create_a_row (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE   DEFAULT get_a_row()."DEPARTMENT_ID" /*PK*/,
    p_department_name IN "DEPARTMENTS"."DEPARTMENT_NAME"%TYPE DEFAULT get_a_row()."DEPARTMENT_NAME",
    p_manager_id      IN "DEPARTMENTS"."MANAGER_ID"%TYPE      DEFAULT get_a_row()."MANAGER_ID" /*FK*/,
    p_location_id     IN "DEPARTMENTS"."LOCATION_ID"%TYPE     DEFAULT get_a_row()."LOCATION_ID" /*FK*/ )
  IS
    v_return "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_department_id   => p_department_id /*PK*/,
      p_department_name => p_department_name,
      p_manager_id      => p_manager_id /*FK*/,
      p_location_id     => p_location_id /*FK*/ );
  END create_a_row;

  FUNCTION read_a_row
  RETURN "DEPARTMENTS"%ROWTYPE IS
    v_row  "DEPARTMENTS"%ROWTYPE;
    CURSOR cur_row IS SELECT * FROM DEPARTMENTS;
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_row;
    CLOSE cur_row;
    RETURN v_row;
  END read_a_row;

END "DEPARTMENTS_API";
/

