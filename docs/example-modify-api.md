# How to modify an API without programming

<!-- toc -->

- [Generate the API](#generate-the-api)
- [Modify with PL/SQL](#modify-with-plsql)

<!-- tocstop -->

## Generate the API

--> Generate API
BEGIN
  om_tapigen.compile_api(p_table_name => 'EMPLOYEES');
END;
/

## Modify with PL/SQL

```sql
-- Modify API to own needs - consider to create a feature request(issue) if you think this is helpful for other users too.
-- https://github.com/OraMUC/table-api-generator/issues/new

DECLARE
  v_clob        CLOB;
  v_cursor      NUMBER;
  v_exec_result PLS_INTEGER;
  PROCEDURE util_execute_sql(p_sql IN OUT NOCOPY CLOB) IS
    v_cursor      NUMBER;
    v_exec_result PLS_INTEGER;
  BEGIN
    v_cursor := dbms_sql.open_cursor;
    dbms_sql.parse(v_cursor,
                   p_sql,
                   dbms_sql.native);
    v_exec_result := dbms_sql.execute(v_cursor);
    dbms_sql.close_cursor(v_cursor);
  EXCEPTION
    WHEN OTHERS THEN
      dbms_sql.close_cursor(v_cursor);
      RAISE;
  END util_execute_sql;
BEGIN
  v_clob := rtrim(dbms_metadata.get_ddl('PACKAGE_BODY',
                                        'EMPLOYEES_API'),
                  '/');

  -- If you create a procedure like this anonymous block of code you can generalize the replacements
  v_clob := REPLACE(REPLACE(v_clob,
                            'INSERT INTO EMPLOYEES ( "EMPLOYEE_ID", ',
                            'INSERT INTO EMPLOYEES ( '),
                    'VALUES ( v_pk, ',
                    'VALUES ( ');

  --dbms_output.put_line(v_clob);
  util_execute_sql(v_clob);

EXCEPTION
  WHEN OTHERS THEN
    NULL;
END;
/
```
