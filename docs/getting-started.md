# Getting Started

<!-- toc -->

- [Installation](#installation)
- [Usage](#usage)
- [Parameters](#parameters)
- [View existing APIs](#view-existing-apis)
- [Complete Example](#complete-example)

<!-- tocstop -->

## Installation

We recommend to install the package `om_tapigen` in a central tools schema. Because the package runs with invokers rights you need to create a private or public synonym for SQL functions inside the package.

1. Download the [latest version][latest] and unzip the source code
1. Run the SQL script `install.sql` in the root folder or compile the spec and body of the package `om_tapigen` and optional `om_tapigen_oddgen_wrapper` for the SQL Developer integration
1. If installed in central tools schema
    - grant execute rights: `GRANT EXECUTE ON om_tapigen TO PUBLIC;`
    - create synonym:
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

## Parameters

There is a dedicated page for the [detailed parameter descriptions](parameters.md) - here as an example the signature for the method `compile_api` with the short descriptions:

```sql
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
  p_enable_one_to_one_view      IN BOOLEAN  DEFAULT FALSE, -- If true, a 1:1 view with read only is generated - useful when you want to separate the tables into an own schema without direct user access.
  p_api_name                    IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the API - you can use substitution like #TABLE_NAME_4_20# (treated as substr(4,20)).
  p_sequence_name               IN VARCHAR2 DEFAULT NULL,  -- If not null, the given name is used for the create_row methods - same substitutions like with API name possible.
  p_exclude_column_list         IN VARCHAR2 DEFAULT NULL,  -- If not null, the provided comma separated column names are excluded on inserts and updates (virtual columns are implicitly excluded).
  p_audit_column_mappings       IN VARCHAR2 DEFAULT NULL,  -- If not null, the provided comma separated column names are excluded and populated by the API (you don't need a trigger for update_by, update_on...).
  p_audit_user_expression       IN VARCHAR2 DEFAULT c_audit_user_expression, -- You can overwrite here the expression to determine the user which created or updated the row (see also the parameter docs...).
  p_row_version_column_mapping  IN VARCHAR2 DEFAULT NULL,  -- If not null, the provided column name is excluded and populated by the API with the provided SQL expression (you don't need a trigger to provide a row version identifier).
  p_enable_custom_defaults      IN BOOLEAN  DEFAULT FALSE, -- If true, additional methods are created (mainly for testing and dummy data creation, see full parameter descriptions).
  p_custom_default_values       IN XMLTYPE  DEFAULT NULL   -- Custom values in XML format for the previous option, if the generator provided defaults are not ok.
);
```

## View existing APIs

There is a pipelined function to view the current status of the API's and the original parameter values from the generation call:

```sql
SELECT *
  FROM TABLE(om_tapigen.view_existing_apis)
 ORDER BY table_name NULLS FIRST;
```

The leading dictionary information is the API package name. It could be, you found API's where the table_name is NULL - this means your API is existing, but your table not anymore. Thats the reason for the order by clause in the example query. You can use this pipelined function for quality assurance or for building a metadata repository with the generation parameters of your API's.


## Complete Example

The normal life cycle:

```sql
--> Check for possible naming conflicts before the very first API generation
SELECT *
  FROM TABLE(om_tapigen.view_naming_conflicts);

--> Initial API generation for your tables
BEGIN
  FOR i IN (SELECT table_name FROM user_tables /*WHERE...*/) LOOP
    om_tapigen.compile_api(
      --these are the defaults, align to your needs, you can omit unchanged parameters
      p_table_name                  => i.table_name,
      p_owner                       => user,
      p_enable_insertion_of_rows    => true,
      p_enable_column_defaults      => false,
      p_enable_update_of_rows       => true,
      p_enable_deletion_of_rows     => false,
      p_enable_parameter_prefixes   => true,
      p_enable_proc_with_out_params => true,
      p_enable_getter_and_setter    => true,
      p_col_prefix_in_method_names  => true,
      p_return_row_instead_of_pk    => false,
      p_double_quote_names          => true,
      p_default_bulk_limit          => 1000,
      p_enable_dml_view             => false,
      p_enable_one_to_one_view      => false,
      p_api_name                    => null, -- defaults to #TABLE_NAME#_API
      p_sequence_name               => null,
      p_exclude_column_list         => null,
      p_audit_column_mappings       => null,
      p_audit_user_expression       => q'[coalesce(sys_context('apex$session','app_user'), sys_context('userenv','os_user'), sys_context('userenv','session_user'))]'
      p_row_version_column_mapping  => null,
      p_enable_custom_defaults      => false,
      p_custom_default_values       => null
    );
  END LOOP;
END;

--> Inspect the results
SELECT *
  FROM TABLE(om_tapigen.view_existing_apis)
 ORDER BY table_name NULLS FIRST;

--> recreate the API's after changes in your model
BEGIN
  --use same statement as above... , ideal use some version control
END;
```

If you want only generate the code, you can do it like so:

```sql
DECLARE
  v_clob CLOB;
BEGIN
  FOR i IN (SELECT table_name FROM user_tables) LOOP
    v_clob := om_tapigen.get_code(
      p_table_name => i.table_name
      --p_...
      --p_...
    );
    dbms_xslprocessor.clob2file(
      v_clob,
      '<your_directory>',
      i.table_name || '_API.sql');
  END LOOP;
END;
```
