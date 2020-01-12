
  CREATE OR REPLACE EDITIONABLE PACKAGE "TESTS"."DEPARTMENTS_API" IS
  /*
  This is the API for the table "DEPARTMENTS".

  GENERATION OPTIONS
  - Must be in the lines 5-35 to be reusable by the generator
  - DO NOT TOUCH THIS until you know what you do
  - Read the docs under github.com/OraMUC/table-api-generator ;-)
  <options
    generator="OM_TAPIGEN"
    generator_version="0.5.0.2"
    generator_action="COMPILE_API"
    generated_at="2020-01-12 20:36:01"
    generated_by="OGOBRECHT"
    p_table_name="DEPARTMENTS"
    p_owner="TESTS"
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
    p_api_name="DEPARTMENTS_API"
    p_sequence_name="DEPARTMENTS_SEQ"
    p_exclude_column_list=""
    p_enable_custom_defaults="TRUE"
    p_custom_default_values="SEE_END_OF_API_PACKAGE_SPEC"
    p_enable_bulk_methods="TRUE"/>

  This API provides DML functionality that can be easily called from APEX.
  Target of the table API is to encapsulate the table DML source code for
  security (UI schema needs only the execute right for the API and the
  read/write right for the DEPARTMENTS_DML_V, tables can be
  hidden in extra data schema) and easy readability of the business logic
  (all DML is then written in the same style). For APEX automatic row
  processing like tabular forms you can optionally use the
  DEPARTMENTS_DML_V. The instead of trigger for this view
  is calling simply this "DEPARTMENTS_API".
  */

  TYPE t_strong_ref_cursor IS REF CURSOR RETURN "DEPARTMENTS"%ROWTYPE;
  TYPE t_rows_tab IS TABLE OF "DEPARTMENTS"%ROWTYPE;

  FUNCTION bulk_is_complete
    RETURN BOOLEAN;

  PROCEDURE set_bulk_limit(p_bulk_limit IN PLS_INTEGER);

  FUNCTION get_bulk_limit
    RETURN PLS_INTEGER;

  FUNCTION row_exists (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE /*PK*/ )
  RETURN BOOLEAN;

  FUNCTION row_exists_yn (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE /*PK*/ )
  RETURN VARCHAR2;

  FUNCTION create_row (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE   DEFAULT NULL /*PK*/,
    p_department_name IN "DEPARTMENTS"."DEPARTMENT_NAME"%TYPE ,
    p_manager_id      IN "DEPARTMENTS"."MANAGER_ID"%TYPE      DEFAULT NULL /*FK*/,
    p_location_id     IN "DEPARTMENTS"."LOCATION_ID"%TYPE     DEFAULT NULL /*FK*/ )
  RETURN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;

  PROCEDURE create_row (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE   DEFAULT NULL /*PK*/,
    p_department_name IN "DEPARTMENTS"."DEPARTMENT_NAME"%TYPE ,
    p_manager_id      IN "DEPARTMENTS"."MANAGER_ID"%TYPE      DEFAULT NULL /*FK*/,
    p_location_id     IN "DEPARTMENTS"."LOCATION_ID"%TYPE     DEFAULT NULL /*FK*/ );

  FUNCTION create_row (
    p_row             IN "DEPARTMENTS"%ROWTYPE )
  RETURN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;

  PROCEDURE create_row (
    p_row             IN "DEPARTMENTS"%ROWTYPE );

  FUNCTION create_rows(p_rows_tab IN t_rows_tab)
    RETURN t_rows_tab;

  PROCEDURE create_rows(p_rows_tab IN t_rows_tab);

  FUNCTION read_row (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE /*PK*/ )
  RETURN "DEPARTMENTS"%ROWTYPE;

  FUNCTION read_rows(p_ref_cursor IN t_strong_ref_cursor)
    RETURN t_rows_tab;

  PROCEDURE update_row (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE DEFAULT NULL /*PK*/,
    p_department_name IN "DEPARTMENTS"."DEPARTMENT_NAME"%TYPE,
    p_manager_id      IN "DEPARTMENTS"."MANAGER_ID"%TYPE /*FK*/,
    p_location_id     IN "DEPARTMENTS"."LOCATION_ID"%TYPE /*FK*/ );

  PROCEDURE update_row (
    p_row             IN "DEPARTMENTS"%ROWTYPE );

  PROCEDURE update_rows(p_rows_tab IN t_rows_tab);

  FUNCTION create_or_update_row (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE DEFAULT NULL /*PK*/,
    p_department_name IN "DEPARTMENTS"."DEPARTMENT_NAME"%TYPE,
    p_manager_id      IN "DEPARTMENTS"."MANAGER_ID"%TYPE /*FK*/,
    p_location_id     IN "DEPARTMENTS"."LOCATION_ID"%TYPE /*FK*/ )
  RETURN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;

  PROCEDURE create_or_update_row (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE DEFAULT NULL /*PK*/,
    p_department_name IN "DEPARTMENTS"."DEPARTMENT_NAME"%TYPE,
    p_manager_id      IN "DEPARTMENTS"."MANAGER_ID"%TYPE /*FK*/,
    p_location_id     IN "DEPARTMENTS"."LOCATION_ID"%TYPE /*FK*/ );

  FUNCTION create_or_update_row (
    p_row             IN "DEPARTMENTS"%ROWTYPE )
  RETURN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;

  PROCEDURE create_or_update_row (
    p_row             IN "DEPARTMENTS"%ROWTYPE );

  FUNCTION get_a_row
  RETURN "DEPARTMENTS"%ROWTYPE;
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Returns a row with (hopefully) complete default data.
   */

  FUNCTION create_a_row (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE   DEFAULT get_a_row()."DEPARTMENT_ID" /*PK*/,
    p_department_name IN "DEPARTMENTS"."DEPARTMENT_NAME"%TYPE DEFAULT get_a_row()."DEPARTMENT_NAME",
    p_manager_id      IN "DEPARTMENTS"."MANAGER_ID"%TYPE      DEFAULT get_a_row()."MANAGER_ID" /*FK*/,
    p_location_id     IN "DEPARTMENTS"."LOCATION_ID"%TYPE     DEFAULT get_a_row()."LOCATION_ID" /*FK*/ )
  RETURN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE;
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Create a new row without (hopefully) providing any parameters.
   */

  PROCEDURE create_a_row (
    p_department_id   IN "DEPARTMENTS"."DEPARTMENT_ID"%TYPE   DEFAULT get_a_row()."DEPARTMENT_ID" /*PK*/,
    p_department_name IN "DEPARTMENTS"."DEPARTMENT_NAME"%TYPE DEFAULT get_a_row()."DEPARTMENT_NAME",
    p_manager_id      IN "DEPARTMENTS"."MANAGER_ID"%TYPE      DEFAULT get_a_row()."MANAGER_ID" /*FK*/,
    p_location_id     IN "DEPARTMENTS"."LOCATION_ID"%TYPE     DEFAULT get_a_row()."LOCATION_ID" /*FK*/ );
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Create a new row without (hopefully) providing any parameters.
   */

  FUNCTION read_a_row
  RETURN "DEPARTMENTS"%ROWTYPE;
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
    <column source="TAPIGEN" name="DEPARTMENT_ID"><![CDATA["DEPARTMENTS_SEQ".nextval]]></column>
    <column source="TAPIGEN" name="DEPARTMENT_NAME"><![CDATA[substr(sys_guid(),1,30)]]></column>
    <column source="TAPIGEN" name="LOCATION_ID"><![CDATA[1]]></column>
  </custom_defaults>
  */
END "DEPARTMENTS_API";
/

