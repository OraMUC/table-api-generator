# Example API

This is an example API for the Oracle demo table HR.EMPLOYEES. You can find the complete demo schema [here](https://github.com/oracle/db-sample-schemas).

This API was generated with the following code - we assume that the om_tapigen is installed locally. It could also be installed in a central tools schema depending on your needs:

```sql
BEGIN
    hr.om_tapigen.compile_api(
        p_table_name                   => 'EMPLOYEES',
        p_reuse_existing_api_params    => true,
        p_col_prefix_in_method_names   => true,
        p_enable_insertion_of_rows     => true,
        p_enable_update_of_rows        => true,
        p_enable_deletion_of_rows      => false,
        p_enable_generic_change_log    => false,
        p_enable_dml_view              => false,
        p_sequence_name                => 'EMPLOYEES_SEQ'
    );
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
create or replace PACKAGE EMPLOYEES_api IS
  /**
   * This is the API for the table EMPLOYEES.
   *
   * GENERATION OPTIONS
   * - must be in the lines 5-25 to be reusable by the generator
   * - DO NOT TOUCH THIS until you know what you do - read the
   *   docs under github.com/OraMUC/table-api-generator ;-)
   * <options
   *   generator="OM_TAPIGEN"
   *   generator_version="0.4.1"
   *   generator_action="COMPILE_API"
   *   generated_at="2017-05-27 20:56:42"
   *   generated_by="OGOBRECHT"
   *   p_table_name="EMPLOYEES"
   *   p_reuse_existing_api_params="TRUE"
   *   p_col_prefix_in_method_names="TRUE"
   *   p_enable_insertion_of_rows="TRUE"
   *   p_enable_update_of_rows="TRUE"
   *   p_enable_deletion_of_rows="FALSE"
   *   p_enable_generic_change_log="FALSE"
   *   p_enable_dml_view="FALSE"
   *   p_sequence_name="EMPLOYEES_SEQ"/>
   *
   * This API provides DML functionality that can be easily called from APEX.   
   * Target of the table API is to encapsulate the table DML source code for  
   * security (UI schema needs only the execute right for the API and the
   * read/write right for the EMPLOYEES_dml_v, tables can be hidden in
   * extra data schema) and easy readability of the business logic (all DML is  
   * then written in the same style). For APEX automatic row processing like
   * tabular forms you can optionally use the EMPLOYEES_dml_v, which has
   * an instead of trigger who is also calling the EMPLOYEES_api.
   */
  ----------------------------------------
  FUNCTION row_exists( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN BOOLEAN;
  ----------------------------------------
  FUNCTION row_exists_yn( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN VARCHAR2;
  ----------------------------------------
  FUNCTION get_pk_by_unique_cols( p_EMAIL EMPLOYEES."EMAIL"%TYPE )
  RETURN EMPLOYEES."EMPLOYEE_ID"%TYPE;
  ----------------------------------------
  FUNCTION create_row( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE DEFAULT NULL, p_FIRST_NAME IN EMPLOYEES."FIRST_NAME"%TYPE, p_LAST_NAME IN EMPLOYEES."LAST_NAME"%TYPE, p_EMAIL IN EMPLOYEES."EMAIL"%TYPE, p_PHONE_NUMBER IN EMPLOYEES."PHONE_NUMBER"%TYPE, p_HIRE_DATE IN EMPLOYEES."HIRE_DATE"%TYPE, p_JOB_ID IN EMPLOYEES."JOB_ID"%TYPE, p_SALARY IN EMPLOYEES."SALARY"%TYPE, p_COMMISSION_PCT IN EMPLOYEES."COMMISSION_PCT"%TYPE, p_MANAGER_ID IN EMPLOYEES."MANAGER_ID"%TYPE, p_DEPARTMENT_ID IN EMPLOYEES."DEPARTMENT_ID"%TYPE )
  RETURN EMPLOYEES."EMPLOYEE_ID"%TYPE;
  ----------------------------------------
  PROCEDURE create_row( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE DEFAULT NULL, p_FIRST_NAME IN EMPLOYEES."FIRST_NAME"%TYPE, p_LAST_NAME IN EMPLOYEES."LAST_NAME"%TYPE, p_EMAIL IN EMPLOYEES."EMAIL"%TYPE, p_PHONE_NUMBER IN EMPLOYEES."PHONE_NUMBER"%TYPE, p_HIRE_DATE IN EMPLOYEES."HIRE_DATE"%TYPE, p_JOB_ID IN EMPLOYEES."JOB_ID"%TYPE, p_SALARY IN EMPLOYEES."SALARY"%TYPE, p_COMMISSION_PCT IN EMPLOYEES."COMMISSION_PCT"%TYPE, p_MANAGER_ID IN EMPLOYEES."MANAGER_ID"%TYPE, p_DEPARTMENT_ID IN EMPLOYEES."DEPARTMENT_ID"%TYPE );
  ----------------------------------------
  FUNCTION create_row( p_row IN EMPLOYEES%ROWTYPE )
  RETURN EMPLOYEES."EMPLOYEE_ID"%TYPE;
  ----------------------------------------
  PROCEDURE create_row( p_row IN EMPLOYEES%ROWTYPE );
  ----------------------------------------
  FUNCTION read_row( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES%ROWTYPE;
  ----------------------------------------
  PROCEDURE read_row( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_FIRST_NAME OUT NOCOPY EMPLOYEES."FIRST_NAME"%TYPE, p_LAST_NAME OUT NOCOPY EMPLOYEES."LAST_NAME"%TYPE, p_EMAIL OUT NOCOPY EMPLOYEES."EMAIL"%TYPE, p_PHONE_NUMBER OUT NOCOPY EMPLOYEES."PHONE_NUMBER"%TYPE, p_HIRE_DATE OUT NOCOPY EMPLOYEES."HIRE_DATE"%TYPE, p_JOB_ID OUT NOCOPY EMPLOYEES."JOB_ID"%TYPE, p_SALARY OUT NOCOPY EMPLOYEES."SALARY"%TYPE, p_COMMISSION_PCT OUT NOCOPY EMPLOYEES."COMMISSION_PCT"%TYPE, p_MANAGER_ID OUT NOCOPY EMPLOYEES."MANAGER_ID"%TYPE, p_DEPARTMENT_ID OUT NOCOPY EMPLOYEES."DEPARTMENT_ID"%TYPE );
  ----------------------------------------
  FUNCTION read_row( p_EMAIL EMPLOYEES."EMAIL"%TYPE )
  RETURN EMPLOYEES%ROWTYPE;
  ----------------------------------------
  PROCEDURE update_row( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE DEFAULT NULL, p_FIRST_NAME IN EMPLOYEES."FIRST_NAME"%TYPE, p_LAST_NAME IN EMPLOYEES."LAST_NAME"%TYPE, p_EMAIL IN EMPLOYEES."EMAIL"%TYPE, p_PHONE_NUMBER IN EMPLOYEES."PHONE_NUMBER"%TYPE, p_HIRE_DATE IN EMPLOYEES."HIRE_DATE"%TYPE, p_JOB_ID IN EMPLOYEES."JOB_ID"%TYPE, p_SALARY IN EMPLOYEES."SALARY"%TYPE, p_COMMISSION_PCT IN EMPLOYEES."COMMISSION_PCT"%TYPE, p_MANAGER_ID IN EMPLOYEES."MANAGER_ID"%TYPE, p_DEPARTMENT_ID IN EMPLOYEES."DEPARTMENT_ID"%TYPE );
  ----------------------------------------
  PROCEDURE update_row( p_row IN EMPLOYEES%ROWTYPE );
  ----------------------------------------
  FUNCTION create_or_update_row( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE DEFAULT NULL, p_FIRST_NAME IN EMPLOYEES."FIRST_NAME"%TYPE, p_LAST_NAME IN EMPLOYEES."LAST_NAME"%TYPE, p_EMAIL IN EMPLOYEES."EMAIL"%TYPE, p_PHONE_NUMBER IN EMPLOYEES."PHONE_NUMBER"%TYPE, p_HIRE_DATE IN EMPLOYEES."HIRE_DATE"%TYPE, p_JOB_ID IN EMPLOYEES."JOB_ID"%TYPE, p_SALARY IN EMPLOYEES."SALARY"%TYPE, p_COMMISSION_PCT IN EMPLOYEES."COMMISSION_PCT"%TYPE, p_MANAGER_ID IN EMPLOYEES."MANAGER_ID"%TYPE, p_DEPARTMENT_ID IN EMPLOYEES."DEPARTMENT_ID"%TYPE )
  RETURN EMPLOYEES."EMPLOYEE_ID"%TYPE;
  ----------------------------------------
  PROCEDURE create_or_update_row( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE DEFAULT NULL, p_FIRST_NAME IN EMPLOYEES."FIRST_NAME"%TYPE, p_LAST_NAME IN EMPLOYEES."LAST_NAME"%TYPE, p_EMAIL IN EMPLOYEES."EMAIL"%TYPE, p_PHONE_NUMBER IN EMPLOYEES."PHONE_NUMBER"%TYPE, p_HIRE_DATE IN EMPLOYEES."HIRE_DATE"%TYPE, p_JOB_ID IN EMPLOYEES."JOB_ID"%TYPE, p_SALARY IN EMPLOYEES."SALARY"%TYPE, p_COMMISSION_PCT IN EMPLOYEES."COMMISSION_PCT"%TYPE, p_MANAGER_ID IN EMPLOYEES."MANAGER_ID"%TYPE, p_DEPARTMENT_ID IN EMPLOYEES."DEPARTMENT_ID"%TYPE );
  ----------------------------------------
  FUNCTION create_or_update_row( p_row IN EMPLOYEES%ROWTYPE )
  RETURN EMPLOYEES."EMPLOYEE_ID"%TYPE;
  ----------------------------------------
  PROCEDURE create_or_update_row( p_row IN EMPLOYEES%ROWTYPE );
  ----------------------------------------
  FUNCTION get_FIRST_NAME( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."FIRST_NAME"%TYPE;
  ----------------------------------------
  FUNCTION get_LAST_NAME( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."LAST_NAME"%TYPE;
  ----------------------------------------
  FUNCTION get_EMAIL( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."EMAIL"%TYPE;
  ----------------------------------------
  FUNCTION get_PHONE_NUMBER( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."PHONE_NUMBER"%TYPE;
  ----------------------------------------
  FUNCTION get_HIRE_DATE( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."HIRE_DATE"%TYPE;
  ----------------------------------------
  FUNCTION get_JOB_ID( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."JOB_ID"%TYPE;
  ----------------------------------------
  FUNCTION get_SALARY( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."SALARY"%TYPE;
  ----------------------------------------
  FUNCTION get_COMMISSION_PCT( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."COMMISSION_PCT"%TYPE;
  ----------------------------------------
  FUNCTION get_MANAGER_ID( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."MANAGER_ID"%TYPE;
  ----------------------------------------
  FUNCTION get_DEPARTMENT_ID( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."DEPARTMENT_ID"%TYPE;
  ----------------------------------------
  PROCEDURE set_FIRST_NAME( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_FIRST_NAME IN EMPLOYEES."FIRST_NAME"%TYPE );
  ----------------------------------------
  PROCEDURE set_LAST_NAME( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_LAST_NAME IN EMPLOYEES."LAST_NAME"%TYPE );
  ----------------------------------------
  PROCEDURE set_EMAIL( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_EMAIL IN EMPLOYEES."EMAIL"%TYPE );
  ----------------------------------------
  PROCEDURE set_PHONE_NUMBER( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_PHONE_NUMBER IN EMPLOYEES."PHONE_NUMBER"%TYPE );
  ----------------------------------------
  PROCEDURE set_HIRE_DATE( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_HIRE_DATE IN EMPLOYEES."HIRE_DATE"%TYPE );
  ----------------------------------------
  PROCEDURE set_JOB_ID( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_JOB_ID IN EMPLOYEES."JOB_ID"%TYPE );
  ----------------------------------------
  PROCEDURE set_SALARY( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_SALARY IN EMPLOYEES."SALARY"%TYPE );
  ----------------------------------------
  PROCEDURE set_COMMISSION_PCT( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_COMMISSION_PCT IN EMPLOYEES."COMMISSION_PCT"%TYPE );
  ----------------------------------------
  PROCEDURE set_MANAGER_ID( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_MANAGER_ID IN EMPLOYEES."MANAGER_ID"%TYPE );
  ----------------------------------------
  PROCEDURE set_DEPARTMENT_ID( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_DEPARTMENT_ID IN EMPLOYEES."DEPARTMENT_ID"%TYPE );
  ----------------------------------------
END EMPLOYEES_api;
```


## Package body

```sql
create or replace PACKAGE BODY EMPLOYEES_api IS
  ----------------------------------------
  FUNCTION row_exists( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN BOOLEAN
  IS
    v_return BOOLEAN := FALSE;
  BEGIN
    FOR i IN ( SELECT 1 FROM EMPLOYEES WHERE "EMPLOYEE_ID" = p_EMPLOYEE_ID ) LOOP
      v_return := TRUE;
    END LOOP;
    RETURN v_return;
  END;
  ----------------------------------------
  FUNCTION row_exists_yn( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN case when row_exists( p_EMPLOYEE_ID => p_EMPLOYEE_ID )
             then 'Y'
             else 'N'
           end;
  END;
  ----------------------------------------
  FUNCTION get_pk_by_unique_cols( p_EMAIL EMPLOYEES."EMAIL"%TYPE )
  RETURN EMPLOYEES."EMPLOYEE_ID"%TYPE IS
    v_pk EMPLOYEES."EMPLOYEE_ID"%TYPE;
    CURSOR cur_row IS
      SELECT "EMPLOYEE_ID" from EMPLOYEES
       WHERE COALESCE( "EMAIL", '@@@@@@@@@@@@@@@' ) = COALESCE( p_EMAIL, '@@@@@@@@@@@@@@@' );
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_pk;
    CLOSE cur_row;
    RETURN v_pk;
  END get_pk_by_unique_cols;
  ----------------------------------------
  FUNCTION create_row( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE DEFAULT NULL, p_FIRST_NAME IN EMPLOYEES."FIRST_NAME"%TYPE, p_LAST_NAME IN EMPLOYEES."LAST_NAME"%TYPE, p_EMAIL IN EMPLOYEES."EMAIL"%TYPE, p_PHONE_NUMBER IN EMPLOYEES."PHONE_NUMBER"%TYPE, p_HIRE_DATE IN EMPLOYEES."HIRE_DATE"%TYPE, p_JOB_ID IN EMPLOYEES."JOB_ID"%TYPE, p_SALARY IN EMPLOYEES."SALARY"%TYPE, p_COMMISSION_PCT IN EMPLOYEES."COMMISSION_PCT"%TYPE, p_MANAGER_ID IN EMPLOYEES."MANAGER_ID"%TYPE, p_DEPARTMENT_ID IN EMPLOYEES."DEPARTMENT_ID"%TYPE )
  RETURN EMPLOYEES."EMPLOYEE_ID"%TYPE IS
    v_pk EMPLOYEES."EMPLOYEE_ID"%TYPE;
  BEGIN
    v_pk :=
    COALESCE( p_EMPLOYEE_ID, EMPLOYEES_SEQ.nextval );
    INSERT INTO EMPLOYEES ( "EMPLOYEE_ID", "FIRST_NAME", "LAST_NAME", "EMAIL", "PHONE_NUMBER", "HIRE_DATE", "JOB_ID", "SALARY", "COMMISSION_PCT", "MANAGER_ID", "DEPARTMENT_ID" )
      VALUES ( v_pk, p_FIRST_NAME, p_LAST_NAME, p_EMAIL, p_PHONE_NUMBER, p_HIRE_DATE, p_JOB_ID, p_SALARY, p_COMMISSION_PCT, p_MANAGER_ID, p_DEPARTMENT_ID );
    RETURN v_pk;
  END create_row;
  ----------------------------------------
  PROCEDURE create_row( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE DEFAULT NULL, p_FIRST_NAME IN EMPLOYEES."FIRST_NAME"%TYPE, p_LAST_NAME IN EMPLOYEES."LAST_NAME"%TYPE, p_EMAIL IN EMPLOYEES."EMAIL"%TYPE, p_PHONE_NUMBER IN EMPLOYEES."PHONE_NUMBER"%TYPE, p_HIRE_DATE IN EMPLOYEES."HIRE_DATE"%TYPE, p_JOB_ID IN EMPLOYEES."JOB_ID"%TYPE, p_SALARY IN EMPLOYEES."SALARY"%TYPE, p_COMMISSION_PCT IN EMPLOYEES."COMMISSION_PCT"%TYPE, p_MANAGER_ID IN EMPLOYEES."MANAGER_ID"%TYPE, p_DEPARTMENT_ID IN EMPLOYEES."DEPARTMENT_ID"%TYPE )
  IS
    v_pk EMPLOYEES."EMPLOYEE_ID"%TYPE;
  BEGIN
    v_pk := create_row( p_EMPLOYEE_ID => p_EMPLOYEE_ID, p_FIRST_NAME => p_FIRST_NAME, p_LAST_NAME => p_LAST_NAME, p_EMAIL => p_EMAIL, p_PHONE_NUMBER => p_PHONE_NUMBER, p_HIRE_DATE => p_HIRE_DATE, p_JOB_ID => p_JOB_ID, p_SALARY => p_SALARY, p_COMMISSION_PCT => p_COMMISSION_PCT, p_MANAGER_ID => p_MANAGER_ID, p_DEPARTMENT_ID => p_DEPARTMENT_ID );
  END create_row;
  ----------------------------------------
  FUNCTION create_row( p_row IN EMPLOYEES%ROWTYPE )
  RETURN EMPLOYEES."EMPLOYEE_ID"%TYPE IS
    v_pk EMPLOYEES."EMPLOYEE_ID"%TYPE;
  BEGIN
    v_pk := create_row( p_EMPLOYEE_ID => p_row."EMPLOYEE_ID", p_FIRST_NAME => p_row."FIRST_NAME", p_LAST_NAME => p_row."LAST_NAME", p_EMAIL => p_row."EMAIL", p_PHONE_NUMBER => p_row."PHONE_NUMBER", p_HIRE_DATE => p_row."HIRE_DATE", p_JOB_ID => p_row."JOB_ID", p_SALARY => p_row."SALARY", p_COMMISSION_PCT => p_row."COMMISSION_PCT", p_MANAGER_ID => p_row."MANAGER_ID", p_DEPARTMENT_ID => p_row."DEPARTMENT_ID" );
    RETURN v_pk;
  END create_row;
  ----------------------------------------
  PROCEDURE create_row( p_row IN EMPLOYEES%ROWTYPE )
  IS
    v_pk EMPLOYEES."EMPLOYEE_ID"%TYPE;
  BEGIN
    v_pk := create_row( p_EMPLOYEE_ID => p_row."EMPLOYEE_ID", p_FIRST_NAME => p_row."FIRST_NAME", p_LAST_NAME => p_row."LAST_NAME", p_EMAIL => p_row."EMAIL", p_PHONE_NUMBER => p_row."PHONE_NUMBER", p_HIRE_DATE => p_row."HIRE_DATE", p_JOB_ID => p_row."JOB_ID", p_SALARY => p_row."SALARY", p_COMMISSION_PCT => p_row."COMMISSION_PCT", p_MANAGER_ID => p_row."MANAGER_ID", p_DEPARTMENT_ID => p_row."DEPARTMENT_ID" );
  END create_row;
  ----------------------------------------
  FUNCTION read_row( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES%ROWTYPE IS
    CURSOR cur_row_by_pk( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE ) IS
      SELECT * FROM EMPLOYEES WHERE "EMPLOYEE_ID" = p_EMPLOYEE_ID;
    v_row EMPLOYEES%ROWTYPE;
  BEGIN
    OPEN cur_row_by_pk( p_EMPLOYEE_ID );
    FETCH cur_row_by_pk INTO v_row;
    CLOSE cur_row_by_pk;
    RETURN v_row;
  END read_row;
  ----------------------------------------
  PROCEDURE read_row( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_FIRST_NAME OUT NOCOPY EMPLOYEES."FIRST_NAME"%TYPE, p_LAST_NAME OUT NOCOPY EMPLOYEES."LAST_NAME"%TYPE, p_EMAIL OUT NOCOPY EMPLOYEES."EMAIL"%TYPE, p_PHONE_NUMBER OUT NOCOPY EMPLOYEES."PHONE_NUMBER"%TYPE, p_HIRE_DATE OUT NOCOPY EMPLOYEES."HIRE_DATE"%TYPE, p_JOB_ID OUT NOCOPY EMPLOYEES."JOB_ID"%TYPE, p_SALARY OUT NOCOPY EMPLOYEES."SALARY"%TYPE, p_COMMISSION_PCT OUT NOCOPY EMPLOYEES."COMMISSION_PCT"%TYPE, p_MANAGER_ID OUT NOCOPY EMPLOYEES."MANAGER_ID"%TYPE, p_DEPARTMENT_ID OUT NOCOPY EMPLOYEES."DEPARTMENT_ID"%TYPE )
  IS
    v_row EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    IF v_row."EMPLOYEE_ID" IS NOT NULL THEN
      p_FIRST_NAME := v_row."FIRST_NAME"; p_LAST_NAME := v_row."LAST_NAME"; p_EMAIL := v_row."EMAIL"; p_PHONE_NUMBER := v_row."PHONE_NUMBER"; p_HIRE_DATE := v_row."HIRE_DATE"; p_JOB_ID := v_row."JOB_ID"; p_SALARY := v_row."SALARY"; p_COMMISSION_PCT := v_row."COMMISSION_PCT"; p_MANAGER_ID := v_row."MANAGER_ID"; p_DEPARTMENT_ID := v_row."DEPARTMENT_ID";
    END IF;
  END read_row;
  ----------------------------------------
  FUNCTION read_row( p_EMAIL EMPLOYEES."EMAIL"%TYPE )
  RETURN EMPLOYEES%ROWTYPE IS
    v_pk EMPLOYEES."EMPLOYEE_ID"%TYPE;
  BEGIN
    v_pk := get_pk_by_unique_cols( p_EMAIL => p_EMAIL );
    RETURN read_row ( p_EMPLOYEE_ID => v_pk );
  END read_row;
  ----------------------------------------
  PROCEDURE update_row( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE DEFAULT NULL, p_FIRST_NAME IN EMPLOYEES."FIRST_NAME"%TYPE, p_LAST_NAME IN EMPLOYEES."LAST_NAME"%TYPE, p_EMAIL IN EMPLOYEES."EMAIL"%TYPE, p_PHONE_NUMBER IN EMPLOYEES."PHONE_NUMBER"%TYPE, p_HIRE_DATE IN EMPLOYEES."HIRE_DATE"%TYPE, p_JOB_ID IN EMPLOYEES."JOB_ID"%TYPE, p_SALARY IN EMPLOYEES."SALARY"%TYPE, p_COMMISSION_PCT IN EMPLOYEES."COMMISSION_PCT"%TYPE, p_MANAGER_ID IN EMPLOYEES."MANAGER_ID"%TYPE, p_DEPARTMENT_ID IN EMPLOYEES."DEPARTMENT_ID"%TYPE )
  IS
    v_row   EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    IF v_row."EMPLOYEE_ID" IS NOT NULL THEN
      -- update only, if the column values really differ
      IF COALESCE( v_row."FIRST_NAME", '@@@@@@@@@@@@@@@' ) <> COALESCE( p_FIRST_NAME, '@@@@@@@@@@@@@@@' )
      OR COALESCE( v_row."LAST_NAME", '@@@@@@@@@@@@@@@' ) <> COALESCE( p_LAST_NAME, '@@@@@@@@@@@@@@@' )
      OR COALESCE( v_row."EMAIL", '@@@@@@@@@@@@@@@' ) <> COALESCE( p_EMAIL, '@@@@@@@@@@@@@@@' )
      OR COALESCE( v_row."PHONE_NUMBER", '@@@@@@@@@@@@@@@' ) <> COALESCE( p_PHONE_NUMBER, '@@@@@@@@@@@@@@@' )
      OR COALESCE( v_row."HIRE_DATE", TO_DATE( '01.01.1900', 'DD.MM.YYYY' ) ) <> COALESCE( p_HIRE_DATE, TO_DATE( '01.01.1900', 'DD.MM.YYYY' ) )
      OR COALESCE( v_row."JOB_ID", '@@@@@@@@@@@@@@@' ) <> COALESCE( p_JOB_ID, '@@@@@@@@@@@@@@@' )
      OR COALESCE( v_row."SALARY", -999999999999999.999999999999999 ) <> COALESCE( p_SALARY, -999999999999999.999999999999999 )
      OR COALESCE( v_row."COMMISSION_PCT", -999999999999999.999999999999999 ) <> COALESCE( p_COMMISSION_PCT, -999999999999999.999999999999999 )
      OR COALESCE( v_row."MANAGER_ID", -999999999999999.999999999999999 ) <> COALESCE( p_MANAGER_ID, -999999999999999.999999999999999 )
      OR COALESCE( v_row."DEPARTMENT_ID", -999999999999999.999999999999999 ) <> COALESCE( p_DEPARTMENT_ID, -999999999999999.999999999999999 )
      THEN
        UPDATE EMPLOYEES
           SET "FIRST_NAME" = p_FIRST_NAME, "LAST_NAME" = p_LAST_NAME, "EMAIL" = p_EMAIL, "PHONE_NUMBER" = p_PHONE_NUMBER, "HIRE_DATE" = p_HIRE_DATE, "JOB_ID" = p_JOB_ID, "SALARY" = p_SALARY, "COMMISSION_PCT" = p_COMMISSION_PCT, "MANAGER_ID" = p_MANAGER_ID, "DEPARTMENT_ID" = p_DEPARTMENT_ID
         WHERE "EMPLOYEE_ID" = v_row."EMPLOYEE_ID";
      END IF;
    END IF;
  END update_row;
  ----------------------------------------
  PROCEDURE update_row( p_row IN EMPLOYEES%ROWTYPE )
  IS
  BEGIN
    update_row( p_EMPLOYEE_ID => p_row."EMPLOYEE_ID", p_FIRST_NAME => p_row."FIRST_NAME", p_LAST_NAME => p_row."LAST_NAME", p_EMAIL => p_row."EMAIL", p_PHONE_NUMBER => p_row."PHONE_NUMBER", p_HIRE_DATE => p_row."HIRE_DATE", p_JOB_ID => p_row."JOB_ID", p_SALARY => p_row."SALARY", p_COMMISSION_PCT => p_row."COMMISSION_PCT", p_MANAGER_ID => p_row."MANAGER_ID", p_DEPARTMENT_ID => p_row."DEPARTMENT_ID" );
  END update_row;
  ----------------------------------------
  FUNCTION create_or_update_row( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE DEFAULT NULL, p_FIRST_NAME IN EMPLOYEES."FIRST_NAME"%TYPE, p_LAST_NAME IN EMPLOYEES."LAST_NAME"%TYPE, p_EMAIL IN EMPLOYEES."EMAIL"%TYPE, p_PHONE_NUMBER IN EMPLOYEES."PHONE_NUMBER"%TYPE, p_HIRE_DATE IN EMPLOYEES."HIRE_DATE"%TYPE, p_JOB_ID IN EMPLOYEES."JOB_ID"%TYPE, p_SALARY IN EMPLOYEES."SALARY"%TYPE, p_COMMISSION_PCT IN EMPLOYEES."COMMISSION_PCT"%TYPE, p_MANAGER_ID IN EMPLOYEES."MANAGER_ID"%TYPE, p_DEPARTMENT_ID IN EMPLOYEES."DEPARTMENT_ID"%TYPE )
  RETURN EMPLOYEES."EMPLOYEE_ID"%TYPE IS
    v_pk EMPLOYEES."EMPLOYEE_ID"%TYPE;
  BEGIN
    IF p_EMPLOYEE_ID IS NULL THEN
      v_pk := create_row( p_EMPLOYEE_ID => p_EMPLOYEE_ID, p_FIRST_NAME => p_FIRST_NAME, p_LAST_NAME => p_LAST_NAME, p_EMAIL => p_EMAIL, p_PHONE_NUMBER => p_PHONE_NUMBER, p_HIRE_DATE => p_HIRE_DATE, p_JOB_ID => p_JOB_ID, p_SALARY => p_SALARY, p_COMMISSION_PCT => p_COMMISSION_PCT, p_MANAGER_ID => p_MANAGER_ID, p_DEPARTMENT_ID => p_DEPARTMENT_ID );
    ELSE
      IF row_exists( p_EMPLOYEE_ID => p_EMPLOYEE_ID ) THEN
        v_pk := p_EMPLOYEE_ID;
        update_row( p_EMPLOYEE_ID => p_EMPLOYEE_ID, p_FIRST_NAME => p_FIRST_NAME, p_LAST_NAME => p_LAST_NAME, p_EMAIL => p_EMAIL, p_PHONE_NUMBER => p_PHONE_NUMBER, p_HIRE_DATE => p_HIRE_DATE, p_JOB_ID => p_JOB_ID, p_SALARY => p_SALARY, p_COMMISSION_PCT => p_COMMISSION_PCT, p_MANAGER_ID => p_MANAGER_ID, p_DEPARTMENT_ID => p_DEPARTMENT_ID );
      ELSE
        v_pk := create_row( p_EMPLOYEE_ID => p_EMPLOYEE_ID, p_FIRST_NAME => p_FIRST_NAME, p_LAST_NAME => p_LAST_NAME, p_EMAIL => p_EMAIL, p_PHONE_NUMBER => p_PHONE_NUMBER, p_HIRE_DATE => p_HIRE_DATE, p_JOB_ID => p_JOB_ID, p_SALARY => p_SALARY, p_COMMISSION_PCT => p_COMMISSION_PCT, p_MANAGER_ID => p_MANAGER_ID, p_DEPARTMENT_ID => p_DEPARTMENT_ID );
      END IF;
    END IF;
    RETURN v_pk;
  END create_or_update_row;
  ----------------------------------------
  PROCEDURE create_or_update_row( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE DEFAULT NULL, p_FIRST_NAME IN EMPLOYEES."FIRST_NAME"%TYPE, p_LAST_NAME IN EMPLOYEES."LAST_NAME"%TYPE, p_EMAIL IN EMPLOYEES."EMAIL"%TYPE, p_PHONE_NUMBER IN EMPLOYEES."PHONE_NUMBER"%TYPE, p_HIRE_DATE IN EMPLOYEES."HIRE_DATE"%TYPE, p_JOB_ID IN EMPLOYEES."JOB_ID"%TYPE, p_SALARY IN EMPLOYEES."SALARY"%TYPE, p_COMMISSION_PCT IN EMPLOYEES."COMMISSION_PCT"%TYPE, p_MANAGER_ID IN EMPLOYEES."MANAGER_ID"%TYPE, p_DEPARTMENT_ID IN EMPLOYEES."DEPARTMENT_ID"%TYPE )
  IS
    v_pk EMPLOYEES."EMPLOYEE_ID"%TYPE;
  BEGIN
    v_pk := create_or_update_row( p_EMPLOYEE_ID => p_EMPLOYEE_ID, p_FIRST_NAME => p_FIRST_NAME, p_LAST_NAME => p_LAST_NAME, p_EMAIL => p_EMAIL, p_PHONE_NUMBER => p_PHONE_NUMBER, p_HIRE_DATE => p_HIRE_DATE, p_JOB_ID => p_JOB_ID, p_SALARY => p_SALARY, p_COMMISSION_PCT => p_COMMISSION_PCT, p_MANAGER_ID => p_MANAGER_ID, p_DEPARTMENT_ID => p_DEPARTMENT_ID );
  END create_or_update_row;
  ----------------------------------------
  FUNCTION create_or_update_row( p_row IN EMPLOYEES%ROWTYPE )
  RETURN EMPLOYEES."EMPLOYEE_ID"%TYPE IS
    v_pk EMPLOYEES."EMPLOYEE_ID"%TYPE;
  BEGIN
    v_pk := create_or_update_row( p_EMPLOYEE_ID => p_row."EMPLOYEE_ID", p_FIRST_NAME => p_row."FIRST_NAME", p_LAST_NAME => p_row."LAST_NAME", p_EMAIL => p_row."EMAIL", p_PHONE_NUMBER => p_row."PHONE_NUMBER", p_HIRE_DATE => p_row."HIRE_DATE", p_JOB_ID => p_row."JOB_ID", p_SALARY => p_row."SALARY", p_COMMISSION_PCT => p_row."COMMISSION_PCT", p_MANAGER_ID => p_row."MANAGER_ID", p_DEPARTMENT_ID => p_row."DEPARTMENT_ID" );
    RETURN v_pk;
  END create_or_update_row;
  ----------------------------------------
  PROCEDURE create_or_update_row( p_row IN EMPLOYEES%ROWTYPE )
  IS
    v_pk EMPLOYEES."EMPLOYEE_ID"%TYPE;
  BEGIN
    v_pk := create_or_update_row( p_EMPLOYEE_ID => p_row."EMPLOYEE_ID", p_FIRST_NAME => p_row."FIRST_NAME", p_LAST_NAME => p_row."LAST_NAME", p_EMAIL => p_row."EMAIL", p_PHONE_NUMBER => p_row."PHONE_NUMBER", p_HIRE_DATE => p_row."HIRE_DATE", p_JOB_ID => p_row."JOB_ID", p_SALARY => p_row."SALARY", p_COMMISSION_PCT => p_row."COMMISSION_PCT", p_MANAGER_ID => p_row."MANAGER_ID", p_DEPARTMENT_ID => p_row."DEPARTMENT_ID" );
  END create_or_update_row;
  ----------------------------------------
  FUNCTION get_FIRST_NAME( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."FIRST_NAME"%TYPE IS
    v_row    EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    RETURN v_row."FIRST_NAME";
  END get_FIRST_NAME;
  ----------------------------------------
  FUNCTION get_LAST_NAME( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."LAST_NAME"%TYPE IS
    v_row    EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    RETURN v_row."LAST_NAME";
  END get_LAST_NAME;
  ----------------------------------------
  FUNCTION get_EMAIL( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."EMAIL"%TYPE IS
    v_row    EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    RETURN v_row."EMAIL";
  END get_EMAIL;
  ----------------------------------------
  FUNCTION get_PHONE_NUMBER( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."PHONE_NUMBER"%TYPE IS
    v_row    EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    RETURN v_row."PHONE_NUMBER";
  END get_PHONE_NUMBER;
  ----------------------------------------
  FUNCTION get_HIRE_DATE( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."HIRE_DATE"%TYPE IS
    v_row    EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    RETURN v_row."HIRE_DATE";
  END get_HIRE_DATE;
  ----------------------------------------
  FUNCTION get_JOB_ID( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."JOB_ID"%TYPE IS
    v_row    EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    RETURN v_row."JOB_ID";
  END get_JOB_ID;
  ----------------------------------------
  FUNCTION get_SALARY( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."SALARY"%TYPE IS
    v_row    EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    RETURN v_row."SALARY";
  END get_SALARY;
  ----------------------------------------
  FUNCTION get_COMMISSION_PCT( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."COMMISSION_PCT"%TYPE IS
    v_row    EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    RETURN v_row."COMMISSION_PCT";
  END get_COMMISSION_PCT;
  ----------------------------------------
  FUNCTION get_MANAGER_ID( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."MANAGER_ID"%TYPE IS
    v_row    EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    RETURN v_row."MANAGER_ID";
  END get_MANAGER_ID;
  ----------------------------------------
  FUNCTION get_DEPARTMENT_ID( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE )
  RETURN EMPLOYEES."DEPARTMENT_ID"%TYPE IS
    v_row    EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    RETURN v_row."DEPARTMENT_ID";
  END get_DEPARTMENT_ID;
  ----------------------------------------
  PROCEDURE set_FIRST_NAME( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_FIRST_NAME IN EMPLOYEES."FIRST_NAME"%TYPE )
  IS
    v_row EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    IF v_row."EMPLOYEE_ID" IS NOT NULL THEN
      -- update only, if the column value really differs
      IF COALESCE( v_row."FIRST_NAME", '@@@@@@@@@@@@@@@' ) <> COALESCE( p_FIRST_NAME, '@@@@@@@@@@@@@@@' ) THEN
        UPDATE EMPLOYEES
           SET "FIRST_NAME" = p_FIRST_NAME
         WHERE "EMPLOYEE_ID" = p_EMPLOYEE_ID;
      END IF;
    END IF;
  END set_FIRST_NAME;
  ----------------------------------------
  PROCEDURE set_LAST_NAME( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_LAST_NAME IN EMPLOYEES."LAST_NAME"%TYPE )
  IS
    v_row EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    IF v_row."EMPLOYEE_ID" IS NOT NULL THEN
      -- update only, if the column value really differs
      IF COALESCE( v_row."LAST_NAME", '@@@@@@@@@@@@@@@' ) <> COALESCE( p_LAST_NAME, '@@@@@@@@@@@@@@@' ) THEN
        UPDATE EMPLOYEES
           SET "LAST_NAME" = p_LAST_NAME
         WHERE "EMPLOYEE_ID" = p_EMPLOYEE_ID;
      END IF;
    END IF;
  END set_LAST_NAME;
  ----------------------------------------
  PROCEDURE set_EMAIL( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_EMAIL IN EMPLOYEES."EMAIL"%TYPE )
  IS
    v_row EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    IF v_row."EMPLOYEE_ID" IS NOT NULL THEN
      -- update only, if the column value really differs
      IF COALESCE( v_row."EMAIL", '@@@@@@@@@@@@@@@' ) <> COALESCE( p_EMAIL, '@@@@@@@@@@@@@@@' ) THEN
        UPDATE EMPLOYEES
           SET "EMAIL" = p_EMAIL
         WHERE "EMPLOYEE_ID" = p_EMPLOYEE_ID;
      END IF;
    END IF;
  END set_EMAIL;
  ----------------------------------------
  PROCEDURE set_PHONE_NUMBER( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_PHONE_NUMBER IN EMPLOYEES."PHONE_NUMBER"%TYPE )
  IS
    v_row EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    IF v_row."EMPLOYEE_ID" IS NOT NULL THEN
      -- update only, if the column value really differs
      IF COALESCE( v_row."PHONE_NUMBER", '@@@@@@@@@@@@@@@' ) <> COALESCE( p_PHONE_NUMBER, '@@@@@@@@@@@@@@@' ) THEN
        UPDATE EMPLOYEES
           SET "PHONE_NUMBER" = p_PHONE_NUMBER
         WHERE "EMPLOYEE_ID" = p_EMPLOYEE_ID;
      END IF;
    END IF;
  END set_PHONE_NUMBER;
  ----------------------------------------
  PROCEDURE set_HIRE_DATE( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_HIRE_DATE IN EMPLOYEES."HIRE_DATE"%TYPE )
  IS
    v_row EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    IF v_row."EMPLOYEE_ID" IS NOT NULL THEN
      -- update only, if the column value really differs
      IF COALESCE( v_row."HIRE_DATE", TO_DATE( '01.01.1900', 'DD.MM.YYYY' ) ) <> COALESCE( p_HIRE_DATE, TO_DATE( '01.01.1900', 'DD.MM.YYYY' ) ) THEN
        UPDATE EMPLOYEES
           SET "HIRE_DATE" = p_HIRE_DATE
         WHERE "EMPLOYEE_ID" = p_EMPLOYEE_ID;
      END IF;
    END IF;
  END set_HIRE_DATE;
  ----------------------------------------
  PROCEDURE set_JOB_ID( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_JOB_ID IN EMPLOYEES."JOB_ID"%TYPE )
  IS
    v_row EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    IF v_row."EMPLOYEE_ID" IS NOT NULL THEN
      -- update only, if the column value really differs
      IF COALESCE( v_row."JOB_ID", '@@@@@@@@@@@@@@@' ) <> COALESCE( p_JOB_ID, '@@@@@@@@@@@@@@@' ) THEN
        UPDATE EMPLOYEES
           SET "JOB_ID" = p_JOB_ID
         WHERE "EMPLOYEE_ID" = p_EMPLOYEE_ID;
      END IF;
    END IF;
  END set_JOB_ID;
  ----------------------------------------
  PROCEDURE set_SALARY( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_SALARY IN EMPLOYEES."SALARY"%TYPE )
  IS
    v_row EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    IF v_row."EMPLOYEE_ID" IS NOT NULL THEN
      -- update only, if the column value really differs
      IF COALESCE( v_row."SALARY", -999999999999999.999999999999999 ) <> COALESCE( p_SALARY, -999999999999999.999999999999999 ) THEN
        UPDATE EMPLOYEES
           SET "SALARY" = p_SALARY
         WHERE "EMPLOYEE_ID" = p_EMPLOYEE_ID;
      END IF;
    END IF;
  END set_SALARY;
  ----------------------------------------
  PROCEDURE set_COMMISSION_PCT( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_COMMISSION_PCT IN EMPLOYEES."COMMISSION_PCT"%TYPE )
  IS
    v_row EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    IF v_row."EMPLOYEE_ID" IS NOT NULL THEN
      -- update only, if the column value really differs
      IF COALESCE( v_row."COMMISSION_PCT", -999999999999999.999999999999999 ) <> COALESCE( p_COMMISSION_PCT, -999999999999999.999999999999999 ) THEN
        UPDATE EMPLOYEES
           SET "COMMISSION_PCT" = p_COMMISSION_PCT
         WHERE "EMPLOYEE_ID" = p_EMPLOYEE_ID;
      END IF;
    END IF;
  END set_COMMISSION_PCT;
  ----------------------------------------
  PROCEDURE set_MANAGER_ID( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_MANAGER_ID IN EMPLOYEES."MANAGER_ID"%TYPE )
  IS
    v_row EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    IF v_row."EMPLOYEE_ID" IS NOT NULL THEN
      -- update only, if the column value really differs
      IF COALESCE( v_row."MANAGER_ID", -999999999999999.999999999999999 ) <> COALESCE( p_MANAGER_ID, -999999999999999.999999999999999 ) THEN
        UPDATE EMPLOYEES
           SET "MANAGER_ID" = p_MANAGER_ID
         WHERE "EMPLOYEE_ID" = p_EMPLOYEE_ID;
      END IF;
    END IF;
  END set_MANAGER_ID;
  ----------------------------------------
  PROCEDURE set_DEPARTMENT_ID( p_EMPLOYEE_ID IN EMPLOYEES."EMPLOYEE_ID"%TYPE, p_DEPARTMENT_ID IN EMPLOYEES."DEPARTMENT_ID"%TYPE )
  IS
    v_row EMPLOYEES%ROWTYPE;
  BEGIN
    v_row := read_row ( p_EMPLOYEE_ID => p_EMPLOYEE_ID );
    IF v_row."EMPLOYEE_ID" IS NOT NULL THEN
      -- update only, if the column value really differs
      IF COALESCE( v_row."DEPARTMENT_ID", -999999999999999.999999999999999 ) <> COALESCE( p_DEPARTMENT_ID, -999999999999999.999999999999999 ) THEN
        UPDATE EMPLOYEES
           SET "DEPARTMENT_ID" = p_DEPARTMENT_ID
         WHERE "EMPLOYEE_ID" = p_EMPLOYEE_ID;
      END IF;
    END IF;
  END set_DEPARTMENT_ID;
  ----------------------------------------
END EMPLOYEES_api;
```
