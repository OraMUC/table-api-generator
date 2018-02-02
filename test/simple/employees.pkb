PACKAGE BODY      "EMPLOYEES_API" IS

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
      "EMPLOYEE_ID",
      "FIRST_NAME",
      "LAST_NAME",
      "EMAIL",
      "PHONE_NUMBER",
      "HIRE_DATE",
      "JOB_ID",
      "SALARY",
      "COMMISSION_PCT",
      "MANAGER_ID",
      "DEPARTMENT_ID" )
    VALUES (
      COALESCE( p_employee_id,"EMPLOYEES_SEQ".nextval ),
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
      p_employee_id    => p_employee_id,
      p_first_name     => p_first_name,
      p_last_name      => p_last_name,
      p_email          => p_email,
      p_phone_number   => p_phone_number,
      p_hire_date      => p_hire_date,
      p_job_id         => p_job_id,
      p_salary         => p_salary,
      p_commission_pct => p_commission_pct,
      p_manager_id     => p_manager_id,
      p_department_id  => p_department_id );
  END create_row;

  FUNCTION create_row (
    p_row            IN "EMPLOYEES"%ROWTYPE )
  RETURN "EMPLOYEES"."EMPLOYEE_ID"%TYPE IS
    v_return "EMPLOYEES"."EMPLOYEE_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_employee_id    => p_row."EMPLOYEE_ID",
      p_first_name     => p_row."FIRST_NAME",
      p_last_name      => p_row."LAST_NAME",
      p_email          => p_row."EMAIL",
      p_phone_number   => p_row."PHONE_NUMBER",
      p_hire_date      => p_row."HIRE_DATE",
      p_job_id         => p_row."JOB_ID",
      p_salary         => p_row."SALARY",
      p_commission_pct => p_row."COMMISSION_PCT",
      p_manager_id     => p_row."MANAGER_ID",
      p_department_id  => p_row."DEPARTMENT_ID" );
    RETURN v_return;
  END create_row;

  PROCEDURE create_row (
    p_row            IN "EMPLOYEES"%ROWTYPE )
  IS
    v_return "EMPLOYEES"."EMPLOYEE_ID"%TYPE;
  BEGIN
    v_return := create_row (
      p_employee_id    => p_row."EMPLOYEE_ID",
      p_first_name     => p_row."FIRST_NAME",
      p_last_name      => p_row."LAST_NAME",
      p_email          => p_row."EMAIL",
      p_phone_number   => p_row."PHONE_NUMBER",
      p_hire_date      => p_row."HIRE_DATE",
      p_job_id         => p_row."JOB_ID",
      p_salary         => p_row."SALARY",
      p_commission_pct => p_row."COMMISSION_PCT",
      p_manager_id     => p_row."MANAGER_ID",
      p_department_id  => p_row."DEPARTMENT_ID" );
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
               "EMAIL"          = p_email,
               "PHONE_NUMBER"   = p_phone_number,
               "HIRE_DATE"      = p_hire_date,
               "JOB_ID"         = p_job_id,
               "SALARY"         = p_salary,
               "COMMISSION_PCT" = p_commission_pct,
               "MANAGER_ID"     = p_manager_id,
               "DEPARTMENT_ID"  = p_department_id
         WHERE COALESCE( "EMPLOYEE_ID",-999999999999999.999999999999999 ) = COALESCE( p_employee_id,-999999999999999.999999999999999 );
      END IF;
    END IF;
  END update_row;

  PROCEDURE update_row (
    p_row            IN "EMPLOYEES"%ROWTYPE )
  IS
  BEGIN
    update_row(
      p_employee_id    => p_row."EMPLOYEE_ID",
      p_first_name     => p_row."FIRST_NAME",
      p_last_name      => p_row."LAST_NAME",
      p_email          => p_row."EMAIL",
      p_phone_number   => p_row."PHONE_NUMBER",
      p_hire_date      => p_row."HIRE_DATE",
      p_job_id         => p_row."JOB_ID",
      p_salary         => p_row."SALARY",
      p_commission_pct => p_row."COMMISSION_PCT",
      p_manager_id     => p_row."MANAGER_ID",
      p_department_id  => p_row."DEPARTMENT_ID" );
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
        p_employee_id    => p_employee_id,
        p_first_name     => p_first_name,
        p_last_name      => p_last_name,
        p_email          => p_email,
        p_phone_number   => p_phone_number,
        p_hire_date      => p_hire_date,
        p_job_id         => p_job_id,
        p_salary         => p_salary,
        p_commission_pct => p_commission_pct,
        p_manager_id     => p_manager_id,
        p_department_id  => p_department_id );
      v_return := read_row ( p_employee_id => p_employee_id )."EMPLOYEE_ID";
    ELSE
      v_return := create_row (
        p_employee_id    => p_employee_id,
        p_first_name     => p_first_name,
        p_last_name      => p_last_name,
        p_email          => p_email,
        p_phone_number   => p_phone_number,
        p_hire_date      => p_hire_date,
        p_job_id         => p_job_id,
        p_salary         => p_salary,
        p_commission_pct => p_commission_pct,
        p_manager_id     => p_manager_id,
        p_department_id  => p_department_id );
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
      p_employee_id    => p_employee_id,
      p_first_name     => p_first_name,
      p_last_name      => p_last_name,
      p_email          => p_email,
      p_phone_number   => p_phone_number,
      p_hire_date      => p_hire_date,
      p_job_id         => p_job_id,
      p_salary         => p_salary,
      p_commission_pct => p_commission_pct,
      p_manager_id     => p_manager_id,
      p_department_id  => p_department_id );
  END create_or_update_row;

  FUNCTION create_or_update_row (
    p_row            IN "EMPLOYEES"%ROWTYPE )
  RETURN "EMPLOYEES"."EMPLOYEE_ID"%TYPE IS
    v_return "EMPLOYEES"."EMPLOYEE_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_employee_id    => p_row."EMPLOYEE_ID",
      p_first_name     => p_row."FIRST_NAME",
      p_last_name      => p_row."LAST_NAME",
      p_email          => p_row."EMAIL",
      p_phone_number   => p_row."PHONE_NUMBER",
      p_hire_date      => p_row."HIRE_DATE",
      p_job_id         => p_row."JOB_ID",
      p_salary         => p_row."SALARY",
      p_commission_pct => p_row."COMMISSION_PCT",
      p_manager_id     => p_row."MANAGER_ID",
      p_department_id  => p_row."DEPARTMENT_ID" );
    RETURN v_return;
  END create_or_update_row;

  PROCEDURE create_or_update_row (
    p_row            IN "EMPLOYEES"%ROWTYPE )
  IS
    v_return "EMPLOYEES"."EMPLOYEE_ID"%TYPE;
  BEGIN
    v_return := create_or_update_row(
      p_employee_id    => p_row."EMPLOYEE_ID",
      p_first_name     => p_row."FIRST_NAME",
      p_last_name      => p_row."LAST_NAME",
      p_email          => p_row."EMAIL",
      p_phone_number   => p_row."PHONE_NUMBER",
      p_hire_date      => p_row."HIRE_DATE",
      p_job_id         => p_row."JOB_ID",
      p_salary         => p_row."SALARY",
      p_commission_pct => p_row."COMMISSION_PCT",
      p_manager_id     => p_row."MANAGER_ID",
      p_department_id  => p_row."DEPARTMENT_ID" );
  END create_or_update_row;

  FUNCTION get_a_row
  RETURN "EMPLOYEES"%ROWTYPE IS
    v_row "EMPLOYEES"%ROWTYPE;
  BEGIN
    v_row."FIRST_NAME"     := substr(sys_guid(),1,20);
    v_row."LAST_NAME"      := substr(sys_guid(),1,25);
    v_row."EMAIL"          := substr(sys_guid(),1,15) || '@dummy.com';
    v_row."PHONE_NUMBER"   := substr('+1.'||lpad(to_char(trunc(dbms_random.value(1,999))),3,'0')||'.'||lpad(to_char(trunc(dbms_random.value(1,999))),3,'0')||'.'||lpad(to_char(trunc(dbms_random.value(1,9999))),4,'0'),1,20);
    v_row."HIRE_DATE"      := to_date(trunc(dbms_random.value(to_char(date'1900-01-01','j'),to_char(date'2099-12-31','j'))),'j');
    v_row."JOB_ID"         := 'IT_PROG';
    v_row."SALARY"         := round(dbms_random.value(1000,10000),2);
    v_row."COMMISSION_PCT" := round(dbms_random.value(0,.99),2);
    v_row."MANAGER_ID"     := 100;
    v_row."DEPARTMENT_ID"  := 90;
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
      p_employee_id    => p_employee_id,
      p_first_name     => p_first_name,
      p_last_name      => p_last_name,
      p_email          => p_email,
      p_phone_number   => p_phone_number,
      p_hire_date      => p_hire_date,
      p_job_id         => p_job_id,
      p_salary         => p_salary,
      p_commission_pct => p_commission_pct,
      p_manager_id     => p_manager_id,
      p_department_id  => p_department_id );
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
      p_employee_id    => p_employee_id,
      p_first_name     => p_first_name,
      p_last_name      => p_last_name,
      p_email          => p_email,
      p_phone_number   => p_phone_number,
      p_hire_date      => p_hire_date,
      p_job_id         => p_job_id,
      p_salary         => p_salary,
      p_commission_pct => p_commission_pct,
      p_manager_id     => p_manager_id,
      p_department_id  => p_department_id );
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
