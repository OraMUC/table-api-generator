prompt Create log table

--drop table, if it exists
begin
  for i in (select table_name from user_tables where table_name = 'TEST_OM_TAPIGEN_LOG') loop
    execute immediate 'drop table ' || i.table_name;
  end loop;
end;
/

--create table
create table test_om_tapigen_log (
  id              integer             generated always as identity,
  test_name       varchar2(128 char)  not null  ,
  table_name      varchar2(128 char)  not null  ,
  generated_on    timestamp           not null  ,
  generated_by    varchar2(30 char)   not null  ,
  generated_code  clob                          ,
  --
  primary key (id)
);

--create table API - clearly, we use our table api generator for this ;-)
begin
  om_tapigen.compile_api(
    p_table_name                  => 'TEST_OM_TAPIGEN_LOG',
    p_enable_update_of_rows       => false,
    p_enable_proc_with_out_params => false,
    p_enable_getter_and_setter    => false,
    p_audit_column_mappings       => 'created=GENERATED_ON, created_by=GENERATED_BY'
  );
end;
/