# SQL Developer Integration

Please install first the [oddgen](https://www.oddgen.org/) extension. Our wrapper package is autodiscovered by this extension.

![SQL Developer Integration](images/sql-developer-integration.png)

## Multiple Ways To Your APIs

You should first think about if you want to version control the generated APIs or the generator itself and the PL/SQL scripts to compile the API. Both ways and any other combination in between are valid solutions and depending on your needs. Fortunately the generator supports three (four, if you take SQL Developer into account) ways to your API. There are three methods in the generator package: compile_api, compile_api_and_get_code, get_code. The last method is used in the SQL Developer integration. This means SQL Developer is not compiling your API, it is simply a helper to generate the code for you with a graphical configuration form and output to a worksheet or the clipboard of your operating system. If you want to fully script your APIs generation then SQL Developer is a no go.

Here one possible way using the SQL Developer

1. Check naming conflicts in your schema before the very first API compilation: `select * from table(om_tapigen.view_naming_conflicts);`
2. Use SQL Developer for the first API creation (you can create API's for multiple tables at once)
3. Inspect and run the generated code as a script, then save it to your version control system for the deployment
4. View the state of all existing API's: `select * from table(om_tapigen.view_existing_apis);`
5. On model changes recreate all existing API's with the original parameters (see script below)

```sql
declare
  function char2bool (p_bool varchar2) return boolean is
  begin
    return case when trim(upper(p_bool)) = 'TRUE' then true else false end;
  end;
begin
  for i in (
    select * from table(om_tapigen.view_existing_apis)
    --this reads the original used parameters from the API package spec
  ) loop
    om_tapigen.compile_api(
      p_table_name                  => i.p_table_name,
      p_owner                       => i.p_owner,
      p_enable_insertion_of_rows    => char2bool(i.p_enable_insertion_of_rows),
      p_enable_column_defaults      => char2bool(i.p_enable_column_defaults),
      p_enable_update_of_rows       => char2bool(i.p_enable_update_of_rows),
      p_enable_deletion_of_rows     => char2bool(i.p_enable_deletion_of_rows),
      p_enable_parameter_prefixes   => char2bool(i.p_enable_parameter_prefixes),
      p_enable_proc_with_out_params => char2bool(i.p_enable_proc_with_out_params),
      p_enable_getter_and_setter    => char2bool(i.p_enable_getter_and_setter),
      p_col_prefix_in_method_names  => char2bool(i.p_col_prefix_in_method_names),
      p_return_row_instead_of_pk    => char2bool(i.p_return_row_instead_of_pk),
      p_double_quote_names          => char2bool(i.p_double_quote_names),
      p_default_bulk_limit          => to_number(i.p_default_bulk_limit),
      p_enable_dml_view             => char2bool(i.p_enable_dml_view),
      p_enable_one_to_one_view      => char2bool(i.p_enable_one_to_one_view),
      p_api_name                    => i.p_api_name,
      p_sequence_name               => i.p_sequence_name,
      p_exclude_column_list         => i.p_exclude_column_list,
      p_audit_column_mappings       => i.p_audit_column_mappings,
      p_audit_user_expression       => i.p_audit_user_expression,
      p_row_version_column_mapping  => i.p_row_version_column_mapping,
      p_enable_custom_defaults      => char2bool(i.p_enable_custom_defaults),
      p_custom_default_values       => case when i.p_custom_default_values is not null
                                         then xmltype(i.p_custom_default_values)
                                         else null
                                       end
    );
  end loop;
end;
/
```
