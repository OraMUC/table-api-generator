# Parameters

<!-- toc -->

- [p_table_name](#p_table_name)
- [p_owner](#p_owner)
- [p_reuse_existing_api_params](#p_reuse_existing_api_params)
- [p_enable_insertion_of_rows](#p_enable_insertion_of_rows)
- [p_enable_column_defaults](#p_enable_column_defaults)
- [p_enable_update_of_rows](#p_enable_update_of_rows)
- [p_enable_deletion_of_rows](#p_enable_deletion_of_rows)
- [p_enable_parameter_prefixes](#p_enable_parameter_prefixes)
- [p_enable_proc_with_out_params](#p_enable_proc_with_out_params)
- [p_enable_getter_and_setter](#p_enable_getter_and_setter)
- [p_col_prefix_in_method_names](#p_col_prefix_in_method_names)
- [p_return_row_instead_of_pk](#p_return_row_instead_of_pk)
- [p_enable_dml_view](#p_enable_dml_view)
- [p_enable_generic_change_log](#p_enable_generic_change_log)
- [p_api_name](#p_api_name)
- [p_sequence_name](#p_sequence_name)
- [p_exclude_column_list](#p_exclude_column_list)
- [p_enable_custom_defaults](#p_enable_custom_defaults)
- [p_custom_default_values](#p_custom_default_values)

<!-- tocstop -->

## p_table_name

- String (all_objects.object_name%TYPE), mandatory
- The table for which an API should be generated


## p_owner

- Stríng (all_users.username%TYPE), default: user
- If not null, the API is generated for the given schema


## p_reuse_existing_api_params

- Boolean, default: true
- If true, all following parameters are ignored, if the generator can find the original parameters in the package specification of the existing API - for new API's this parameter is ignored and the following parameters are used
- If false, the generator ignores any existing API options and you are able to redefine the parameters


## p_enable_insertion_of_rows

- Boolean, default: true
- Selfexplanatory, isn't it?
- If true, then create_row procedure and function is generated
- If true and parameter p_enable_update_of_rows is true, then create_or_update_row procedure and function is generated
- If false, then create_row and create_or_update_row procedure and function is NOT generated
- If false, then the corresponding DML view(`#TABLE_NAME_24#_DML_V`) instead of trigger (`#TABLE_NAME_24#_IOIUD`) raises an exception on an insert attempt


## p_enable_column_defaults

- Boolean, default: false
- If true, the data dictionary defaults of the columns are used for the create methods


## p_enable_update_of_rows

- Boolean, default: true
- Selfexplanatory, isn't it?
- If true, then update_row procedure is generated
- If true and parameter p_enable_insertion_of_rows is true, then create_or_update_row procedure and function is generated
- If false, then create_row and create_or_update_row procedure and function is NOT generated
- If false, then setter procedures for each columns are NOT generated
- If false, then the corresponding DML view(`#TABLE_NAME_24#_DML_V`) instead of trigger (`#TABLE_NAME_24#_IOIUD`) raises an exception on an update attempt


## p_enable_deletion_of_rows

- Boolean, default: false
- Selfexplanatory, isn't it?
- If true, then a delete_row procedure is generated
- If false, then the delete_row procedure is NOT generated
- If false, then the corresponding DML view(`#TABLE_NAME_24#_DML_V`) instead of trigger (`#TABLE_NAME_24#_IOIUD`) raises an exception on a delete attempt


## p_enable_parameter_prefixes

- Boolean, default: true
- If true, the parameter names of functions and procedures will be prefixed with 'p_'
- If you want to have the parameter names equal the column names then set this to false


## p_enable_proc_with_out_params

- Boolean, dafault: true
- If true, a helper method with out params is generated - can be useful for managing session state (e.g. fetch process in APEX)


## p_enable_getter_and_setter

- Boolean, default: true
- If true, for each column a get function and a set procedure is created


## p_col_prefix_in_method_names

- Boolean, default: true
- The generator is generally shorten your column names to 26 characters to build the names for the column based getter and setter methods (get_xxx, set_xxx)
- If true, the generator does no other modifications
- If false, the generator tries to find a unique column prefix for all the colums in your table
- If he find one, this column prefix is first deleted from your column name before building the short name with 26 characters
- If he could not find a column prefix, then the generator throws an exception (should we simple ignore this? let us know...)


## p_return_row_instead_of_pk

- Boolean, default: false
- If true, all relevant functions returning the row instead of the primary key column


## p_enable_dml_view

- Boolean, default: false
- If true, an updatable view named `#TABLE_NAME_24#_DML_V` is created as logical layer above the database table
- If true, a view trigger named `#TABLE_NAME_24#_IOIUD` is created to handle DML operations on the view
- If false, view and trigger are NOT generated


## p_enable_generic_change_log

- Boolean, default: false
- If true, one log entry is created for each changed column over all API enabled schema tables in one generic log table - very handy to create a record history in the user interface
- The table generic_change_log and a corresponding sequence generic_change_log_seq is created in the schema during the API creation on the very first API that uses this feature
- We could long describe this feature - try it out in your development system and decide, if you want to have it or not
- One last thing: This could NOT replace a historicization, but can deliver things, that would not so easy with a historicization - we use both sometimes together...


## p_api_name

- String (all_objects.object_name%TYPE), default: null
- If not null, the given name is used for the API 
- You can use substitutions - examples:
  - `#TABLE_NAME_20#` is treated as `substr(table_name,1,20)`
  - `#TABLE_NAME_5_20#` is treated as `substr(table_name,5,20)`
  - `#TABLE_NAME_-20_20#` is treated as `substr(table_name,-20,20)`
  - For table EMP and `p_api_name => '#TABLE_NAME_26#_API'` you get `EMP_API`


## p_sequence_name

- String (all_objects.object_name%TYPE), default: null
- If a sequence name is given here, then the resulting API is taken the ID for the create_row methods and you don't need to create a trigger for your table only for the sequence handling
- you can use the following substitution Strings, the generator is replacing this at runtime: `#TABLE_NAME_24#`, `#TABLE_NAME_26#`, `#TABLE_NAME_28#`, `#PK_COLUMN_26#`, `#PK_COLUMN_28#`, `#COLUMN_PREFIX#`
- Example 1: `#TABLE_NAME_26#_SEQ`
- Example 2: `SEQ_#PK_COLUMN_26#`
- Example 3: `#COLUMN_PREFIX#_SEQ`


## p_exclude_column_list

- String (VARCHAR2), default: null
- If not null, the provided comma separated column names are excluded on inserts and updates (virtual columns are implicitly excluded)
- Note that the excluded columns are included in all return values and possible getter methods and also can be submitted with the row based insert and update methods (values will be ignored, sure)
- Example: `'LAST_CHANGED_BY,LAST_CHANGED_ON'`


## p_enable_custom_defaults

- Boolean, default: false
- If set to true, this will create a set of new methods mainly for testing and dummy data generation purposes:
  - `get_a_row` function returns a row with (hopefully) complete default data
  - `create_a_row` function (returning pk or row depending on the parameter `return_row_instead_of_pk`) and procedure to create a new row without (hopefully) providing any parameters
  - `read_a_row` function to fetch one row (the first the database delivers) without providing a primary key parameter
  - The default values are provided by the generator and can be overwritten by passing data to the new parameter `p_custom_column_defaults xmltype default null` - you can grab the defaults from the end of the package spec - see example below:

```sql
om_tapigen.compile_api(
  p_table_name                    => 'EMPLOYEES',
  p_reuse_existing_api_params     => false,
  p_enable_proc_with_out_params   => false,
  p_enable_getter_and_setter      => false,
  p_return_row_instead_of_pk      => true,
  p_enable_dml_view               => false,
  p_api_name                      => 'EMPLOYEES_API',
  p_sequence_name                 => 'EMPLOYEES_SEQ',
  p_exclude_column_list           => 'SALARY,COMMISSION_PCT',
  p_enable_custom_defaults        => true,
  p_custom_default_values         => xmltype(q'#
    <custom_defaults>
      <column name="SALARY"><![CDATA[round(dbms_random.value(1000,10000),2)]]></column>
    </custom_defaults>#')
);
```

The custom defaults are saved as a comment at the end of the package spec to be reusable by the generator in case of a parameterless recreation with the help of the package procedure `recreate_existing_apis` - here an example from the `EMPLOYEES_API` above:

```sql
  -- end of package spec --

  /*
  Only custom defaults with the source "USER" are used when "p_reuse_existing_api_params" is set to true.
  All other custom defaults are only listed for convenience and determined at runtime by the generator.
  You can simply copy over the defaults to your generator call - the attribute "source" is ignored then.
  <custom_defaults>
    <column source="TAPIGEN" name="EMPLOYEE_ID"><![CDATA["EMPLOYEES_SEQ".nextval]]></column>
    <column source="TAPIGEN" name="FIRST_NAME"><![CDATA[substr(sys_guid(),1,20)]]></column>
    <column source="TAPIGEN" name="LAST_NAME"><![CDATA[substr(sys_guid(),1,25)]]></column>
    <column source="TAPIGEN" name="EMAIL"><![CDATA[substr(sys_guid(),1,15) || '@dummy.com']]></column>
    <column source="TAPIGEN" name="PHONE_NUMBER"><![CDATA[substr('+1.' || lpad(to_char(trunc(dbms_random.value(1,999))),3,'0') || '.' || lpad(to_char(trunc(dbms_random.value(1,999))),3,'0') || '.' || lpad(to_char(trunc(dbms_random.value(1,9999))),4,'0'),1,20)]]></column>
    <column source="TAPIGEN" name="HIRE_DATE"><![CDATA[to_date(trunc(dbms_random.value(to_char(date'1900-01-01','j'),to_char(date'2099-12-31','j'))),'j')]]></column>
    <column source="TAPIGEN" name="JOB_ID"><![CDATA['AC_ACCOUNT']]></column>
    <column source="USER"    name="SALARY"><![CDATA[round(dbms_random.value(1000,10000),2)]]></column>
    <column source="TAPIGEN" name="COMMISSION_PCT"><![CDATA[round(dbms_random.value(0,.99),2)]]></column>
    <column source="TAPIGEN" name="MANAGER_ID"><![CDATA[100]]></column>
    <column source="TAPIGEN" name="DEPARTMENT_ID"><![CDATA[10]]></column>
  </custom_defaults>
  */
END "EMPLOYEES_API";
/
```

You can let the generator do the work to generate defaults, grab the XML from the spec, modify it to your needs and use it in your generator call. In the example above I would modify the `HIRE_DATE` and the `SALARY` because the generator provided only  default random data depending on the data type and length.

With the provided defaults you are now able to do this:

```sql
-- create 100 rows without providing any data...
BEGIN
  FOR i IN 1..100 LOOP
    employees_api.create_a_row;
  END LOOP;
END;
/

-- of course, you can use the parameters if you like...
BEGIN
  FOR i IN 1..100 LOOP
    employees_api.create_a_row(
      p_job_id          => 'AD_VP',
      p_manager_id      => 100,
      p_department_id   => 90
    );
  END LOOP;
END;
/
```


## p_custom_default_values

- XMLTYPE, default null
- Custom values in XML format, if the generator provided defaults are not ok
- See also parameter p_enable_custom_defaults
