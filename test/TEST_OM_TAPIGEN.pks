CREATE OR REPLACE PACKAGE test_om_tapigen IS
-- Minimum needed DB version:     12.1
-- Needed system priviliges:      create procedure/sequence/table/trigger/view
-- Run The Test As SQL Statement: select * from table(ut.run('test_om_tapigen'));
--------------------------------------------------------------------------------

--%suite(OraMUC Table API Generator)
--%rollback(manual)

--%beforeall
procedure drop_and_create_test_table_objects;

--%beforeeach
procedure drop_generated_objects;

--%test
procedure all_tables_with_defaults;

--%test
procedure all_tables_return_row_instead_of_pk;

--%test
procedure all_tables_no_double_quote_of_names;

--%test
procedure all_tables_set_audit_column_mappings;

--------------------------------------------------------------------------------

procedure create_test_table_objects;
procedure drop_test_table_objects;
function  get_list_of_invalid_generated_objects return varchar2;
function  get_package_method_name return varchar2;

--------------------------------------------------------------------------------

cursor all_test_tables is
  select
    table_name
  from
    user_tables
  where
    table_name like 'TAG\_%' escape '\';

--------------------------------------------------------------------------------

cursor all_test_table_objects is
  select
    *
  from
    user_objects
  where
    object_type in ('TABLE', 'SEQUENCE')
    and object_name like 'TAG\_%' escape '\';

--------------------------------------------------------------------------------

cursor all_generated_objects is
  select
    *
  from
    user_objects
  where
    object_type in ('VIEW', 'PACKAGE')
    and object_name like 'TAG\_%' escape '\';

--------------------------------------------------------------------------------

END test_om_tapigen;
/
