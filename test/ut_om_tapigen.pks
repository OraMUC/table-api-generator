create or replace package ut_om_tapigen as
  --%suite(table api generator)
  --%rollback(manual)

  --%beforeall
  procedure create_test_table;

  --%test(get_code returns api package for test_table)
  procedure get_code_basic_test;

  --%afterall
  procedure drop_test_table;
end;
/
