CREATE OR REPLACE PACKAGE "TEST"."JOBS_API" IS
  /*
  This is the API for the table "JOBS".

  GENERATION OPTIONS
  - Must be in the lines 5-35 to be reusable by the generator
  - DO NOT TOUCH THIS until you know what you do
  - Read the docs under github.com/OraMUC/table-api-generator ;-)
  <options
    generator="OM_TAPIGEN"
    generator_version="0.5.0"
    generator_action="COMPILE_API"
    generated_at="2018-12-20 19:43:14"
    generated_by="OGOBRECHT"
    p_table_name="JOBS"
    p_owner="TEST"
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
    p_api_name="JOBS_API"
    p_sequence_name=""
    p_exclude_column_list=""
    p_enable_custom_defaults="TRUE"
    p_custom_default_values="SEE_END_OF_API_PACKAGE_SPEC"/>

  This API provides DML functionality that can be easily called from APEX.
  Target of the table API is to encapsulate the table DML source code for
  security (UI schema needs only the execute right for the API and the
  read/write right for the JOBS_DML_V, tables can be
  hidden in extra data schema) and easy readability of the business logic
  (all DML is then written in the same style). For APEX automatic row
  processing like tabular forms you can optionally use the
  JOBS_DML_V. The instead of trigger for this view
  is calling simply this "JOBS_API".
  */

  FUNCTION row_exists (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE /*PK*/ )
  RETURN BOOLEAN;

  FUNCTION row_exists_yn (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE /*PK*/ )
  RETURN VARCHAR2;

  FUNCTION create_row (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE     DEFAULT NULL /*PK*/,
    p_job_title  IN "JOBS"."JOB_TITLE"%TYPE  ,
    p_min_salary IN "JOBS"."MIN_SALARY"%TYPE DEFAULT NULL,
    p_max_salary IN "JOBS"."MAX_SALARY"%TYPE DEFAULT NULL )
  RETURN "JOBS"."JOB_ID"%TYPE;

  PROCEDURE create_row (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE     DEFAULT NULL /*PK*/,
    p_job_title  IN "JOBS"."JOB_TITLE"%TYPE  ,
    p_min_salary IN "JOBS"."MIN_SALARY"%TYPE DEFAULT NULL,
    p_max_salary IN "JOBS"."MAX_SALARY"%TYPE DEFAULT NULL );

  FUNCTION create_row (
    p_row        IN "JOBS"%ROWTYPE )
  RETURN "JOBS"."JOB_ID"%TYPE;

  PROCEDURE create_row (
    p_row        IN "JOBS"%ROWTYPE );

  FUNCTION read_row (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE /*PK*/ )
  RETURN "JOBS"%ROWTYPE;

  PROCEDURE update_row (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE DEFAULT NULL /*PK*/,
    p_job_title  IN "JOBS"."JOB_TITLE"%TYPE,
    p_min_salary IN "JOBS"."MIN_SALARY"%TYPE,
    p_max_salary IN "JOBS"."MAX_SALARY"%TYPE );

  PROCEDURE update_row (
    p_row        IN "JOBS"%ROWTYPE );

  FUNCTION create_or_update_row (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE DEFAULT NULL /*PK*/,
    p_job_title  IN "JOBS"."JOB_TITLE"%TYPE,
    p_min_salary IN "JOBS"."MIN_SALARY"%TYPE,
    p_max_salary IN "JOBS"."MAX_SALARY"%TYPE )
  RETURN "JOBS"."JOB_ID"%TYPE;

  PROCEDURE create_or_update_row (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE DEFAULT NULL /*PK*/,
    p_job_title  IN "JOBS"."JOB_TITLE"%TYPE,
    p_min_salary IN "JOBS"."MIN_SALARY"%TYPE,
    p_max_salary IN "JOBS"."MAX_SALARY"%TYPE );

  FUNCTION create_or_update_row (
    p_row        IN "JOBS"%ROWTYPE )
  RETURN "JOBS"."JOB_ID"%TYPE;

  PROCEDURE create_or_update_row (
    p_row        IN "JOBS"%ROWTYPE );

  FUNCTION get_a_row
  RETURN "JOBS"%ROWTYPE;
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Returns a row with (hopefully) complete default data.
   */

  FUNCTION create_a_row (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE     DEFAULT get_a_row()."JOB_ID" /*PK*/,
    p_job_title  IN "JOBS"."JOB_TITLE"%TYPE  DEFAULT get_a_row()."JOB_TITLE",
    p_min_salary IN "JOBS"."MIN_SALARY"%TYPE DEFAULT get_a_row()."MIN_SALARY",
    p_max_salary IN "JOBS"."MAX_SALARY"%TYPE DEFAULT get_a_row()."MAX_SALARY" )
  RETURN "JOBS"."JOB_ID"%TYPE;
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Create a new row without (hopefully) providing any parameters.
   */

  PROCEDURE create_a_row (
    p_job_id     IN "JOBS"."JOB_ID"%TYPE     DEFAULT get_a_row()."JOB_ID" /*PK*/,
    p_job_title  IN "JOBS"."JOB_TITLE"%TYPE  DEFAULT get_a_row()."JOB_TITLE",
    p_min_salary IN "JOBS"."MIN_SALARY"%TYPE DEFAULT get_a_row()."MIN_SALARY",
    p_max_salary IN "JOBS"."MAX_SALARY"%TYPE DEFAULT get_a_row()."MAX_SALARY" );
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Create a new row without (hopefully) providing any parameters.
   */

  FUNCTION read_a_row
  RETURN "JOBS"%ROWTYPE;
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
    <column source="TAPIGEN" name="JOB_ID"><![CDATA[substr(sys_guid(),1,10)]]></column>
    <column source="TAPIGEN" name="JOB_TITLE"><![CDATA[substr(sys_guid(),1,35)]]></column>
    <column source="TAPIGEN" name="MIN_SALARY"><![CDATA[round(dbms_random.value(0,999999),0)]]></column>
    <column source="TAPIGEN" name="MAX_SALARY"><![CDATA[round(dbms_random.value(0,999999),0)]]></column>
  </custom_defaults>
  */
END "JOBS_API";
/


