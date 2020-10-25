prompt Compile package test_om_tapigen (spec)
CREATE OR REPLACE PACKAGE test_om_tapigen IS
-- Minimum needed DB version:     12.1
-- Needed system priviliges:      create procedure/sequence/table/trigger/view
-- Run The Test As SQL Statement: select * from table(ut.run('test_om_tapigen'));
--------------------------------------------------------------------------------

--%suite(OraMUC Table API Generator)
--%rollback(manual)

--%beforeall
procedure util_drop_and_create_test_table_objects;

--%beforeeach
procedure util_drop_generated_objects;

--%test
procedure test_all_tables_with_defaults;

--%test
procedure test_all_tables_enable_dml_and_1_to_1_view;

--%test
procedure test_all_tables_return_row_instead_of_pk_true;

--%test
procedure test_all_tables_double_quote_names_false;

--%test
procedure test_all_tables_enable_column_defaults_true;

--%test
procedure test_users_roles_rights_audit_column_mappings_configured;

--%test
procedure test_table_users_create_methods_only;

--%test
procedure test_table_users_update_methods_only;

--%test
procedure test_table_users_delete_methods_only;

--%test
procedure test_table_users_create_and_update_methods;

--%test
procedure test_table_with_very_short_column_names;

--%test
procedure test_table_with_very_long_column_names;

--%test
procedure test_table_users_default_api_object_names;

--%test
procedure test_table_users_different_api_object_names;

--%test
procedure test_table_with_tenant_id_invisible;

--%test
procedure test_table_with_tenant_id_visible;

--%test
procedure test_all_tables_enable_custom_defaults_true;

--------------------------------------------------------------------------------

subtype t_name is varchar2(128);

cursor cur_all_test_tables is
  select table_name
    from user_tables
   where table_name like 'TAG\_%' escape '\';

cursor cur_user_roles_rights is
  select table_name
    from user_tables
   where table_name like 'TAG%USERS%'
      or table_name like 'TAG%ROLES%'
      or table_name like 'TAG%RIGHTS%';

cursor cur_all_test_table_objects is
  select *
    from user_objects
   where object_type in ('TABLE', 'SEQUENCE')
     and object_name like 'TAG\_%' escape '\';

cursor cur_all_generated_objects is
  select *
    from user_objects
   where object_type in ('VIEW', 'PACKAGE')
     and object_name like 'TAG\_%' escape '\';

--------------------------------------------------------------------------------

procedure util_create_test_table_objects;

procedure util_drop_test_table_objects;

function util_count_generated_objects return integer;

function util_get_list_of_invalid_generated_objects return varchar2;

function util_get_test_name return varchar2;
function util_get_spec_regex_count (
  p_code        clob,
  p_regex_count varchar2
) return integer;

function util_get_regex_substr_count (
  p_code         clob,
  p_regex_substr varchar2,
  p_regex_count  varchar2
) return integer;

function  util_check_if_package_exists (p_name varchar2) return boolean;

function  util_check_if_view_exists (p_name varchar2) return boolean;

function  util_check_if_trigger_exists (p_name varchar2) return boolean;

--------------------------------------------------------------------------------

END test_om_tapigen;
/
show errors
