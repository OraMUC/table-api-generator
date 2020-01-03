
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
    generated_at="2020-01-03 22:14:27"
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
    <column source="TAPIGEN" name="COUNTRY_ID"><![CDATA['09']]></column>
  </custom_defaults>
  */
END "LOCATIONS_API";
/

