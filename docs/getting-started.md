# Getting Started

<!-- toc -->

- [Installation](#installation)
- [Usage](#usage)

<!-- tocstop -->

## Installation

We recommend to install the package `om_tapigen` in a central tools schema. Because the package runs with invokers rights you need to create a private or public synonym for SQL functions inside the package.

1. Download the [latest version][latest] and unzip the source code
1. Run the SQL script `install.sql` in the root folder or compile the spec and body of the package `om_tapigen` and optional `om_tapigen_oddgen_wrapper` for the SQL Developer integration
1. Optional for central tools schema - grant execute rights: `GRANT EXECUTE ON om_tapigen TO PUBLIC;`
1. Optional for central tools schema - create synonym:
    - public in tools schema: `CREATE PUBLIC SYNONYM om_tapigen FOR om_tapigen;`
    - or private in target schema: `CREATE SYNONYM om_tapigen FOR <yourToolsSchema>.om_tapigen;`

[latest]: https://github.com/OraMUC/table-api-generator/releases/latest

## Usage

There are three methods - all have the same parameters:

1. compile_api: This procedure generates the code and compiles it directly
1. compile_api_and_get_code: This functions does the same as the previous procedure and returns additionally the generated code as a clob
1. get_code: This function only returns the code as a clob (this function is called by the oddgen wrapper for the SQL Developer integration)

In the simplest way you directly compile an API by providing a table name:

```sql
begin
  --> minimal parameter, see also the section "The Parameters"
  om_tapigen.compile_api (p_table_name => 'EMP');
end;
```

### Parameters

There is a dedicated page for the [detailed parameter descriptions](https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md) - here as an example the signature for the method `compile_api` with the short descriptions:

```sql
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
```

### Helpers

There is a pipelined function to view the current status of the API's and the original parameter values from the generation call:

```sql
SELECT *
  FROM TABLE(om_tapigen.view_existing_apis)
 ORDER BY table_name NULLS FIRST;
```

The leading dictionary information is the API package name. It could be, you found API's where the table_name is NULL - this means your API is existing, but your table not anymore. Thats the reason for the order by clause in the example query. You can use this pipelined function for quality assurance or for building a metadata repository with the generation parameters of your API's. It also used by the second helper method, a procedure to recreate all existing API's at once with the original parameter values in case of changes in your data model:

```sql
BEGIN
  om_tapigen.recreate_existing_apis;
END;
```

As you can see, you need no parameters for this procedure - they are taken from the dictionary user source, because we save it as a comment in the package specification. If you ask, why not use package constants we want ask you: Have you already tried to read a package constant when the package is invalid because of changes in your corresponding table... ;-)


### Complete Example

The normal life cycle:

```sql
--> Check for possible naming conflicts before the first API generation
SELECT *
  FROM TABLE(om_tapigen.view_naming_conflicts);

--> Initial API generation for your tables
BEGIN
  FOR i IN (SELECT table_name FROM user_tables /*WHERE...*/) LOOP
    om_tapigen.compile_api(
      p_table_name                  => i.table_name,
      p_owner                       => user,
      p_reuse_existing_api_params   => true,
      p_enable_insertion_of_rows    => true,
      p_enable_column_defaults      => false,
      p_enable_update_of_rows       => true,
      p_enable_deletion_of_rows     => false,
      p_enable_parameter_prefixes   => true,
      p_enable_proc_with_out_params => true,
      p_enable_getter_and_setter    => true,
      p_col_prefix_in_method_names  => true,
      p_return_row_instead_of_pk    => false,
      p_enable_dml_view             => false,
      p_enable_generic_change_log   => false,
      p_api_name                    => NULL, -- defaults to #TABLE_NAME_26#_API
      p_sequence_name               => NULL,
      p_exclude_column_list         => NULL,
      p_enable_custom_defaults      => false,
      p_custom_default_values       => NULL  
    );
  END LOOP;
END;

--> Inspect the results
SELECT *
  FROM TABLE(om_tapigen.view_existing_apis)
 ORDER BY table_name NULLS FIRST;

--> recreate the API's after changes in your model
BEGIN
  om_tapigen.recreate_existing_apis;
END;
```

If you want only generate the code, you can do it like so:

```sql
DECLARE
  v_clob CLOB;
BEGIN
  FOR i IN (SELECT table_name FROM user_tables) LOOP
    v_clob := om_tapigen.get_code(
      p_table_name => i.table_name);
    dbms_xslprocessor.clob2file(
      v_clob,
      '<your_directory>',
      substr(i.table_name, 1, 26) || '_API.sql');
  END LOOP;
END;
```