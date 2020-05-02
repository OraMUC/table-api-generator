create or replace package body test_om_tapigen is

  procedure compile_apis_with_defaults is
    pragma autonomous_transaction;
    --
    function compile_apis return varchar2 is
    begin
      for i in (
        select table_name from user_tables where table_name like 'TAG%'
      ) loop
        om_tapigen.compile_api(p_table_name => i.table_name);
      end loop;
      return get_list_of_invalid_objects;
    end;
    --
  begin
    ut.expect(compile_apis).to_be_null;
  end compile_apis_with_defaults;

  procedure drop_objects_and_create_tables is
  begin
    drop_objects(p_only_if_all_valid => false);
    execute immediate 'create sequence tag_global_version_sequence';
    execute immediate '
      create table tag_users (
        u_id             integer       generated always as identity,
        u_first_name     varchar2(15)            ,
        u_last_name      varchar2(15)            ,
        u_email          varchar2(30)  not null  ,
        u_version_id     integer       not null  ,
        u_created_on     date          not null  , -- This is only for demonstration
        u_created_by     char(15)      not null  , -- purposes. In reality we expect
        u_updated_at     timestamp     not null  , -- more unified names and types
        u_updated_by     varchar2(15)  not null  , -- for audit columns.
        --
        primary key (u_id),
        unique (u_email)
      )
    ';
    execute immediate '
      create table tag_all_data_types_single_pk (
        adt1_id             integer       generated always as identity,
        adt1_varchar        varchar2(15)            ,
        adt1_char           char(1)       not null  ,
        adt1_integer        integer                 ,
        adt1_number         number                  ,
        adt1_number_x_5     number(*,5)             ,
        adt1_number_20_5    number(20,5)            ,
        adt1_float          float                   ,
        adt1_float_size_30  float(30)               ,
        adt1_xmltype        xmltype                 ,
        adt1_clob           clob                    ,
        adt1_blob           blob                    ,
        --
        primary key (adt1_id),
        unique (adt1_varchar)
      )
    ';
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
    execute immediate '
      begin null; end;
    ';
    execute immediate '
      begin null; end;
    ';
    execute immediate '
      begin null; end;
    ';
  end drop_objects_and_create_tables;

  procedure drop_objects(p_only_if_all_valid boolean default true) is
    --
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
    --
    procedure drop_other_objects is
    begin
      for i in (
        select
          *
        from
          user_objects
        where
          object_type in ('TABLE', 'SEQUENCE', 'VIEW', 'PACKAGE')
          and object_name like 'TAG_%' escape '\'
      ) loop
        execute immediate 'drop ' || i.object_type || ' ' || i.object_name;
      end loop;
    end drop_other_objects;
    --
  begin
    if
      p_only_if_all_valid and get_list_of_invalid_objects is null
      or
      not p_only_if_all_valid
    then
      drop_fk_constraints;
      drop_other_objects;
      execute immediate 'purge recyclebin';
    end if;
  end drop_objects;

  function get_list_of_invalid_objects return varchar2 is
    v_return varchar2(4000);
  begin
    select listagg(object_name || to_char(LAST_DDL_TIME,' yyyy-mm-dd hh24:mi:ss'), ', ') within group(order by object_name) as invalid_objects
    into v_return
    from user_objects
    where status = 'INVALID';
    return v_return;
  end get_list_of_invalid_objects;

end test_om_tapigen;
/
