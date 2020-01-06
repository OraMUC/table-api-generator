
  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HR"."LOCATIONS_API" IS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.7.0"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-03 22:14:27"
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
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE /*PK*/ )
  RETURN BOOLEAN
  IS
    v_return BOOLEAN := FALSE;
    v_dummy  PLS_INTEGER;
    CURSOR   cur_bool IS
      SELECT 1
        FROM "LOCATIONS"
       WHERE "LOCATION_ID" = p_location_id;
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
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE /*PK*/ )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN CASE WHEN row_exists( p_location_id => p_location_id )
             THEN 'Y'
             ELSE 'N'
           END;
  END;

  FUNCTION create_row (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE    DEFAULT NULL /*PK*/,
    p_street_address IN "LOCATIONS"."STREET_ADDRESS"%TYPE DEFAULT NULL,
    p_postal_code    IN "LOCATIONS"."POSTAL_CODE"%TYPE    DEFAULT NULL,
    p_city           IN "LOCATIONS"."CITY"%TYPE           ,
    p_state_province IN "LOCATIONS"."STATE_PROVINCE"%TYPE DEFAULT NULL,
    p_country_id     IN "LOCATIONS"."COUNTRY_ID"%TYPE     DEFAULT NULL /*FK*/ )
  RETURN "LOCATIONS"."LOCATION_ID"%TYPE IS
    v_return "LOCATIONS"."LOCATION_ID"%TYPE;
  BEGIN
    INSERT INTO "LOCATIONS" (
      "LOCATION_ID" /*PK*/,
      "STREET_ADDRESS",
      "POSTAL_CODE",
      "CITY",
      "STATE_PROVINCE",
      "COUNTRY_ID" /*FK*/ )
    VALUES (
      COALESCE( p_location_id, "LOCATIONS_SEQ".nextval ),
      p_street_address,
      p_postal_code,
      p_city,
      p_state_province,
      p_country_id )
    RETURN
      "LOCATION_ID"
    INTO v_return;
    RETURN v_return;
  END create_row;

  PROCEDURE create_row (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE    DEFAULT NULL /*PK*/,
    p_street_address IN "LOCATIONS"."STREET_ADDRESS"%TYPE DEFAULT NULL,
    p_postal_code    IN "LOCATIONS"."POSTAL_CODE"%TYPE    DEFAULT NULL,
    p_city           IN "LOCATIONS"."CITY"%TYPE           ,
    p_state_province IN "LOCATIONS"."STATE_PROVINCE"%TYPE DEFAULT NULL,
    p_country_id     IN "LOCATIONS"."COUNTRY_ID"%TYPE     DEFAULT NULL /*FK*/ )
  IS
    v_return "LOCATIONS"."LOCATION_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_location_id    => p_location_id /*PK*/,
      p_street_address => p_street_address,
      p_postal_code    => p_postal_code,
      p_city           => p_city,
      p_state_province => p_state_province,
      p_country_id     => p_country_id /*FK*/ );
  END create_row;

  FUNCTION create_row (
    p_row            IN "LOCATIONS"%ROWTYPE )
  RETURN "LOCATIONS"."LOCATION_ID"%TYPE IS
    v_return "LOCATIONS"."LOCATION_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_location_id    => p_row."LOCATION_ID" /*PK*/,
      p_street_address => p_row."STREET_ADDRESS",
      p_postal_code    => p_row."POSTAL_CODE",
      p_city           => p_row."CITY",
      p_state_province => p_row."STATE_PROVINCE",
      p_country_id     => p_row."COUNTRY_ID" /*FK*/ );
    RETURN v_return;
  END create_row;

  PROCEDURE create_row (
    p_row            IN "LOCATIONS"%ROWTYPE )
  IS
    v_return "LOCATIONS"."LOCATION_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_location_id    => p_row."LOCATION_ID" /*PK*/,
      p_street_address => p_row."STREET_ADDRESS",
      p_postal_code    => p_row."POSTAL_CODE",
      p_city           => p_row."CITY",
      p_state_province => p_row."STATE_PROVINCE",
      p_country_id     => p_row."COUNTRY_ID" /*FK*/ );
  END create_row;

  FUNCTION create_rows(p_rows_tab IN t_rows_tab)
    RETURN t_rows_tab IS
    v_return t_rows_tab;
  BEGIN
    v_return := p_rows_tab;

    FOR i IN 1 .. v_return.COUNT
    LOOP
      v_return(i)."LOCATION_ID" := COALESCE(v_return(i)."LOCATION_ID", "LOCATIONS_SEQ".NEXTVAL);
    END LOOP;

    FORALL i IN INDICES OF p_rows_tab
      INSERT INTO "LOCATIONS" (
      "LOCATION_ID" /*PK*/,
      "STREET_ADDRESS",
      "POSTAL_CODE",
      "CITY",
      "STATE_PROVINCE",
      "COUNTRY_ID" /*FK*/ )
      VALUES (
      v_return(i)."LOCATION_ID",
        v_return(i)."STREET_ADDRESS",
        v_return(i)."POSTAL_CODE",
        v_return(i)."CITY",
        v_return(i)."STATE_PROVINCE",
        v_return(i)."COUNTRY_ID" );

    RETURN v_return;
  END create_rows;

  PROCEDURE create_rows(p_rows_tab IN t_rows_tab)
  IS
    v_return t_rows_tab;
  BEGIN
    v_return := create_rows(p_rows_tab => p_rows_tab);
  END create_rows;

  FUNCTION read_row (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE /*PK*/ )
  RETURN "LOCATIONS"%ROWTYPE IS
    v_row "LOCATIONS"%ROWTYPE;
    CURSOR cur_row IS
      SELECT *
        FROM "LOCATIONS"
       WHERE "LOCATION_ID" = p_location_id;
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
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE DEFAULT NULL /*PK*/,
    p_street_address IN "LOCATIONS"."STREET_ADDRESS"%TYPE,
    p_postal_code    IN "LOCATIONS"."POSTAL_CODE"%TYPE,
    p_city           IN "LOCATIONS"."CITY"%TYPE,
    p_state_province IN "LOCATIONS"."STATE_PROVINCE"%TYPE,
    p_country_id     IN "LOCATIONS"."COUNTRY_ID"%TYPE /*FK*/ )
  IS
    v_row   "LOCATIONS"%ROWTYPE;

  BEGIN
    IF row_exists ( p_location_id => p_location_id ) THEN
      v_row := read_row ( p_location_id => p_location_id );
      -- update only, if the column values really differ
      IF COALESCE(v_row."STREET_ADDRESS", '@@@@@@@@@@@@@@@') <> COALESCE(p_street_address, '@@@@@@@@@@@@@@@')
      OR COALESCE(v_row."POSTAL_CODE", '@@@@@@@@@@@@@@@') <> COALESCE(p_postal_code, '@@@@@@@@@@@@@@@')
      OR v_row."CITY" <> p_city
      OR COALESCE(v_row."STATE_PROVINCE", '@@@@@@@@@@@@@@@') <> COALESCE(p_state_province, '@@@@@@@@@@@@@@@')
      OR COALESCE(v_row."COUNTRY_ID", '@@@@@@@@@@@@@@@') <> COALESCE(p_country_id, '@@@@@@@@@@@@@@@')

      THEN
        UPDATE LOCATIONS
           SET "STREET_ADDRESS" = p_street_address,
               "POSTAL_CODE"    = p_postal_code,
               "CITY"           = p_city,
               "STATE_PROVINCE" = p_state_province,
               "COUNTRY_ID"     = p_country_id /*FK*/
         WHERE "LOCATION_ID" = p_location_id;
      END IF;
    END IF;
  END update_row;

  PROCEDURE update_row (
    p_row            IN "LOCATIONS"%ROWTYPE )
  IS
  BEGIN
    update_row(
      p_location_id    => p_row."LOCATION_ID" /*PK*/,
      p_street_address => p_row."STREET_ADDRESS",
      p_postal_code    => p_row."POSTAL_CODE",
      p_city           => p_row."CITY",
      p_state_province => p_row."STATE_PROVINCE",
      p_country_id     => p_row."COUNTRY_ID" /*FK*/ );
  END update_row;

  PROCEDURE update_rows(p_rows_tab IN t_rows_tab)
  IS
  BEGIN
    FORALL i IN INDICES OF p_rows_tab
        UPDATE LOCATIONS
           SET "STREET_ADDRESS" = p_rows_tab(i)."STREET_ADDRESS",
               "POSTAL_CODE"    = p_rows_tab(i)."POSTAL_CODE",
               "CITY"           = p_rows_tab(i)."CITY",
               "STATE_PROVINCE" = p_rows_tab(i)."STATE_PROVINCE",
               "COUNTRY_ID"     = p_rows_tab(i)."COUNTRY_ID" /*FK*/
         WHERE "LOCATION_ID" = p_rows_tab(i)."LOCATION_ID";
  END update_rows;

  FUNCTION create_or_update_row (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE DEFAULT NULL /*PK*/,
    p_street_address IN "LOCATIONS"."STREET_ADDRESS"%TYPE,
    p_postal_code    IN "LOCATIONS"."POSTAL_CODE"%TYPE,
    p_city           IN "LOCATIONS"."CITY"%TYPE,
    p_state_province IN "LOCATIONS"."STATE_PROVINCE"%TYPE,
    p_country_id     IN "LOCATIONS"."COUNTRY_ID"%TYPE /*FK*/ )
  RETURN "LOCATIONS"."LOCATION_ID"%TYPE IS
    v_return "LOCATIONS"."LOCATION_ID"%TYPE;
  BEGIN
    IF row_exists( p_location_id => p_location_id ) THEN
      update_row(
        p_location_id    => p_location_id /*PK*/,
        p_street_address => p_street_address,
        p_postal_code    => p_postal_code,
        p_city           => p_city,
        p_state_province => p_state_province,
        p_country_id     => p_country_id /*FK*/ );
      v_return := read_row ( p_location_id => p_location_id )."LOCATION_ID";
    ELSE
      v_return := create_row (
        p_location_id    => p_location_id /*PK*/,
        p_street_address => p_street_address,
        p_postal_code    => p_postal_code,
        p_city           => p_city,
        p_state_province => p_state_province,
        p_country_id     => p_country_id /*FK*/ );
    END IF;
    RETURN v_return;
  END create_or_update_row;

  PROCEDURE create_or_update_row (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE DEFAULT NULL /*PK*/,
    p_street_address IN "LOCATIONS"."STREET_ADDRESS"%TYPE,
    p_postal_code    IN "LOCATIONS"."POSTAL_CODE"%TYPE,
    p_city           IN "LOCATIONS"."CITY"%TYPE,
    p_state_province IN "LOCATIONS"."STATE_PROVINCE"%TYPE,
    p_country_id     IN "LOCATIONS"."COUNTRY_ID"%TYPE /*FK*/ )
  IS
    v_return "LOCATIONS"."LOCATION_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_location_id    => p_location_id /*PK*/,
      p_street_address => p_street_address,
      p_postal_code    => p_postal_code,
      p_city           => p_city,
      p_state_province => p_state_province,
      p_country_id     => p_country_id /*FK*/ );
  END create_or_update_row;

  FUNCTION create_or_update_row (
    p_row            IN "LOCATIONS"%ROWTYPE )
  RETURN "LOCATIONS"."LOCATION_ID"%TYPE IS
    v_return "LOCATIONS"."LOCATION_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_location_id    => p_row."LOCATION_ID" /*PK*/,
      p_street_address => p_row."STREET_ADDRESS",
      p_postal_code    => p_row."POSTAL_CODE",
      p_city           => p_row."CITY",
      p_state_province => p_row."STATE_PROVINCE",
      p_country_id     => p_row."COUNTRY_ID" /*FK*/ );
    RETURN v_return;
  END create_or_update_row;

  PROCEDURE create_or_update_row (
    p_row            IN "LOCATIONS"%ROWTYPE )
  IS
    v_return "LOCATIONS"."LOCATION_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_location_id    => p_row."LOCATION_ID" /*PK*/,
      p_street_address => p_row."STREET_ADDRESS",
      p_postal_code    => p_row."POSTAL_CODE",
      p_city           => p_row."CITY",
      p_state_province => p_row."STATE_PROVINCE",
      p_country_id     => p_row."COUNTRY_ID" /*FK*/ );
  END create_or_update_row;

  FUNCTION get_a_row
  RETURN "LOCATIONS"%ROWTYPE IS
    v_row "LOCATIONS"%ROWTYPE;
  BEGIN
    v_row."LOCATION_ID"    := "LOCATIONS_SEQ".nextval /*PK*/;
    v_row."STREET_ADDRESS" := substr(sys_guid(),1,40);
    v_row."POSTAL_CODE"    := substr(sys_guid(),1,12);
    v_row."CITY"           := substr(sys_guid(),1,30);
    v_row."STATE_PROVINCE" := substr(sys_guid(),1,25);
    v_row."COUNTRY_ID"     := '09' /*FK*/;
    return v_row;
  END get_a_row;

  FUNCTION create_a_row (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE    DEFAULT get_a_row()."LOCATION_ID" /*PK*/,
    p_street_address IN "LOCATIONS"."STREET_ADDRESS"%TYPE DEFAULT get_a_row()."STREET_ADDRESS",
    p_postal_code    IN "LOCATIONS"."POSTAL_CODE"%TYPE    DEFAULT get_a_row()."POSTAL_CODE",
    p_city           IN "LOCATIONS"."CITY"%TYPE           DEFAULT get_a_row()."CITY",
    p_state_province IN "LOCATIONS"."STATE_PROVINCE"%TYPE DEFAULT get_a_row()."STATE_PROVINCE",
    p_country_id     IN "LOCATIONS"."COUNTRY_ID"%TYPE     DEFAULT get_a_row()."COUNTRY_ID" /*FK*/ )
  RETURN "LOCATIONS"."LOCATION_ID"%TYPE IS
    v_return "LOCATIONS"."LOCATION_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_location_id    => p_location_id /*PK*/,
      p_street_address => p_street_address,
      p_postal_code    => p_postal_code,
      p_city           => p_city,
      p_state_province => p_state_province,
      p_country_id     => p_country_id /*FK*/ );
    RETURN v_return;
  END create_a_row;

  PROCEDURE create_a_row (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE    DEFAULT get_a_row()."LOCATION_ID" /*PK*/,
    p_street_address IN "LOCATIONS"."STREET_ADDRESS"%TYPE DEFAULT get_a_row()."STREET_ADDRESS",
    p_postal_code    IN "LOCATIONS"."POSTAL_CODE"%TYPE    DEFAULT get_a_row()."POSTAL_CODE",
    p_city           IN "LOCATIONS"."CITY"%TYPE           DEFAULT get_a_row()."CITY",
    p_state_province IN "LOCATIONS"."STATE_PROVINCE"%TYPE DEFAULT get_a_row()."STATE_PROVINCE",
    p_country_id     IN "LOCATIONS"."COUNTRY_ID"%TYPE     DEFAULT get_a_row()."COUNTRY_ID" /*FK*/ )
  IS
    v_return "LOCATIONS"."LOCATION_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_location_id    => p_location_id /*PK*/,
      p_street_address => p_street_address,
      p_postal_code    => p_postal_code,
      p_city           => p_city,
      p_state_province => p_state_province,
      p_country_id     => p_country_id /*FK*/ );
  END create_a_row;

  FUNCTION read_a_row
  RETURN "LOCATIONS"%ROWTYPE IS
    v_row  "LOCATIONS"%ROWTYPE;
    CURSOR cur_row IS SELECT * FROM LOCATIONS;
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_row;
    CLOSE cur_row;
    RETURN v_row;
  END read_a_row;

END "LOCATIONS_API";
/

