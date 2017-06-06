create or replace package body ut_om_tapigen as

  procedure create_test_table is
    pragma autonomous_transaction;
  begin
    execute immediate 'create table employees_test (employee_id number primary key, commission_pct number, salary number)';
    execute immediate 'insert into employees_test values (1001, 0.2, 8400)';
    execute immediate 'insert into employees_test values (1002, 0.25, 6000)';
    execute immediate 'insert into employees_test values (1003, 0.3, 5000)';
    commit;
  end;

  procedure get_code_basic_test is
    l_actual clob;
    l_expected clob;
  begin
    l_actual := om_tapigen.get_code('EMPLOYEES_TEST');
    ut.expect( l_actual ).to_equal(l_expected);
  end;

  procedure drop_test_table is
  begin
    execute immediate 'drop table employees_test';
  end;
end;
/
