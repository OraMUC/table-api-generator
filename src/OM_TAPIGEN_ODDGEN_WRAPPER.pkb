CREATE OR REPLACE PACKAGE BODY om_tapigen_oddgen_wrapper IS

  c_parameter_descriptions      CONSTANT param_type := 'Detailed parameter descriptions can be found here';
  c_enable_insertion_of_rows    CONSTANT param_type := 'Enable insertion of rows';
  c_enable_column_defaults      CONSTANT param_type := 'Enable column defaults (for create methods)';
  c_enable_update_of_rows       CONSTANT param_type := 'Enable update of rows';
  c_enable_deletion_of_rows     CONSTANT param_type := 'Enable deletion of rows';
  c_enable_parameter_prefixes   CONSTANT param_type := 'Enable parameter prefixes (p_ + colname)';
  c_enable_proc_with_out_params CONSTANT param_type := 'Enable procedure with out parameters';
  c_enable_getter_and_setter    CONSTANT param_type := 'Enable getter/setter methods';
  c_col_prefix_in_method_names  CONSTANT param_type := 'Keep column prefix in getter/setter method names';
  c_return_row_instead_of_pk    CONSTANT param_type := 'Return row instead of pk (for create methods)';
  c_double_quote_names          CONSTANT param_type := 'Place column and table names in double quotes';
  c_default_bulk_limit          CONSTANT param_type := 'Default bulk size for set based methods';
  c_enable_dml_view             CONSTANT param_type := 'Enable DML view';
  c_dml_view_name               CONSTANT param_type := 'DML view name (e.g. #TABLE_NAME#_DML_V)';
  c_enable_one_to_one_view      CONSTANT param_type := 'Enable 1:1 view with read only';
  c_one_to_one_view_name        CONSTANT param_type := '1:1 view name (e.g. #TABLE_NAME#_V)';
  c_api_name                    CONSTANT param_type := 'API name (e.g. #TABLE_NAME#_API)';
  c_sequence_name               CONSTANT param_type := 'Sequence name (e.g. #TABLE_NAME_26#_SEQ)';
  c_exclude_column_list         CONSTANT param_type := 'Exclude column list (comma separated)';
  c_audit_column_mappings       CONSTANT param_type := 'Audit column mappings (comma separated)';
  c_audit_user_expression       CONSTANT param_type := 'Audit user expression';
  c_row_version_column_mapping  CONSTANT param_type := 'Row version column mapping';
  c_enable_custom_defaults      CONSTANT param_type := 'Enable custom defaults (additional methods)';
  c_custom_default_values       CONSTANT param_type := 'Custom default values (XMLTYPE)';

  FUNCTION util_string_to_bool(p_string IN VARCHAR2) RETURN BOOLEAN IS
  BEGIN
    RETURN CASE lower(p_string) WHEN 'true' THEN TRUE WHEN 'false' THEN FALSE ELSE NULL END;
  END util_string_to_bool;

  FUNCTION util_bool_to_string(p_bool IN BOOLEAN) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE p_bool WHEN TRUE THEN 'true' WHEN FALSE THEN 'false' ELSE NULL END;
  END util_bool_to_string;

  FUNCTION get_name RETURN VARCHAR2 IS
  BEGIN
    RETURN 'OraMUC Table API Generator (v' || om_tapigen.c_generator_version || ')';
  END get_name;

  FUNCTION get_description RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Generates table APIs for tables found in the current schema.';
  END get_description;

  FUNCTION get_object_types RETURN t_string IS
  BEGIN
    RETURN NEW t_string('TABLE');
  END get_object_types;

  FUNCTION get_params RETURN t_param IS
    v_params t_param;
  BEGIN
    v_params(c_parameter_descriptions)      := 'https://github.com/OraMUC/table-api-generator/blob/master/docs/parameters.md';
    v_params(c_enable_insertion_of_rows)    := 'true';
    v_params(c_enable_column_defaults)      := 'false';
    v_params(c_enable_update_of_rows)       := 'true';
    v_params(c_enable_deletion_of_rows)     := 'false';
    v_params(c_enable_parameter_prefixes)   := 'true';
    v_params(c_enable_proc_with_out_params) := 'true';
    v_params(c_enable_getter_and_setter)    := 'true';
    v_params(c_col_prefix_in_method_names)  := 'true';
    v_params(c_return_row_instead_of_pk)    := 'false';
    v_params(c_double_quote_names)          := 'true';
    v_params(c_default_bulk_limit)          := '1000';
    v_params(c_enable_dml_view)             := 'false';
    v_params(c_dml_view_name)               := NULL;
    v_params(c_enable_one_to_one_view)      := 'false';
    v_params(c_one_to_one_view_name)        := NULL;
    v_params(c_api_name)                    := NULL;
    v_params(c_sequence_name)               := NULL;
    v_params(c_exclude_column_list)         := NULL;
    v_params(c_audit_column_mappings)       := NULL;
    v_params(c_audit_user_expression)       := om_tapigen.c_audit_user_expression;
    v_params(c_row_version_column_mapping)  := NULL;
    v_params(c_enable_custom_defaults)      := 'false';
    v_params(c_custom_default_values)       := NULL;
    RETURN v_params;
  END get_params;

  FUNCTION get_ordered_params RETURN t_string IS
  BEGIN
    RETURN NEW t_string(
      c_parameter_descriptions,
      c_enable_insertion_of_rows,
      c_enable_column_defaults,
      c_enable_update_of_rows,
      c_enable_deletion_of_rows,
      c_enable_parameter_prefixes,
      c_enable_proc_with_out_params,
      c_enable_getter_and_setter,
      c_col_prefix_in_method_names,
      c_return_row_instead_of_pk,
      c_double_quote_names,
      c_default_bulk_limit,
      c_enable_dml_view,
      c_dml_view_name,
      c_enable_one_to_one_view,
      c_one_to_one_view_name,
      c_api_name,
      c_sequence_name,
      c_exclude_column_list,
      c_audit_column_mappings,
      c_audit_user_expression,
      c_row_version_column_mapping,
      c_enable_custom_defaults,
      c_custom_default_values);
  END get_ordered_params;

  FUNCTION get_lov RETURN t_lov IS
    v_lov t_lov;
  BEGIN
    v_lov(c_enable_insertion_of_rows)    := NEW t_string('true', 'false');
    v_lov(c_enable_column_defaults)      := NEW t_string('true', 'false');
    v_lov(c_enable_update_of_rows)       := NEW t_string('true', 'false');
    v_lov(c_enable_deletion_of_rows)     := NEW t_string('true', 'false');
    v_lov(c_enable_parameter_prefixes)   := NEW t_string('true', 'false');
    v_lov(c_enable_proc_with_out_params) := NEW t_string('true', 'false');
    v_lov(c_enable_getter_and_setter)    := NEW t_string('true', 'false');
    v_lov(c_col_prefix_in_method_names)  := NEW t_string('true', 'false');
    v_lov(c_return_row_instead_of_pk)    := NEW t_string('true', 'false');
    v_lov(c_double_quote_names)          := NEW t_string('true', 'false');
    v_lov(c_enable_dml_view)             := NEW t_string('true', 'false');
    v_lov(c_enable_one_to_one_view)      := NEW t_string('true', 'false');
    v_lov(c_enable_custom_defaults)      := NEW t_string('true', 'false');
    RETURN v_lov;
  END get_lov;

  FUNCTION generate
  (
    in_object_type IN VARCHAR2,
    in_object_name IN VARCHAR2,
    in_params      IN t_param
  ) RETURN CLOB IS
  BEGIN
    RETURN om_tapigen.get_code(
      p_table_name                  => in_object_name,
      p_enable_insertion_of_rows    => util_string_to_bool(in_params(c_enable_insertion_of_rows)),
      p_enable_column_defaults      => util_string_to_bool(in_params(c_enable_column_defaults)),
      p_enable_update_of_rows       => util_string_to_bool(in_params(c_enable_update_of_rows)),
      p_enable_deletion_of_rows     => util_string_to_bool(in_params(c_enable_deletion_of_rows)),
      p_enable_parameter_prefixes   => util_string_to_bool(in_params(c_enable_parameter_prefixes)),
      p_enable_proc_with_out_params => util_string_to_bool(in_params(c_enable_proc_with_out_params)),
      p_enable_getter_and_setter    => util_string_to_bool(in_params(c_enable_getter_and_setter)),
      p_col_prefix_in_method_names  => util_string_to_bool(in_params(c_col_prefix_in_method_names)),
      p_return_row_instead_of_pk    => util_string_to_bool(in_params(c_return_row_instead_of_pk)),
      p_double_quote_names          => util_string_to_bool(in_params(c_double_quote_names)),
      p_default_bulk_limit          => to_number(in_params(c_default_bulk_limit)),
      p_enable_dml_view             => util_string_to_bool(in_params(c_enable_dml_view)),
      p_dml_view_name               => in_params(c_dml_view_name),
      p_enable_one_to_one_view      => util_string_to_bool(in_params(c_enable_one_to_one_view)),
      p_one_to_one_view_name        => in_params(c_one_to_one_view_name),
      p_api_name                    => in_params(c_api_name),
      p_sequence_name               => in_params(c_sequence_name),
      p_exclude_column_list         => in_params(c_exclude_column_list),
      p_audit_column_mappings       => in_params(c_audit_column_mappings),
      p_audit_user_expression       => in_params(c_audit_user_expression),
      p_row_version_column_mapping  => in_params(c_row_version_column_mapping),
      p_enable_custom_defaults      => util_string_to_bool(in_params(c_enable_custom_defaults)),
      p_custom_default_values       => CASE
                                        WHEN in_params(c_custom_default_values) IS NOT NULL THEN
                                          xmltype(in_params(c_custom_default_values))
                                        ELSE
                                          NULL
                                      END);
  END generate;

END om_tapigen_oddgen_wrapper;
/
