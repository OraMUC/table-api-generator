CREATE OR REPLACE PACKAGE om_tapigen AUTHID CURRENT_USER IS 
c_generator         CONSTANT VARCHAR2(10 CHAR) := 'OM_TAPIGEN';
c_generator_version CONSTANT VARCHAR2(10 CHAR) := '0.5.1';
/**

Oracle PL/SQL Table API Generator
=================================

_This table API generator can be integrated in the Oracle SQL-Developer with an
additional wrapper package for the [SQL Developer extension oddgen](https://www.oddgen.org/)._

The effort of generated API's is to reduce your PL/SQL code by calling standard
procedures and functions for usual DML operations on tables. So the generated
table APIs work as a logical layer between your business logic and the data. And
by the way this logical layer enables you to easily seperate the data schema and
the UI schema for your applications to improve security by granting only execute
privs on table APIs to the application schema. In addition to that table APIs
will speed up your development cycles because developers are able to set the
focal point to the business logic instead of wasting time by manual creating
boilerplate code for your tables.

> Get Rid of Hard-Coding in PL/SQL ([Steven Feuerstein](https://www.youtube.com/playlist?list=PL0mkplxCP4ygQo3zAvhYrrU6hIQ0JtYTA))

FEATURES

- Generates small wrappers around your tables
- You only need to specify generation options once per table - parameters are
  saved in the package spec source and can be reused for regeneration
- Highly configurable
- Standard CRUD methods (column and row type based) and an additional create 
  or update method
- Insert / Update / Delete of rows can be enabled or disabled
- Functions to check if a row exists (primary key based, returning boolean or 
  varchar2)
- For each unique constraint a getter function to fetch the primary key
- Optional getter and setter for each column
- Optional generic logging (one log entry for each changed column over all API
  enabled tables in one generic log table - very handy to create a record
  history in the user interface)
- Checks for real changes during UPDATE operation and updates only if required
- Supports APEX automatic row processing by generation of an optional updatable
  view with an instead of trigger (which calls simply the API and, if enabled, 
  the generic logging)

LICENSE

- [The MIT License (MIT)](https://github.com/OraMUC/table-api-generator/blob/master/LICENSE.txt)
- Copyright (c) 2015-2018 André Borngräber, Ottmar Gobrecht

We give our best to produce clean and robust code, but we are NOT responsible,
if you loose any code or data by using this API generator. By using it you
accept the MIT license. As a best practice test the generator first in your
development environment and decide after your tests, if you want to use it in
production. If you miss any feature or find a bug, we are happy to hear from you
via the GitHub [Issues](https://github.com/OraMUC/table-api-generator/issues)
functionality.

DOCS

- [Example API for the demo table HR.EMPLOYEES](https://github.com/OraMUC/table-api-generator/blob/master/docs/example-api.md)
- [Getting started](https://github.com/OraMUC/table-api-generator/blob/master/docs/getting-started.md)
- [Detailed parameter descriptions](https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md)
- [Naming conventions](https://github.com/OraMUC/table-api-generator/blob/master/docs/naming-conventions.md)
- [SQL Developer integration](https://github.com/OraMUC/table-api-generator/blob/master/docs/sql-developer-integration.md)
- [Changelog](https://github.com/OraMUC/table-api-generator/blob/master/docs/changelog.md)

LINKS

- [Project home page](https://github.com/OraMUC/table-api-generator)
- [Download the latest version](https://github.com/OraMUC/table-api-generator/releases/latest)
- [Issues](https://github.com/OraMUC/table-api-generator/issues)

**/

--------------------------------------------------------------------------------
-- Public global constants c_*
--------------------------------------------------------------------------------
c_ora_max_name_len CONSTANT INTEGER :=
  $IF dbms_db_version.ver_le_11_1 $THEN 
    30
  $ELSE
    $IF dbms_db_version.ver_le_11_2 $THEN
      30
    $ELSE
      $IF dbms_db_version.ver_le_12_1 $THEN 
        30
      $ELSE
        ora_max_name_len
      $END
    $END
  $END;

-- parameter defaults
c_true_reuse_existing_api_para CONSTANT BOOLEAN := TRUE;
c_true_enable_insertion_of_row CONSTANT BOOLEAN := TRUE;
c_false_enable_column_defaults CONSTANT BOOLEAN := FALSE;
c_true_enable_update_of_rows   CONSTANT BOOLEAN := TRUE;
c_false_enable_deletion_of_row CONSTANT BOOLEAN := FALSE;
c_true_enable_parameter_prefix CONSTANT BOOLEAN := TRUE;
c_true_enable_proc_with_out_pa CONSTANT BOOLEAN := TRUE;
c_true_enable_getter_and_sette CONSTANT BOOLEAN := TRUE;
c_true_col_prefix_in_method_na CONSTANT BOOLEAN := TRUE;
c_false_return_row_instead_of_ CONSTANT BOOLEAN := FALSE;
c_false_enable_dml_view        CONSTANT BOOLEAN := FALSE;
c_false_enable_generic_change_ CONSTANT BOOLEAN := FALSE;
c_false_enable_custom_defaults CONSTANT BOOLEAN := FALSE;

--------------------------------------------------------------------------------
-- Subtypes (st_*)
--------------------------------------------------------------------------------
SUBTYPE st_session_module IS VARCHAR2(64);
SUBTYPE st_session_action IS VARCHAR2(64);

--------------------------------------------------------------------------------
-- Public record (t_rec_*) and collection (t_tab_*) types
--------------------------------------------------------------------------------
TYPE t_rec_existing_apis IS RECORD(
  errors                        VARCHAR2(4000 CHAR),
  owner                         all_users.username%TYPE,
  table_name                    all_objects.object_name%TYPE,
  package_name                  all_objects.object_name%TYPE,
  spec_status                   all_objects.status%TYPE,
  spec_last_ddl_time            all_objects.last_ddl_time%TYPE,
  body_status                   all_objects.status%TYPE,
  body_last_ddl_time            all_objects.last_ddl_time%TYPE,
  generator                     VARCHAR2(10 CHAR),
  generator_version             VARCHAR2(10 CHAR),
  generator_action              VARCHAR2(24 CHAR),
  generated_at                  DATE,
  generated_by                  all_users.username%TYPE,
  p_owner                       all_users.username%TYPE,
  p_table_name                  all_objects.object_name%TYPE,
  p_reuse_existing_api_params   VARCHAR2(5 CHAR),
  p_enable_insertion_of_rows    VARCHAR2(5 CHAR),
  p_enable_column_defaults      VARCHAR2(5 CHAR),
  p_enable_update_of_rows       VARCHAR2(5 CHAR),
  p_enable_deletion_of_rows     VARCHAR2(5 CHAR),
  p_enable_parameter_prefixes   VARCHAR2(5 CHAR),
  p_enable_proc_with_out_params VARCHAR2(5 CHAR),
  p_enable_getter_and_setter    VARCHAR2(5 CHAR),
  p_col_prefix_in_method_names  VARCHAR2(5 CHAR),
  p_return_row_instead_of_pk    VARCHAR2(5 CHAR),
  p_enable_dml_view             VARCHAR2(5 CHAR),
  p_enable_generic_change_log   VARCHAR2(5 CHAR),
  p_api_name                    all_objects.object_name%TYPE,
  p_sequence_name               all_objects.object_name%TYPE,
  p_exclude_column_list         VARCHAR2(4000 CHAR),
  p_enable_custom_defaults      VARCHAR2(5 CHAR),
  p_custom_default_values       VARCHAR2(30 CHAR));

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
  action     st_session_action,
  start_time TIMESTAMP(6));

TYPE t_tab_debug_data IS TABLE OF t_rec_debug_data;

--    

TYPE t_rec_columns IS RECORD(
  column_name           all_tab_cols.column_name%TYPE,
  data_type             all_tab_cols.data_type%TYPE,
  data_length           all_tab_cols.data_length%TYPE,
  data_precision        all_tab_cols.data_precision%TYPE,
  data_scale            all_tab_cols.data_scale%TYPE,
  data_default          VARCHAR2(4000 CHAR),
  char_length           all_tab_cols.char_length%TYPE,
  data_custom_default   VARCHAR2(4000 CHAR),
  custom_default_source VARCHAR2(15 CHAR),
  identity_type         VARCHAR2(15 CHAR),
  is_pk_yn              VARCHAR2(1 CHAR),
  is_uk_yn              VARCHAR2(1 CHAR),
  is_fk_yn              VARCHAR2(1 CHAR),
  is_nullable_yn        VARCHAR2(1 CHAR),
  is_excluded_yn        VARCHAR2(1 CHAR),
  r_owner               all_users.username%TYPE,
  r_table_name          all_objects.object_name%TYPE,
  r_column_name         all_tab_cols.column_name%TYPE);

TYPE t_tab_debug_columns IS TABLE OF t_rec_columns;
/* We use t_tab_columns as a private array/collection inside the package body
indexed by binary_intager. For the pipelined function util_view_columns_array
we need this additional table type. */

--

TYPE t_rec_clob_line_by_line IS RECORD(
  text VARCHAR2(4000));

TYPE t_tab_clob_line_by_line IS TABLE OF t_rec_clob_line_by_line;

--

TYPE t_tab_vc2_4k IS TABLE OF VARCHAR2(4000);


--------------------------------------------------------------------------------
-- Public table API generation methods
--------------------------------------------------------------------------------

PROCEDURE compile_api
( --> For detailed parameter descriptions see https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md
  p_table_name                  IN all_objects.object_name%TYPE,
  p_owner                       IN all_users.username%TYPE DEFAULT USER,
  p_reuse_existing_api_params   IN BOOLEAN DEFAULT om_tapigen.c_true_reuse_existing_api_para, -- If true, all following params are ignored when API is already existing and params are extractable from spec source.
  p_enable_insertion_of_rows    IN BOOLEAN DEFAULT om_tapigen.c_true_enable_insertion_of_row,
  p_enable_column_defaults      IN BOOLEAN DEFAULT om_tapigen.c_false_enable_column_defaults, -- If true, the data dictionary defaults of the columns are used for the create methods.
  p_enable_update_of_rows       IN BOOLEAN DEFAULT om_tapigen.c_true_enable_update_of_rows,
  p_enable_deletion_of_rows     IN BOOLEAN DEFAULT om_tapigen.c_false_enable_deletion_of_row,
  p_enable_parameter_prefixes   IN BOOLEAN DEFAULT om_tapigen.c_true_enable_parameter_prefix, -- If true, the param names of methods will be prefixed with 'p_'.
  p_enable_proc_with_out_params IN BOOLEAN DEFAULT om_tapigen.c_true_enable_proc_with_out_pa, -- If true, a helper method with out params is generated - can be useful for managing session state (e.g. fetch process in APEX).
  p_enable_getter_and_setter    IN BOOLEAN DEFAULT om_tapigen.c_true_enable_getter_and_sette, -- prefixedIf true, for each column get and set methods are created.
  p_col_prefix_in_method_names  IN BOOLEAN DEFAULT om_tapigen.c_true_col_prefix_in_method_na, -- If true, a found unique column prefix is kept otherwise omitted in the getter and setter method names
  p_return_row_instead_of_pk    IN BOOLEAN DEFAULT om_tapigen.c_false_return_row_instead_of_,
  p_enable_dml_view             IN BOOLEAN DEFAULT om_tapigen.c_false_enable_dml_view,
  p_enable_generic_change_log   IN BOOLEAN DEFAULT om_tapigen.c_false_enable_generic_change_,
  p_api_name                    IN all_objects.object_name%TYPE DEFAULT NULL,                 -- If not null, the given name is used for the API - you can use substitution like #TABLE_NAME_4_20# (treated as substr(4,20))
  p_sequence_name               IN all_objects.object_name%TYPE DEFAULT NULL,                 -- If not null, the given name is used for the create_row methods - same substitutions like with API name possible
  p_exclude_column_list         IN VARCHAR2 DEFAULT NULL,                                     -- If not null, the provided comma separated column names are excluded on inserts and updates (virtual columns are implicitly excluded)
  p_enable_custom_defaults      IN BOOLEAN DEFAULT om_tapigen.c_false_enable_custom_defaults, -- If true, additional methods are created (mainly for testing and dummy data creation, see full parameter descriptions)
  p_custom_default_values       IN xmltype DEFAULT NULL                                       -- Custom values in XML format for the previous option, if the generator provided defaults are not ok
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
  p_table_name                  IN all_objects.object_name%TYPE,
  p_owner                       IN all_users.username%TYPE DEFAULT USER,
  p_reuse_existing_api_params   IN BOOLEAN DEFAULT om_tapigen.c_true_reuse_existing_api_para, -- If true, all following params are ignored when API is already existing and params are extractable from spec source.
  p_enable_insertion_of_rows    IN BOOLEAN DEFAULT om_tapigen.c_true_enable_insertion_of_row,
  p_enable_column_defaults      IN BOOLEAN DEFAULT om_tapigen.c_false_enable_column_defaults, -- If true, the data dictionary defaults of the columns are used for the create methods.
  p_enable_update_of_rows       IN BOOLEAN DEFAULT om_tapigen.c_true_enable_update_of_rows,
  p_enable_deletion_of_rows     IN BOOLEAN DEFAULT om_tapigen.c_false_enable_deletion_of_row,
  p_enable_parameter_prefixes   IN BOOLEAN DEFAULT om_tapigen.c_true_enable_parameter_prefix, -- If true, the param names of methods will be prefixed with 'p_'.
  p_enable_proc_with_out_params IN BOOLEAN DEFAULT om_tapigen.c_true_enable_proc_with_out_pa, -- If true, a helper method with out params is generated - can be useful for managing session state (e.g. fetch process in APEX).
  p_enable_getter_and_setter    IN BOOLEAN DEFAULT om_tapigen.c_true_enable_getter_and_sette, -- prefixedIf true, for each column get and set methods are created.
  p_col_prefix_in_method_names  IN BOOLEAN DEFAULT om_tapigen.c_true_col_prefix_in_method_na, -- If true, a found unique column prefix is kept otherwise omitted in the getter and setter method names
  p_return_row_instead_of_pk    IN BOOLEAN DEFAULT om_tapigen.c_false_return_row_instead_of_,
  p_enable_dml_view             IN BOOLEAN DEFAULT om_tapigen.c_false_enable_dml_view,
  p_enable_generic_change_log   IN BOOLEAN DEFAULT om_tapigen.c_false_enable_generic_change_,
  p_api_name                    IN all_objects.object_name%TYPE DEFAULT NULL,                 -- If not null, the given name is used for the API - you can use substitution like #TABLE_NAME_4_20# (treated as substr(4,20))
  p_sequence_name               IN all_objects.object_name%TYPE DEFAULT NULL,                 -- If not null, the given name is used for the create_row methods - same substitutions like with API name possible
  p_exclude_column_list         IN VARCHAR2 DEFAULT NULL,                                     -- If not null, the provided comma separated column names are excluded on inserts and updates (virtual columns are implicitly excluded)
  p_enable_custom_defaults      IN BOOLEAN DEFAULT om_tapigen.c_false_enable_custom_defaults, -- If true, additional methods are created (mainly for testing and dummy data creation, see full parameter descriptions)
  p_custom_default_values       IN xmltype DEFAULT NULL                                       -- Custom values in XML format for the previous option, if the generator provided defaults are not ok
) RETURN CLOB;
/**

Generates the code, compiles and returns it as a CLOB. When the defaults are used you need only
to provide the table name.

```sql
DECLARE
  l_clob CLOB;
BEGIN
  l_clob := om_tapigen.compile_api_and_get_code (p_table_name => 'EMP');
  --> do something with the CLOB
END;
```
**/


FUNCTION get_code
( --> For detailed parameter descriptions see https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md
  p_table_name                  IN all_objects.object_name%TYPE,
  p_owner                       IN all_users.username%TYPE DEFAULT USER,
  p_reuse_existing_api_params   IN BOOLEAN DEFAULT om_tapigen.c_true_reuse_existing_api_para, -- If true, all following params are ignored when API is already existing and params are extractable from spec source.
  p_enable_insertion_of_rows    IN BOOLEAN DEFAULT om_tapigen.c_true_enable_insertion_of_row,
  p_enable_column_defaults      IN BOOLEAN DEFAULT om_tapigen.c_false_enable_column_defaults, -- If true, the data dictionary defaults of the columns are used for the create methods.
  p_enable_update_of_rows       IN BOOLEAN DEFAULT om_tapigen.c_true_enable_update_of_rows,
  p_enable_deletion_of_rows     IN BOOLEAN DEFAULT om_tapigen.c_false_enable_deletion_of_row,
  p_enable_parameter_prefixes   IN BOOLEAN DEFAULT om_tapigen.c_true_enable_parameter_prefix, -- If true, the param names of methods will be prefixed with 'p_'.
  p_enable_proc_with_out_params IN BOOLEAN DEFAULT om_tapigen.c_true_enable_proc_with_out_pa, -- If true, a helper method with out params is generated - can be useful for managing session state (e.g. fetch process in APEX).
  p_enable_getter_and_setter    IN BOOLEAN DEFAULT om_tapigen.c_true_enable_getter_and_sette, -- prefixedIf true, for each column get and set methods are created.
  p_col_prefix_in_method_names  IN BOOLEAN DEFAULT om_tapigen.c_true_col_prefix_in_method_na, -- If true, a found unique column prefix is kept otherwise omitted in the getter and setter method names
  p_return_row_instead_of_pk    IN BOOLEAN DEFAULT om_tapigen.c_false_return_row_instead_of_,
  p_enable_dml_view             IN BOOLEAN DEFAULT om_tapigen.c_false_enable_dml_view,
  p_enable_generic_change_log   IN BOOLEAN DEFAULT om_tapigen.c_false_enable_generic_change_,
  p_api_name                    IN all_objects.object_name%TYPE DEFAULT NULL,                 -- If not null, the given name is used for the API - you can use substitution like #TABLE_NAME_4_20# (treated as substr(4,20))
  p_sequence_name               IN all_objects.object_name%TYPE DEFAULT NULL,                 -- If not null, the given name is used for the create_row methods - same substitutions like with API name possible
  p_exclude_column_list         IN VARCHAR2 DEFAULT NULL,                                     -- If not null, the provided comma separated column names are excluded on inserts and updates (virtual columns are implicitly excluded)
  p_enable_custom_defaults      IN BOOLEAN DEFAULT om_tapigen.c_false_enable_custom_defaults, -- If true, additional methods are created (mainly for testing and dummy data creation, see full parameter descriptions)
  p_custom_default_values       IN xmltype DEFAULT NULL                                       -- Custom values in XML format for the previous option, if the generator provided defaults are not ok
) RETURN CLOB;
/**

Generates the code and returns it as a CLOB. When the defaults are used you 
need only to provide the table name.

This function is called by the oddgen wrapper for the SQL Developer integration.

```sql
DECLARE
  l_clob CLOB;
BEGIN
  l_clob := om_tapigen.get_code (p_table_name => 'EMP');
  --> do something with the CLOB
END;
```
**/


--------------------------------------------------------------------------------
-- Public helper methods
--------------------------------------------------------------------------------

PROCEDURE recreate_existing_apis(p_owner IN all_users.username%TYPE DEFAULT USER);
/**

Helper to recreate all APIs in the current (or another) schema with the original
call parameters (read from the package specs).

```sql
BEGIN
  om_tapigen.recreate_existing_apis;
END;
```
**/


FUNCTION view_existing_apis
(
  p_table_name all_tables.table_name%TYPE DEFAULT NULL,
  p_owner      all_users.username%TYPE DEFAULT USER
) RETURN t_tab_existing_apis
  PIPELINED;
/**

Helper function (pipelined) to list all APIs generated by om_tapigen.

```sql
SELECT * FROM TABLE (om_tapigen.view_existing_apis);
```
**/


FUNCTION view_naming_conflicts(p_owner all_users.username%TYPE DEFAULT USER)
  RETURN t_tab_naming_conflicts
  PIPELINED;
/**

Helper to check possible naming conflicts before the first usage of the API generator.

Also see the [naming conventions](https://github.com/OraMUC/table-api-generator/blob/master/docs/naming-conventions.md) of the generator.

```sql
SELECT * FROM TABLE (om_tapigen.view_naming_conflicts);
-- No rows expected. After you generated some APIs there will be results ;-)
```
**/


FUNCTION util_get_column_data_default
(
  p_table_name  IN VARCHAR2,
  p_column_name IN VARCHAR2,
  p_owner       VARCHAR2 DEFAULT USER
) RETURN VARCHAR2;
/*

Helper to read a column data default from the dictionary.
[Working with long columns](http://www.oracle-developer.net/display.php?id=430).

*/


FUNCTION util_get_cons_search_condition
(
  p_constraint_name IN VARCHAR2,
  p_owner           IN VARCHAR2 DEFAULT USER
) RETURN VARCHAR2;
/*

Helper to read a constraint search condition from the dictionary (not needed 
in 12cR1 and above, there we have a column search_condition_vc in 
user_constraints).

*/


FUNCTION util_split_to_table
(
  p_string    IN VARCHAR2,
  p_delimiter IN VARCHAR2 DEFAULT ','
) RETURN t_tab_vc2_4k
  PIPELINED;
/*

Helper function to split a string to a selectable table.

```sql
SELECT column_value FROM TABLE (om_tapigen.util_split_to_table('1,2,3,test'));
```
*/


FUNCTION util_get_ora_max_name_len RETURN INTEGER;
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


FUNCTION util_view_debug_log RETURN t_tab_debug_data
  PIPELINED;
/*

View the debug details. Maximum 999 API creations are captured for memory 
reasons. You can reset the debugging by calling `om_tapigen.util_set_debug_on`.

```sql
SELECT * FROM TABLE(om_tapigen.util_view_debug_log);
```
*/


FUNCTION util_view_columns_array RETURN t_tab_debug_columns
  PIPELINED;
/*

View the internal columns array from the last API generation. This view is
independend from the debug mode, because this array is resetted for each API
generation.

```sql
SELECT * FROM TABLE(om_tapigen.util_view_columns_array);
```
*/

FUNCTION util_get_ddl
(
  p_object_type VARCHAR2,
  p_object_name VARCHAR2,
  p_owner       VARCHAR2 DEFAULT USER
) RETURN CLOB;
/*

Helper for testing to get the DDL of generated objects.

*/

END om_tapigen;
/
