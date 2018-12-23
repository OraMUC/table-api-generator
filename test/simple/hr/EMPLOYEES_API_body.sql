CREATE OR REPLACE PACKAGE BODY "TEST"."EMPLOYEES_API" IS
  /**
   * generator="OM_TAPIGEN"
   * generator_version="0.5.0"
   * generator_action="COMPILE_API"
   * generated_at="2018-12-20 19:43:15"
   * generated_by="OGOBRECHT"
   */

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
    v_row."JOB_ID"         := '6A3FE8B021' /*FK*/;
    v_row."SALARY"         := round(dbms_random.value(1000,10000),2);
    v_row."COMMISSION_PCT" := round(dbms_random.value(0,.99),2);
    v_row."DEPARTMENT_ID"  := 1 /*FK*/;
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

