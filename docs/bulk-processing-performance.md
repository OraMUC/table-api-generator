# Bulk Processing

## Create the table

```sql
create table app_users (
  au_id             integer            generated always as identity,
  au_first_name     varchar2(15 char)            ,
  au_last_name      varchar2(15 char)            ,
  au_email          varchar2(30 char)  not null  ,
  au_created_on     date               not null  , -- This is only for demo purposes.
  au_created_by     char(15 char)      not null  , -- In reality we expect more
  au_updated_at     timestamp          not null  , -- unified names and types
  au_updated_by     varchar2(15 char)  not null  , -- for audit columns.
  --
  primary key (au_id),
  unique (au_email)
);
```

## Create the API

```sql
begin
  om_tapigen.compile_api(
    p_table_name             => 'APP_USERS',
    p_enable_custom_defaults => true, -- our special feature for the testing folks ;-)
    p_audit_column_mappings  => 'created=#PREFIX#_CREATED_ON, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED_AT, updated_by=#PREFIX#_UPDATED_BY'
  );
end;
/
```

## Create 10,000 rows

```sql
begin
  for i in 1 .. 100000 loop
    app_users_api.create_a_row; -- this method exists because of p_enable_custom_defaults => true, also see the docs
  end loop;
  commit;
end;
/
```

## Example row by row (slow by slow) processing

```sql
begin
  <<slow_by_slow>>
  for i in (select * from app_users) loop
    app_users_api.set_au_email(
      p_au_id    => i.au_id,
      p_au_email => upper(i.au_email)
    );
  end loop slow_by_slow;
  commit;
end;
/
```

## Example set based processing

```sql
set timing on

declare
  l_rows_tab   app_users_api.t_rows_tab;
  l_ref_cursor app_users_api.t_strong_ref_cursor;
begin
  open l_ref_cursor for select * from app_users;

  --optionally set bulk limit, default is 1000
  --app_users_api.set_bulk_limit(500);

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

## Analyze statements

```sql
select * from app_users;

select
  max(au_updated_at) - min(au_updated_at) as db_runtime,
  min(au_updated_at) min_update,
  max(au_updated_at) max_update
from
  app_users;

with t as (
select
  count(*) as bulk_size
from
  app_users
group by
  au_updated_at)
select count(*) as number_bulks, bulk_size
from t group by bulk_size;
```
