<!-- nav -->

[Index](README.md)
| [Changelog](changelog.md)
| [Getting Started](getting-started.md)
| [Parameters](parameters.md)
| [Naming Conventions](naming-conventions.md)
| [Bulk Processing](bulk-processing.md)
| [Example API](example-api.md)

<!-- navstop -->

# Changelog

This project uses [semantic versioning][semver].

Please use for all comments, discussions, feature requests or bug reports the GitHub [issues] functionality.

[semver]: http://semver.org/
[issues]: https://github.com/OraMUC/table-api-generator/issues

<!-- toc -->

- [0.6.0 (2020-xx-xx)](#060-2020-xx-xx)
- [0.5.2 (2020-05-09)](#052-2020-05-09)
- [0.5.1 (2020-04-19)](#051-2020-04-19)
- [0.5.0 (2018-12-23)](#050-2018-12-23)
- [0.4.1 (2017-05-27)](#041-2017-05-27)
- [0.4.0 (2017-03-30)](#040-2017-03-30)
- [0.3.0 (2016-07-03)](#030-2016-07-03)
- [0.2.0 (not published)](#020-not-published)
- [0.1.0 (not published)](#010-not-published)

<!-- tocstop -->

## 0.6.0 (2020-xx-xx)

- added: support for bulk processing (generated per default as core functionality)
- added: support for audit columns (parameters p_audit_column_mappings and p_audit_user_expression)
- added: support for a row version column (parameter p_row_version_column_mapping)
- added: support for a 1:1 view with read only (parameter p_enable_one_to_one_view)
- added: double quoting of table and column names can now be configured (parameter p_double_quote_names, default true)
- added: update function with return clause (mainly for use in create_or_update_row to prevent read row after update)
- added: unit tests with utPLSQL (it will be a permanent task to improve the tests with every new feature or bugfix)
- removed: support for a generic change log (parameter p_enable_generic_change_log - makes no sense anymore with bulk processing and multi column primary keys)
- removed: prevent updates if columns do not differ (remove was needed to support all possible column types and for performance reasons)
- removed: parameter p_reuse_existing_api_params (usage was was not logic, simply provide always your needed parameters and create scripts or a wrapper)
- removed: procedure recreate_existing_apis (this was a parameterless procedure which reused the existing API parameters, you can still do this with the help of the pipelined function view_existing_apis)
- fixed: identity columns are always hidden on create methods (is now handled correct and in the sense of an API)

## 0.5.2 (2020-05-09)

Fixes #30: Primary key missing from create_row when identity column is used as PK - thanks to PaoloM (github.com/softinn72) to report this issue.

## 0.5.1 (2020-04-19)

Fixes #29: Primary key not returned on create_row when XMLTYPE column is present - thanks to PaoloM (github.com/softinn72) to report this issue.

## 0.5.0 (2018-12-23)

Special thanks to Jacek Gębal (github.com/jgebal), Peter Ettinger (github.com/pettinger) and PaoloM (github.com/softinn72) for the valuable feedback in several issues.

ATTENTION: When installed in a central tools schema you need from version 0.5 onwards a synonym `om_tapigen` (private in the target schema or public) to run the package because of SQL functions inside the package.

New support for multi column primary keys:

- NOT generated: get_pk_by_unique_cols functions - use instead read_row functions, which are also overloaded with unique constraint params and returning the whole row
- NOT supported: use of generic change log (p_enable_generic_change_log)

New parameters:

- `p_owner ALL_USERS.USERNAME%TYPE DEFAULT USER`: [docs](https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md#p_owner)
- `p_enable_column_defaults BOOLEAN DEFAULT FALSE`: [docs](https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md#p_enable_column_defaults)
- `p_enable_parameter_prefixes BOOLEAN DEFAULT TRUE`: [docs](https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md#p_enable_parameter_prefixes)
- `p_enable_proc_with_out_params BOOLEAN DEFAULT TRUE`: [docs](https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md#p_enable_proc_with_out_params)
- `p_enable_getter_and_setter BOOLEAN DEFAULT TRUE`: [docs](https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md#p_enable_getter_and_setter)
- `p_return_row_instead_of_pk BOOLEAN DEFAULT FALSE`: [docs](https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md#p_return_row_instead_of_pk)
- `p_api_name VARCHAR2 DEFAULT NULL`: [docs](https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md#p_api_name)
- `p_exclude_column_list VARCHAR2 DEFAULT NULL`: [docs](https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md#p_exclude_column_list)
- `p_enable_custom_defaults BOOLEAN DEFAULT FALSE`: [docs](https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md#p_enable_custom_defaults)
- `p_custom_default_values XMLTYPE DEFAULT NULL`: [docs](https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md#p_custom_default_values)

Other things, mostly internals, the visible one is better formatted API code:

- Support for Oracle 12c long identifiers
- Rework pipelined table function `view_existing_apis` to be able to find also APIs with names other then `<TABLE_NAME>_API` since the API name is now changeable with the parameter `p_api_name`
- Changed signatur of the helper method `create_change_log_entry` with column type parameters to support also varchar2 pk_id values (needed for natural pk's like an ISO currency code)
- Enhanced template engine - Supports now dynamic substitutions:
  - Changed template placeholder from `#EXAMPLE_STATIC#` to `{{ EXAMPLE_STATIC }}` and `{% EXAMPLE_DYNAMIC %}`, because `#` is a valid character in a column name
  - This was needed for the column compare list, which can be easily grow over 32k with only slightly more then one hundred columns
  - Switched all column lists to dynamic substitutions, because since DB release 12 we have 128 chars for a column, so normal column lists could also easily grow over 32k
  - Nicer output: lowercase paramaters and method names, lists with one entry per line and we tried to align the parameter definitions and mappings...
- New code instrumentation (debugging):
  - Capture run time statistics for all steps in the API generation
  - Write session module and action for DB administration
  - Maximum 1000 API creations will be captured for memory reasons (debug log is saved in memory)
- We started to implement tests:
  - In the first step we have simple scripts to test various tables definitions
  - In the second step we want to use also utPLSQL for tests
- Many rework in the background, mainly for the multi column primary keys - Thank you Peter ;-)

## 0.4.1 (2017-05-27)

- Fixes #5: Parameter with PK is not used to insert - thanks to Jacek Gębal to report this issue

## 0.4.0 (2017-03-30)

New generated API functions / procedures:

- adding a **row_exists_yn** function that returns 'Y' or 'N', same functionality as the existing **row_exists** function but allows to check a row within SQL context
- adding additional **read_row** functions that takes unique constraint columns as parameter and returns the row, for each unique constraint one read_row function
- **new enable INSERT, UPDATE, DELETE parameter** for fine granular definition, which DML operations are allowed on the table
- optional DML view as logical layer above the database table. This can be used in e.g. in APEX instead of the table to create forms, interactive grids etc AND to ensure, that table API is used
- optional DML view trigger that additionally catches unallowed DML operations and throws exceptions in dependency of **new enable INSERT, UPDATE, DELETE parameter**

Code optimizations:

- getter functions for each column: remove unnecessary variable declaration (variable v_return)
- setter functions for each column: remove unnecessary variable declaration (variable v_#column_name#)
- limit clause for bulk collect operations introduced to avoid session memory conflicts

Other stuff:

- added some additional comments on internal procedures and functions
- renaming internal variables more consistently
- supporting special column names, by using quotes around column names and validating / converting parameter names

## 0.3.0 (2016-07-03)

- First public release
- André: Complete redesign with global package collections and initialisation phase to avoid many dictionary queries
- Ottmar: Integration of all dependencies as package utilities, template engine to avoid many replace statements, integration in SQL-Developer, save parameters in source code for easy recreation

## 0.2.0 (not published)

- André: Read row procedure for APEX with out parameters for the page items, rowtype based methods
- Ottmar: Generic change log, get pk by unique columns function, idea for rowtype based methods

## 0.1.0 (not published)

- André: Idea and first running version
- Ottmar: Fan of the idea and first usage in a project :-)
