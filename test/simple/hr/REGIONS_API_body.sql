CREATE OR REPLACE PACKAGE BODY "TEST"."REGIONS_API" IS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0"
   * generator_action="COMPILE_API"
   * generated_at="2018-12-20 19:43:13"
   * generated_by="OGOBRECHT"
   */

  FUNCTION row_exists (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE /*PK*/ )
  RETURN BOOLEAN
  IS
    v_return BOOLEAN := FALSE;
    v_dummy  PLS_INTEGER;
    CURSOR   cur_bool IS
      SELECT 1
        FROM "REGIONS"
       WHERE "REGION_ID" = p_region_id;
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
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE /*PK*/ )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN CASE WHEN row_exists( p_region_id => p_region_id )
             THEN 'Y'
             ELSE 'N'
           END;
  END;

  FUNCTION create_row (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE   DEFAULT NULL /*PK*/,
    p_region_name IN "REGIONS"."REGION_NAME"%TYPE DEFAULT NULL )
  RETURN "REGIONS"."REGION_ID"%TYPE IS
    v_return "REGIONS"."REGION_ID"%TYPE;
  BEGIN
    INSERT INTO "REGIONS" (
      "REGION_ID" /*PK*/,
      "REGION_NAME" )
    VALUES (
      p_region_id,
      p_region_name )
    RETURN
      "REGION_ID"
    INTO v_return;
    RETURN v_return;
  END create_row;

  PROCEDURE create_row (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE   DEFAULT NULL /*PK*/,
    p_region_name IN "REGIONS"."REGION_NAME"%TYPE DEFAULT NULL )
  IS
    v_return "REGIONS"."REGION_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_region_id   => p_region_id /*PK*/,
      p_region_name => p_region_name );
  END create_row;

  FUNCTION create_row (
    p_row         IN "REGIONS"%ROWTYPE )
  RETURN "REGIONS"."REGION_ID"%TYPE IS
    v_return "REGIONS"."REGION_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_region_id   => p_row."REGION_ID" /*PK*/,
      p_region_name => p_row."REGION_NAME" );
    RETURN v_return;
  END create_row;

  PROCEDURE create_row (
    p_row         IN "REGIONS"%ROWTYPE )
  IS
    v_return "REGIONS"."REGION_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_region_id   => p_row."REGION_ID" /*PK*/,
      p_region_name => p_row."REGION_NAME" );
  END create_row;

  FUNCTION read_row (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE /*PK*/ )
  RETURN "REGIONS"%ROWTYPE IS
    v_row "REGIONS"%ROWTYPE;
    CURSOR cur_row IS
      SELECT *
        FROM "REGIONS"
       WHERE "REGION_ID" = p_region_id;
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_row;
    CLOSE cur_row;
    RETURN v_row;
  END read_row;

  PROCEDURE update_row (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE DEFAULT NULL /*PK*/,
    p_region_name IN "REGIONS"."REGION_NAME"%TYPE )
  IS
    v_row   "REGIONS"%ROWTYPE;

  BEGIN
    IF row_exists ( p_region_id => p_region_id ) THEN
      v_row := read_row ( p_region_id => p_region_id );
      -- update only, if the column values really differ
      IF COALESCE(v_row."REGION_NAME", '@@@@@@@@@@@@@@@') <> COALESCE(p_region_name, '@@@@@@@@@@@@@@@')

      THEN
        UPDATE REGIONS
           SET "REGION_NAME" = p_region_name
         WHERE "REGION_ID" = p_region_id;
      END IF;
    END IF;
  END update_row;

  PROCEDURE update_row (
    p_row         IN "REGIONS"%ROWTYPE )
  IS
  BEGIN
    update_row(
      p_region_id   => p_row."REGION_ID" /*PK*/,
      p_region_name => p_row."REGION_NAME" );
  END update_row;

  FUNCTION create_or_update_row (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE DEFAULT NULL /*PK*/,
    p_region_name IN "REGIONS"."REGION_NAME"%TYPE )
  RETURN "REGIONS"."REGION_ID"%TYPE IS
    v_return "REGIONS"."REGION_ID"%TYPE;
  BEGIN
    IF row_exists( p_region_id => p_region_id ) THEN
      update_row(
        p_region_id   => p_region_id /*PK*/,
        p_region_name => p_region_name );
      v_return := read_row ( p_region_id => p_region_id )."REGION_ID";
    ELSE
      v_return := create_row (
        p_region_id   => p_region_id /*PK*/,
        p_region_name => p_region_name );
    END IF;
    RETURN v_return;
  END create_or_update_row;

  PROCEDURE create_or_update_row (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE DEFAULT NULL /*PK*/,
    p_region_name IN "REGIONS"."REGION_NAME"%TYPE )
  IS
    v_return "REGIONS"."REGION_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_region_id   => p_region_id /*PK*/,
      p_region_name => p_region_name );
  END create_or_update_row;

  FUNCTION create_or_update_row (
    p_row         IN "REGIONS"%ROWTYPE )
  RETURN "REGIONS"."REGION_ID"%TYPE IS
    v_return "REGIONS"."REGION_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_region_id   => p_row."REGION_ID" /*PK*/,
      p_region_name => p_row."REGION_NAME" );
    RETURN v_return;
  END create_or_update_row;

  PROCEDURE create_or_update_row (
    p_row         IN "REGIONS"%ROWTYPE )
  IS
    v_return "REGIONS"."REGION_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_region_id   => p_row."REGION_ID" /*PK*/,
      p_region_name => p_row."REGION_NAME" );
  END create_or_update_row;

  FUNCTION get_a_row
  RETURN "REGIONS"%ROWTYPE IS
    v_row "REGIONS"%ROWTYPE;
  BEGIN
    v_row."REGION_ID"   := round(dbms_random.value(0,999999999),0) /*PK*/;
    v_row."REGION_NAME" := substr(sys_guid(),1,25);
    return v_row;
  END get_a_row;

  FUNCTION create_a_row (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE   DEFAULT get_a_row()."REGION_ID" /*PK*/,
    p_region_name IN "REGIONS"."REGION_NAME"%TYPE DEFAULT get_a_row()."REGION_NAME" )
  RETURN "REGIONS"."REGION_ID"%TYPE IS
    v_return "REGIONS"."REGION_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_region_id   => p_region_id /*PK*/,
      p_region_name => p_region_name );
    RETURN v_return;
  END create_a_row;

  PROCEDURE create_a_row (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE   DEFAULT get_a_row()."REGION_ID" /*PK*/,
    p_region_name IN "REGIONS"."REGION_NAME"%TYPE DEFAULT get_a_row()."REGION_NAME" )
  IS
    v_return "REGIONS"."REGION_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_region_id   => p_region_id /*PK*/,
      p_region_name => p_region_name );
  END create_a_row;

  FUNCTION read_a_row
  RETURN "REGIONS"%ROWTYPE IS
    v_row  "REGIONS"%ROWTYPE;
    CURSOR cur_row IS SELECT * FROM REGIONS;
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_row;
    CLOSE cur_row;
    RETURN v_row;
  END read_a_row;

END "REGIONS_API";
/

