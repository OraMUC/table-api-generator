CREATE OR REPLACE PACKAGE om_tapigen AUTHID CURRENT_USER IS
c_generator         CONSTANT VARCHAR2(10 CHAR) := 'OM_TAPIGEN';
c_generator_version CONSTANT VARCHAR2(10 CHAR) := '0.5.2.35';
/**
Oracle PL/SQL Table API Generator
=================================

_This table API generator needs an Oracle DB version 12.1 or higher and can be
integrated in the Oracle SQL-Developer with an additional wrapper package
for the [SQL Developer extension oddgen](https://www.oddgen.org/)._

The effort of generated API's is to reduce your PL/SQL code by calling standard
procedures and functions for usual DML operations on tables. So the generated
table APIs work as a logical layer between your business logic and the data. And
by the way this logical layer enables you to easily separate the data schema and
the UI schema for your applications to improve security by granting only execute
rights on table APIs to the application schema. In addition to that table APIs
will speed up your development cycles because developers are able to set the
focal point to the business logic instead of wasting time by manual creating
boilerplate code for your tables.

> Get Rid of Hard-Coding in PL/SQL ([Steven Feuerstein](https://www.youtube.com/playlist?list=PL0mkplxCP4ygQo3zAvhYrrU6hIQ0JtYTA))

FEATURES

- Generates small wrappers around your tables
- Highly configurable
- You can enable or disable separately insert, update and delete functionality
- Standard CRUD methods (column and row type based) and an additional create
  or update method
- Set based methods for high performance DML processing
- For each unique constraint a read method and a getter to fetch the primary key
- Functions to check if a row exists (primary key based, returning boolean or
  varchar2)
- Support for audit columns
- Support for a row version column
- Optional getter and setter for each column
- Optional 1:1 view to support the separation of concerns (also known as ThickDB/SmartDB/PinkDB paradigm)
- Optional DML view with an instead of trigger to support low code tools like APEX

LICENSE

- [The MIT License (MIT)](https://github.com/OraMUC/table-api-generator/blob/master/LICENSE.txt)
- Copyright (c) 2015-2020 André Borngräber, Ottmar Gobrecht

We give our best to produce clean and robust code, but we are NOT responsible,
if you loose any code or data by using this API generator. By using it you
accept the MIT license. As a best practice test the generator first in your
development environment and decide after your tests, if you want to use it in
production. If you miss any feature or find a bug, we are happy to hear from you
via the GitHub [issues](https://github.com/OraMUC/table-api-generator/issues)
functionality.

DOCS

- [Changelog](https://github.com/OraMUC/table-api-generator/blob/master/docs/changelog.md)
- [Getting started](https://github.com/OraMUC/table-api-generator/blob/master/docs/getting-started.md)
- [Detailed parameter descriptions](https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md)
- [Bulk processing](https://github.com/OraMUC/table-api-generator/blob/master/docs/bulk-processing.md)
- [Example API](https://github.com/OraMUC/table-api-generator/blob/master/docs/example-api.md)
- [SQL Developer integration](https://github.com/OraMUC/table-api-generator/blob/master/docs/sql-developer-integration.md)

LINKS

- [Project home page](https://github.com/OraMUC/table-api-generator)
- [Download the latest version](https://github.com/OraMUC/table-api-generator/releases/latest)
- [Issues](https://github.com/OraMUC/table-api-generator/issues)

**/

--------------------------------------------------------------------------------
-- Public constants (c_*) and subtypes (t_*)
--------------------------------------------------------------------------------
c_ora_max_name_len CONSTANT INTEGER := $IF $$db_version < 121 $THEN 30 $ELSE ora_max_name_len $END;

SUBTYPE t_ora_max_name_len IS VARCHAR2(c_ora_max_name_len CHAR); -- 30 or 128 depending on the system
SUBTYPE t_vc2_1            IS VARCHAR2(1 CHAR);
SUBTYPE t_vc2_2            IS VARCHAR2(2 CHAR);
SUBTYPE t_vc2_5            IS VARCHAR2(5 CHAR);
SUBTYPE t_vc2_10           IS VARCHAR2(10 CHAR);
SUBTYPE t_vc2_20           IS VARCHAR2(20 CHAR);
SUBTYPE t_vc2_30           IS VARCHAR2(30 CHAR);
SUBTYPE t_vc2_64           IS VARCHAR2(64 CHAR);
SUBTYPE t_vc2_100          IS VARCHAR2(100 CHAR);
SUBTYPE t_vc2_128          IS VARCHAR2(128 CHAR);
SUBTYPE t_vc2_200          IS VARCHAR2(200 CHAR);
SUBTYPE t_vc2_4k           IS VARCHAR2(4000 CHAR);
SUBTYPE t_vc2_16K          IS VARCHAR2(16000 CHAR);
SUBTYPE t_vc2_32K          IS VARCHAR2(32767 CHAR);

c_audit_user_expression CONSTANT t_vc2_200 := q'[coalesce(sys_context('apex$session','app_user'), sys_context('userenv','os_user'), sys_context('userenv','session_user'))]';
--------------------------------------------------------------------------------
-- Public global constants c_*
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Public record (t_rec_*) and collection (t_tab_*) types
--------------------------------------------------------------------------------
TYPE t_rec_existing_apis IS RECORD(
  errors                        t_vc2_4k,
  owner                         all_users.username%TYPE,
  table_name                    all_objects.object_name%TYPE,
  package_name                  all_objects.object_name%TYPE,
  spec_status                   all_objects.status%TYPE,
  spec_last_ddl_time            all_objects.last_ddl_time%TYPE,
  body_status                   all_objects.status%TYPE,
  body_last_ddl_time            all_objects.last_ddl_time%TYPE,
  generator                     t_vc2_10,
  generator_version             t_vc2_10,
  generator_action              t_vc2_30,
  generated_at                  DATE,
  generated_by                  all_users.username%TYPE,
  p_owner                       all_users.username%TYPE,
  p_table_name                  all_objects.object_name%TYPE,
  p_enable_insertion_of_rows    t_vc2_5,
  p_enable_column_defaults      t_vc2_5,
  p_enable_update_of_rows       t_vc2_5,
  p_enable_deletion_of_rows     t_vc2_5,
  p_enable_parameter_prefixes   t_vc2_5,
  p_enable_proc_with_out_params t_vc2_5,
  p_enable_getter_and_setter    t_vc2_5,
  p_col_prefix_in_method_names  t_vc2_5,
  p_return_row_instead_of_pk    t_vc2_5,
  p_double_quote_names          t_vc2_5,
  p_default_bulk_limit          INTEGER,
  p_enable_dml_view             t_vc2_5,
  p_dml_view_name               all_objects.object_name%TYPE,
  p_dml_view_trigger_name       all_objects.object_name%TYPE,
  p_enable_one_to_one_view      t_vc2_5,
  p_api_name                    all_objects.object_name%TYPE,
  p_sequence_name               all_objects.object_name%TYPE,
  p_exclude_column_list         t_vc2_4k,
  p_audit_column_mappings       t_vc2_4k,
  p_audit_user_expression       t_vc2_4k,
  p_row_version_column_mapping  t_vc2_4k,
  p_tenant_column_mapping       t_vc2_4k,
  p_enable_custom_defaults      t_vc2_5,
  p_custom_default_values       t_vc2_30);

TYPE t_tab_existing_apis IS TABLE OF t_rec_existing_apis;

--

TYPE t_rec_naming_conflicts IS RECORD(
  object_name   all_objects.object_name%TYPE,
  object_type   all_objects.object_type%TYPE,
  status        all_objects.status%TYPE,
  last_ddl_time all_objects.last_ddl_time%TYPE);

TYPE t_tab_naming_conflicts IS TABLE OF t_rec_naming_conflicts;

--

TYPE t_rec_debug_data IS RECORD(
  run        INTEGER,
  run_time   NUMBER,
  owner      all_users.username%TYPE,
  table_name all_objects.object_name%TYPE,
  step       INTEGER,
  elapsed    NUMBER,
  execution  NUMBER,
  action     t_vc2_64,
  start_time TIMESTAMP(6));

TYPE t_tab_debug_data IS TABLE OF t_rec_debug_data;

--

TYPE t_rec_columns IS RECORD(
  column_name            all_tab_cols.column_name%TYPE,
  data_type              all_tab_cols.data_type%TYPE,
  char_length            all_tab_cols.char_length%TYPE,
  data_length            all_tab_cols.data_length%TYPE,
  data_precision         all_tab_cols.data_precision%TYPE,
  data_scale             all_tab_cols.data_scale%TYPE,
  data_default           t_vc2_4k,
  data_custom_default    t_vc2_4k,
  custom_default_source  t_vc2_20,
  identity_type          t_vc2_20,
  default_on_null_yn     t_vc2_1,
  is_pk_yn               t_vc2_1,
  is_uk_yn               t_vc2_1,
  is_fk_yn               t_vc2_1,
  is_nullable_yn         t_vc2_1,
  is_hidden_yn           t_vc2_1,
  is_virtual_yn          t_vc2_1,
  is_excluded_yn         t_vc2_1,
  audit_type             t_vc2_20,
  row_version_expression t_vc2_4k,
  tenant_expression      t_vc2_4k,
  r_owner                all_users.username%TYPE,
  r_table_name           all_objects.object_name%TYPE,
  r_column_name          all_tab_cols.column_name%TYPE);

TYPE t_tab_debug_columns IS TABLE OF t_rec_columns;
/* We use t_tab_debug_columns as a private array/collection inside the package body
indexed by binary_integer. For the pipelined function util_view_columns_array
we need this additional table type. */

--

TYPE t_rec_package_state IS RECORD(
  package_status_key    t_vc2_30,
  value                 t_vc2_200);

TYPE t_tab_package_state IS TABLE OF t_rec_package_state;
/* For debugging we can view some global package state
variables with the pipelined function util_view_package_state. */

--

TYPE t_rec_clob_line_by_line IS RECORD(
  text t_vc2_4k);

TYPE t_tab_clob_line_by_line IS TABLE OF t_rec_clob_line_by_line;

--

TYPE t_tab_vc2_4k IS TABLE OF t_vc2_4k;


--------------------------------------------------------------------------------
-- Public table API generation methods
--------------------------------------------------------------------------------

PROCEDURE compile_api
( --> For detailed parameter descriptions see https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md
  p_table_name                  IN VARCHAR2,
  p_owner                       IN VARCHAR2 DEFAULT USER,  -- The schema, in which the API should be generated.
  p_enable_insertion_of_rows    IN BOOLEAN  DEFAULT TRUE,  -- If true, create methods are generated.
  p_enable_column_defaults      IN BOOLEAN  DEFAULT FALSE, -- If true, the data dictionary defaults of the columns are used for the create methods.
  p_enable_update_of_rows       IN BOOLEAN  DEFAULT TRUE,  -- If true, update methods are generated.
  p_enable_deletion_of_rows     IN BOOLEAN  DEFAULT FALSE, -- If true, delete methods are generated.
  p_enable_parameter_prefixes   IN BOOLEAN  DEFAULT TRUE,  -- If true, the param names of methods will be prefixed with 'p_'.
  p_enable_proc_with_out_params IN BOOLEAN  DEFAULT TRUE,  -- If true, a helper method with out parameters is generated - can be useful for low code frontends like APEX to manage session state.
  p_enable_getter_and_setter    IN BOOLEAN  DEFAULT TRUE,  -- If true, getter and setter methods are created for each column.
  p_col_prefix_in_method_names  IN BOOLEAN  DEFAULT TRUE,  -- If true, a found unique column prefix is kept otherwise omitted in the getter and setter method names.
  p_return_row_instead_of_pk    IN BOOLEAN  DEFAULT FALSE, -- If true, the whole row instead of the pk columns is returned on create methods.
  p_double_quote_names          IN BOOLEAN  DEFAULT TRUE,  -- If true, object names (owner, table, columns) are placed in double quotes.
  p_default_bulk_limit          IN INTEGER  DEFAULT 1000,  -- The default bulk size for the set based methods (create_rows, read_rows, update_rows)
  p_enable_dml_view             IN BOOLEAN  DEFAULT FALSE, -- If true, a view with an instead of trigger is generated, which simply calls the API methods - can be useful for low code frontends like APEX.
  p_dml_view_name               IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the DML view - you can use substitutions like #TABLE_NAME# , #TABLE_NAME_26# or #TABLE_NAME_4_20# (treated as substr(table_name, 4, 20)).
  p_dml_view_trigger_name       IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the DML view trigger - you can use substitutions like #TABLE_NAME#, #TABLE_NAME_26# or #TABLE_NAME_4_20# (treated as substr(table_name, 4, 20)).
  p_enable_one_to_one_view      IN BOOLEAN  DEFAULT FALSE, -- If true, a 1:1 view with read only is generated - useful when you want to separate the tables into an own schema without direct user access.
  p_one_to_one_view_name        IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the 1:1 view - you can use substitutions like #TABLE_NAME#, #TABLE_NAME_26# or #TABLE_NAME_4_20# (treated as substr(table_name, 4, 20)).
  p_api_name                    IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the API - you can use substitutions like #TABLE_NAME#, #TABLE_NAME_26# or #TABLE_NAME_4_20# (treated as substr(table_name, 4, 20)).
  p_sequence_name               IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the create_row methods - same substitutions like with API name possible.
  p_exclude_column_list         IN VARCHAR2 DEFAULT NULL,  -- If not null, the provided comma separated column names are excluded on inserts and updates (virtual columns are implicitly excluded).
  p_audit_column_mappings       IN VARCHAR2 DEFAULT NULL,  -- If not null, the provided comma separated column names are excluded and populated by the API (you don't need a trigger for update_by, update_on...).
  p_audit_user_expression       IN VARCHAR2 DEFAULT c_audit_user_expression, -- You can overwrite here the expression to determine the user which created or updated the row (see also the parameter docs...).
  p_row_version_column_mapping  IN VARCHAR2 DEFAULT NULL,  -- If not null, the provided column name is excluded and populated by the API with the provided SQL expression (you don't need a trigger to provide a row version identifier).
  p_tenant_column_mapping       IN VARCHAR2 DEFAULT NULL,  -- If not null, the provided column name is hidden inside the API, populated with the provided SQL expression and used as a tenant_id in all relevant API methods.
  p_enable_custom_defaults      IN BOOLEAN  DEFAULT FALSE, -- If true, additional methods are created (mainly for testing and dummy data creation, see full parameter descriptions).
  p_custom_default_values       IN XMLTYPE  DEFAULT NULL   -- Custom values in XML format for the previous option, if the generator provided defaults are not ok.
);
/**

Generates the code and compiles it. When the defaults are used you need only
to provide the table name.

```sql
BEGIN
  om_tapigen.compile_api (p_table_name => 'EMP');
END;
```

**/

FUNCTION compile_api_and_get_code
( --> For detailed parameter descriptions see https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md
  p_table_name                  IN VARCHAR2,
  p_owner                       IN VARCHAR2 DEFAULT USER,  -- The schema, in which the API should be generated.
  p_enable_insertion_of_rows    IN BOOLEAN  DEFAULT TRUE,  -- If true, create methods are generated.
  p_enable_column_defaults      IN BOOLEAN  DEFAULT FALSE, -- If true, the data dictionary defaults of the columns are used for the create methods.
  p_enable_update_of_rows       IN BOOLEAN  DEFAULT TRUE,  -- If true, update methods are generated.
  p_enable_deletion_of_rows     IN BOOLEAN  DEFAULT FALSE, -- If true, delete methods are generated.
  p_enable_parameter_prefixes   IN BOOLEAN  DEFAULT TRUE,  -- If true, the param names of methods will be prefixed with 'p_'.
  p_enable_proc_with_out_params IN BOOLEAN  DEFAULT TRUE,  -- If true, a helper method with out parameters is generated - can be useful for low code frontends like APEX to manage session state.
  p_enable_getter_and_setter    IN BOOLEAN  DEFAULT TRUE,  -- If true, getter and setter methods are created for each column.
  p_col_prefix_in_method_names  IN BOOLEAN  DEFAULT TRUE,  -- If true, a found unique column prefix is kept otherwise omitted in the getter and setter method names.
  p_return_row_instead_of_pk    IN BOOLEAN  DEFAULT FALSE, -- If true, the whole row instead of the pk columns is returned on create methods.
  p_double_quote_names          IN BOOLEAN  DEFAULT TRUE,  -- If true, object names (owner, table, columns) are placed in double quotes.
  p_default_bulk_limit          IN INTEGER  DEFAULT 1000,  -- The default bulk size for the set based methods (create_rows, read_rows, update_rows)
  p_enable_dml_view             IN BOOLEAN  DEFAULT FALSE, -- If true, a view with an instead of trigger is generated, which simply calls the API methods - can be useful for low code frontends like APEX.
  p_dml_view_name               IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the DML view - you can use substitutions like #TABLE_NAME# , #TABLE_NAME_26# or #TABLE_NAME_4_20# (treated as substr(table_name, 4, 20)).
  p_dml_view_trigger_name       IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the DML view trigger - you can use substitutions like #TABLE_NAME#, #TABLE_NAME_26# or #TABLE_NAME_4_20# (treated as substr(table_name, 4, 20)).
  p_enable_one_to_one_view      IN BOOLEAN  DEFAULT FALSE, -- If true, a 1:1 view with read only is generated - useful when you want to separate the tables into an own schema without direct user access.
  p_one_to_one_view_name        IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the 1:1 view - you can use substitutions like #TABLE_NAME#, #TABLE_NAME_26# or #TABLE_NAME_4_20# (treated as substr(table_name, 4, 20)).
  p_api_name                    IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the API - you can use substitutions like #TABLE_NAME#, #TABLE_NAME_26# or #TABLE_NAME_4_20# (treated as substr(table_name, 4, 20)).
  p_sequence_name               IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the create_row methods - same substitutions like with API name possible.
  p_exclude_column_list         IN VARCHAR2 DEFAULT NULL,  -- If not null, the provided comma separated column names are excluded on inserts and updates (virtual columns are implicitly excluded).
  p_audit_column_mappings       IN VARCHAR2 DEFAULT NULL,  -- If not null, the provided comma separated column names are excluded and populated by the API (you don't need a trigger for update_by, update_on...).
  p_audit_user_expression       IN VARCHAR2 DEFAULT c_audit_user_expression, -- You can overwrite here the expression to determine the user which created or updated the row (see also the parameter docs...).
  p_row_version_column_mapping  IN VARCHAR2 DEFAULT NULL,  -- If not null, the provided column name is excluded and populated by the API with the provided SQL expression (you don't need a trigger to provide a row version identifier).
  p_tenant_column_mapping       IN VARCHAR2 DEFAULT NULL,  -- If not null, the provided column name is hidden inside the API, populated with the provided SQL expression and used as a tenant_id in all relevant API methods.
  p_enable_custom_defaults      IN BOOLEAN  DEFAULT FALSE, -- If true, additional methods are created (mainly for testing and dummy data creation, see full parameter descriptions).
  p_custom_default_values       IN XMLTYPE  DEFAULT NULL   -- Custom values in XML format for the previous option, if the generator provided defaults are not ok.
) RETURN CLOB;
/**

Generates the code, compiles and returns it as a CLOB. When the defaults are used you need only
to provide the table name.

```sql
DECLARE
  l_api_code CLOB;
BEGIN
  l_api_code := om_tapigen.compile_api_and_get_code (p_table_name => 'EMP');
  --> do something with the API code
END;
```

**/


FUNCTION get_code
( --> For detailed parameter descriptions see https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md
  p_table_name                  IN VARCHAR2,
  p_owner                       IN VARCHAR2 DEFAULT USER,  -- The schema, in which the API should be generated.
  p_enable_insertion_of_rows    IN BOOLEAN  DEFAULT TRUE,  -- If true, create methods are generated.
  p_enable_column_defaults      IN BOOLEAN  DEFAULT FALSE, -- If true, the data dictionary defaults of the columns are used for the create methods.
  p_enable_update_of_rows       IN BOOLEAN  DEFAULT TRUE,  -- If true, update methods are generated.
  p_enable_deletion_of_rows     IN BOOLEAN  DEFAULT FALSE, -- If true, delete methods are generated.
  p_enable_parameter_prefixes   IN BOOLEAN  DEFAULT TRUE,  -- If true, the param names of methods will be prefixed with 'p_'.
  p_enable_proc_with_out_params IN BOOLEAN  DEFAULT TRUE,  -- If true, a helper method with out parameters is generated - can be useful for low code frontends like APEX to manage session state.
  p_enable_getter_and_setter    IN BOOLEAN  DEFAULT TRUE,  -- If true, getter and setter methods are created for each column.
  p_col_prefix_in_method_names  IN BOOLEAN  DEFAULT TRUE,  -- If true, a found unique column prefix is kept otherwise omitted in the getter and setter method names.
  p_return_row_instead_of_pk    IN BOOLEAN  DEFAULT FALSE, -- If true, the whole row instead of the pk columns is returned on create methods.
  p_double_quote_names          IN BOOLEAN  DEFAULT TRUE,  -- If true, object names (owner, table, columns) are placed in double quotes.
  p_default_bulk_limit          IN INTEGER  DEFAULT 1000,  -- The default bulk size for the set based methods (create_rows, read_rows, update_rows)
  p_enable_dml_view             IN BOOLEAN  DEFAULT FALSE, -- If true, a view with an instead of trigger is generated, which simply calls the API methods - can be useful for low code frontends like APEX.
  p_dml_view_name               IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the DML view - you can use substitutions like #TABLE_NAME# , #TABLE_NAME_26# or #TABLE_NAME_4_20# (treated as substr(table_name, 4, 20)).
  p_dml_view_trigger_name       IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the DML view trigger - you can use substitutions like #TABLE_NAME#, #TABLE_NAME_26# or #TABLE_NAME_4_20# (treated as substr(table_name, 4, 20)).
  p_enable_one_to_one_view      IN BOOLEAN  DEFAULT FALSE, -- If true, a 1:1 view with read only is generated - useful when you want to separate the tables into an own schema without direct user access.
  p_one_to_one_view_name        IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the 1:1 view - you can use substitutions like #TABLE_NAME#, #TABLE_NAME_26# or #TABLE_NAME_4_20# (treated as substr(table_name, 4, 20)).
  p_api_name                    IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the API - you can use substitutions like #TABLE_NAME#, #TABLE_NAME_26# or #TABLE_NAME_4_20# (treated as substr(table_name, 4, 20)).
  p_sequence_name               IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the create_row methods - same substitutions like with API name possible.
  p_exclude_column_list         IN VARCHAR2 DEFAULT NULL,  -- If not null, the provided comma separated column names are excluded on inserts and updates (virtual columns are implicitly excluded).
  p_audit_column_mappings       IN VARCHAR2 DEFAULT NULL,  -- If not null, the provided comma separated column names are excluded and populated by the API (you don't need a trigger for update_by, update_on...).
  p_audit_user_expression       IN VARCHAR2 DEFAULT c_audit_user_expression, -- You can overwrite here the expression to determine the user which created or updated the row (see also the parameter docs...).
  p_row_version_column_mapping  IN VARCHAR2 DEFAULT NULL,  -- If not null, the provided column name is excluded and populated by the API with the provided SQL expression (you don't need a trigger to provide a row version identifier).
  p_tenant_column_mapping       IN VARCHAR2 DEFAULT NULL,  -- If not null, the provided column name is hidden inside the API, populated with the provided SQL expression and used as a tenant_id in all relevant API methods.
  p_enable_custom_defaults      IN BOOLEAN  DEFAULT FALSE, -- If true, additional methods are created (mainly for testing and dummy data creation, see full parameter descriptions).
  p_custom_default_values       IN XMLTYPE  DEFAULT NULL   -- Custom values in XML format for the previous option, if the generator provided defaults are not ok.
) RETURN CLOB;
/**

Generates the code and returns it as a CLOB. When the defaults are used you
need only to provide the table name.

This function is called by the oddgen wrapper for the SQL Developer integration.

```sql
DECLARE
  l_api_code CLOB;
BEGIN
  l_api_code := om_tapigen.get_code (p_table_name => 'EMP');
  --> do something with the API code
END;
```

**/


--------------------------------------------------------------------------------
-- Public helper methods
--------------------------------------------------------------------------------

FUNCTION view_existing_apis(
  p_table_name VARCHAR2 DEFAULT NULL,
  p_owner      VARCHAR2 DEFAULT USER)
RETURN t_tab_existing_apis PIPELINED;
/**

Helper function (pipelined) to list all APIs generated by om_tapigen.

```sql
SELECT * FROM TABLE (om_tapigen.view_existing_apis);
```

**/


FUNCTION view_naming_conflicts(
  p_owner VARCHAR2 DEFAULT USER)
RETURN t_tab_naming_conflicts PIPELINED;
/**

Helper to check possible naming conflicts before the very first usage of the API generator.

Also see the [naming conventions](https://github.com/OraMUC/table-api-generator/blob/master/docs/naming-conventions.md) of the generator.

```sql
SELECT * FROM TABLE (om_tapigen.view_naming_conflicts);
-- No rows expected. After you generated some APIs there will be results ;-)
```

**/


FUNCTION util_get_column_data_default(
  p_table_name  IN VARCHAR2,
  p_column_name IN VARCHAR2,
  p_owner       VARCHAR2 DEFAULT USER)
RETURN VARCHAR2;
/*

Helper to read a column data default from the dictionary.
[Working with long columns](http://www.oracle-developer.net/display.php?id=430).

*/


FUNCTION util_get_cons_search_condition(
  p_constraint_name IN VARCHAR2,
  p_owner           IN VARCHAR2 DEFAULT USER)
RETURN VARCHAR2;
/*

Helper to read a constraint search condition from the dictionary (not needed
in 12cR1 and above, there we have a column search_condition_vc in
user_constraints).

*/


FUNCTION util_split_to_table(
  p_string    IN VARCHAR2,
  p_delimiter IN VARCHAR2 DEFAULT ',')
RETURN t_tab_vc2_4k PIPELINED;
/*

Helper function to split a string to a selectable table.

```sql
SELECT column_value FROM TABLE (om_tapigen.util_split_to_table('1,2,3,test'));
```
*/


FUNCTION util_get_ora_max_name_len
RETURN INTEGER;
/*

Helper function to determine the maximum length for an identifier name (e.g.
column name). Returns the package constant c_ora_max_name_len, which is
determined by a conditional compilation.

*/


PROCEDURE util_set_debug_on;
/*

Enable (and reset) the debugging (previous debug data will be lost)

```sql
BEGIN
  om_tapigen.util_set_debug_on;
END;
```
*/


PROCEDURE util_set_debug_off;
/*

Disable the debugging

```sql
BEGIN
  om_tapigen.util_set_debug_off;
END;
```

*/


FUNCTION util_view_debug_log
RETURN t_tab_debug_data PIPELINED;
/*

View the debug details. Maximum 999 API creations are captured for memory
reasons. You can reset the debugging by calling `om_tapigen.util_set_debug_on`.

```sql
SELECT * FROM TABLE(om_tapigen.util_view_debug_log);
```

*/


FUNCTION util_view_columns_array
RETURN t_tab_debug_columns PIPELINED;
/*

View the internal columns array from the last API generation. This view is
independend from the debug mode, because this array is resetted for each API
generation.

```sql
SELECT * FROM TABLE(om_tapigen.util_view_columns_array);
```

*/


FUNCTION util_view_package_state
RETURN t_tab_package_state PIPELINED;
/*

View some informations from the internal package state for debug purposes.

```sql
SELECT * FROM TABLE(om_tapigen.util_view_package_state);
```

*/

END om_tapigen;
/
