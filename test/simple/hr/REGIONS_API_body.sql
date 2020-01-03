
  CREATE OR REPLACE EDITIONABLE PACKAGE "HR"."REGIONS_API" IS
  /*
  This is the API for the table "REGIONS".

  GENERATION OPTIONS
  - Must be in the lines 5-35 to be reusable by the generator
  - DO NOT TOUCH THIS until you know what you do
  - Read the docs under github.com/OraMUC/table-api-generator ;-)
  <options
    generator="OM_TAPIGEN"
    generator_version="0.7.0"
    generator_action="COMPILE_API"
    generated_at="2020-01-03 21:39:44"
    generated_by="DATA-ABC\INFO"
    p_table_name="REGIONS"
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
    p_api_name="REGIONS_API"
    p_sequence_name=""
    p_exclude_column_list=""
    p_enable_custom_defaults="TRUE"
    p_custom_default_values="SEE_END_OF_API_PACKAGE_SPEC"
    p_enable_bulk_methods="TRUE"/>

  This API provides DML functionality that can be easily called from APEX.
  Target of the table API is to encapsulate the table DML source code for
  security (UI schema needs only the execute right for the API and the
  read/write right for the REGIONS_DML_V, tables can be
  hidden in extra data schema) and easy readability of the business logic
  (all DML is then written in the same style). For APEX automatic row
  processing like tabular forms you can optionally use the
  REGIONS_DML_V. The instead of trigger for this view
  is calling simply this "REGIONS_API".
  */

  TYPE t_strong_ref_cursor IS REF CURSOR RETURN "REGIONS"%ROWTYPE;
  TYPE t_rows_tab IS TABLE OF "REGIONS"%ROWTYPE;

  FUNCTION bulk_is_complete
    RETURN BOOLEAN;

  PROCEDURE set_bulk_limit(p_bulk_limit IN PLS_INTEGER);

  FUNCTION get_bulk_limit
    RETURN PLS_INTEGER;

  FUNCTION row_exists (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE /*PK*/ )
  RETURN BOOLEAN;

  FUNCTION row_exists_yn (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE /*PK*/ )
  RETURN VARCHAR2;

  FUNCTION create_row (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE   DEFAULT NULL /*PK*/,
    p_region_name IN "REGIONS"."REGION_NAME"%TYPE DEFAULT NULL )
  RETURN "REGIONS"."REGION_ID"%TYPE;

  PROCEDURE create_row (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE   DEFAULT NULL /*PK*/,
    p_region_name IN "REGIONS"."REGION_NAME"%TYPE DEFAULT NULL );

  FUNCTION create_row (
    p_row         IN "REGIONS"%ROWTYPE )
  RETURN "REGIONS"."REGION_ID"%TYPE;

  PROCEDURE create_row (
    p_row         IN "REGIONS"%ROWTYPE );

  FUNCTION create_rows(p_rows_tab IN t_rows_tab)
    RETURN t_rows_tab;

  PROCEDURE create_rows(p_rows_tab IN t_rows_tab);

  FUNCTION read_row (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE /*PK*/ )
  RETURN "REGIONS"%ROWTYPE;

  FUNCTION read_rows(p_ref_cursor IN t_strong_ref_cursor)
    RETURN t_rows_tab;

  PROCEDURE update_row (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE DEFAULT NULL /*PK*/,
    p_region_name IN "REGIONS"."REGION_NAME"%TYPE );

  PROCEDURE update_row (
    p_row         IN "REGIONS"%ROWTYPE );

  PROCEDURE update_rows(p_rows_tab IN t_rows_tab);

  FUNCTION create_or_update_row (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE DEFAULT NULL /*PK*/,
    p_region_name IN "REGIONS"."REGION_NAME"%TYPE )
  RETURN "REGIONS"."REGION_ID"%TYPE;

  PROCEDURE create_or_update_row (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE DEFAULT NULL /*PK*/,
    p_region_name IN "REGIONS"."REGION_NAME"%TYPE );

  FUNCTION create_or_update_row (
    p_row         IN "REGIONS"%ROWTYPE )
  RETURN "REGIONS"."REGION_ID"%TYPE;

  PROCEDURE create_or_update_row (
    p_row         IN "REGIONS"%ROWTYPE );

  FUNCTION get_a_row
  RETURN "REGIONS"%ROWTYPE;
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Returns a row with (hopefully) complete default data.
   */

  FUNCTION create_a_row (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE   DEFAULT get_a_row()."REGION_ID" /*PK*/,
    p_region_name IN "REGIONS"."REGION_NAME"%TYPE DEFAULT get_a_row()."REGION_NAME" )
  RETURN "REGIONS"."REGION_ID"%TYPE;
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Create a new row without (hopefully) providing any parameters.
   */

  PROCEDURE create_a_row (
    p_region_id   IN "REGIONS"."REGION_ID"%TYPE   DEFAULT get_a_row()."REGION_ID" /*PK*/,
    p_region_name IN "REGIONS"."REGION_NAME"%TYPE DEFAULT get_a_row()."REGION_NAME" );
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Create a new row without (hopefully) providing any parameters.
   */

  FUNCTION read_a_row
  RETURN "REGIONS"%ROWTYPE;
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
    <column source="TAPIGEN" name="REGION_ID"><![CDATA[round(dbms_random.value(0,999999999),0)]]></column>
    <column source="TAPIGEN" name="REGION_NAME"><![CDATA[substr(sys_guid(),1,25)]]></column>
  </custom_defaults>
  */
END "REGIONS_API";
/
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HR"."REGIONS_API" IS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.7.0"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-03 21:39:44"
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

  FUNCTION create_rows(p_rows_tab IN t_rows_tab)
    RETURN t_rows_tab IS
    v_return t_rows_tab;
  BEGIN
    v_return := p_rows_tab;

    FORALL i IN INDICES OF p_rows_tab
      INSERT INTO "REGIONS" (
      "REGION_ID" /*PK*/,
      "REGION_NAME" )
      VALUES (
      v_return(i)."REGION_ID",
        v_return(i)."REGION_NAME" );

    RETURN v_return;
  END create_rows;

  PROCEDURE create_rows(p_rows_tab IN t_rows_tab)
  IS
    v_return t_rows_tab;
  BEGIN
    v_return := create_rows(p_rows_tab => p_rows_tab);
  END create_rows;

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

  PROCEDURE update_rows(p_rows_tab IN t_rows_tab)
  IS
  BEGIN
    FORALL i IN INDICES OF p_rows_tab
        UPDATE REGIONS
           SET "REGION_NAME" = p_rows_tab(i)."REGION_NAME"
         WHERE "REGION_ID" = p_rows_tab(i)."REGION_ID";
  END update_rows;

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

