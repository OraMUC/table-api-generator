# Naming Conventions

The generator is creating the following objects for each table during the compilation phase (with the create or replace clause):

- `#TABLE_NAME#_API`: The API package itself
- `#TABLE_NAME#_DML_V`: An optional DML view, mainly a helper for APEX tabular forms
- `#TABLE_NAME#_IOIUD`: An optional instead of trigger on the DML view, which calls simply the table API

If you want to check if generated objects with their names already exist before the very first API compilation, you can use this pipelined table function:

```sql
select * from table(om_tapigen.view_naming_conflicts);
```
