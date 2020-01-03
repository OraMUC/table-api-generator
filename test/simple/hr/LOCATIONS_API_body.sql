
  CREATE OR REPLACE EDITIONABLE PACKAGE "HR"."LOCATIONS_API" IS
  /*
  This is the API for the table "LOCATIONS".

  GENERATION OPTIONS
  - Must be in the lines 5-35 to be reusable by the generator
  - DO NOT TOUCH THIS until you know what you do
  - Read the docs under github.com/OraMUC/table-api-generator ;-)
  <options
    generator="OM_TAPIGEN"
    generator_version="0.7.0"
    generator_action="COMPILE_API"
    generated_at="2020-01-03 21:39:43"
    generated_by="DATA-ABC\INFO"
    p_table_name="LOCATIONS"
    p_owner="HR"
    p_reuse_existing_api_params="FALSE"
    p_enable_insertion_of_rows="TRUE"
    p_enable_column_defaults="TRUE"
    p_enable_update_of_rows="TRUE"
    p_enable_deletion_of_rows="FALSE"
    p_enable_parameter_prefixes="TRUE"
    p_enable_proc_with_out_params="FALSE"
    p_enable_getter_and_setter="FALSE"
    p_col_prefix_in_method_names="TRUE"
    p_return_row_instead_of_pk="FALSE"
    p_enable_dml_view="TRUE"
    p_enable_generic_change_log="FALSE"
    p_api_name="LOCATIONS_API"
    p_sequence_name="LOCATIONS_SEQ"
    p_exclude_column_list=""
    p_enable_custom_defaults="TRUE"
    p_custom_default_values="SEE_END_OF_API_PACKAGE_SPEC"
    p_enable_bulk_methods="TRUE"/>

  This API provides DML functionality that can be easily called from APEX.
  Target of the table API is to encapsulate the table DML source code for
  security (UI schema needs only the execute right for the API and the
  read/write right for the LOCATIONS_DML_V, tables can be
  hidden in extra data schema) and easy readability of the business logic
  (all DML is then written in the same style). For APEX automatic row
  processing like tabular forms you can optionally use the
  LOCATIONS_DML_V. The instead of trigger for this view
  is calling simply this "LOCATIONS_API".
  */

  TYPE t_strong_ref_cursor IS REF CURSOR RETURN "LOCATIONS"%ROWTYPE;
  TYPE t_rows_tab IS TABLE OF "LOCATIONS"%ROWTYPE;

  FUNCTION bulk_is_complete
    RETURN BOOLEAN;

  PROCEDURE set_bulk_limit(p_bulk_limit IN PLS_INTEGER);

  FUNCTION get_bulk_limit
    RETURN PLS_INTEGER;

  FUNCTION row_exists (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE /*PK*/ )
  RETURN BOOLEAN;

  FUNCTION row_exists_yn (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE /*PK*/ )
  RETURN VARCHAR2;

  FUNCTION create_row (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE    DEFAULT NULL /*PK*/,
    p_street_address IN "LOCATIONS"."STREET_ADDRESS"%TYPE DEFAULT NULL,
    p_postal_code    IN "LOCATIONS"."POSTAL_CODE"%TYPE    DEFAULT NULL,
    p_city           IN "LOCATIONS"."CITY"%TYPE           ,
    p_state_province IN "LOCATIONS"."STATE_PROVINCE"%TYPE DEFAULT NULL,
    p_country_id     IN "LOCATIONS"."COUNTRY_ID"%TYPE     DEFAULT NULL /*FK*/ )
  RETURN "LOCATIONS"."LOCATION_ID"%TYPE;

  PROCEDURE create_row (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE    DEFAULT NULL /*PK*/,
    p_street_address IN "LOCATIONS"."STREET_ADDRESS"%TYPE DEFAULT NULL,
    p_postal_code    IN "LOCATIONS"."POSTAL_CODE"%TYPE    DEFAULT NULL,
    p_city           IN "LOCATIONS"."CITY"%TYPE           ,
    p_state_province IN "LOCATIONS"."STATE_PROVINCE"%TYPE DEFAULT NULL,
    p_country_id     IN "LOCATIONS"."COUNTRY_ID"%TYPE     DEFAULT NULL /*FK*/ );

  FUNCTION create_row (
    p_row            IN "LOCATIONS"%ROWTYPE )
  RETURN "LOCATIONS"."LOCATION_ID"%TYPE;

  PROCEDURE create_row (
    p_row            IN "LOCATIONS"%ROWTYPE );

  FUNCTION create_rows(p_rows_tab IN t_rows_tab)
    RETURN t_rows_tab;

  PROCEDURE create_rows(p_rows_tab IN t_rows_tab);

  FUNCTION read_row (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE /*PK*/ )
  RETURN "LOCATIONS"%ROWTYPE;

  FUNCTION read_rows(p_ref_cursor IN t_strong_ref_cursor)
    RETURN t_rows_tab;

  PROCEDURE update_row (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE DEFAULT NULL /*PK*/,
    p_street_address IN "LOCATIONS"."STREET_ADDRESS"%TYPE,
    p_postal_code    IN "LOCATIONS"."POSTAL_CODE"%TYPE,
    p_city           IN "LOCATIONS"."CITY"%TYPE,
    p_state_province IN "LOCATIONS"."STATE_PROVINCE"%TYPE,
    p_country_id     IN "LOCATIONS"."COUNTRY_ID"%TYPE /*FK*/ );

  PROCEDURE update_row (
    p_row            IN "LOCATIONS"%ROWTYPE );

  PROCEDURE update_rows(p_rows_tab IN t_rows_tab);

  FUNCTION create_or_update_row (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE DEFAULT NULL /*PK*/,
    p_street_address IN "LOCATIONS"."STREET_ADDRESS"%TYPE,
    p_postal_code    IN "LOCATIONS"."POSTAL_CODE"%TYPE,
    p_city           IN "LOCATIONS"."CITY"%TYPE,
    p_state_province IN "LOCATIONS"."STATE_PROVINCE"%TYPE,
    p_country_id     IN "LOCATIONS"."COUNTRY_ID"%TYPE /*FK*/ )
  RETURN "LOCATIONS"."LOCATION_ID"%TYPE;

  PROCEDURE create_or_update_row (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE DEFAULT NULL /*PK*/,
    p_street_address IN "LOCATIONS"."STREET_ADDRESS"%TYPE,
    p_postal_code    IN "LOCATIONS"."POSTAL_CODE"%TYPE,
    p_city           IN "LOCATIONS"."CITY"%TYPE,
    p_state_province IN "LOCATIONS"."STATE_PROVINCE"%TYPE,
    p_country_id     IN "LOCATIONS"."COUNTRY_ID"%TYPE /*FK*/ );

  FUNCTION create_or_update_row (
    p_row            IN "LOCATIONS"%ROWTYPE )
  RETURN "LOCATIONS"."LOCATION_ID"%TYPE;

  PROCEDURE create_or_update_row (
    p_row            IN "LOCATIONS"%ROWTYPE );

  FUNCTION get_a_row
  RETURN "LOCATIONS"%ROWTYPE;
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Returns a row with (hopefully) complete default data.
   */

  FUNCTION create_a_row (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE    DEFAULT get_a_row()."LOCATION_ID" /*PK*/,
    p_street_address IN "LOCATIONS"."STREET_ADDRESS"%TYPE DEFAULT get_a_row()."STREET_ADDRESS",
    p_postal_code    IN "LOCATIONS"."POSTAL_CODE"%TYPE    DEFAULT get_a_row()."POSTAL_CODE",
    p_city           IN "LOCATIONS"."CITY"%TYPE           DEFAULT get_a_row()."CITY",
    p_state_province IN "LOCATIONS"."STATE_PROVINCE"%TYPE DEFAULT get_a_row()."STATE_PROVINCE",
    p_country_id     IN "LOCATIONS"."COUNTRY_ID"%TYPE     DEFAULT get_a_row()."COUNTRY_ID" /*FK*/ )
  RETURN "LOCATIONS"."LOCATION_ID"%TYPE;
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Create a new row without (hopefully) providing any parameters.
   */

  PROCEDURE create_a_row (
    p_location_id    IN "LOCATIONS"."LOCATION_ID"%TYPE    DEFAULT get_a_row()."LOCATION_ID" /*PK*/,
    p_street_address IN "LOCATIONS"."STREET_ADDRESS"%TYPE DEFAULT get_a_row()."STREET_ADDRESS",
    p_postal_code    IN "LOCATIONS"."POSTAL_CODE"%TYPE    DEFAULT get_a_row()."POSTAL_CODE",
    p_city           IN "LOCATIONS"."CITY"%TYPE           DEFAULT get_a_row()."CITY",
    p_state_province IN "LOCATIONS"."STATE_PROVINCE"%TYPE DEFAULT get_a_row()."STATE_PROVINCE",
    p_country_id     IN "LOCATIONS"."COUNTRY_ID"%TYPE     DEFAULT get_a_row()."COUNTRY_ID" /*FK*/ );
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Create a new row without (hopefully) providing any parameters.
   */

  FUNCTION read_a_row
  RETURN "LOCATIONS"%ROWTYPE;
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Fetch one row (the first the database delivers) without providing
   * a primary key parameter.
   */

  /*
  Only custom defaults with the source "USER" are used when "p_reuse_existing_api_params" is set to true.
  All other custom defaults are only listed for convenience and determined at runtime by the generator.
  You can simply copy over the defaults to your generator call - the attribute "source" is ignored then.
  <custom_defaults>
    <column source="TAPIGEN" name="LOCATION_ID"><![CDATA["LOCATIONS_SEQ".nextval]]></column>
    <column source="TAPIGEN" name="STREET_ADDRESS"><![CDATA[substr(sys_guid(),1,40)]]></column>
    <column source="TAPIGEN" name="POSTAL_CODE"><![CDATA[substr(sys_guid(),1,12)]]></column>
    <column source="TAPIGEN" name="CITY"><![CDATA[substr(sys_guid(),1,30)]]></column>
    <column source="TAPIGEN" name="STATE_PROVINCE"><![CDATA[substr(sys_guid(),1,25)]]></column>
    <column source="TAPIGEN" name="COUNTRY_ID"><![CDATA['34']]></column>
  </custom_defaults>
  */
END "LOCATIONS_API";
/
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HR"."LOCATIONS_API" IS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.7.0"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-03 21:39:43"
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
    v_row."COUNTRY_ID"     := '34' /*FK*/;
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

