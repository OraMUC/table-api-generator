<!-- nav -->

[Index](index.md)
| [Changelog](changelog.md)
| [Getting Started](getting-started.md)
| [Parameters](parameters.md)
| [Naming Conventions](naming-conventions.md)
| [Bulk Processing](bulk-processing.md)
| [Example API](example-api.md)

<!-- navstop -->

# Bulk Processing

<!-- toc -->

- [Create the Table](#create-the-table)
- [Create the API](#create-the-api)
- [Example Insert](#example-insert)
- [Example Update](#example-update)

<!-- tocstop -->

## Create the Table

```sql
create table app_users (
  au_id          integer            generated always as identity,
  au_first_name  varchar2(15 char)                         ,
  au_last_name   varchar2(15 char)                         ,
  au_email       varchar2(30 char)               not null  ,
  au_active_yn   varchar2(1 char)   default 'Y'  not null  ,
  au_created_on  date                            not null  , -- This is only for demo purposes.
  au_created_by  char(15 char)                   not null  , -- In reality we expect more
  au_updated_at  timestamp                       not null  , -- unified names and types
  au_updated_by  varchar2(15 char)               not null  , -- for audit columns.
  --
  primary key (au_id),
  unique (au_email),
  check (au_active_yn in ('Y', 'N'))
);
```

## Create the API

```sql
begin
  om_tapigen.compile_api(
    p_table_name            => 'APP_USERS',
    p_audit_column_mappings => 'created=#PREFIX#_CREATED_ON, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED_AT, updated_by=#PREFIX#_UPDATED_BY'
  );
end;
/
```

## Example Insert

```sql
declare
  l_rows_tab     app_users_api.t_rows_tab;
  l_number_bulks integer := 100;
  l_bulk_size    integer := 1000;
begin
  l_rows_tab := app_users_api.t_rows_tab();
  l_rows_tab.extend(l_bulk_size);

  <<number_bulks>>
  for z in 1 .. l_number_bulks loop

    <<bulk_size>>
    for i in 1 .. l_bulk_size loop
      l_rows_tab(i).au_first_name := initcap(sys.dbms_random.string('L', round(sys.dbms_random.value(3, 15))));
      l_rows_tab(i).au_last_name  := initcap(sys.dbms_random.string('L', round(sys.dbms_random.value(3, 15))));
      l_rows_tab(i).au_email      := sys.dbms_random.string('L', round(sys.dbms_random.value(6, 12)))
        || '@' || sys.dbms_random.string('L', round(sys.dbms_random.value(6, 12)))
        || '.' || sys.dbms_random.string('L', round(sys.dbms_random.value(2, 4)));
      l_rows_tab(i).au_active_yn  := 'Y';
    end loop bulk_size;

    app_users_api.create_rows(l_rows_tab);
    commit;

  end loop number_bulks;
end;
/
```

## Example Update

```sql
declare
  l_rows_tab   app_users_api.t_rows_tab;
  l_ref_cursor app_users_api.t_strong_ref_cursor;
begin
  -- optionally set bulk limit, default is 1000
  -- app_users_api.set_bulk_limit(500);
  open l_ref_cursor for select * from app_users;

  <<outer_bulk>>
  loop
    l_rows_tab := app_users_api.read_rows(l_ref_cursor);

    <<inner_data>>
    for i in 1 .. l_rows_tab.count
    loop
      --do your business logic here
      l_rows_tab(i).au_email := upper(l_rows_tab(i).au_email);
    end loop inner_data;

    app_users_api.update_rows(l_rows_tab);
    commit;

    exit when app_users_api.bulk_is_complete;
  end loop outer_bulk;

  close l_ref_cursor;
end;
/
```
