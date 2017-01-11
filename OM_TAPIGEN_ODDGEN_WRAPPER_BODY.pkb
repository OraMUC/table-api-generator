CREATE OR REPLACE PACKAGE BODY om_tapigen_oddgen_wrapper
IS
   -----------------------------------------------------------------------------
   c_reuse_existing_api_params  CONSTANT param_type
      := 'Reuse existing API package parameters' ;
   c_col_prefix_in_method_names CONSTANT param_type
      := 'Keep column prefix in method names' ;
   c_enable_insertion_of_rows   CONSTANT param_type
                                            := 'Enable insertion of rows' ;
   c_enable_update_of_rows      CONSTANT param_type := 'Enable update of rows';
   c_enable_deletion_of_rows    CONSTANT param_type
                                            := 'Enable deletion of rows' ;
   c_enable_generic_change_log  CONSTANT param_type
                                            := 'Enable generic change log' ;
   c_sequence_name              CONSTANT param_type
      := 'Sequence name (example: #TABLE_NAME_26#_SEQ)' ;

   -----------------------------------------------------------------------------
   FUNCTION get_name
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN    'github.com/OraMUC/table-api-generator (v'
             || om_tapigen.c_generator_version
             || ')';
   END get_name;

   -----------------------------------------------------------------------------
   FUNCTION get_description
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN 'Generate table API''s to avoid hard-coding SQL. The generated API''s enables you to easy seperate the data schema and the UI schema for your applications to improve security and also speeding up your development cycles. You can concentrate on business logic instead of wasting time by manual creating boilerplate code for your tables.';
   END get_description;

   -----------------------------------------------------------------------------
   FUNCTION get_object_types
      RETURN t_string
   IS
   BEGIN
      RETURN NEW t_string('TABLE');
   END get_object_types;

   -----------------------------------------------------------------------------
   FUNCTION get_params
      RETURN t_param
   IS
      v_params t_param;
   BEGIN
      v_params(c_reuse_existing_api_params)  := 'true';
      v_params(c_col_prefix_in_method_names) := 'false';
      v_params(c_enable_insertion_of_rows)   := 'true';
      v_params(c_enable_update_of_rows)      := 'true';
      v_params(c_enable_deletion_of_rows)    := 'false';
      v_params(c_enable_generic_change_log)  := 'false';
      v_params(c_sequence_name)              := '#TABLE_NAME_26#_SEQ';
      RETURN v_params;
   END get_params;

   -----------------------------------------------------------------------------
   FUNCTION get_ordered_params
      RETURN t_string
   IS
   BEGIN
      RETURN NEW t_string(c_reuse_existing_api_params
                        , c_col_prefix_in_method_names
                        , c_enable_insertion_of_rows
                        , c_enable_update_of_rows
                        , c_enable_deletion_of_rows
                        , c_enable_generic_change_log
                        , c_sequence_name);
   END get_ordered_params;

   -----------------------------------------------------------------------------
   FUNCTION get_lov
      RETURN t_lov
   IS
      v_lov t_lov;
   BEGIN
      v_lov(c_reuse_existing_api_params)  := NEW t_string('true', 'false');
      v_lov(c_col_prefix_in_method_names) := NEW t_string('true', 'false');
      v_lov(c_enable_insertion_of_rows)   := NEW t_string('true', 'false');
      v_lov(c_enable_update_of_rows)      := NEW t_string('true', 'false');
      v_lov(c_enable_deletion_of_rows)    := NEW t_string('true', 'false');
      v_lov(c_enable_generic_change_log)  := NEW t_string('true', 'false');
      RETURN v_lov;
   END get_lov;

   -----------------------------------------------------------------------------
   FUNCTION util_string_to_bool(p_string IN VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN CASE
                WHEN LOWER(p_string) IN ('true'
                                       , 'yes'
                                       , 'y'
                                       , '1')
                THEN
                   TRUE
                WHEN LOWER(p_string) IN ('false'
                                       , 'no'
                                       , 'n'
                                       , '0')
                THEN
                   FALSE
                ELSE
                   NULL
             END;
   END util_string_to_bool;

   -----------------------------------------------------------------------------
   FUNCTION generate(in_object_type IN VARCHAR2
                   , in_object_name IN VARCHAR2
                   , in_params      IN t_param)
      RETURN CLOB
   IS
   BEGIN
      RETURN om_tapigen.get_code(
                p_table_name                 => in_object_name
              , p_reuse_existing_api_params  => util_string_to_bool(
                                                  in_params(
                                                     c_reuse_existing_api_params))
              , p_col_prefix_in_method_names => util_string_to_bool(
                                                  in_params(
                                                     c_col_prefix_in_method_names))
              , p_enable_insertion_of_rows   => util_string_to_bool(
                                                  in_params(
                                                     c_enable_insertion_of_rows))
              , p_enable_update_of_rows      => util_string_to_bool(
                                                  in_params(
                                                     c_enable_update_of_rows))
              , p_enable_deletion_of_rows    => util_string_to_bool(
                                                  in_params(
                                                     c_enable_deletion_of_rows))
              , p_enable_generic_change_log  => util_string_to_bool(
                                                  in_params(
                                                     c_enable_generic_change_log))
              , p_sequence_name              => in_params(c_sequence_name));
   END generate;
--------------------------------------------------------------------------------
END om_tapigen_oddgen_wrapper;
/