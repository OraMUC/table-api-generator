PACKAGE BODY      "DEPARTMENTS_API" IS

  FUNCTION row_exists (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE /*PK*/ )
  RETURN BOOLEAN
  IS
    v_return BOOLEAN := FALSE;
    v_dummy  PLS_INTEGER;
    CURSOR   cur_bool IS
      SELECT 1
        FROM "DEPARTMENTS"
       WHERE COALESCE( "DEPARTMENT_ID",-999999999999999.999999999999999 ) = COALESCE( p_department_id,-999999999999999.999999999999999 );
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
      "DEPARTMENT_ID",
      "DEPARTMENT_NAME",
      "MANAGER_ID",
      "LOCATION_ID" )
    VALUES (
      COALESCE( p_department_id,"DEPARTMENTS_SEQ".nextval ),
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
      p_department_id   => p_department_id,
      p_department_name => p_department_name,
      p_manager_id      => p_manager_id,
      p_location_id     => p_location_id );
  END create_row;

  FUNCTION create_row (
    p_row             IN "DEPARTMENTS"%ROWTYPE )
  RETURN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE IS
    v_return "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_department_id   => p_row."DEPARTMENT_ID",
      p_department_name => p_row."DEPARTMENT_NAME",
      p_manager_id      => p_row."MANAGER_ID",
      p_location_id     => p_row."LOCATION_ID" );
    RETURN v_return;
  END create_row;

  PROCEDURE create_row (
    p_row             IN "DEPARTMENTS"%ROWTYPE )
  IS
    v_return "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_department_id   => p_row."DEPARTMENT_ID",
      p_department_name => p_row."DEPARTMENT_NAME",
      p_manager_id      => p_row."MANAGER_ID",
      p_location_id     => p_row."LOCATION_ID" );
  END create_row;

  FUNCTION read_row (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE /*PK*/ )
  RETURN "DEPARTMENTS"%ROWTYPE IS
    v_row "DEPARTMENTS"%ROWTYPE;
    CURSOR cur_row IS
      SELECT *
        FROM "DEPARTMENTS"
       WHERE COALESCE( "DEPARTMENT_ID",-999999999999999.999999999999999 ) = COALESCE( p_department_id,-999999999999999.999999999999999 );
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_row;
    CLOSE cur_row;
    RETURN v_row;
  END read_row;

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
      -- update only,if the column values really differ
      IF COALESCE( v_row."DEPARTMENT_NAME",'@@@@@@@@@@@@@@@' ) <> COALESCE( p_department_name,'@@@@@@@@@@@@@@@' )
      OR COALESCE( v_row."MANAGER_ID",-999999999999999.999999999999999 ) <> COALESCE( p_manager_id,-999999999999999.999999999999999 )
      OR COALESCE( v_row."LOCATION_ID",-999999999999999.999999999999999 ) <> COALESCE( p_location_id,-999999999999999.999999999999999 )

      THEN
        UPDATE DEPARTMENTS
           SET "DEPARTMENT_NAME" = p_department_name,
               "MANAGER_ID"      = p_manager_id,
               "LOCATION_ID"     = p_location_id
         WHERE COALESCE( "DEPARTMENT_ID",-999999999999999.999999999999999 ) = COALESCE( p_department_id,-999999999999999.999999999999999 );
      END IF;
    END IF;
  END update_row;

  PROCEDURE update_row (
    p_row             IN "DEPARTMENTS"%ROWTYPE )
  IS
  BEGIN
    update_row(
      p_department_id   => p_row."DEPARTMENT_ID",
      p_department_name => p_row."DEPARTMENT_NAME",
      p_manager_id      => p_row."MANAGER_ID",
      p_location_id     => p_row."LOCATION_ID" );
  END update_row;

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
        p_department_id   => p_department_id,
        p_department_name => p_department_name,
        p_manager_id      => p_manager_id,
        p_location_id     => p_location_id );
      v_return := read_row ( p_department_id => p_department_id )."DEPARTMENT_ID";
    ELSE
      v_return := create_row (
        p_department_id   => p_department_id,
        p_department_name => p_department_name,
        p_manager_id      => p_manager_id,
        p_location_id     => p_location_id );
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
      p_department_id   => p_department_id,
      p_department_name => p_department_name,
      p_manager_id      => p_manager_id,
      p_location_id     => p_location_id );
  END create_or_update_row;

  FUNCTION create_or_update_row (
    p_row             IN "DEPARTMENTS"%ROWTYPE )
  RETURN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE IS
    v_return "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_department_id   => p_row."DEPARTMENT_ID",
      p_department_name => p_row."DEPARTMENT_NAME",
      p_manager_id      => p_row."MANAGER_ID",
      p_location_id     => p_row."LOCATION_ID" );
    RETURN v_return;
  END create_or_update_row;

  PROCEDURE create_or_update_row (
    p_row             IN "DEPARTMENTS"%ROWTYPE )
  IS
    v_return "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_department_id   => p_row."DEPARTMENT_ID",
      p_department_name => p_row."DEPARTMENT_NAME",
      p_manager_id      => p_row."MANAGER_ID",
      p_location_id     => p_row."LOCATION_ID" );
  END create_or_update_row;

  FUNCTION get_a_row
  RETURN "DEPARTMENTS"%ROWTYPE IS
    v_row "DEPARTMENTS"%ROWTYPE;
  BEGIN
    v_row."DEPARTMENT_NAME" := substr(sys_guid(),1,30);
    v_row."MANAGER_ID"      := 100;
    v_row."LOCATION_ID"     := 1500;
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
      p_department_id   => p_department_id,
      p_department_name => p_department_name,
      p_manager_id      => p_manager_id,
      p_location_id     => p_location_id );
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
      p_department_id   => p_department_id,
      p_department_name => p_department_name,
      p_manager_id      => p_manager_id,
      p_location_id     => p_location_id );
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
