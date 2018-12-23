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
    generator_version="0.5.0"
    generator_action="GET_CODE"
    generated_at="2018-12-19 19:43:04"
    generated_by="OGOBRECHT"
    p_table_name="EMPLOYEES"
    p_owner="HR"
    p_reuse_existing_api_params="TRUE"
    p_enable_insertion_of_rows="TRUE"
    p_enable_column_defaults="FALSE"
    p_enable_update_of_rows="TRUE"
    p_enable_deletion_of_rows="FALSE"
    p_enable_parameter_prefixes="TRUE"
    p_enable_proc_with_out_params="TRUE"
    p_enable_getter_and_setter="TRUE"
    p_col_prefix_in_method_names="TRUE"
    p_return_row_instead_of_pk="FALSE"
    p_enable_dml_view="FALSE"
    p_enable_generic_change_log="FALSE"
    p_api_name="EMPLOYEES_API"
    p_sequence_name=""
    p_exclude_column_list=""
    p_enable_custom_defaults="FALSE"
    p_custom_default_values=""/>

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

  PROCEDURE create_row (
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

  PROCEDURE read_row (
    p_employee_id    IN            "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_first_name        OUT NOCOPY "EMPLOYEES"."FIRST_NAME"%TYPE,
    p_last_name         OUT NOCOPY "EMPLOYEES"."LAST_NAME"%TYPE,
    p_email             OUT NOCOPY "EMPLOYEES"."EMAIL"%TYPE /*UK*/,
    p_phone_number      OUT NOCOPY "EMPLOYEES"."PHONE_NUMBER"%TYPE,
    p_hire_date         OUT NOCOPY "EMPLOYEES"."HIRE_DATE"%TYPE,
    p_job_id            OUT NOCOPY "EMPLOYEES"."JOB_ID"%TYPE /*FK*/,
    p_salary            OUT NOCOPY "EMPLOYEES"."SALARY"%TYPE,
    p_commission_pct    OUT NOCOPY "EMPLOYEES"."COMMISSION_PCT"%TYPE,
    p_manager_id        OUT NOCOPY "EMPLOYEES"."MANAGER_ID"%TYPE /*FK*/,
    p_department_id     OUT NOCOPY "EMPLOYEES"."DEPARTMENT_ID"%TYPE /*FK*/ );

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

  FUNCTION get_first_name(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."FIRST_NAME"%TYPE;

  FUNCTION get_last_name(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."LAST_NAME"%TYPE;

  FUNCTION get_email(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."EMAIL"%TYPE;

  FUNCTION get_phone_number(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."PHONE_NUMBER"%TYPE;

  FUNCTION get_hire_date(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."HIRE_DATE"%TYPE;

  FUNCTION get_job_id(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."JOB_ID"%TYPE;

  FUNCTION get_salary(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."SALARY"%TYPE;

  FUNCTION get_commission_pct(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."COMMISSION_PCT"%TYPE;

  FUNCTION get_manager_id(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."MANAGER_ID"%TYPE;

  FUNCTION get_department_id(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."DEPARTMENT_ID"%TYPE;

  PROCEDURE set_first_name(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_first_name     IN "EMPLOYEES"."FIRST_NAME"%TYPE );

  PROCEDURE set_last_name(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_last_name      IN "EMPLOYEES"."LAST_NAME"%TYPE );

  PROCEDURE set_email(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_email          IN "EMPLOYEES"."EMAIL"%TYPE );

  PROCEDURE set_phone_number(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_phone_number   IN "EMPLOYEES"."PHONE_NUMBER"%TYPE );

  PROCEDURE set_hire_date(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_hire_date      IN "EMPLOYEES"."HIRE_DATE"%TYPE );

  PROCEDURE set_job_id(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_job_id         IN "EMPLOYEES"."JOB_ID"%TYPE );

  PROCEDURE set_salary(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_salary         IN "EMPLOYEES"."SALARY"%TYPE );

  PROCEDURE set_commission_pct(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_commission_pct IN "EMPLOYEES"."COMMISSION_PCT"%TYPE );

  PROCEDURE set_manager_id(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_manager_id     IN "EMPLOYEES"."MANAGER_ID"%TYPE );

  PROCEDURE set_department_id(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_department_id  IN "EMPLOYEES"."DEPARTMENT_ID"%TYPE );
END "EMPLOYEES_API";
/
```


## Package body

```sql
CREATE OR REPLACE PACKAGE BODY "HR"."EMPLOYEES_API" IS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0"
   * generator_action="GET_CODE"
   * generated_at="2018-12-19 19:43:04"
   * generated_by="OGOBRECHT"
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
  RETURN "EMPLOYEES"."EMPLOYEE_ID"%TYPE IS
    v_return "EMPLOYEES"."EMPLOYEE_ID"%TYPE;
  BEGIN
    v_return := read_row ( p_email => p_email )."EMPLOYEE_ID";
    RETURN v_return;
  END get_pk_by_unique_cols;

  FUNCTION create_row (
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
      p_employee_id,
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

  PROCEDURE read_row (
    p_employee_id    IN            "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_first_name        OUT NOCOPY "EMPLOYEES"."FIRST_NAME"%TYPE,
    p_last_name         OUT NOCOPY "EMPLOYEES"."LAST_NAME"%TYPE,
    p_email             OUT NOCOPY "EMPLOYEES"."EMAIL"%TYPE /*UK*/,
    p_phone_number      OUT NOCOPY "EMPLOYEES"."PHONE_NUMBER"%TYPE,
    p_hire_date         OUT NOCOPY "EMPLOYEES"."HIRE_DATE"%TYPE,
    p_job_id            OUT NOCOPY "EMPLOYEES"."JOB_ID"%TYPE /*FK*/,
    p_salary            OUT NOCOPY "EMPLOYEES"."SALARY"%TYPE,
    p_commission_pct    OUT NOCOPY "EMPLOYEES"."COMMISSION_PCT"%TYPE,
    p_manager_id        OUT NOCOPY "EMPLOYEES"."MANAGER_ID"%TYPE /*FK*/,
    p_department_id     OUT NOCOPY "EMPLOYEES"."DEPARTMENT_ID"%TYPE /*FK*/ )
  IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    IF row_exists( p_employee_id => p_employee_id ) THEN
      v_row := read_row ( p_employee_id => p_employee_id );
      p_first_name     := v_row."FIRST_NAME"; 
      p_last_name      := v_row."LAST_NAME"; 
      p_email          := v_row."EMAIL"; 
      p_phone_number   := v_row."PHONE_NUMBER"; 
      p_hire_date      := v_row."HIRE_DATE"; 
      p_job_id         := v_row."JOB_ID"; 
      p_salary         := v_row."SALARY"; 
      p_commission_pct := v_row."COMMISSION_PCT"; 
      p_manager_id     := v_row."MANAGER_ID"; 
      p_department_id  := v_row."DEPARTMENT_ID"; 
    END IF;
  END read_row;

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
      -- update only, if the column values really differ
      IF COALESCE(v_row."FIRST_NAME", '@@@@@@@@@@@@@@@') <> COALESCE(p_first_name, '@@@@@@@@@@@@@@@')
      OR v_row."LAST_NAME" <> p_last_name
      OR v_row."EMAIL" <> p_email
      OR COALESCE(v_row."PHONE_NUMBER", '@@@@@@@@@@@@@@@') <> COALESCE(p_phone_number, '@@@@@@@@@@@@@@@')
      OR v_row."HIRE_DATE" <> p_hire_date
      OR v_row."JOB_ID" <> p_job_id
      OR COALESCE(v_row."SALARY", -999999999999999.999999999999999) <> COALESCE(p_salary, -999999999999999.999999999999999)
      OR COALESCE(v_row."COMMISSION_PCT", -999999999999999.999999999999999) <> COALESCE(p_commission_pct, -999999999999999.999999999999999)
      OR COALESCE(v_row."MANAGER_ID", -999999999999999.999999999999999) <> COALESCE(p_manager_id, -999999999999999.999999999999999)
      OR COALESCE(v_row."DEPARTMENT_ID", -999999999999999.999999999999999) <> COALESCE(p_department_id, -999999999999999.999999999999999)

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

  FUNCTION get_first_name(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."FIRST_NAME"%TYPE IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_row := read_row ( p_employee_id => p_employee_id );
    RETURN v_row."FIRST_NAME";
  END get_first_name;

  FUNCTION get_last_name(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."LAST_NAME"%TYPE IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_row := read_row ( p_employee_id => p_employee_id );
    RETURN v_row."LAST_NAME";
  END get_last_name;

  FUNCTION get_email(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."EMAIL"%TYPE IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_row := read_row ( p_employee_id => p_employee_id );
    RETURN v_row."EMAIL";
  END get_email;

  FUNCTION get_phone_number(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."PHONE_NUMBER"%TYPE IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_row := read_row ( p_employee_id => p_employee_id );
    RETURN v_row."PHONE_NUMBER";
  END get_phone_number;

  FUNCTION get_hire_date(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."HIRE_DATE"%TYPE IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_row := read_row ( p_employee_id => p_employee_id );
    RETURN v_row."HIRE_DATE";
  END get_hire_date;

  FUNCTION get_job_id(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."JOB_ID"%TYPE IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_row := read_row ( p_employee_id => p_employee_id );
    RETURN v_row."JOB_ID";
  END get_job_id;

  FUNCTION get_salary(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."SALARY"%TYPE IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_row := read_row ( p_employee_id => p_employee_id );
    RETURN v_row."SALARY";
  END get_salary;

  FUNCTION get_commission_pct(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."COMMISSION_PCT"%TYPE IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_row := read_row ( p_employee_id => p_employee_id );
    RETURN v_row."COMMISSION_PCT";
  END get_commission_pct;

  FUNCTION get_manager_id(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."MANAGER_ID"%TYPE IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_row := read_row ( p_employee_id => p_employee_id );
    RETURN v_row."MANAGER_ID";
  END get_manager_id;

  FUNCTION get_department_id(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/ )
  RETURN "EMPLOYEES"."DEPARTMENT_ID"%TYPE IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_row := read_row ( p_employee_id => p_employee_id );
    RETURN v_row."DEPARTMENT_ID";
  END get_department_id;

  PROCEDURE set_first_name(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_first_name     IN "EMPLOYEES"."FIRST_NAME"%TYPE )
  IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    IF row_exists ( p_employee_id => p_employee_id ) THEN
      v_row := read_row ( p_employee_id => p_employee_id );
      -- update only,if the column value really differs
      IF COALESCE(v_row."FIRST_NAME", '@@@@@@@@@@@@@@@') <> COALESCE(p_first_name, '@@@@@@@@@@@@@@@') THEN
        UPDATE EMPLOYEES
           SET "FIRST_NAME" = p_first_name    
         WHERE "EMPLOYEE_ID" = p_employee_id;
      END IF;
    END IF;
  END set_first_name;

  PROCEDURE set_last_name(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_last_name      IN "EMPLOYEES"."LAST_NAME"%TYPE )
  IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    IF row_exists ( p_employee_id => p_employee_id ) THEN
      v_row := read_row ( p_employee_id => p_employee_id );
      -- update only,if the column value really differs
      IF v_row."LAST_NAME" <> p_last_name THEN
        UPDATE EMPLOYEES
           SET "LAST_NAME" = p_last_name     
         WHERE "EMPLOYEE_ID" = p_employee_id;
      END IF;
    END IF;
  END set_last_name;

  PROCEDURE set_email(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_email          IN "EMPLOYEES"."EMAIL"%TYPE )
  IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    IF row_exists ( p_employee_id => p_employee_id ) THEN
      v_row := read_row ( p_employee_id => p_employee_id );
      -- update only,if the column value really differs
      IF v_row."EMAIL" <> p_email THEN
        UPDATE EMPLOYEES
           SET "EMAIL" = p_email         
         WHERE "EMPLOYEE_ID" = p_employee_id;
      END IF;
    END IF;
  END set_email;

  PROCEDURE set_phone_number(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_phone_number   IN "EMPLOYEES"."PHONE_NUMBER"%TYPE )
  IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    IF row_exists ( p_employee_id => p_employee_id ) THEN
      v_row := read_row ( p_employee_id => p_employee_id );
      -- update only,if the column value really differs
      IF COALESCE(v_row."PHONE_NUMBER", '@@@@@@@@@@@@@@@') <> COALESCE(p_phone_number, '@@@@@@@@@@@@@@@') THEN
        UPDATE EMPLOYEES
           SET "PHONE_NUMBER" = p_phone_number  
         WHERE "EMPLOYEE_ID" = p_employee_id;
      END IF;
    END IF;
  END set_phone_number;

  PROCEDURE set_hire_date(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_hire_date      IN "EMPLOYEES"."HIRE_DATE"%TYPE )
  IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    IF row_exists ( p_employee_id => p_employee_id ) THEN
      v_row := read_row ( p_employee_id => p_employee_id );
      -- update only,if the column value really differs
      IF v_row."HIRE_DATE" <> p_hire_date THEN
        UPDATE EMPLOYEES
           SET "HIRE_DATE" = p_hire_date     
         WHERE "EMPLOYEE_ID" = p_employee_id;
      END IF;
    END IF;
  END set_hire_date;

  PROCEDURE set_job_id(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_job_id         IN "EMPLOYEES"."JOB_ID"%TYPE )
  IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    IF row_exists ( p_employee_id => p_employee_id ) THEN
      v_row := read_row ( p_employee_id => p_employee_id );
      -- update only,if the column value really differs
      IF v_row."JOB_ID" <> p_job_id THEN
        UPDATE EMPLOYEES
           SET "JOB_ID" = p_job_id        
         WHERE "EMPLOYEE_ID" = p_employee_id;
      END IF;
    END IF;
  END set_job_id;

  PROCEDURE set_salary(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_salary         IN "EMPLOYEES"."SALARY"%TYPE )
  IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    IF row_exists ( p_employee_id => p_employee_id ) THEN
      v_row := read_row ( p_employee_id => p_employee_id );
      -- update only,if the column value really differs
      IF COALESCE(v_row."SALARY", -999999999999999.999999999999999) <> COALESCE(p_salary, -999999999999999.999999999999999) THEN
        UPDATE EMPLOYEES
           SET "SALARY" = p_salary        
         WHERE "EMPLOYEE_ID" = p_employee_id;
      END IF;
    END IF;
  END set_salary;

  PROCEDURE set_commission_pct(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_commission_pct IN "EMPLOYEES"."COMMISSION_PCT"%TYPE )
  IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    IF row_exists ( p_employee_id => p_employee_id ) THEN
      v_row := read_row ( p_employee_id => p_employee_id );
      -- update only,if the column value really differs
      IF COALESCE(v_row."COMMISSION_PCT", -999999999999999.999999999999999) <> COALESCE(p_commission_pct, -999999999999999.999999999999999) THEN
        UPDATE EMPLOYEES
           SET "COMMISSION_PCT" = p_commission_pct
         WHERE "EMPLOYEE_ID" = p_employee_id;
      END IF;
    END IF;
  END set_commission_pct;

  PROCEDURE set_manager_id(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_manager_id     IN "EMPLOYEES"."MANAGER_ID"%TYPE )
  IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    IF row_exists ( p_employee_id => p_employee_id ) THEN
      v_row := read_row ( p_employee_id => p_employee_id );
      -- update only,if the column value really differs
      IF COALESCE(v_row."MANAGER_ID", -999999999999999.999999999999999) <> COALESCE(p_manager_id, -999999999999999.999999999999999) THEN
        UPDATE EMPLOYEES
           SET "MANAGER_ID" = p_manager_id    
         WHERE "EMPLOYEE_ID" = p_employee_id;
      END IF;
    END IF;
  END set_manager_id;

  PROCEDURE set_department_id(
    p_employee_id    IN "EMPLOYEES"."EMPLOYEE_ID"%TYPE /*PK*/,
    p_department_id  IN "EMPLOYEES"."DEPARTMENT_ID"%TYPE )
  IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    IF row_exists ( p_employee_id => p_employee_id ) THEN
      v_row := read_row ( p_employee_id => p_employee_id );
      -- update only,if the column value really differs
      IF COALESCE(v_row."DEPARTMENT_ID", -999999999999999.999999999999999) <> COALESCE(p_department_id, -999999999999999.999999999999999) THEN
        UPDATE EMPLOYEES
           SET "DEPARTMENT_ID" = p_department_id 
         WHERE "EMPLOYEE_ID" = p_employee_id;
      END IF;
    END IF;
  END set_department_id;

END "EMPLOYEES_API";
/
```
