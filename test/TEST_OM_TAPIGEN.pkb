create or replace package body test_om_tapigen is

--------------------------------------------------------------------------------

procedure test_all_tables_with_defaults is
  ----------
  function compile_apis_return_invalid_object_names return varchar2 is
  begin
    for i in cur_all_test_tables loop
      test_om_tapigen_log_api.create_row (
        p_table_name     => i.table_name,
        p_test_name      => util_get_test_name,
        p_generated_code => om_tapigen.compile_api_and_get_code(
          p_table_name => i.table_name
        )
      );
    end loop;
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_apis_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_apis_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(3);
end test_all_tables_with_defaults;

--------------------------------------------------------------------------------

procedure test_all_tables_enable_dml_and_1_to_1_view is
  ----------
  function compile_apis_return_invalid_object_names return varchar2 is
  begin
    for i in cur_all_test_tables loop
      test_om_tapigen_log_api.create_row (
        p_table_name     => i.table_name,
        p_test_name      => util_get_test_name,
        p_generated_code => om_tapigen.compile_api_and_get_code(
          p_table_name               => i.table_name,
          p_return_row_instead_of_pk => true,
          p_enable_dml_view          => true,
          p_enable_one_to_one_view   => true
        )
      );
    end loop;
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_apis_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_apis_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(12);
end test_all_tables_enable_dml_and_1_to_1_view;

--------------------------------------------------------------------------------

procedure test_all_tables_return_row_instead_of_pk_true is
  ----------
  function compile_apis_return_invalid_object_names return varchar2 is
  begin
    for i in cur_all_test_tables loop
      test_om_tapigen_log_api.create_row (
        p_table_name     => i.table_name,
        p_test_name      => util_get_test_name,
        p_generated_code => om_tapigen.compile_api_and_get_code(
          p_table_name               => i.table_name,
          p_return_row_instead_of_pk => true
        )
      );
    end loop;
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_apis_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_apis_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(3);
end test_all_tables_return_row_instead_of_pk_true;

--------------------------------------------------------------------------------

procedure test_all_tables_double_quote_names_false is
  ----------
  function compile_apis_return_invalid_object_names return varchar2 is
  begin
    for i in cur_all_test_tables loop
      test_om_tapigen_log_api.create_row (
        p_table_name     => i.table_name,
        p_test_name      => util_get_test_name,
        p_generated_code => om_tapigen.compile_api_and_get_code(
          p_table_name         => i.table_name,
          p_double_quote_names => false
        )
      );
    end loop;
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_apis_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_apis_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(3);
end test_all_tables_double_quote_names_false;

--------------------------------------------------------------------------------

procedure test_all_tables_audit_column_mappings_configured is
  ----------
  function compile_apis_return_invalid_object_names return varchar2 is
  begin
    for i in cur_all_test_tables loop
      test_om_tapigen_log_api.create_row (
        p_table_name     => i.table_name,
        p_test_name      => util_get_test_name,
        p_generated_code => om_tapigen.compile_api_and_get_code(
          p_table_name                 => i.table_name,
          p_row_version_column_mapping => '#PREFIX#_VERSION_ID=tag_global_version_sequence.nextval',
          p_audit_column_mappings      => 'created=#PREFIX#_CREATED, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED, updated_by=#PREFIX#_UPDATED_BY'
        )
      );
    end loop;
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_apis_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_apis_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(3);
end test_all_tables_audit_column_mappings_configured;

--------------------------------------------------------------------------------

procedure test_table_users_create_methods_only is
  l_table_name t_name := 'TAG_USERS';
  l_code clob;
  ----------
  function compile_api_return_invalid_object_names return varchar2 is
  begin
    l_code := om_tapigen.compile_api_and_get_code(
      p_table_name                 => l_table_name,
      p_enable_insertion_of_rows   => true,
      p_enable_update_of_rows      => false,
      p_enable_deletion_of_rows    => false,
      p_row_version_column_mapping => '#PREFIX#_VERSION_ID=tag_global_version_sequence.nextval',
      p_audit_column_mappings      => 'created=#PREFIX#_CREATED_ON, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED_AT, updated_by=#PREFIX#_UPDATED_BY'
    );
    test_om_tapigen_log_api.create_row (
      p_table_name     => l_table_name,
      p_test_name      => util_get_test_name,
      p_generated_code => l_code
    );
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_api_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_api_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(1);
  ut.expect(util_get_spec_regex_count(l_code,' get_pk_by_unique_cols')).to_equal(1);
  ut.expect(util_get_spec_regex_count(l_code,' create_row')).to_equal(6);
  ut.expect(util_get_spec_regex_count(l_code,' read_row')).to_equal(4);
  ut.expect(util_get_spec_regex_count(l_code,' update_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' delete_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' create_or_update_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' get_u_')).to_equal(9);
  ut.expect(util_get_spec_regex_count(l_code,' set_u_')).to_equal(0);
end test_table_users_create_methods_only;

--------------------------------------------------------------------------------

procedure test_table_users_update_methods_only is
  l_table_name t_name := 'TAG_USERS';
  l_code clob;
  ----------
  function compile_api_return_invalid_object_names return varchar2 is
  begin
    l_code := om_tapigen.compile_api_and_get_code(
      p_table_name                 => l_table_name,
      p_enable_insertion_of_rows   => false,
      p_enable_update_of_rows      => true,
      p_enable_deletion_of_rows    => false,
      p_row_version_column_mapping => '#PREFIX#_VERSION_ID=tag_global_version_sequence.nextval',
      p_audit_column_mappings      => 'created=#PREFIX#_CREATED_ON, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED_AT, updated_by=#PREFIX#_UPDATED_BY'
    );
    test_om_tapigen_log_api.create_row (
      p_table_name     => l_table_name,
      p_test_name      => util_get_test_name,
      p_generated_code => l_code
    );
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_api_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_api_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(1);
  ut.expect(util_get_spec_regex_count(l_code,' get_pk_by_unique_cols')).to_equal(1);
  ut.expect(util_get_spec_regex_count(l_code,' create_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' read_row')).to_equal(4);
  ut.expect(util_get_spec_regex_count(l_code,' update_row')).to_equal(3);
  ut.expect(util_get_spec_regex_count(l_code,' delete_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' create_or_update_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' get_u_')).to_equal(9);
  ut.expect(util_get_spec_regex_count(l_code,' set_u_')).to_equal(4);
end test_table_users_update_methods_only;

--------------------------------------------------------------------------------

procedure test_table_users_delete_methods_only is
  l_table_name t_name := 'TAG_USERS';
  l_code clob;
  ----------
  function compile_api_return_invalid_object_names return varchar2 is
  begin
    l_code := om_tapigen.compile_api_and_get_code(
      p_table_name                 => l_table_name,
      p_enable_insertion_of_rows   => false,
      p_enable_update_of_rows      => false,
      p_enable_deletion_of_rows    => true,
      p_row_version_column_mapping => '#PREFIX#_VERSION_ID=tag_global_version_sequence.nextval',
      p_audit_column_mappings      => 'created=#PREFIX#_CREATED_ON, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED_AT, updated_by=#PREFIX#_UPDATED_BY'
    );
    test_om_tapigen_log_api.create_row (
      p_table_name     => l_table_name,
      p_test_name      => util_get_test_name,
      p_generated_code => l_code
    );
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_api_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_api_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(1);
  ut.expect(util_get_spec_regex_count(l_code,' get_pk_by_unique_cols')).to_equal(1);
  ut.expect(util_get_spec_regex_count(l_code,' create_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' read_row')).to_equal(4);
  ut.expect(util_get_spec_regex_count(l_code,' update_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' delete_row')).to_equal(2);
  ut.expect(util_get_spec_regex_count(l_code,' create_or_update_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' get_u_')).to_equal(9);
  ut.expect(util_get_spec_regex_count(l_code,' set_u_')).to_equal(0);
end test_table_users_delete_methods_only;

--------------------------------------------------------------------------------

procedure test_table_users_create_and_update_methods is
  l_table_name t_name := 'TAG_USERS';
  l_code clob;
  ----------
  function compile_api_return_invalid_object_names return varchar2 is
  begin
    l_code := om_tapigen.compile_api_and_get_code(
      p_table_name                 => l_table_name,
      p_enable_insertion_of_rows   => true,
      p_enable_update_of_rows      => true,
      p_enable_deletion_of_rows    => false,
      p_enable_dml_view          => true,
      p_enable_one_to_one_view   => true,
      p_row_version_column_mapping => '#PREFIX#_VERSION_ID=tag_global_version_sequence.nextval',
      p_audit_column_mappings      => 'created=#PREFIX#_CREATED_ON, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED_AT, updated_by=#PREFIX#_UPDATED_BY'
    );
    test_om_tapigen_log_api.create_row (
      p_table_name     => l_table_name,
      p_test_name      => util_get_test_name,
      p_generated_code => l_code
    );
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_api_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_api_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(4);
  ut.expect(util_get_spec_regex_count(l_code,' get_pk_by_unique_cols')).to_equal(1);
  ut.expect(util_get_spec_regex_count(l_code,' create_row')).to_equal(6);
  ut.expect(util_get_spec_regex_count(l_code,' read_row')).to_equal(4);
  ut.expect(util_get_spec_regex_count(l_code,' update_row')).to_equal(3);
  ut.expect(util_get_spec_regex_count(l_code,' delete_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' create_or_update_row')).to_equal(4);
  ut.expect(util_get_spec_regex_count(l_code,' get_u_')).to_equal(9);
  ut.expect(util_get_spec_regex_count(l_code,' set_u_')).to_equal(4);
  ut.expect(util_get_regex_substr_count(l_code,'create_row \(.*?\)', 'p_u_')).to_equal(4);
  ut.expect(util_get_regex_substr_count(l_code,'update_row \(.*?\)', 'p_u_')).to_equal(5);
end test_table_users_create_and_update_methods;

--------------------------------------------------------------------------------

procedure util_drop_and_create_test_table_objects is
begin
  util_drop_test_table_objects;
  util_create_test_table_objects;
end util_drop_and_create_test_table_objects;

--------------------------------------------------------------------------------

procedure util_create_test_table_objects is
  ----------
  procedure tag_global_version_sequence is
  begin
    execute immediate 'create sequence tag_global_version_sequence';
  end tag_global_version_sequence;
  ----------
  procedure tag_users is
  begin
    execute immediate q'[
      create table tag_users (
        u_id          integer            generated always as identity,
        u_first_name  varchar2(15 char)                         ,
        u_last_name   varchar2(15 char)                         ,
        u_email       varchar2(30 char)               not null  ,
        u_active_yn   varchar2(1 char)   default 'Y'  not null  ,
        u_version_id  integer                         not null  ,
        u_created_on  date                            not null  , -- This is only for demo purposes.
        u_created_by  char(15 char)                   not null  , -- In reality we expect more
        u_updated_at  timestamp                       not null  , -- unified names and types
        u_updated_by  varchar2(15 char)               not null  , -- for audit columns.
        --
        primary key (u_id),
        unique (u_email),
        check (u_active_yn in ('Y', 'N'))
      )
    ]';
  end tag_users;
  ----------
  procedure tag_all_data_types_single_pk is
  begin
    execute immediate '
      create table tag_all_data_types_single_pk (
        adt1_id             integer            generated always as identity,
        adt1_varchar        varchar2(15 char)            ,
        adt1_char           char(1 char)       not null  ,
        adt1_integer        integer                      ,
        adt1_number         number                       ,
        adt1_number_x_5     number(*,5)                  ,
        adt1_number_20_5    number(20,5)                 ,
        adt1_float          float                        ,
        adt1_float_size_30  float(30)                    ,
        adt1_xmltype        xmltype                      ,
        adt1_clob           clob                         ,
        adt1_blob           blob                         ,
        --
        primary key (adt1_id),
        unique (adt1_varchar)
      )
    ';
  end tag_all_data_types_single_pk;
  ----------
  procedure tag_all_data_types_multi_pk is
  begin
    execute immediate '
      create table tag_all_data_types_multi_pk (
        adt2_id             integer       generated always as identity,
        adt2_varchar        varchar2(15)            ,
        adt2_char           char(1)       not null  ,
        adt2_integer        integer                 ,
        adt2_number         number                  ,
        adt2_number_x_5     number(*,5)             ,
        adt2_number_20_5    number(20,5)            ,
        adt2_float          float                   ,
        adt2_float_size_30  float(30)               ,
        adt2_xmltype        xmltype                 ,
        adt2_clob           clob                    ,
        adt2_blob           blob                    ,
        --
        primary key (adt2_id, adt2_varchar)
      )
    ';
  end tag_all_data_types_multi_pk;
  ----------
begin
  tag_global_version_sequence;
  tag_users;
  tag_all_data_types_single_pk;
  tag_all_data_types_multi_pk;
end util_create_test_table_objects;

--------------------------------------------------------------------------------

procedure util_drop_test_table_objects is
  ----------
  procedure drop_fk_constraints is
  begin
    for i in (
        select
          constraint_name,
          table_name
        from
          user_constraints
        where
          constraint_type = 'R'
          and table_name like 'TAG_%' escape '\'
    ) loop
      execute immediate 'alter table ' || i.table_name || ' drop constraint ' || i.constraint_name;
    end loop;
  end drop_fk_constraints;
  ----------
  procedure drop_tables_and_sequences is
  begin
    for i in cur_all_test_table_objects loop
      execute immediate 'drop ' || i.object_type || ' ' || i.object_name;
    end loop;
  end drop_tables_and_sequences;
  ----------
begin
  drop_fk_constraints;
  drop_tables_and_sequences;
  execute immediate 'purge recyclebin';
end util_drop_test_table_objects;

--------------------------------------------------------------------------------

procedure util_drop_generated_objects is
begin
  for i in cur_all_generated_objects loop
    execute immediate 'drop ' || i.object_type || ' ' || i.object_name;
  end loop;
  execute immediate 'purge recyclebin';
end util_drop_generated_objects;

--------------------------------------------------------------------------------

function  util_count_generated_objects return integer is
  l_return integer;
begin
  select
    count(*)
  into
    l_return
  from
    user_objects
  where
    object_type in ('PACKAGE', 'VIEW', 'TRIGGER')
    and object_name like 'TAG\_%' escape '\';
  return l_return;
end util_count_generated_objects;

--------------------------------------------------------------------------------

function util_get_list_of_invalid_generated_objects return varchar2 is
  l_return varchar2(4000);
begin
  select
    listagg(object_name || to_char(LAST_DDL_TIME,' yyyy-mm-dd hh24:mi:ss'), ', ')
      within group(order by object_name) as invalid_objects
  into
    l_return
  from
    user_objects
  where
    object_name like 'TAG\_%' escape '\'
    and status = 'INVALID';
  return l_return;
end util_get_list_of_invalid_generated_objects;

--------------------------------------------------------------------------------

function util_get_test_name return varchar2 is
begin
  -- https://stackoverflow.com/questions/50536323/currently-executing-procedure-name-within-the-package-in-oracle
  return utl_call_stack.subprogram(2)(2);
end util_get_test_name;

--------------------------------------------------------------------------------

function  util_get_spec_regex_count (
  p_code        clob,
  p_regex_count varchar2
) return integer is
  l_spec clob;
begin
  l_spec := regexp_substr(p_code, '(CREATE OR REPLACE PACKAGE.*)CREATE OR REPLACE PACKAGE BODY', 1, 1, 'in', 1);
  return regexp_count(l_spec, p_regex_count);
end util_get_spec_regex_count;

--------------------------------------------------------------------------------

function util_get_regex_substr_count (
  p_code         clob,
  p_regex_substr varchar2,
  p_regex_count  varchar2
) return integer is
  l_substr clob;
begin
  l_substr := regexp_substr(p_code, p_regex_substr, 1, 1, 'in');
  --logger.log('l_substr: '|| l_substr);
  return regexp_count(l_substr, p_regex_count);
end util_get_regex_substr_count;

--------------------------------------------------------------------------------

end test_om_tapigen;
/
