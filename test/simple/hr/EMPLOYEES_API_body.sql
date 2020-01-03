
  CREATE OR REPLACE EDITIONABLE PACKAGE "HR"."EMPLOYEES_API" IS
  /*
  This is the API for the table "EMPLOYEES".

  GENERATION OPTIONS
  - Must be in the lines 5-35 to be reusable by the generator
  - DO NOT TOUCH THIS until you know what you do
  - Read the docs under github.com/OraMUC/table-api-generator ;-)
  <options
    generator="OM_TAPIGEN"
    generator_version="0.7.0"
    generator_action="COMPILE_API"
    generated_at="2020-01-03 21:39:45"
    generated_by="DATA-ABC\INFO"
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
    p_return_row_instead_of_pk="TRUE"
    p_enable_dml_view="TRUE"
    p_enable_generic_change_log="TRUE"
    p_api_name="EMPLOYEES_API"
    p_sequence_name="EMPLOYEES_SEQ"
    p_exclude_column_list=""
    p_enable_custom_defaults="TRUE"
    p_custom_default_values="SEE_END_OF_API_PACKAGE_SPEC"
    p_enable_bulk_methods="TRUE"/>

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

  TYPE t_strong_ref_cursor IS REF CURSOR RETURN "EMPLOYEES"%ROWTYPE;
  TYPE t_rows_tab IS TABLE OF "EMPLOYEES"%ROWTYPE;

  FUNCTION bulk_is_complete
    RETURN BOOLEAN;

  PROCEDURE set_bulk_limit(p_bulk_limit IN PLS_INTEGER);

  FUNCTION get_bulk_limit
    RETURN PLS_INTEGER;

  FUNCTION row_exists (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN BOOLEAN;

  FUNCTION row_exists_yn (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN VARCHAR2;

  FUNCTION get_pk_by_unique_cols (
    p_email          IN "EMPLOYEES"."EMAIL"%TYPE /*UK*/ )
  RETURN "EMPLOYEES"%ROWTYPE;

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
  RETURN "EMPLOYEES"%ROWTYPE;

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
  RETURN "EMPLOYEES"%ROWTYPE;

  PROCEDURE create_row (
    p_row            IN "EMPLOYEES"%ROWTYPE );

  FUNCTION create_rows(p_rows_tab IN t_rows_tab)
    RETURN t_rows_tab;

  PROCEDURE create_rows(p_rows_tab IN t_rows_tab);

  FUNCTION read_row (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"%ROWTYPE;

  FUNCTION read_row (
    p_email          IN "EMPLOYEES"."EMAIL"%TYPE /*UK*/ )
  RETURN "EMPLOYEES"%ROWTYPE;

  FUNCTION read_rows(p_ref_cursor IN t_strong_ref_cursor)
    RETURN t_rows_tab;

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

  PROCEDURE update_rows(p_rows_tab IN t_rows_tab);

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
  RETURN "EMPLOYEES"%ROWTYPE;

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
  RETURN "EMPLOYEES"%ROWTYPE;

  PROCEDURE create_or_update_row (
    p_row            IN "EMPLOYEES"%ROWTYPE );

  FUNCTION get_a_row
  RETURN "EMPLOYEES"%ROWTYPE;
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Returns a row with (hopefully) complete default data.
   */

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
  RETURN "EMPLOYEES"%ROWTYPE;
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Create a new row without (hopefully) providing any parameters.
   */

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
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Create a new row without (hopefully) providing any parameters.
   */

  FUNCTION read_a_row
  RETURN "EMPLOYEES"%ROWTYPE;
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
    <column source="TAPIGEN" name="EMPLOYEE_ID"><![CDATA["EMPLOYEES_SEQ".nextval]]></column>
    <column source="TAPIGEN" name="FIRST_NAME"><![CDATA[substr(sys_guid(),1,20)]]></column>
    <column source="TAPIGEN" name="LAST_NAME"><![CDATA[substr(sys_guid(),1,25)]]></column>
    <column source="TAPIGEN" name="EMAIL"><![CDATA[substr(sys_guid(),1,15) || '@dummy.com']]></column>
    <column source="TAPIGEN" name="PHONE_NUMBER"><![CDATA[substr('+1.' || lpad(to_char(trunc(dbms_random.value(1,999))),3,'0') || '.' || lpad(to_char(trunc(dbms_random.value(1,999))),3,'0') || '.' || lpad(to_char(trunc(dbms_random.value(1,9999))),4,'0'),1,20)]]></column>
    <column source="TAPIGEN" name="HIRE_DATE"><![CDATA[to_date(trunc(dbms_random.value(to_char(date'1900-01-01','j'),to_char(date'2099-12-31','j'))),'j')]]></column>
    <column source="TAPIGEN" name="JOB_ID"><![CDATA['3A8CAB7373']]></column>
    <column source="USER"    name="SALARY"><![CDATA[round(dbms_random.value(1000,10000),2)]]></column>
    <column source="TAPIGEN" name="COMMISSION_PCT"><![CDATA[round(dbms_random.value(0,.99),2)]]></column>
    <column source="TAPIGEN" name="MANAGER_ID"><![CDATA[100]]></column>
    <column source="TAPIGEN" name="DEPARTMENT_ID"><![CDATA[10]]></column>
  </custom_defaults>
  */
END "EMPLOYEES_API";
/
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HR"."EMPLOYEES_API" IS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.7.0"
   * generator_action="COMPILE_API"
   * generated_at="2020-01-03 21:39:45"
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

  PROCEDURE create_change_log_entry (
    p_table     IN generic_change_log.gcl_table%TYPE,
    p_column    IN generic_change_log.gcl_column%TYPE,
    p_pk_id     IN generic_change_log.gcl_pk_id%TYPE,
    p_old_value IN generic_change_log.gcl_old_value%TYPE,
    p_new_value IN generic_change_log.gcl_new_value%TYPE )
  IS
  BEGIN
    INSERT INTO generic_change_log (
      gcl_id,
      gcl_table,
      gcl_column,
      gcl_pk_id,
      gcl_old_value,
      gcl_new_value,
      gcl_user )
    VALUES (
      generic_change_log_seq.nextval,
      p_table,
      p_column,
      p_pk_id,
      p_old_value,
      p_new_value,
      coalesce(v('APP_USER'),sys_context('USERENV','OS_USER')) );
  END;

  FUNCTION row_exists (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN BOOLEAN
  IS
    v_return BOOLEAN := FALSE;
    v_dummy  PLS_INTEGER;
    CURSOR   cur_bool IS
      SELECT 1
        FROM "EMPLOYEES"
       WHERE "EMPLOYEE_ID" = p_employee_id;
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
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN CASE WHEN row_exists( p_employee_id => p_employee_id )
             THEN 'Y'
             ELSE 'N'
           END;
  END;

  FUNCTION get_pk_by_unique_cols (
    p_email          IN "EMPLOYEES"."EMAIL"%TYPE /*UK*/ )
  RETURN "EMPLOYEES"%ROWTYPE IS
    v_return "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_return := read_row ( p_email => p_email );
    RETURN v_return;
  END get_pk_by_unique_cols;

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
  RETURN "EMPLOYEES"%ROWTYPE IS
    v_return "EMPLOYEES"%ROWTYPE;
  BEGIN
    INSERT INTO "EMPLOYEES" (
      "EMPLOYEE_ID" /*PK*/,
      "FIRST_NAME",
      "LAST_NAME",
      "EMAIL" /*UK*/,
      "PHONE_NUMBER",
      "HIRE_DATE",
      "JOB_ID" /*FK*/,
      "SALARY",
      "COMMISSION_PCT",
      "MANAGER_ID" /*FK*/,
      "DEPARTMENT_ID" /*FK*/ )
    VALUES (
      COALESCE( p_employee_id, "EMPLOYEES_SEQ".nextval ),
      p_first_name,
      p_last_name,
      p_email,
      p_phone_number,
      p_hire_date,
      p_job_id,
      p_salary,
      p_commission_pct,
      p_manager_id,
      p_department_id )
    RETURN
      "EMPLOYEE_ID" /*PK*/,
       "FIRST_NAME",
       "LAST_NAME",
       "EMAIL" /*UK*/,
       "PHONE_NUMBER",
       "HIRE_DATE",
       "JOB_ID" /*FK*/,
       "SALARY",
       "COMMISSION_PCT",
       "MANAGER_ID" /*FK*/,
       "DEPARTMENT_ID" /*FK*/
    INTO v_return;
    create_change_log_entry (
      p_table     => 'EMPLOYEES',
      p_column    => 'EMPLOYEE_ID',
      p_pk_id     => v_return."EMPLOYEE_ID",
      p_old_value => 'ROW CREATED',
      p_new_value => 'ROW CREATED' );
    RETURN v_return;
  END create_row;

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
    p_department_id  IN "EMPLOYEES"."DEPARTMENT_ID"%TYPE  DEFAULT NULL /*FK*/ )
  IS
    v_return "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_return := create_row (
      p_employee_id    => p_employee_id /*PK*/,
      p_first_name     => p_first_name,
      p_last_name      => p_last_name,
      p_email          => p_email /*UK*/,
      p_phone_number   => p_phone_number,
      p_hire_date      => p_hire_date,
      p_job_id         => p_job_id /*FK*/,
      p_salary         => p_salary,
      p_commission_pct => p_commission_pct,
      p_manager_id     => p_manager_id /*FK*/,
      p_department_id  => p_department_id /*FK*/ );
  END create_row;

  FUNCTION create_row (
    p_row            IN "EMPLOYEES"%ROWTYPE )
  RETURN "EMPLOYEES"%ROWTYPE IS
    v_return "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_return := create_row (
      p_employee_id    => p_row."EMPLOYEE_ID" /*PK*/,
      p_first_name     => p_row."FIRST_NAME",
      p_last_name      => p_row."LAST_NAME",
      p_email          => p_row."EMAIL" /*UK*/,
      p_phone_number   => p_row."PHONE_NUMBER",
      p_hire_date      => p_row."HIRE_DATE",
      p_job_id         => p_row."JOB_ID" /*FK*/,
      p_salary         => p_row."SALARY",
      p_commission_pct => p_row."COMMISSION_PCT",
      p_manager_id     => p_row."MANAGER_ID" /*FK*/,
      p_department_id  => p_row."DEPARTMENT_ID" /*FK*/ );
    RETURN v_return;
  END create_row;

  PROCEDURE create_row (
    p_row            IN "EMPLOYEES"%ROWTYPE )
  IS
    v_return "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_return := create_row (
      p_employee_id    => p_row."EMPLOYEE_ID" /*PK*/,
      p_first_name     => p_row."FIRST_NAME",
      p_last_name      => p_row."LAST_NAME",
      p_email          => p_row."EMAIL" /*UK*/,
      p_phone_number   => p_row."PHONE_NUMBER",
      p_hire_date      => p_row."HIRE_DATE",
      p_job_id         => p_row."JOB_ID" /*FK*/,
      p_salary         => p_row."SALARY",
      p_commission_pct => p_row."COMMISSION_PCT",
      p_manager_id     => p_row."MANAGER_ID" /*FK*/,
      p_department_id  => p_row."DEPARTMENT_ID" /*FK*/ );
  END create_row;

  FUNCTION create_rows(p_rows_tab IN t_rows_tab)
    RETURN t_rows_tab IS
    v_return t_rows_tab;
  BEGIN
    v_return := p_rows_tab;

    FOR i IN 1 .. v_return.COUNT
    LOOP
      v_return(i)."EMPLOYEE_ID" := COALESCE(v_return(i)."EMPLOYEE_ID", "EMPLOYEES_SEQ".NEXTVAL);
    END LOOP;

    FORALL i IN INDICES OF p_rows_tab
      INSERT INTO "EMPLOYEES" (
      "EMPLOYEE_ID" /*PK*/,
      "FIRST_NAME",
      "LAST_NAME",
      "EMAIL" /*UK*/,
      "PHONE_NUMBER",
      "HIRE_DATE",
      "JOB_ID" /*FK*/,
      "SALARY",
      "COMMISSION_PCT",
      "MANAGER_ID" /*FK*/,
      "DEPARTMENT_ID" /*FK*/ )
      VALUES (
      v_return(i)."EMPLOYEE_ID",
        v_return(i)."FIRST_NAME",
        v_return(i)."LAST_NAME",
        v_return(i)."EMAIL",
        v_return(i)."PHONE_NUMBER",
        v_return(i)."HIRE_DATE",
        v_return(i)."JOB_ID",
        v_return(i)."SALARY",
        v_return(i)."COMMISSION_PCT",
        v_return(i)."MANAGER_ID",
        v_return(i)."DEPARTMENT_ID" );

    RETURN v_return;
  END create_rows;

  PROCEDURE create_rows(p_rows_tab IN t_rows_tab)
  IS
    v_return t_rows_tab;
  BEGIN
    v_return := create_rows(p_rows_tab => p_rows_tab);
  END create_rows;

  FUNCTION read_row (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"%ROWTYPE IS
    v_row "EMPLOYEES"%ROWTYPE;
    CURSOR cur_row IS
      SELECT *
        FROM "EMPLOYEES"
       WHERE "EMPLOYEE_ID" = p_employee_id;
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_row;
    CLOSE cur_row;
    RETURN v_row;
  END read_row;

  FUNCTION read_row (
    p_email          IN "EMPLOYEES"."EMAIL"%TYPE /*UK*/ )
  RETURN "EMPLOYEES"%ROWTYPE IS
    v_row "EMPLOYEES"%ROWTYPE;
    CURSOR cur_row IS
      SELECT *
        FROM "EMPLOYEES"
       WHERE "EMAIL" = p_email;
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_row;
    CLOSE cur_row;
    RETURN v_row;
  END;

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
  IS
    v_row   "EMPLOYEES"%ROWTYPE;
    v_count PLS_INTEGER := 0;
  BEGIN
    IF row_exists ( p_employee_id => p_employee_id ) THEN
      v_row := read_row ( p_employee_id => p_employee_id );
      -- update only, if the column values really differ
      IF COALESCE(v_row."FIRST_NAME", '@@@@@@@@@@@@@@@') <> COALESCE(p_first_name, '@@@@@@@@@@@@@@@') THEN
        v_count := v_count + 1;
        create_change_log_entry (
          p_table     => 'EMPLOYEES',
          p_column    => 'FIRST_NAME',
          p_pk_id     => v_row."EMPLOYEE_ID",
          p_old_value => substr(v_row."FIRST_NAME",1,4000),
          p_new_value => substr(p_first_name,1,4000) );
      END IF;
      IF v_row."LAST_NAME" <> p_last_name THEN
        v_count := v_count + 1;
        create_change_log_entry (
          p_table     => 'EMPLOYEES',
          p_column    => 'LAST_NAME',
          p_pk_id     => v_row."EMPLOYEE_ID",
          p_old_value => substr(v_row."LAST_NAME",1,4000),
          p_new_value => substr(p_last_name,1,4000) );
      END IF;
      IF v_row."EMAIL" <> p_email THEN
        v_count := v_count + 1;
        create_change_log_entry (
          p_table     => 'EMPLOYEES',
          p_column    => 'EMAIL',
          p_pk_id     => v_row."EMPLOYEE_ID",
          p_old_value => substr(v_row."EMAIL",1,4000),
          p_new_value => substr(p_email,1,4000) );
      END IF;
      IF COALESCE(v_row."PHONE_NUMBER", '@@@@@@@@@@@@@@@') <> COALESCE(p_phone_number, '@@@@@@@@@@@@@@@') THEN
        v_count := v_count + 1;
        create_change_log_entry (
          p_table     => 'EMPLOYEES',
          p_column    => 'PHONE_NUMBER',
          p_pk_id     => v_row."EMPLOYEE_ID",
          p_old_value => substr(v_row."PHONE_NUMBER",1,4000),
          p_new_value => substr(p_phone_number,1,4000) );
      END IF;
      IF v_row."HIRE_DATE" <> p_hire_date THEN
        v_count := v_count + 1;
        create_change_log_entry (
          p_table     => 'EMPLOYEES',
          p_column    => 'HIRE_DATE',
          p_pk_id     => v_row."EMPLOYEE_ID",
          p_old_value => to_char(v_row."HIRE_DATE",'yyyy.mm.dd hh24:mi:ss'),
          p_new_value => to_char(p_hire_date,'yyyy.mm.dd hh24:mi:ss') );
      END IF;
      IF v_row."JOB_ID" <> p_job_id THEN
        v_count := v_count + 1;
        create_change_log_entry (
          p_table     => 'EMPLOYEES',
          p_column    => 'JOB_ID',
          p_pk_id     => v_row."EMPLOYEE_ID",
          p_old_value => substr(v_row."JOB_ID",1,4000),
          p_new_value => substr(p_job_id,1,4000) );
      END IF;
      IF COALESCE(v_row."SALARY", -999999999999999.999999999999999) <> COALESCE(p_salary, -999999999999999.999999999999999) THEN
        v_count := v_count + 1;
        create_change_log_entry (
          p_table     => 'EMPLOYEES',
          p_column    => 'SALARY',
          p_pk_id     => v_row."EMPLOYEE_ID",
          p_old_value => to_char(v_row."SALARY"),
          p_new_value => to_char(p_salary) );
      END IF;
      IF COALESCE(v_row."COMMISSION_PCT", -999999999999999.999999999999999) <> COALESCE(p_commission_pct, -999999999999999.999999999999999) THEN
        v_count := v_count + 1;
        create_change_log_entry (
          p_table     => 'EMPLOYEES',
          p_column    => 'COMMISSION_PCT',
          p_pk_id     => v_row."EMPLOYEE_ID",
          p_old_value => to_char(v_row."COMMISSION_PCT"),
          p_new_value => to_char(p_commission_pct) );
      END IF;
      IF COALESCE(v_row."MANAGER_ID", -999999999999999.999999999999999) <> COALESCE(p_manager_id, -999999999999999.999999999999999) THEN
        v_count := v_count + 1;
        create_change_log_entry (
          p_table     => 'EMPLOYEES',
          p_column    => 'MANAGER_ID',
          p_pk_id     => v_row."EMPLOYEE_ID",
          p_old_value => to_char(v_row."MANAGER_ID"),
          p_new_value => to_char(p_manager_id) );
      END IF;
      IF COALESCE(v_row."DEPARTMENT_ID", -999999999999999.999999999999999) <> COALESCE(p_department_id, -999999999999999.999999999999999) THEN
        v_count := v_count + 1;
        create_change_log_entry (
          p_table     => 'EMPLOYEES',
          p_column    => 'DEPARTMENT_ID',
          p_pk_id     => v_row."EMPLOYEE_ID",
          p_old_value => to_char(v_row."DEPARTMENT_ID"),
          p_new_value => to_char(p_department_id) );
      END IF;
      IF v_count > 0
      THEN
        UPDATE EMPLOYEES
           SET "FIRST_NAME"     = p_first_name,
               "LAST_NAME"      = p_last_name,
               "EMAIL"          = p_email /*UK*/,
               "PHONE_NUMBER"   = p_phone_number,
               "HIRE_DATE"      = p_hire_date,
               "JOB_ID"         = p_job_id /*FK*/,
               "SALARY"         = p_salary,
               "COMMISSION_PCT" = p_commission_pct,
               "MANAGER_ID"     = p_manager_id /*FK*/,
               "DEPARTMENT_ID"  = p_department_id /*FK*/
         WHERE "EMPLOYEE_ID" = p_employee_id;
      END IF;
    END IF;
  END update_row;

  PROCEDURE update_row (
    p_row            IN "EMPLOYEES"%ROWTYPE )
  IS
  BEGIN
    update_row(
      p_employee_id    => p_row."EMPLOYEE_ID" /*PK*/,
      p_first_name     => p_row."FIRST_NAME",
      p_last_name      => p_row."LAST_NAME",
      p_email          => p_row."EMAIL" /*UK*/,
      p_phone_number   => p_row."PHONE_NUMBER",
      p_hire_date      => p_row."HIRE_DATE",
      p_job_id         => p_row."JOB_ID" /*FK*/,
      p_salary         => p_row."SALARY",
      p_commission_pct => p_row."COMMISSION_PCT",
      p_manager_id     => p_row."MANAGER_ID" /*FK*/,
      p_department_id  => p_row."DEPARTMENT_ID" /*FK*/ );
  END update_row;

  PROCEDURE update_rows(p_rows_tab IN t_rows_tab)
  IS
  BEGIN
    FORALL i IN INDICES OF p_rows_tab
        UPDATE EMPLOYEES
           SET "FIRST_NAME"     = p_rows_tab(i)."FIRST_NAME",
               "LAST_NAME"      = p_rows_tab(i)."LAST_NAME",
               "EMAIL"          = p_rows_tab(i)."EMAIL" /*UK*/,
               "PHONE_NUMBER"   = p_rows_tab(i)."PHONE_NUMBER",
               "HIRE_DATE"      = p_rows_tab(i)."HIRE_DATE",
               "JOB_ID"         = p_rows_tab(i)."JOB_ID" /*FK*/,
               "SALARY"         = p_rows_tab(i)."SALARY",
               "COMMISSION_PCT" = p_rows_tab(i)."COMMISSION_PCT",
               "MANAGER_ID"     = p_rows_tab(i)."MANAGER_ID" /*FK*/,
               "DEPARTMENT_ID"  = p_rows_tab(i)."DEPARTMENT_ID" /*FK*/
         WHERE "EMPLOYEE_ID" = p_rows_tab(i)."EMPLOYEE_ID";
  END update_rows;

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
  RETURN "EMPLOYEES"%ROWTYPE IS
    v_return "EMPLOYEES"%ROWTYPE;
  BEGIN
    IF row_exists( p_employee_id => p_employee_id ) THEN
      update_row(
        p_employee_id    => p_employee_id /*PK*/,
        p_first_name     => p_first_name,
        p_last_name      => p_last_name,
        p_email          => p_email /*UK*/,
        p_phone_number   => p_phone_number,
        p_hire_date      => p_hire_date,
        p_job_id         => p_job_id /*FK*/,
        p_salary         => p_salary,
        p_commission_pct => p_commission_pct,
        p_manager_id     => p_manager_id /*FK*/,
        p_department_id  => p_department_id /*FK*/ );
      v_return := read_row ( p_employee_id => p_employee_id );
    ELSE
      v_return := create_row (
        p_employee_id    => p_employee_id /*PK*/,
        p_first_name     => p_first_name,
        p_last_name      => p_last_name,
        p_email          => p_email /*UK*/,
        p_phone_number   => p_phone_number,
        p_hire_date      => p_hire_date,
        p_job_id         => p_job_id /*FK*/,
        p_salary         => p_salary,
        p_commission_pct => p_commission_pct,
        p_manager_id     => p_manager_id /*FK*/,
        p_department_id  => p_department_id /*FK*/ );
    END IF;
    RETURN v_return;
  END create_or_update_row;

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
    p_department_id  IN "EMPLOYEES"."DEPARTMENT_ID"%TYPE /*FK*/ )
  IS
    v_return "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_return := create_or_update_row(
      p_employee_id    => p_employee_id /*PK*/,
      p_first_name     => p_first_name,
      p_last_name      => p_last_name,
      p_email          => p_email /*UK*/,
      p_phone_number   => p_phone_number,
      p_hire_date      => p_hire_date,
      p_job_id         => p_job_id /*FK*/,
      p_salary         => p_salary,
      p_commission_pct => p_commission_pct,
      p_manager_id     => p_manager_id /*FK*/,
      p_department_id  => p_department_id /*FK*/ );
  END create_or_update_row;

  FUNCTION create_or_update_row (
    p_row            IN "EMPLOYEES"%ROWTYPE )
  RETURN "EMPLOYEES"%ROWTYPE IS
    v_return "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_return := create_or_update_row(
      p_employee_id    => p_row."EMPLOYEE_ID" /*PK*/,
      p_first_name     => p_row."FIRST_NAME",
      p_last_name      => p_row."LAST_NAME",
      p_email          => p_row."EMAIL" /*UK*/,
      p_phone_number   => p_row."PHONE_NUMBER",
      p_hire_date      => p_row."HIRE_DATE",
      p_job_id         => p_row."JOB_ID" /*FK*/,
      p_salary         => p_row."SALARY",
      p_commission_pct => p_row."COMMISSION_PCT",
      p_manager_id     => p_row."MANAGER_ID" /*FK*/,
      p_department_id  => p_row."DEPARTMENT_ID" /*FK*/ );
    RETURN v_return;
  END create_or_update_row;

  PROCEDURE create_or_update_row (
    p_row            IN "EMPLOYEES"%ROWTYPE )
  IS
    v_return "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_return := create_or_update_row(
      p_employee_id    => p_row."EMPLOYEE_ID" /*PK*/,
      p_first_name     => p_row."FIRST_NAME",
      p_last_name      => p_row."LAST_NAME",
      p_email          => p_row."EMAIL" /*UK*/,
      p_phone_number   => p_row."PHONE_NUMBER",
      p_hire_date      => p_row."HIRE_DATE",
      p_job_id         => p_row."JOB_ID" /*FK*/,
      p_salary         => p_row."SALARY",
      p_commission_pct => p_row."COMMISSION_PCT",
      p_manager_id     => p_row."MANAGER_ID" /*FK*/,
      p_department_id  => p_row."DEPARTMENT_ID" /*FK*/ );
  END create_or_update_row;

  FUNCTION get_a_row
  RETURN "EMPLOYEES"%ROWTYPE IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_row."EMPLOYEE_ID"    := "EMPLOYEES_SEQ".nextval /*PK*/;
    v_row."FIRST_NAME"     := substr(sys_guid(),1,20);
    v_row."LAST_NAME"      := substr(sys_guid(),1,25);
    v_row."EMAIL"          := substr(sys_guid(),1,15) || '@dummy.com' /*UK*/;
    v_row."PHONE_NUMBER"   := substr('+1.' || lpad(to_char(trunc(dbms_random.value(1,999))),3,'0') || '.' || lpad(to_char(trunc(dbms_random.value(1,999))),3,'0') || '.' || lpad(to_char(trunc(dbms_random.value(1,9999))),4,'0'),1,20);
    v_row."HIRE_DATE"      := to_date(trunc(dbms_random.value(to_char(date'1900-01-01','j'),to_char(date'2099-12-31','j'))),'j');
    v_row."JOB_ID"         := '3A8CAB7373' /*FK*/;
    v_row."SALARY"         := round(dbms_random.value(1000,10000),2);
    v_row."COMMISSION_PCT" := round(dbms_random.value(0,.99),2);
    v_row."MANAGER_ID"     := 100 /*FK*/;
    v_row."DEPARTMENT_ID"  := 10 /*FK*/;
    return v_row;
  END get_a_row;

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
  RETURN "EMPLOYEES"%ROWTYPE IS
    v_return "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_return := create_row (
      p_employee_id    => p_employee_id /*PK*/,
      p_first_name     => p_first_name,
      p_last_name      => p_last_name,
      p_email          => p_email /*UK*/,
      p_phone_number   => p_phone_number,
      p_hire_date      => p_hire_date,
      p_job_id         => p_job_id /*FK*/,
      p_salary         => p_salary,
      p_commission_pct => p_commission_pct,
      p_manager_id     => p_manager_id /*FK*/,
      p_department_id  => p_department_id /*FK*/ );
    RETURN v_return;
  END create_a_row;

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
    p_department_id  IN "EMPLOYEES"."DEPARTMENT_ID"%TYPE  DEFAULT get_a_row()."DEPARTMENT_ID" /*FK*/ )
  IS
    v_return "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_return := create_row (
      p_employee_id    => p_employee_id /*PK*/,
      p_first_name     => p_first_name,
      p_last_name      => p_last_name,
      p_email          => p_email /*UK*/,
      p_phone_number   => p_phone_number,
      p_hire_date      => p_hire_date,
      p_job_id         => p_job_id /*FK*/,
      p_salary         => p_salary,
      p_commission_pct => p_commission_pct,
      p_manager_id     => p_manager_id /*FK*/,
      p_department_id  => p_department_id /*FK*/ );
  END create_a_row;

  FUNCTION read_a_row
  RETURN "EMPLOYEES"%ROWTYPE IS
    v_row  "EMPLOYEES"%ROWTYPE;
    CURSOR cur_row IS SELECT * FROM EMPLOYEES;
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_row;
    CLOSE cur_row;
    RETURN v_row;
  END read_a_row;

END "EMPLOYEES_API";
/

