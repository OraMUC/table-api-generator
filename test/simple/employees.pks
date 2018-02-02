PACKAGE      "EMPLOYEES_API" IS
  /*
  This is the API for the table "EMPLOYEES".

  GENERATION OPTIONS
  - Must be in the lines 5-35 to be reusable by the generator
  - DO NOT TOUCH THIS until you know what you do
  - Read the docs under github.com/OraMUC/table-api-generator ;-)
  <options
    generator="OM_TAPIGEN"
    generator_version="0.5.0_b4"
    generator_action="COMPILE_API"
    generated_at="2018-02-02 22:24:48"
    generated_by="DECAF4"
    p_table_name="EMPLOYEES"
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
    p_enable_dml_view="FALSE"
    p_enable_generic_change_log="FALSE"
    p_api_name="EMPLOYEES_API"
    p_sequence_name="EMPLOYEES_SEQ"
    p_exclude_column_list=""
    p_enable_custom_defaults="TRUE"
    p_custom_default_values="SEE_END_OF_API_PACKAGE_SPEC"/>

  This API provides DML functionality that can be easily called from APEX.
  Target of the table API is to encapsulate the table DML source code for
  security (UI schema needs only the execute right for the API and the 
  read/write right for the EMPLOYEES_DML_V, tables can be 
  hidden in extra data schema) and easy readability of the business logic 
  (all DML is then written in the same style). For APEX automatic row 
  processing like tabular forms you can optionally use the 
  EMPLOYEES_DML_V. The instead of trigger for this view
  is calling simply this "EMPLOYEES_API".
  */

  FUNCTION row_exists (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN BOOLEAN;

  FUNCTION row_exists_yn (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN VARCHAR2;

  FUNCTION get_pk_by_unique_cols (
    p_email          IN "EMPLOYEES"."EMAIL"%TYPE /*UK*/ )
  RETURN "EMPLOYEES"."EMPLOYEE_ID"%TYPE;

  FUNCTION create_row (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE    DEFAULT NULL /*PK*/,
    p_first_name     IN "EMPLOYEES"."FIRST_NAME"%TYPE     DEFAULT NULL,
    p_last_name      IN "EMPLOYEES"."LAST_NAME"%TYPE      ,
    p_email          IN "EMPLOYEES"."EMAIL"%TYPE           /*UK*/,
    p_phone_number   IN "EMPLOYEES"."PHONE_NUMBER"%TYPE   DEFAULT NULL,
    p_hire_date      IN "EMPLOYEES"."HIRE_DATE"%TYPE      ,
    p_job_id         IN "EMPLOYEES"."JOB_ID"%TYPE          /*FK*/,
    p_salary         IN "EMPLOYEES"."SALARY"%TYPE         DEFAULT NULL,
    p_commission_pct IN "EMPLOYEES"."COMMISSION_PCT"%TYPE DEFAULT NULL,
    p_manager_id     IN "EMPLOYEES"."MANAGER_ID"%TYPE     DEFAULT NULL /*FK*/,
    p_department_id  IN "EMPLOYEES"."DEPARTMENT_ID"%TYPE  DEFAULT NULL /*FK*/ )
  RETURN "EMPLOYEES"."EMPLOYEE_ID"%TYPE;

  PROCEDURE create_row (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE    DEFAULT NULL /*PK*/,
    p_first_name     IN "EMPLOYEES"."FIRST_NAME"%TYPE     DEFAULT NULL,
    p_last_name      IN "EMPLOYEES"."LAST_NAME"%TYPE      ,
    p_email          IN "EMPLOYEES"."EMAIL"%TYPE           /*UK*/,
    p_phone_number   IN "EMPLOYEES"."PHONE_NUMBER"%TYPE   DEFAULT NULL,
    p_hire_date      IN "EMPLOYEES"."HIRE_DATE"%TYPE      ,
    p_job_id         IN "EMPLOYEES"."JOB_ID"%TYPE          /*FK*/,
    p_salary         IN "EMPLOYEES"."SALARY"%TYPE         DEFAULT NULL,
    p_commission_pct IN "EMPLOYEES"."COMMISSION_PCT"%TYPE DEFAULT NULL,
    p_manager_id     IN "EMPLOYEES"."MANAGER_ID"%TYPE     DEFAULT NULL /*FK*/,
    p_department_id  IN "EMPLOYEES"."DEPARTMENT_ID"%TYPE  DEFAULT NULL /*FK*/ );

  FUNCTION create_row (
    p_row            IN "EMPLOYEES"%ROWTYPE )
  RETURN "EMPLOYEES"."EMPLOYEE_ID"%TYPE;

  PROCEDURE create_row (
    p_row            IN "EMPLOYEES"%ROWTYPE );

  FUNCTION read_row (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"%ROWTYPE;

  FUNCTION read_row (
    p_email          IN "EMPLOYEES"."EMAIL"%TYPE /*UK*/ )
  RETURN "EMPLOYEES"%ROWTYPE;

  PROCEDURE update_row (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE DEFAULT NULL /*PK*/,
    p_first_name     IN "EMPLOYEES"."FIRST_NAME"%TYPE,
    p_last_name      IN "EMPLOYEES"."LAST_NAME"%TYPE,
    p_email          IN "EMPLOYEES"."EMAIL"%TYPE /*UK*/,
    p_phone_number   IN "EMPLOYEES"."PHONE_NUMBER"%TYPE,
    p_hire_date      IN "EMPLOYEES"."HIRE_DATE"%TYPE,
    p_job_id         IN "EMPLOYEES"."JOB_ID"%TYPE /*FK*/,
    p_salary         IN "EMPLOYEES"."SALARY"%TYPE,
    p_commission_pct IN "EMPLOYEES"."COMMISSION_PCT"%TYPE,
    p_manager_id     IN "EMPLOYEES"."MANAGER_ID"%TYPE /*FK*/,
    p_department_id  IN "EMPLOYEES"."DEPARTMENT_ID"%TYPE /*FK*/ );

  PROCEDURE update_row (
    p_row            IN "EMPLOYEES"%ROWTYPE );

  FUNCTION create_or_update_row (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE DEFAULT NULL /*PK*/,
    p_first_name     IN "EMPLOYEES"."FIRST_NAME"%TYPE,
    p_last_name      IN "EMPLOYEES"."LAST_NAME"%TYPE,
    p_email          IN "EMPLOYEES"."EMAIL"%TYPE /*UK*/,
    p_phone_number   IN "EMPLOYEES"."PHONE_NUMBER"%TYPE,
    p_hire_date      IN "EMPLOYEES"."HIRE_DATE"%TYPE,
    p_job_id         IN "EMPLOYEES"."JOB_ID"%TYPE /*FK*/,
    p_salary         IN "EMPLOYEES"."SALARY"%TYPE,
    p_commission_pct IN "EMPLOYEES"."COMMISSION_PCT"%TYPE,
    p_manager_id     IN "EMPLOYEES"."MANAGER_ID"%TYPE /*FK*/,
    p_department_id  IN "EMPLOYEES"."DEPARTMENT_ID"%TYPE /*FK*/ )
  RETURN "EMPLOYEES"."EMPLOYEE_ID"%TYPE;

  PROCEDURE create_or_update_row (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE DEFAULT NULL /*PK*/,
    p_first_name     IN "EMPLOYEES"."FIRST_NAME"%TYPE,
    p_last_name      IN "EMPLOYEES"."LAST_NAME"%TYPE,
    p_email          IN "EMPLOYEES"."EMAIL"%TYPE /*UK*/,
    p_phone_number   IN "EMPLOYEES"."PHONE_NUMBER"%TYPE,
    p_hire_date      IN "EMPLOYEES"."HIRE_DATE"%TYPE,
    p_job_id         IN "EMPLOYEES"."JOB_ID"%TYPE /*FK*/,
    p_salary         IN "EMPLOYEES"."SALARY"%TYPE,
    p_commission_pct IN "EMPLOYEES"."COMMISSION_PCT"%TYPE,
    p_manager_id     IN "EMPLOYEES"."MANAGER_ID"%TYPE /*FK*/,
    p_department_id  IN "EMPLOYEES"."DEPARTMENT_ID"%TYPE /*FK*/ );

  FUNCTION create_or_update_row (
    p_row            IN "EMPLOYEES"%ROWTYPE )
  RETURN "EMPLOYEES"."EMPLOYEE_ID"%TYPE;

  PROCEDURE create_or_update_row (
    p_row            IN "EMPLOYEES"%ROWTYPE );

  FUNCTION get_a_row
  RETURN "EMPLOYEES"%ROWTYPE;

  FUNCTION create_a_row (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE    DEFAULT get_a_row()."EMPLOYEE_ID" /*PK*/,
    p_first_name     IN "EMPLOYEES"."FIRST_NAME"%TYPE     DEFAULT get_a_row()."FIRST_NAME",
    p_last_name      IN "EMPLOYEES"."LAST_NAME"%TYPE      DEFAULT get_a_row()."LAST_NAME",
    p_email          IN "EMPLOYEES"."EMAIL"%TYPE          DEFAULT get_a_row()."EMAIL" /*UK*/,
    p_phone_number   IN "EMPLOYEES"."PHONE_NUMBER"%TYPE   DEFAULT get_a_row()."PHONE_NUMBER",
    p_hire_date      IN "EMPLOYEES"."HIRE_DATE"%TYPE      DEFAULT get_a_row()."HIRE_DATE",
    p_job_id         IN "EMPLOYEES"."JOB_ID"%TYPE         DEFAULT get_a_row()."JOB_ID" /*FK*/,
    p_salary         IN "EMPLOYEES"."SALARY"%TYPE         DEFAULT get_a_row()."SALARY",
    p_commission_pct IN "EMPLOYEES"."COMMISSION_PCT"%TYPE DEFAULT get_a_row()."COMMISSION_PCT",
    p_manager_id     IN "EMPLOYEES"."MANAGER_ID"%TYPE     DEFAULT get_a_row()."MANAGER_ID" /*FK*/,
    p_department_id  IN "EMPLOYEES"."DEPARTMENT_ID"%TYPE  DEFAULT get_a_row()."DEPARTMENT_ID" /*FK*/ )
  RETURN "EMPLOYEES"."EMPLOYEE_ID"%TYPE;

  PROCEDURE create_a_row (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE    DEFAULT get_a_row()."EMPLOYEE_ID" /*PK*/,
    p_first_name     IN "EMPLOYEES"."FIRST_NAME"%TYPE     DEFAULT get_a_row()."FIRST_NAME",
    p_last_name      IN "EMPLOYEES"."LAST_NAME"%TYPE      DEFAULT get_a_row()."LAST_NAME",
    p_email          IN "EMPLOYEES"."EMAIL"%TYPE          DEFAULT get_a_row()."EMAIL" /*UK*/,
    p_phone_number   IN "EMPLOYEES"."PHONE_NUMBER"%TYPE   DEFAULT get_a_row()."PHONE_NUMBER",
    p_hire_date      IN "EMPLOYEES"."HIRE_DATE"%TYPE      DEFAULT get_a_row()."HIRE_DATE",
    p_job_id         IN "EMPLOYEES"."JOB_ID"%TYPE         DEFAULT get_a_row()."JOB_ID" /*FK*/,
    p_salary         IN "EMPLOYEES"."SALARY"%TYPE         DEFAULT get_a_row()."SALARY",
    p_commission_pct IN "EMPLOYEES"."COMMISSION_PCT"%TYPE DEFAULT get_a_row()."COMMISSION_PCT",
    p_manager_id     IN "EMPLOYEES"."MANAGER_ID"%TYPE     DEFAULT get_a_row()."MANAGER_ID" /*FK*/,
    p_department_id  IN "EMPLOYEES"."DEPARTMENT_ID"%TYPE  DEFAULT get_a_row()."DEPARTMENT_ID" /*FK*/ );

  FUNCTION read_a_row
  RETURN "EMPLOYEES"%ROWTYPE;

  /*
  Only custom defaults with the source "USER" are used when "p_reuse_existing_api_params" is set to true.
  All other custom defaults are only listed for convenience and determined at runtime by the generator.
  You can simply copy over the defaults to your generator call - the attribute "source" is ignored then.
  <custom_defaults>
    <column source="TAPIGEN" name="FIRST_NAME"><![CDATA[substr(sys_guid(),1,20)]]></column>
    <column source="TAPIGEN" name="LAST_NAME"><![CDATA[substr(sys_guid(),1,25)]]></column>
    <column source="TAPIGEN" name="EMAIL"><![CDATA[substr(sys_guid(),1,15) || '@dummy.com']]></column>
    <column source="TAPIGEN" name="PHONE_NUMBER"><![CDATA[substr('+1.'||lpad(to_char(trunc(dbms_random.value(1,999))),3,'0')||'.'||lpad(to_char(trunc(dbms_random.value(1,999))),3,'0')||'.'||lpad(to_char(trunc(dbms_random.value(1,9999))),4,'0'),1,20)]]></column>
    <column source="TAPIGEN" name="HIRE_DATE"><![CDATA[to_date(trunc(dbms_random.value(to_char(date'1900-01-01','j'),to_char(date'2099-12-31','j'))),'j')]]></column>
    <column source="USER"    name="JOB_ID"><![CDATA['IT_PROG']]></column>
    <column source="USER"    name="SALARY"><![CDATA[round(dbms_random.value(1000,10000),2)]]></column>
    <column source="TAPIGEN" name="COMMISSION_PCT"><![CDATA[round(dbms_random.value(0,.99),2)]]></column>
    <column source="USER"    name="MANAGER_ID"><![CDATA[100]]></column>
    <column source="USER"    name="DEPARTMENT_ID"><![CDATA[90]]></column>
  </custom_defaults>
  */

END "EMPLOYEES_API";
