create or replace package body test_om_tapigen is

--------------------------------------------------------------------------------

procedure all_tables_with_defaults is
  ----------
  function compile_apis return varchar2 is
  begin
    for i in all_test_tables loop
      test_om_tapigen_log_api.create_row (
        p_table_name     => i.table_name,
        p_test_name      => get_package_method_name,
        p_generated_code => om_tapigen.compile_api_and_get_code(
          p_table_name => i.table_name
        )
      );
    end loop;
    commit;
    return get_list_of_invalid_generated_objects;
  end;
  ----------
begin
  ut.expect(compile_apis).to_be_null;
end all_tables_with_defaults;

--------------------------------------------------------------------------------

procedure all_tables_return_row_instead_of_pk is
  ----------
  function compile_apis return varchar2 is
  begin
    for i in all_test_tables loop
      test_om_tapigen_log_api.create_row (
        p_table_name     => i.table_name,
        p_test_name      => get_package_method_name,
        p_generated_code => om_tapigen.compile_api_and_get_code(
          p_table_name               => i.table_name,
          p_return_row_instead_of_pk => true
        )
      );
    end loop;
    commit;
    return get_list_of_invalid_generated_objects;
  end;
  ----------
begin
  ut.expect(compile_apis).to_be_null;
end all_tables_return_row_instead_of_pk;

--------------------------------------------------------------------------------

procedure all_tables_no_double_quote_of_names is
  ----------
  function compile_apis return varchar2 is
  begin
    for i in all_test_tables loop
      test_om_tapigen_log_api.create_row (
        p_table_name     => i.table_name,
        p_test_name      => get_package_method_name,
        p_generated_code => om_tapigen.compile_api_and_get_code(
          p_table_name         => i.table_name,
          p_double_quote_names => false
        )
      );
    end loop;
    commit;
    return get_list_of_invalid_generated_objects;
  end;
  ----------
begin
  ut.expect(compile_apis).to_be_null;
end all_tables_no_double_quote_of_names;

--------------------------------------------------------------------------------

procedure all_tables_set_audit_column_mappings is
  ----------
  function compile_apis return varchar2 is
  begin
    for i in all_test_tables loop
      test_om_tapigen_log_api.create_row (
        p_table_name     => i.table_name,
        p_test_name      => get_package_method_name,
        p_generated_code => om_tapigen.compile_api_and_get_code(
          p_table_name                 => i.table_name,
          p_row_version_column_mapping => '#PREFIX#_VERSION_ID=tag_global_version_sequence.nextval',
          p_audit_column_mappings      =>
            'created=#PREFIX#_CREATED, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED, updated_by=#PREFIX#_UPDATED_BY'
        )
      );
    end loop;
    commit;
    return get_list_of_invalid_generated_objects;
  end;
  ----------
begin
  ut.expect(compile_apis).to_be_null;
end all_tables_set_audit_column_mappings;

--------------------------------------------------------------------------------

procedure drop_and_create_test_table_objects is
begin
  drop_test_table_objects;
  create_test_table_objects;
end;

--------------------------------------------------------------------------------

procedure create_test_table_objects is
  ----------
  procedure tag_global_version_sequence is
  begin
    execute immediate 'create sequence tag_global_version_sequence';
  end tag_global_version_sequence;
  ----------
  procedure tag_users is
  begin
    execute immediate '
      create table tag_users (
        u_id             integer            generated always as identity,
        u_first_name     varchar2(15 char)            ,
        u_last_name      varchar2(15 char)            ,
        u_email          varchar2(30 char)  not null  ,
        u_version_id     integer            not null  ,
        u_created        date               not null  , -- This is only for demonstration
        u_created_by     char(15 char)      not null  , -- purposes. In reality we expect
        u_updated        timestamp          not null  , -- more unified names and types
        u_updated_by     varchar2(15 char)  not null  , -- for audit columns.
        --
        primary key (u_id),
        unique (u_email)
      )
    ';
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
end create_test_table_objects;

--------------------------------------------------------------------------------

procedure drop_test_table_objects is
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
    for i in all_test_table_objects loop
      execute immediate 'drop ' || i.object_type || ' ' || i.object_name;
    end loop;
  end drop_tables_and_sequences;
  ----------
begin
  drop_fk_constraints;
  drop_tables_and_sequences;
  execute immediate 'purge recyclebin';
end drop_test_table_objects;

--------------------------------------------------------------------------------

procedure drop_generated_objects is
begin
  for i in all_generated_objects loop
    execute immediate 'drop ' || i.object_type || ' ' || i.object_name;
  end loop;
  execute immediate 'purge recyclebin';
end drop_generated_objects;

--------------------------------------------------------------------------------

function get_list_of_invalid_generated_objects return varchar2 is
  v_return varchar2(4000);
begin
  select
    listagg(object_name || to_char(LAST_DDL_TIME,' yyyy-mm-dd hh24:mi:ss'), ', ')
      within group(order by object_name) as invalid_objects
  into
    v_return
  from
    user_objects
  where
    object_name like 'TAG\_%' escape '\'
    and status = 'INVALID';
  return v_return;
end get_list_of_invalid_generated_objects;

--------------------------------------------------------------------------------

function get_package_method_name return varchar2 is
begin
  -- https://stackoverflow.com/questions/50536323/currently-executing-procedure-name-within-the-package-in-oracle
  return utl_call_stack.subprogram(2)(2);
end get_package_method_name;

--------------------------------------------------------------------------------

end test_om_tapigen;
/
