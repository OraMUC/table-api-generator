# Naming Conventions

The generator is creating the following objects for each table during the compilation phase (with the create or replace clause):

- `#TABLE_NAME_26#_API`: The API package itself
- `#TABLE_NAME_24#_DML_V`: An optional DML view, mainly a helper for APEX tabular forms
- `#TABLE_NAME_24#_IOIUD`: An optional instead of trigger on the DML view, which calls simply the table API

Additionally the generator is creating once in a schema a generic change log table if you set the parameter p_enable_generic_change_log to true:

- `GENERIC_CHANGE_LOG`: The table itself
- `GENERIC_CHANGE_LOG_SEQ`: The sequence
- `GENERIC_CHANGE_LOG_PK`: The primary key index
- `GENERIC_CHANGE_LOG_IDX`: An additional index

The generator is checking by itself, if the corresponding sequence and index names are already in use in the schema. If it is the case, an error is raised.

We think currently about a new parameter to enable or disable the generation of the view and the trigger. Not all of the projects require updatable DML views and you can also use the API methods on a tabular form directly (but the wizard driven tabular form creation is easier to implement with the DML view).

If you want to check if generated objects with their names already exist before the very first API compilation, you can use this pipelined table function:

```sql
SELECT *
  FROM TABLE(your_install_schema.om_tapigen.view_naming_conflicts);
```