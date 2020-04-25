set linesize 240 pagesize 20 feedback off serveroutput on
whenever sqlerror exit sql.sqlcode rollback

prompt --drop table
drop table app_users;

prompt --drop sequence
drop sequence global_version_sequence;

prompt --create sequence
create sequence global_version_sequence;

prompt --create table
create table app_users(
  au_id          integer       generated always as identity,
  au_first_name  varchar2(15)            ,
  au_last_name   varchar2(15)            ,
  au_email       varchar2(30)  not null  ,
  au_version_id  integer       not null  ,
  au_created_on  date          not null  , -- This is only for demonstration
  au_created_by  char(15)      not null  , -- purposes. In reality we expect
  au_updated_at  timestamp     not null  , -- more unified names and types
  au_updated_by  varchar2(15)  not null  , -- for audit columns.
  au_number      number                  ,
  au_float       float                   ,
  au_xmltype     xmltype                 ,
  au_clob        clob                    ,
  au_blob        blob                    ,
  --
  primary key (au_id),
  unique (au_email)
);

prompt --create the api
begin
  om_tapigen.util_set_debug_on;
  om_tapigen.compile_api(
    p_table_name                 => 'APP_USERS',
    p_enable_insertion_of_rows   => true,
    p_enable_update_of_rows      => true,
    p_enable_deletion_of_rows    => true,
    p_return_row_instead_of_pk   => false,
    p_enable_dml_view            => true,
    p_audit_column_mappings      => 'created=#PREFIX#_CREATED_ON, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED_AT, updated_by=#PREFIX#_UPDATED_BY',
    p_row_version_column_mapping => '#PREFIX#_VERSION_ID=global_version_sequence.nextval',
    p_enable_custom_defaults     => true);
end;
/
prompt --parameter based create and update
begin
  app_users_api.create_row(
    --p_au_id         => null,
    p_au_first_name => 'Dummy',
    p_au_last_name  => 'User',
    p_au_email      => 'dummy.user@world.com',
    p_au_number     => null,
    p_au_float      => null,
    p_au_xmltype    => null,
    p_au_clob       => null,
    p_au_blob       => null);
  --
  app_users_api.update_row(
    p_au_id         => app_users_api.get_pk_by_unique_cols(p_au_email => 'dummy.user@world.com'),
    p_au_first_name => 'Dummy',
    p_au_last_name  => 'User',
    p_au_email      => 'dummy.user@world.net',
    p_au_number     => null,
    p_au_float      => null,
    p_au_xmltype    => xmltype('<test/>'),
    p_au_clob       => null,
    p_au_blob       => null);
end;
/
prompt --row based create and update
declare
  v_row app_users%rowtype;
begin
  v_row.au_email := 'test@test.com';
  app_users_api.create_row(v_row);
  -- you get a read method for each primary/unique key
  v_row := app_users_api.read_row(p_au_email => 'test@test.com');
  v_row.au_last_name := 'dummy';
  app_users_api.update_row(v_row);
end;
/

prompt --create 10 rows without any parameter
begin
  for i in 1..10 loop
    app_users_api.create_a_row;
  end loop;
end;
/

prompt --commit work
commit;

prompt --select existing data and invalid objects
SELECT
  au_id,
  au_first_name,
  au_last_name,
  au_email,
  au_version_id,
  au_created_on,
  au_created_by,
  au_updated_at,
  au_updated_by
FROM
  app_users;

select app_users_api.get_au_xmltype(1) as au_xmltype_id_1 from dual;

SELECT LISTAGG(OBJECT_NAME, ', ') WITHIN GROUP(ORDER BY OBJECT_NAME) as invalid_objects
  FROM USER_OBJECTS
 WHERE STATUS = 'INVALID';

select * from table(om_tapigen.util_view_package_state);

/*
select * from table(om_tapigen.util_view_columns_array);
select * from table(om_tapigen.util_view_package_state);
select * from table(om_tapigen.util_view_debug_log) order by run desc, step desc;
select * from table(om_tapigen.view_existing_apis);
select * from table(om_tapigen.view_naming_conflicts);
select * from logger_logs order by id desc;
select table_name, column_name, default_on_null from user_tab_cols;
*/