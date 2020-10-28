<!-- nav -->

[Index](README.md)
| [Changelog](changelog.md)
| [Getting Started](getting-started.md)
| [Parameters](parameters.md)
| [Bulk Processing](bulk-processing.md)
| [Example API](example-api.md)
| [SQL Developer Integration](sql-developer-integration.md)

<!-- navstop -->

# Parameters

<!-- toc -->

- [p_table_name (since v0.0.0 ;-)](#p_table_name-since-v000--)
- [p_owner (since v0.5.0)](#p_owner-since-v050)
- [p_enable_insertion_of_rows (since v0.4.0)](#p_enable_insertion_of_rows-since-v040)
- [p_enable_column_defaults (since v0.5.0)](#p_enable_column_defaults-since-v050)
- [p_enable_update_of_rows (since v0.4.0)](#p_enable_update_of_rows-since-v040)
- [p_enable_deletion_of_rows (since v0.4.0)](#p_enable_deletion_of_rows-since-v040)
- [p_enable_parameter_prefixes (since v0.5.0)](#p_enable_parameter_prefixes-since-v050)
- [p_enable_proc_with_out_params (since v0.5.0)](#p_enable_proc_with_out_params-since-v050)
- [p_enable_getter_and_setter (since v0.5.0)](#p_enable_getter_and_setter-since-v050)
- [p_col_prefix_in_method_names (since v0.3.0)](#p_col_prefix_in_method_names-since-v030)
- [p_return_row_instead_of_pk (since v0.5.0)](#p_return_row_instead_of_pk-since-v050)
- [p_double_quote_names (since v0.6.0)](#p_double_quote_names-since-v060)
- [p_default_bulk_limit (since v0.6.0)](#p_default_bulk_limit-since-v060)
- [p_enable_dml_view (since v0.4.0)](#p_enable_dml_view-since-v040)
- [p_dml_view_name (since v0.6.0)](#p_dml_view_name-since-v060)
- [p_dml_view_trigger_name (since v0.6.0)](#p_dml_view_trigger_name-since-v060)
- [p_enable_one_to_one_view (since v0.6.0)](#p_enable_one_to_one_view-since-v060)
- [p_one_to_one_view_name (since v0.6.0)](#p_one_to_one_view_name-since-v060)
- [p_api_name (since v0.5.0)](#p_api_name-since-v050)
- [p_sequence_name (since v0.2.0)](#p_sequence_name-since-v020)
- [p_exclude_column_list (since v0.5.0)](#p_exclude_column_list-since-v050)
- [p_audit_column_mappings (since v0.6.0)](#p_audit_column_mappings-since-v060)
- [p_audit_user_expression (since v0.6.0)](#p_audit_user_expression-since-v060)
- [p_row_version_column_mapping (since v0.6.0)](#p_row_version_column_mapping-since-v060)
- [p_tenant_column_mapping (since v0.6.0)](#p_tenant_column_mapping-since-v060)
- [p_enable_custom_defaults (since v0.5.0)](#p_enable_custom_defaults-since-v050)
- [p_custom_default_values (since v0.5.0)](#p_custom_default_values-since-v050)
- [Removed Parameters](#removed-parameters)

<!-- tocstop -->

## p_table_name (since v0.0.0 ;-)

- String (varchar2), mandatory
- The table for which an API should be generated

## p_owner (since v0.5.0)

- Stríng (all_users.username%TYPE), default: user
- If not null, the API is generated for the given schema

## p_enable_insertion_of_rows (since v0.4.0)

- Boolean, default: true
- Selfexplanatory, isn't it?
- If true, then create_row procedure and function is generated
- If true and parameter p_enable_update_of_rows is true, then create_or_update_row procedure and function is generated
- If false, then create_row and create_or_update_row procedure and function is NOT generated
- If false, then the corresponding DML view(`#TABLE_NAME_24#_DML_V`) instead of trigger (`#TABLE_NAME_24#_IOIUD`) raises an exception on an insert attempt

## p_enable_column_defaults (since v0.5.0)

- Boolean, default: false
- If true, the data dictionary defaults of the columns are used for the create methods

## p_enable_update_of_rows (since v0.4.0)

- Boolean, default: true
- Selfexplanatory, isn't it?
- If true, then update_row procedure is generated
- If true and parameter p_enable_insertion_of_rows is true, then create_or_update_row procedure and function is generated
- If false, then create_row and create_or_update_row procedure and function is NOT generated
- If false, then setter procedures for each columns are NOT generated
- If false, then the corresponding DML view(`#TABLE_NAME_24#_DML_V`) instead of trigger (`#TABLE_NAME_24#_IOIUD`) raises an exception on an update attempt

## p_enable_deletion_of_rows (since v0.4.0)

- Boolean, default: false
- Selfexplanatory, isn't it?
- If true, then a delete_row procedure is generated
- If false, then the delete_row procedure is NOT generated
- If false, then the corresponding DML view(`#TABLE_NAME_24#_DML_V`) instead of trigger (`#TABLE_NAME_24#_IOIUD`) raises an exception on a delete attempt

## p_enable_parameter_prefixes (since v0.5.0)

- Boolean, default: true
- If true, the parameter names of functions and procedures will be prefixed with 'p_'
- If you want to have the parameter names equal the column names then set this to false

## p_enable_proc_with_out_params (since v0.5.0)

- Boolean, dafault: true
- If true, a helper method with out params is generated - can be useful for managing session state (e.g. fetch process in APEX)

## p_enable_getter_and_setter (since v0.5.0)

- Boolean, default: true
- If true, for each column a get function and a set procedure is created

## p_col_prefix_in_method_names (since v0.3.0)

- Boolean, default: true
- The generator is generally shorten your column names to 26 characters to build the names for the column based getter and setter methods (get_xxx, set_xxx)
- If true, the generator does no other modifications
- If false, the generator tries to find a unique column prefix for all the colums in your table
- If he find one, this column prefix is first deleted from your column name before building the short name with 26 characters
- If he could not find a column prefix, then the generator throws an exception (should we simple ignore this? let us know...)

## p_return_row_instead_of_pk (since v0.5.0)

- Boolean, default: false
- If true, all relevant functions returning the row instead of the primary key column

## p_double_quote_names (since v0.6.0)

- Boolean, default: true
- If true, object names (owner, table, columns) are placed in double quotes

## p_default_bulk_limit (since v0.6.0)

- Integer, default: 1000
- The default bulk size for the set based methods (create_rows, read_rows, update_rows)
- You can overwrite this at runtime by calling `your_table_api.set_bulk_limit(500);`

## p_enable_dml_view (since v0.4.0)

- Boolean, default: false
- If true, an updatable view named `#TABLE_NAME#_DML_V` is created as logical layer above the database table
- If true, a view trigger named `#TABLE_NAME#_IOIUD` is created to handle DML operations on the view
- If false, view and trigger are NOT generated

## p_dml_view_name (since v0.6.0)

- String (varchar2), default: null
- If not null, the given name is used for the DML view
- You can use the substitutions `#TABLE_NAME#`, `#COLUMN_PREFIX#` and `#PK_COLUMN#` (the first column on multicolumn primary keys)
- Examples:
  - `#TABLE_NAME#` is substituted as `table_name`
  - `#TABLE_NAME_20#` is treated as `substr(table_name, 1, 20)`
  - `#TABLE_NAME_5_20#` is treated as `substr(table_name, 5, 20)`
  - `#TABLE_NAME_-20_20#` is treated as `substr(table_name, -20, 20)`
  - For TABLE_NAME_WITH_29_CHARACTERS and `p_dml_view_name => '#TABLE_NAME_24#_DML_V'` you get `TABLE_NAME_WITH_29_CHARA_DML_V`

## p_dml_view_trigger_name (since v0.6.0)

- String (varchar2), default: null
- If not null, the given name is used for the DML view trigger
- You can use the substitutions `#TABLE_NAME#`, `#COLUMN_PREFIX#` and `#PK_COLUMN#` (the first column on multicolumn primary keys)
- Examples:
  - `#TABLE_NAME#` is substituted as `table_name`
  - `#TABLE_NAME_20#` is treated as `substr(table_name, 1, 20)`
  - `#TABLE_NAME_5_20#` is treated as `substr(table_name, 5, 20)`
  - `#TABLE_NAME_-20_20#` is treated as `substr(table_name, -20, 20)`
  - For TABLE_NAME_WITH_29_CHARACTERS and `p_dml_view_trigger_name => '#TABLE_NAME_24#_IOIUD'` you get `TABLE_NAME_WITH_29_CHARA_IOIUD`

## p_enable_one_to_one_view (since v0.6.0)

- Boolean, default: false
- If true, a 1:1 view with read only is generated
- Can be useful when you want to separate the tables into an own schema without direct user access

## p_one_to_one_view_name (since v0.6.0)

- String (varchar2), default: null
- If not null, the given name is used for the 1:1 view
- You can use the substitutions `#TABLE_NAME#`, `#COLUMN_PREFIX#` and `#PK_COLUMN#` (the first column on multicolumn primary keys)
- Examples:
  - `#TABLE_NAME#` is substituted as `table_name`
  - `#TABLE_NAME_20#` is treated as `substr(table_name, 1, 20)`
  - `#TABLE_NAME_5_20#` is treated as `substr(table_name, 5, 20)`
  - `#TABLE_NAME_-20_20#` is treated as `substr(table_name, -20, 20)`
  - For TABLE_NAME_WITH_29_CHARACTERS and `p_one_to_one_view_name => '#TABLE_NAME_28#_V'` you get `TABLE_NAME_WITH_29_CHARACTER_V`

## p_api_name (since v0.5.0)

- String (varchar2), default: null
- If not null, the given name is used for the API
- You can use the substitutions `#TABLE_NAME#`, `#COLUMN_PREFIX#` and `#PK_COLUMN#` (the first column on multicolumn primary keys)
- Examples:
  - `#TABLE_NAME#` is substituted as `table_name`
  - `#TABLE_NAME_20#` is treated as `substr(table_name, 1, 20)`
  - `#TABLE_NAME_5_20#` is treated as `substr(table_name, 5, 20)`
  - `#TABLE_NAME_-20_20#` is treated as `substr(table_name, -20, 20)`
  - For TABLE_NAME_WITH_29_CHARACTERS and `p_api_name => '#TABLE_NAME_26#_API'` you get `TABLE_NAME_WITH_29_CHARACT_API`

## p_sequence_name (since v0.2.0)

- String (varchar2), default: null
- If a sequence name is given here, then the resulting API is taken the ID for the create_row methods and you don't need to create a trigger for your table only for the sequence handling
- you can use the following substitution Strings, the generator is replacing this at runtime: `#TABLE_NAME_24#`, `#TABLE_NAME_26#`, `#TABLE_NAME_28#`, `#PK_COLUMN_26#`, `#PK_COLUMN_28#`, `#COLUMN_PREFIX#`
- Example 1: `#TABLE_NAME_26#_SEQ`
- Example 2: `SEQ_#PK_COLUMN_26#`
- Example 3: `#COLUMN_PREFIX#_SEQ`

## p_exclude_column_list (since v0.5.0)

- String (varchar2), default: null
- If not null, the provided comma separated column names are excluded on inserts and updates (virtual columns are implicitly excluded)
- Note that the excluded columns are included in all return values and possible getter methods and also can be submitted with the row based insert and update methods (values will be ignored, sure)
- Example: `'LAST_CHANGED_BY,LAST_CHANGED_ON'`

## p_audit_column_mappings (since v0.6.0)

- String (varchar2)
- If not null, the provided comma separated column names are excluded and populated by the API (you don't need a trigger for update_by, update_on...)
- Supports column prefix placeholders to be able to reuse the same mappings in multiple tables with different column_prefixes
- Example: `created=#PREFIX#_CREATED_ON, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED_ON, updated_by=#PREFIX#_UPDATED_BY`

## p_audit_user_expression (since v0.6.0)

- String (varchar2), default: `coalesce(sys_context('apex$session','app_user'), sys_context('userenv','os_user'), sys_context('userenv','session_user'))`
- This default should be ok for most of the projects, align it to your needs

## p_row_version_column_mapping (since v0.6.0)

- String (varchar2), default: null
- If not null, the provided column name is excluded and populated by the API with the provided SQL expression (you don't need a trigger to provide a row version identifier)
- Supports column prefix placeholders to be able to reuse the same mappings in multiple tables with different column_prefixes
- Example with a global version sequence: `#PREFIX#_VERSION_ID=tag_global_version_sequence.nextval`

## p_tenant_column_mapping (since v0.6.0)
- String (varchar2), default: null
- If not null, the provided column name is excluded from the parameters and appended to all primary key where clauses with the provided SQL expression
- If you have unique keys in your tables you should make sure the tenant column is part of it, otherwise the unique key based read_row methods are not filtering correct
- For the ref cursor based bulk fetch method `read_rows` the API cannot do anything for you, because the ref cursor is defined outside the API - you need to make sure that all view provided to the users are secured correct with an appropriate where clause - the generated DML and 1:1 views do this also
- You should consider to hide your column from standard `select *` queries: Also see [Invisible Columns in Oracle Database 12c Release 1 (12.1)](https://oracle-base.com/articles/12c/invisible-columns-12cr1)
- Supports column prefix placeholders to be able to reuse the same mappings in multiple tables with different column_prefixes
- Example: `#PREFIX#_TENANT_ID=to_number(sys_context('my_sec_ctx','my_tenant_id'))`

## p_enable_custom_defaults (since v0.5.0)

- Boolean, default: false
- If set to true, this will create a set of new methods mainly for testing and dummy data generation purposes:
  - `get_a_row` function returns a row with (hopefully) complete default data
  - `create_a_row` function (returning pk or row depending on the parameter `return_row_instead_of_pk`) and procedure to create a new row without (hopefully) providing any parameters
  - `read_a_row` function to fetch one row (the first the database delivers) without providing a primary key parameter
  - The default values are provided by the generator and can be overwritten by passing data to the new parameter `p_custom_column_defaults xmltype default null` - you can grab the defaults from the end of the package spec - see example below:

```sql
create table app_users (
  au_id          integer            generated always as identity,
  au_first_name  varchar2(15 char)                         ,
  au_last_name   varchar2(15 char)                         ,
  au_email       varchar2(30 char)               not null  ,
  au_credits     integer                                   ,
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

begin
  om_tapigen.compile_api(
    p_table_name                    => 'APP_USERS',
    p_enable_custom_defaults        => true,
    p_custom_default_values         => xmltype(q'#
      <custom_defaults>
        <column name="AU_CREDITS"><![CDATA[round(dbms_random.value(1000,3000))]]></column>
      </custom_defaults>#')
  );
end;
/
```

The custom defaults are saved as a comment at the end of the package spec to be reusable by the generator - here an example from the `APP_USERS_API` above:

```sql
  /*
  You can simply copy over the defaults to your generator call - the attribute "source" is ignored then.
  <custom_defaults>
    <column source="TAPIGEN" name="AU_FIRST_NAME"><![CDATA[initcap(sys.dbms_random.string('L', round(sys.dbms_random.value(3, 15))))]]></column>
    <column source="TAPIGEN" name="AU_LAST_NAME"><![CDATA[initcap(sys.dbms_random.string('L', round(sys.dbms_random.value(3, 15))))]]></column>
    <column source="TAPIGEN" name="AU_EMAIL"><![CDATA[sys.dbms_random.string('L', round(sys.dbms_random.value(6, 12))) || '@' || sys.dbms_random.string('L', round(sys.dbms_random.value(6, 12))) || '.' || sys.dbms_random.string('L', round(sys.dbms_random.value(2, 4)))]]></column>
    <column source="USER"    name="AU_CREDITS"><![CDATA[round(dbms_random.value(1000,3000))]]></column>
    <column source="TABLE"   name="AU_ACTIVE_YN"><![CDATA['Y'  ]]></column>
    <column source="TAPIGEN" name="AU_CREATED_ON"><![CDATA[to_date(round(sys.dbms_random.value(to_char(date '1900-01-01', 'j'), to_char(date '2099-12-31', 'j'))), 'j')]]></column>
    <column source="TAPIGEN" name="AU_CREATED_BY"><![CDATA[sys.dbms_random.string('A', round(sys.dbms_random.value(1, 15)))]]></column>
    <column source="TAPIGEN" name="AU_UPDATED_AT"><![CDATA[systimestamp]]></column>
    <column source="TAPIGEN" name="AU_UPDATED_BY"><![CDATA[sys.dbms_random.string('A', round(sys.dbms_random.value(1, 15)))]]></column>
  </custom_defaults>
  */
END "EMPLOYEES_API";
/
```

You can let the generator do the work to generate defaults, grab the XML from the spec, modify it to your needs and use it in your generator call with the parameter p_custom_default_values.

With the provided defaults you are now able to do this:

```sql
-- create 100 rows without providing any data...
begin
  for i in 1..100 loop
    app_users_api.create_a_row;
  end loop;
end;
/

-- of course, you can use the parameters if you like...
begin
  for i in 1..100 loop
    app_users_api.create_a_row(
      p_au_credits => 100
    );
  end loop;
end;
/
```

## p_custom_default_values (since v0.5.0)

- XMLTYPE, default null
- Custom values in XML format, if the generator provided defaults are not ok
- See also parameter p_enable_custom_defaults

## Removed Parameters

### p_reuse_existing_api_params (available until v0.5.x)

- Boolean, default: true
- If true, all following parameters are ignored, if the generator can find the original parameters in the package specification of the existing API - for new API's this parameter is ignored and the following parameters are used
- If false, the generator ignores any existing API options and you are able to redefine the parameters

### p_enable_generic_change_log (available until v0.5.x)

- Boolean, default: false
- If true, one log entry is created for each changed column over all API enabled schema tables in one generic log table - very handy to create a record history in the user interface
- The table generic_change_log and a corresponding sequence generic_change_log_seq is created in the schema during the API creation on the very first API that uses this feature
- We could long describe this feature - try it out in your development system and decide, if you want to have it or not
- One last thing: This could NOT replace a historicization, but can deliver things, that would not so easy with a historicization - we use both sometimes together...
