# Example API

This is an example API for the Oracle demo table HR.EMPLOYEES. You can find the complete demo schema [here](https://github.com/oracle/db-sample-schemas).

This API was generated with the following code:

```sql
BEGIN
    om_tapigen.compile_api(p_table_name => 'EMPLOYEES');
    --> for all options see README in project root
END;
```

## Table Structure

```sql
CREATE TABLE "HR"."EMPLOYEES" (
    "EMPLOYEE_ID"      NUMBER(6,0),
    "FIRST_NAME"       VARCHAR2(20 BYTE),
    "LAST_NAME"        VARCHAR2(25 BYTE)
        CONSTRAINT "EMP_LAST_NAME_NN" NOT NULL ENABLE,
    "EMAIL"            VARCHAR2(25 BYTE)
        CONSTRAINT "EMP_EMAIL_NN" NOT NULL ENABLE,
    "PHONE_NUMBER"     VARCHAR2(20 BYTE),
    "HIRE_DATE"        DATE
        CONSTRAINT "EMP_HIRE_DATE_NN" NOT NULL ENABLE,
    "JOB_ID"           VARCHAR2(10 BYTE)
        CONSTRAINT "EMP_JOB_NN" NOT NULL ENABLE,
    "SALARY"           NUMBER(8,2),
    "COMMISSION_PCT"   NUMBER(2,2),
    "MANAGER_ID"       NUMBER(6,0),
    "DEPARTMENT_ID"    NUMBER(4,0),
    CONSTRAINT "EMP_SALARY_MIN" CHECK (
        salary > 0
    ) ENABLE,
    CONSTRAINT "EMP_EMAIL_UK" UNIQUE ( "EMAIL" ) ENABLE,
    CONSTRAINT "EMP_EMP_ID_PK" PRIMARY KEY ( "EMPLOYEE_ID" ) ENABLE,
    CONSTRAINT "EMP_DEPT_FK" FOREIGN KEY ( "DEPARTMENT_ID" )
        REFERENCES "HR"."DEPARTMENTS" ( "DEPARTMENT_ID" )
    ENABLE,
    CONSTRAINT "EMP_JOB_FK" FOREIGN KEY ( "JOB_ID" )
        REFERENCES "HR"."JOBS" ( "JOB_ID" )
    ENABLE,
    CONSTRAINT "EMP_MANAGER_FK" FOREIGN KEY ( "MANAGER_ID" )
        REFERENCES "HR"."EMPLOYEES" ( "EMPLOYEE_ID" )
    ENABLE
);
```

## Package Specification

```sql
CREATE OR REPLACE PACKAGE "HR"."EMPLOYEES_API" IS
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
    generated_at="2018-02-05 20:26:38"
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
    p_enable_dml_view="TRUE"
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
    <column source="TAPIGEN" name="EMPLOYEE_ID"><![CDATA["EMPLOYEES_SEQ".nextval]]></column>
    <column source="TAPIGEN" name="FIRST_NAME"><![CDATA[substr(sys_guid(),1,20)]]></column>
    <column source="TAPIGEN" name="LAST_NAME"><![CDATA[substr(sys_guid(),1,25)]]></column>
    <column source="TAPIGEN" name="EMAIL"><![CDATA[substr(sys_guid(),1,15) || '@dummy.com']]></column>
    <column source="TAPIGEN" name="PHONE_NUMBER"><![CDATA[substr('+1.' || lpad(to_char(trunc(dbms_random.value(1,999))),3,'0') || '.' || lpad(to_char(trunc(dbms_random.value(1,999))),3,'0') || '.' || lpad(to_char(trunc(dbms_random.value(1,9999))),4,'0'),1,20)]]></column>
    <column source="TAPIGEN" name="HIRE_DATE"><![CDATA[to_date(trunc(dbms_random.value(to_char(date'1900-01-01','j'),to_char(date'2099-12-31','j'))),'j')]]></column>
    <column source="TAPIGEN" name="JOB_ID"><![CDATA['AC_ACCOUNT']]></column>
    <column source="USER"    name="SALARY"><![CDATA[round(dbms_random.value(1000,10000),2)]]></column>
    <column source="TAPIGEN" name="COMMISSION_PCT"><![CDATA[round(dbms_random.value(0,.99),2)]]></column>
    <column source="TAPIGEN" name="MANAGER_ID"><![CDATA[100]]></column>
    <column source="TAPIGEN" name="DEPARTMENT_ID"><![CDATA[10]]></column>
  </custom_defaults>
  */
END "EMPLOYEES_API";
/
```


## Package body

```sql
CREATE OR REPLACE PACKAGE BODY "HR"."EMPLOYEES_API" IS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0_b4"
   * generator_action="COMPILE_API"
   * generated_at="2018-02-05 20:26:38"
   * generated_by="DECAF4"
   */

  FUNCTION row_exists (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN BOOLEAN
  IS
    v_return BOOLEAN := FALSE;
    v_dummy  PLS_INTEGER;
    CURSOR   cur_bool IS
      SELECT 1
        FROM "EMPLOYEES"
       WHERE COALESCE( "EMPLOYEE_ID",-999999999999999.999999999999999 ) = COALESCE( p_employee_id,-999999999999999.999999999999999 );
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
  RETURN "EMPLOYEES"."EMPLOYEE_ID"%TYPE IS
    v_return "EMPLOYEES"."EMPLOYEE_ID"%TYPE;
  BEGIN
    v_return := read_row ( p_email => p_email )."EMPLOYEE_ID";
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
  RETURN "EMPLOYEES"."EMPLOYEE_ID"%TYPE IS
    v_return "EMPLOYEES"."EMPLOYEE_ID"%TYPE;
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
      "EMPLOYEE_ID"
    INTO v_return;
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
    v_return "EMPLOYEES"."EMPLOYEE_ID"%TYPE;
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
  RETURN "EMPLOYEES"."EMPLOYEE_ID"%TYPE IS
    v_return "EMPLOYEES"."EMPLOYEE_ID"%TYPE;
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
    v_return "EMPLOYEES"."EMPLOYEE_ID"%TYPE;
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

  FUNCTION read_row (
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"%ROWTYPE IS
    v_row "EMPLOYEES"%ROWTYPE;
    CURSOR cur_row IS
      SELECT *
        FROM "EMPLOYEES"
       WHERE COALESCE( "EMPLOYEE_ID",-999999999999999.999999999999999 ) = COALESCE( p_employee_id,-999999999999999.999999999999999 );
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
       WHERE COALESCE( "EMAIL",'@@@@@@@@@@@@@@@' ) = COALESCE( p_email,'@@@@@@@@@@@@@@@' );
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_row;
    CLOSE cur_row;
    RETURN v_row;
  END;

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

  BEGIN
    IF row_exists ( p_employee_id => p_employee_id ) THEN
      v_row := read_row ( p_employee_id => p_employee_id );
      -- update only,if the column values really differ
      IF COALESCE( v_row."FIRST_NAME",'@@@@@@@@@@@@@@@' ) <> COALESCE( p_first_name,'@@@@@@@@@@@@@@@' )
      OR COALESCE( v_row."LAST_NAME",'@@@@@@@@@@@@@@@' ) <> COALESCE( p_last_name,'@@@@@@@@@@@@@@@' )
      OR COALESCE( v_row."EMAIL",'@@@@@@@@@@@@@@@' ) <> COALESCE( p_email,'@@@@@@@@@@@@@@@' )
      OR COALESCE( v_row."PHONE_NUMBER",'@@@@@@@@@@@@@@@' ) <> COALESCE( p_phone_number,'@@@@@@@@@@@@@@@' )
      OR COALESCE( v_row."HIRE_DATE",TO_DATE( '01.01.1900','DD.MM.YYYY' ) ) <> COALESCE( p_hire_date,TO_DATE( '01.01.1900','DD.MM.YYYY' ) )
      OR COALESCE( v_row."JOB_ID",'@@@@@@@@@@@@@@@' ) <> COALESCE( p_job_id,'@@@@@@@@@@@@@@@' )
      OR COALESCE( v_row."SALARY",-999999999999999.999999999999999 ) <> COALESCE( p_salary,-999999999999999.999999999999999 )
      OR COALESCE( v_row."COMMISSION_PCT",-999999999999999.999999999999999 ) <> COALESCE( p_commission_pct,-999999999999999.999999999999999 )
      OR COALESCE( v_row."MANAGER_ID",-999999999999999.999999999999999 ) <> COALESCE( p_manager_id,-999999999999999.999999999999999 )
      OR COALESCE( v_row."DEPARTMENT_ID",-999999999999999.999999999999999 ) <> COALESCE( p_department_id,-999999999999999.999999999999999 )

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
         WHERE COALESCE( "EMPLOYEE_ID",-999999999999999.999999999999999 ) = COALESCE( p_employee_id,-999999999999999.999999999999999 );
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
  RETURN "EMPLOYEES"."EMPLOYEE_ID"%TYPE IS
    v_return "EMPLOYEES"."EMPLOYEE_ID"%TYPE;
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
      v_return := read_row ( p_employee_id => p_employee_id )."EMPLOYEE_ID";
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
    v_return "EMPLOYEES"."EMPLOYEE_ID"%TYPE;
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
  RETURN "EMPLOYEES"."EMPLOYEE_ID"%TYPE IS
    v_return "EMPLOYEES"."EMPLOYEE_ID"%TYPE;
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
    v_return "EMPLOYEES"."EMPLOYEE_ID"%TYPE;
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
    v_row."JOB_ID"         := 'AC_ACCOUNT' /*FK*/;
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
  RETURN "EMPLOYEES"."EMPLOYEE_ID"%TYPE IS
    v_return "EMPLOYEES"."EMPLOYEE_ID"%TYPE;
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
    v_return "EMPLOYEES"."EMPLOYEE_ID"%TYPE;
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
```
