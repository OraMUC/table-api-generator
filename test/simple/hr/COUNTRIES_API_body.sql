
  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HR"."COUNTRIES_API" IS
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
    p_country_id   IN "COUNTRIES"."COUNTRY_ID"%TYPE /*PK*/ )
  RETURN BOOLEAN
  IS
    v_return BOOLEAN := FALSE;
    v_dummy  PLS_INTEGER;
    CURSOR   cur_bool IS
      SELECT 1
        FROM "COUNTRIES"
       WHERE "COUNTRY_ID" = p_country_id;
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
    p_country_id   IN "COUNTRIES"."COUNTRY_ID"%TYPE /*PK*/ )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN CASE WHEN row_exists( p_country_id => p_country_id )
             THEN 'Y'
             ELSE 'N'
           END;
  END;

  FUNCTION create_row (
    p_country_id   IN "COUNTRIES"."COUNTRY_ID"%TYPE   DEFAULT NULL /*PK*/,
    p_country_name IN "COUNTRIES"."COUNTRY_NAME"%TYPE DEFAULT NULL,
    p_region_id    IN "COUNTRIES"."REGION_ID"%TYPE    DEFAULT NULL /*FK*/ )
  RETURN "COUNTRIES"."COUNTRY_ID"%TYPE IS
    v_return "COUNTRIES"."COUNTRY_ID"%TYPE;
  BEGIN
    INSERT INTO "COUNTRIES" (
      "COUNTRY_ID" /*PK*/,
      "COUNTRY_NAME",
      "REGION_ID" /*FK*/ )
    VALUES (
      p_country_id,
      p_country_name,
      p_region_id )
    RETURN
      "COUNTRY_ID"
    INTO v_return;
    RETURN v_return;
  END create_row;

  PROCEDURE create_row (
    p_country_id   IN "COUNTRIES"."COUNTRY_ID"%TYPE   DEFAULT NULL /*PK*/,
    p_country_name IN "COUNTRIES"."COUNTRY_NAME"%TYPE DEFAULT NULL,
    p_region_id    IN "COUNTRIES"."REGION_ID"%TYPE    DEFAULT NULL /*FK*/ )
  IS
    v_return "COUNTRIES"."COUNTRY_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_country_id   => p_country_id /*PK*/,
      p_country_name => p_country_name,
      p_region_id    => p_region_id /*FK*/ );
  END create_row;

  FUNCTION create_row (
    p_row          IN "COUNTRIES"%ROWTYPE )
  RETURN "COUNTRIES"."COUNTRY_ID"%TYPE IS
    v_return "COUNTRIES"."COUNTRY_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_country_id   => p_row."COUNTRY_ID" /*PK*/,
      p_country_name => p_row."COUNTRY_NAME",
      p_region_id    => p_row."REGION_ID" /*FK*/ );
    RETURN v_return;
  END create_row;

  PROCEDURE create_row (
    p_row          IN "COUNTRIES"%ROWTYPE )
  IS
    v_return "COUNTRIES"."COUNTRY_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_country_id   => p_row."COUNTRY_ID" /*PK*/,
      p_country_name => p_row."COUNTRY_NAME",
      p_region_id    => p_row."REGION_ID" /*FK*/ );
  END create_row;

  FUNCTION create_rows(p_rows_tab IN t_rows_tab)
    RETURN t_rows_tab IS
    v_return t_rows_tab;
  BEGIN
    v_return := p_rows_tab;

    FORALL i IN INDICES OF p_rows_tab
      INSERT INTO "COUNTRIES" (
      "COUNTRY_ID" /*PK*/,
      "COUNTRY_NAME",
      "REGION_ID" /*FK*/ )
      VALUES (
      v_return(i)."COUNTRY_ID",
        v_return(i)."COUNTRY_NAME",
        v_return(i)."REGION_ID" );

    RETURN v_return;
  END create_rows;

  PROCEDURE create_rows(p_rows_tab IN t_rows_tab)
  IS
    v_return t_rows_tab;
  BEGIN
    v_return := create_rows(p_rows_tab => p_rows_tab);
  END create_rows;

  FUNCTION read_row (
    p_country_id   IN "COUNTRIES"."COUNTRY_ID"%TYPE /*PK*/ )
  RETURN "COUNTRIES"%ROWTYPE IS
    v_row "COUNTRIES"%ROWTYPE;
    CURSOR cur_row IS
      SELECT *
        FROM "COUNTRIES"
       WHERE "COUNTRY_ID" = p_country_id;
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
    p_country_id   IN "COUNTRIES"."COUNTRY_ID"%TYPE DEFAULT NULL /*PK*/,
    p_country_name IN "COUNTRIES"."COUNTRY_NAME"%TYPE,
    p_region_id    IN "COUNTRIES"."REGION_ID"%TYPE /*FK*/ )
  IS
    v_row   "COUNTRIES"%ROWTYPE;

  BEGIN
    IF row_exists ( p_country_id => p_country_id ) THEN
      v_row := read_row ( p_country_id => p_country_id );
      -- update only, if the column values really differ
      IF COALESCE(v_row."COUNTRY_NAME", '@@@@@@@@@@@@@@@') <> COALESCE(p_country_name, '@@@@@@@@@@@@@@@')
      OR COALESCE(v_row."REGION_ID", -999999999999999.999999999999999) <> COALESCE(p_region_id, -999999999999999.999999999999999)

      THEN
        UPDATE COUNTRIES
           SET "COUNTRY_NAME" = p_country_name,
               "REGION_ID"    = p_region_id /*FK*/
         WHERE "COUNTRY_ID" = p_country_id;
      END IF;
    END IF;
  END update_row;

  PROCEDURE update_row (
    p_row          IN "COUNTRIES"%ROWTYPE )
  IS
  BEGIN
    update_row(
      p_country_id   => p_row."COUNTRY_ID" /*PK*/,
      p_country_name => p_row."COUNTRY_NAME",
      p_region_id    => p_row."REGION_ID" /*FK*/ );
  END update_row;

  PROCEDURE update_rows(p_rows_tab IN t_rows_tab)
  IS
  BEGIN
    FORALL i IN INDICES OF p_rows_tab
        UPDATE COUNTRIES
           SET "COUNTRY_NAME" = p_rows_tab(i)."COUNTRY_NAME",
               "REGION_ID"    = p_rows_tab(i)."REGION_ID" /*FK*/
         WHERE "COUNTRY_ID" = p_rows_tab(i)."COUNTRY_ID";
  END update_rows;

  FUNCTION create_or_update_row (
    p_country_id   IN "COUNTRIES"."COUNTRY_ID"%TYPE DEFAULT NULL /*PK*/,
    p_country_name IN "COUNTRIES"."COUNTRY_NAME"%TYPE,
    p_region_id    IN "COUNTRIES"."REGION_ID"%TYPE /*FK*/ )
  RETURN "COUNTRIES"."COUNTRY_ID"%TYPE IS
    v_return "COUNTRIES"."COUNTRY_ID"%TYPE;
  BEGIN
    IF row_exists( p_country_id => p_country_id ) THEN
      update_row(
        p_country_id   => p_country_id /*PK*/,
        p_country_name => p_country_name,
        p_region_id    => p_region_id /*FK*/ );
      v_return := read_row ( p_country_id => p_country_id )."COUNTRY_ID";
    ELSE
      v_return := create_row (
        p_country_id   => p_country_id /*PK*/,
        p_country_name => p_country_name,
        p_region_id    => p_region_id /*FK*/ );
    END IF;
    RETURN v_return;
  END create_or_update_row;

  PROCEDURE create_or_update_row (
    p_country_id   IN "COUNTRIES"."COUNTRY_ID"%TYPE DEFAULT NULL /*PK*/,
    p_country_name IN "COUNTRIES"."COUNTRY_NAME"%TYPE,
    p_region_id    IN "COUNTRIES"."REGION_ID"%TYPE /*FK*/ )
  IS
    v_return "COUNTRIES"."COUNTRY_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_country_id   => p_country_id /*PK*/,
      p_country_name => p_country_name,
      p_region_id    => p_region_id /*FK*/ );
  END create_or_update_row;

  FUNCTION create_or_update_row (
    p_row          IN "COUNTRIES"%ROWTYPE )
  RETURN "COUNTRIES"."COUNTRY_ID"%TYPE IS
    v_return "COUNTRIES"."COUNTRY_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_country_id   => p_row."COUNTRY_ID" /*PK*/,
      p_country_name => p_row."COUNTRY_NAME",
      p_region_id    => p_row."REGION_ID" /*FK*/ );
    RETURN v_return;
  END create_or_update_row;

  PROCEDURE create_or_update_row (
    p_row          IN "COUNTRIES"%ROWTYPE )
  IS
    v_return "COUNTRIES"."COUNTRY_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_country_id   => p_row."COUNTRY_ID" /*PK*/,
      p_country_name => p_row."COUNTRY_NAME",
      p_region_id    => p_row."REGION_ID" /*FK*/ );
  END create_or_update_row;

  FUNCTION get_a_row
  RETURN "COUNTRIES"%ROWTYPE IS
    v_row "COUNTRIES"%ROWTYPE;
  BEGIN
    v_row."COUNTRY_ID"   := substr(sys_guid(),1,2) /*PK*/;
    v_row."COUNTRY_NAME" := substr(sys_guid(),1,40);
    return v_row;
  END get_a_row;

  FUNCTION create_a_row (
    p_country_id   IN "COUNTRIES"."COUNTRY_ID"%TYPE   DEFAULT get_a_row()."COUNTRY_ID" /*PK*/,
    p_country_name IN "COUNTRIES"."COUNTRY_NAME"%TYPE DEFAULT get_a_row()."COUNTRY_NAME",
    p_region_id    IN "COUNTRIES"."REGION_ID"%TYPE    DEFAULT get_a_row()."REGION_ID" /*FK*/ )
  RETURN "COUNTRIES"."COUNTRY_ID"%TYPE IS
    v_return "COUNTRIES"."COUNTRY_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_country_id   => p_country_id /*PK*/,
      p_country_name => p_country_name,
      p_region_id    => p_region_id /*FK*/ );
    RETURN v_return;
  END create_a_row;

  PROCEDURE create_a_row (
    p_country_id   IN "COUNTRIES"."COUNTRY_ID"%TYPE   DEFAULT get_a_row()."COUNTRY_ID" /*PK*/,
    p_country_name IN "COUNTRIES"."COUNTRY_NAME"%TYPE DEFAULT get_a_row()."COUNTRY_NAME",
    p_region_id    IN "COUNTRIES"."REGION_ID"%TYPE    DEFAULT get_a_row()."REGION_ID" /*FK*/ )
  IS
    v_return "COUNTRIES"."COUNTRY_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_country_id   => p_country_id /*PK*/,
      p_country_name => p_country_name,
      p_region_id    => p_region_id /*FK*/ );
  END create_a_row;

  FUNCTION read_a_row
  RETURN "COUNTRIES"%ROWTYPE IS
    v_row  "COUNTRIES"%ROWTYPE;
    CURSOR cur_row IS SELECT * FROM COUNTRIES;
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_row;
    CLOSE cur_row;
    RETURN v_row;
  END read_a_row;

END "COUNTRIES_API";
/

