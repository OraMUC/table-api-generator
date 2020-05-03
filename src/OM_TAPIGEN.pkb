CREATE OR REPLACE PACKAGE BODY om_tapigen IS

  -----------------------------------------------------------------------------
  -- Private global constants (c_*)
  -----------------------------------------------------------------------------
  c_generator_error_number      CONSTANT PLS_INTEGER := -20000;
  c_lf                          CONSTANT t_vc2_1 := chr(10);
  c_lflf                        CONSTANT t_vc2_2 := chr(10) || chr(10);
  c_list_delimiter              CONSTANT t_vc2_2 := ',' || chr(10);
  c_custom_defaults_present_msg CONSTANT t_vc2_30 := 'SEE_END_OF_API_PACKAGE_SPEC';
  c_spec_options_min_line       CONSTANT INTEGER := 5;
  c_spec_options_max_line       CONSTANT INTEGER := 40;
  c_debug_max_runs              CONSTANT INTEGER := 1000;

  -----------------------------------------------------------------------------
  -- Private record (t_rec_*) and collection (t_tab_*) types
  -----------------------------------------------------------------------------
  TYPE t_rec_params IS RECORD(
    table_name                  all_objects.object_name%TYPE,
    owner                       all_users.username%TYPE,
    enable_insertion_of_rows    BOOLEAN,
    enable_column_defaults      BOOLEAN,
    enable_update_of_rows       BOOLEAN,
    enable_deletion_of_rows     BOOLEAN,
    enable_parameter_prefixes   BOOLEAN,
    enable_proc_with_out_params BOOLEAN,
    enable_getter_and_setter    BOOLEAN,
    col_prefix_in_method_names  BOOLEAN,
    return_row_instead_of_pk    BOOLEAN,
    double_quote_names          BOOLEAN,
    default_bulk_limit          INTEGER,
    enable_dml_view             BOOLEAN,
    enable_one_to_one_view      BOOLEAN,
    api_name                    all_objects.object_name%TYPE,
    sequence_name               all_sequences.sequence_name%TYPE,
    exclude_column_list         t_vc2_4k,
    audit_column_mappings       t_vc2_4k,
    audit_user_expression       t_vc2_4k,
    row_version_column_mapping  t_vc2_4k,
    enable_custom_defaults      BOOLEAN,
    custom_default_values       XMLTYPE,
    custom_defaults_serialized  t_vc2_32k);

  TYPE t_rec_status IS RECORD(
    generator_action       t_vc2_30,
    column_prefix          all_tab_cols.column_name%TYPE,
    pk_is_multi_column     BOOLEAN,
    identity_column        all_tab_cols.column_name%TYPE,
    identity_type          t_vc2_30,
    xmltype_column_present BOOLEAN,
    number_of_data_columns INTEGER,
    number_of_pk_columns   INTEGER,
    number_of_uk_columns   INTEGER,
    number_of_fk_columns   INTEGER,
    rpad_columns           INTEGER,
    rpad_pk_columns        INTEGER,
    rpad_uk_columns        INTEGER);

  --

  TYPE t_tab_columns IS TABLE OF t_rec_columns INDEX BY BINARY_INTEGER; -- record type is public beacause of util_view_columns_array

  --

  TYPE t_tab_columns_index IS TABLE OF INTEGER INDEX BY user_tab_columns.column_name%TYPE;

  --

  TYPE t_rec_constraints IS RECORD(
    constraint_name user_constraints.constraint_name%TYPE);

  TYPE t_tab_constraints IS TABLE OF t_rec_constraints INDEX BY BINARY_INTEGER;

  --

  TYPE t_rec_cons_columns IS RECORD(
    constraint_name    all_cons_columns.constraint_name%TYPE,
    position           all_cons_columns.position%TYPE,
    column_name        all_cons_columns.column_name%TYPE,
    column_name_length INTEGER,
    data_type          all_tab_cols.data_type%TYPE,
    r_owner            all_users.username%TYPE,
    r_table_name       all_objects.object_name%TYPE,
    r_column_name      all_tab_cols.column_name%TYPE);

  TYPE t_tab_cons_columns IS TABLE OF t_rec_cons_columns INDEX BY BINARY_INTEGER;

  --

  TYPE t_rec_code_blocks IS RECORD(
    template                       t_vc2_32k,
    api_spec                       CLOB,
    api_spec_varchar_cache         t_vc2_32k,
    api_body                       CLOB,
    api_body_varchar_cache         t_vc2_32k,
    dml_view                       CLOB,
    dml_view_varchar_cache         t_vc2_32k,
    dml_view_trigger               CLOB,
    dml_view_trigger_varchar_cache t_vc2_32k,
    one_to_one_view                CLOB,
    one_to_one_view_varchar_cache  t_vc2_32k
    );

  --

  TYPE t_rec_template_options IS RECORD(
    use_column_defaults   BOOLEAN,
    crud_mode             t_vc2_10,
    padding               INTEGER);

  --

  TYPE t_tab_vc2_2k IS TABLE OF t_vc2_2k INDEX BY BINARY_INTEGER;

  --

  TYPE t_rec_iterator IS RECORD(
    column_name           all_tab_cols.column_name%TYPE,
    method_name           all_tab_cols.column_name%TYPE,
    parameter_name        all_tab_cols.column_name%TYPE,
    old_value             t_vc2_500,
    new_value             t_vc2_500,
    current_uk_constraint all_objects.object_name%TYPE);

  --

  TYPE t_rec_debug_details IS RECORD(
    step       INTEGER(4),
    module     t_vc2_64,
    action     t_vc2_64,
    start_time TIMESTAMP(6),
    stop_time  TIMESTAMP(6));

  TYPE t_tab_debug_details IS TABLE OF t_rec_debug_details INDEX BY BINARY_INTEGER;

  --

  TYPE t_rec_debug IS RECORD(
    run        INTEGER(4),
    owner      all_users.username%TYPE,
    table_name all_objects.object_name%TYPE,
    start_time TIMESTAMP(6),
    stop_time  TIMESTAMP(6),
    details    t_tab_debug_details);

  TYPE t_tab_debug IS TABLE OF t_rec_debug INDEX BY BINARY_INTEGER;

  -----------------------------------------------------------------------------
  -- private global variables (g_*)
  -----------------------------------------------------------------------------

  --variables
  g_debug_enabled BOOLEAN;
  g_debug_run     INTEGER;
  g_debug_step    INTEGER;
  g_debug_module  t_vc2_64;

  -- records
  g_params              t_rec_params;
  g_iterator            t_rec_iterator;
  g_code_blocks         t_rec_code_blocks;
  g_status              t_rec_status;
  g_template_options    t_rec_template_options;

  -- collections
  g_columns               t_tab_columns;
  g_columns_reverse_index t_tab_columns_index;
  g_uk_constraints        t_tab_constraints;
  g_fk_constraints        t_tab_constraints;
  g_pk_columns            t_tab_cons_columns;
  g_uk_columns            t_tab_cons_columns;
  g_fk_columns            t_tab_cons_columns;
  g_debug                 t_tab_debug;

  -----------------------------------------------------------------------------
  -- private global cursors (g_cur_*)
  -----------------------------------------------------------------------------
  /* Because we use the SQL Developer PLSQL Cop plug-in we need to duplicate
  the whole cursor for the conditional compilation to avoid syntax errors.
  Also see the issue on GitHub:
  https://github.com/Trivadis/plsql-cop-sqldev/issues/4 */
  $IF $$db_version < 121 $THEN
  CURSOR g_cur_columns IS
    WITH not_null_columns AS
     (SELECT CASE
               WHEN instr(column_name_nn, '"') = 0 THEN
                upper(column_name_nn)
               ELSE
                TRIM(both '"' FROM column_name_nn)
             END AS column_name_nn
        FROM (SELECT regexp_substr(
                       om_tapigen.util_get_cons_search_condition(
                         p_owner           => USER,
                         p_constraint_name => constraint_name),
                       '^\s*("[^"]+"|[a-zA-Z0-9_#$]+)\s+is\s+not\s+null\s*$',
                       1,
                       1,
                       'i',
                       1) AS column_name_nn
                FROM all_constraints
               WHERE owner = g_params.owner
                 AND table_name = g_params.table_name
                 AND constraint_type = 'C'
                 AND status = 'ENABLED')
       WHERE column_name_nn IS NOT NULL),
    excluded_columns AS
     (SELECT column_value AS column_name_excluded
        FROM TABLE(om_tapigen.util_split_to_table(g_params.exclude_column_list))),
    identity_columns AS (
      SELECT 'DUMMY_COLUMN_NAME' AS column_name_identity,
              NULL AS identity_type
        FROM dual
      ),
    t AS
     (SELECT DISTINCT column_id,
                      column_name,
                      data_type,
                      char_length,
                      data_length,
                      data_precision,
                      data_scale,
                      identity_type,
                      'N' AS default_on_null_yn,
                      CASE
                        WHEN data_default IS NOT NULL THEN
                         (SELECT om_tapigen.util_get_column_data_default(p_owner       => g_params.owner,
                                                                         p_table_name  => table_name,
                                                                         p_column_name => column_name)
                            FROM dual)
                        ELSE
                         NULL
                      END AS data_default,
                      virtual_column,
                      CASE
                        WHEN column_name_nn IS NOT NULL THEN
                         'N'
                        ELSE
                         'Y'
                      END AS is_nullable_yn,
                      CASE
                        WHEN (virtual_column = 'YES' AND data_type != 'XMLTYPE') OR
                             excluded_columns.column_name_excluded IS NOT NULL THEN
                         'Y'
                        ELSE
                         'N'
                      END AS is_excluded_yn
        FROM all_tab_cols
        LEFT JOIN not_null_columns ON all_tab_cols.column_name = not_null_columns.column_name_nn
        LEFT JOIN excluded_columns ON all_tab_cols.column_name = excluded_columns.column_name_excluded
        LEFT JOIN identity_columns ON all_tab_cols.column_name = identity_columns.column_name_identity
       WHERE owner = g_params.owner
         AND table_name = g_params.table_name
         AND hidden_column = 'NO'
       ORDER BY column_id)
    SELECT column_name,
           data_type,
           char_length,
           data_length,
           data_precision,
           data_scale,
           data_default,
           NULL AS data_custom_default,
           NULL AS custom_default_source,
           identity_type,
           default_on_null_yn,
           'N' AS is_pk_yn,
           'N' AS is_uk_yn,
           'N' AS is_fk_yn,
           is_nullable_yn,
           is_excluded_yn,
           NULL AS audit_type,
           NULL AS row_version_expression,
           NULL AS r_owner,
           NULL AS r_table_name,
           NULL AS r_column_name
      FROM t;
  $ELSE
  CURSOR g_cur_columns IS
    WITH not_null_columns AS
     (SELECT CASE
               WHEN instr(column_name_nn, '"') = 0 THEN
                upper(column_name_nn)
               ELSE
                TRIM(both '"' FROM column_name_nn)
             END AS column_name_nn
        FROM (SELECT regexp_substr(
                       search_condition_vc,
                       '^\s*("[^"]+"|[a-zA-Z0-9_#$]+)\s+is\s+not\s+null\s*$',
                       1,
                       1,
                       'i',
                       1) AS column_name_nn
                FROM all_constraints
               WHERE owner = g_params.owner
                 AND table_name = g_params.table_name
                 AND constraint_type = 'C'
                 AND status = 'ENABLED')
       WHERE column_name_nn IS NOT NULL),
    excluded_columns AS
     (SELECT column_value AS column_name_excluded
        FROM TABLE(om_tapigen.util_split_to_table(g_params.exclude_column_list))),
    identity_columns AS
     (SELECT column_name AS column_name_identity,
             generation_type AS identity_type
        FROM all_tab_identity_cols
       WHERE owner = g_params.owner
         AND table_name = g_params.table_name),
    t AS
     (SELECT DISTINCT column_id,
                      column_name,
                      data_type,
                      char_length,
                      data_length,
                      data_precision,
                      data_scale,
                      identity_type,
                      CASE WHEN default_on_null = 'YES' THEN 'Y' ELSE 'N' END AS default_on_null_yn,
                      CASE
                        WHEN data_default IS NOT NULL THEN
                         (SELECT om_tapigen.util_get_column_data_default(p_owner       => g_params.owner,
                                                                         p_table_name  => table_name,
                                                                         p_column_name => column_name)
                            FROM dual)
                        ELSE
                         NULL
                      END AS data_default,
                      virtual_column,
                      CASE
                        WHEN column_name_nn IS NOT NULL THEN
                         'N'
                        ELSE
                         'Y'
                      END AS is_nullable_yn,
                      CASE
                        WHEN (virtual_column = 'YES' AND data_type != 'XMLTYPE') OR
                             excluded_columns.column_name_excluded IS NOT NULL THEN
                         'Y'
                        ELSE
                         'N'
                      END AS is_excluded_yn
        FROM all_tab_cols
        LEFT JOIN not_null_columns ON all_tab_cols.column_name = not_null_columns.column_name_nn
        LEFT JOIN excluded_columns ON all_tab_cols.column_name = excluded_columns.column_name_excluded
        LEFT JOIN identity_columns ON all_tab_cols.column_name = identity_columns.column_name_identity
       WHERE owner = g_params.owner
         AND table_name = g_params.table_name
         AND hidden_column = 'NO'
       ORDER BY column_id)
    SELECT column_name,
           data_type,
           char_length,
           data_length,
           data_precision,
           data_scale,
           data_default,
           NULL AS data_custom_default,
           NULL AS custom_default_source,
           identity_type,
           default_on_null_yn,
           'N' AS is_pk_yn,
           'N' AS is_uk_yn,
           'N' AS is_fk_yn,
           is_nullable_yn,
           is_excluded_yn,
           NULL AS audit_type,
           NULL AS row_version_expression,
           NULL AS r_owner,
           NULL AS r_table_name,
           NULL AS r_column_name
      FROM t;
  $END
  -----------------------------------------------------------------------------
  -- util_execute_sql is a private helper procedure that parses and executes
  -- generated code with the help of DBMS_SQL package. Execute immediate is not
  -- used here directly, because of the missing possibility of parsing a
  -- statement in a performant way. Executing immediate and catching
  -- the error is more expensive than parsing the statement and catching the
  -- error.
  -----------------------------------------------------------------------------
  PROCEDURE util_execute_sql(p_sql IN OUT NOCOPY CLOB) IS
    v_cursor      PLS_INTEGER;
    v_exec_result PLS_INTEGER;
  BEGIN
    v_cursor := sys.dbms_sql.open_cursor;
    sys.dbms_sql.parse(v_cursor, p_sql, sys.dbms_sql.native);
    v_exec_result := sys.dbms_sql.execute(v_cursor);
    sys.dbms_sql.close_cursor(v_cursor);
  EXCEPTION
    WHEN OTHERS THEN
      sys.dbms_sql.close_cursor(v_cursor);
      RAISE;
  END util_execute_sql;

  -----------------------------------------------------------------------------
  -- util_string_to_bool is a private helper function to deliver a
  -- boolean representation of an string value. True is returned,if:
  --   true,yes,y,1
  -- is given. False is returned when:
  --   false,no,n,0
  -- is given.
  -----------------------------------------------------------------------------
  FUNCTION util_string_to_bool(p_string IN VARCHAR2) RETURN BOOLEAN IS
  BEGIN
    RETURN CASE WHEN lower(p_string) IN('true', 'yes', 'y', '1') THEN TRUE WHEN lower(p_string) IN('false',
                                                                                                   'no',
                                                                                                   'n',
                                                                                                   '0') THEN FALSE ELSE NULL END;
  END util_string_to_bool;

  -----------------------------------------------------------------------------
  -- util_bool_to_string is a private helper function to deliver a
  -- varchar2 representation of an boolean value. 'TRUE' is returned,if
  -- boolean value is true. 'FALSE' is returned when boolean value is false.
  -----------------------------------------------------------------------------
  FUNCTION util_bool_to_string(p_bool IN BOOLEAN) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE WHEN p_bool THEN 'TRUE' WHEN NOT p_bool THEN 'FALSE' ELSE NULL END;
  END util_bool_to_string;

  FUNCTION util_double_quote(p_name IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE WHEN g_params.double_quote_names THEN '"'||p_name||'"' ELSE p_name END;
  END util_double_quote;

  -----------------------------------------------------------------------------
  -- util_get_attribute_surrogate is a private helper function to find out a
  -- datatype dependent surrogate. This is required for comparing two
  -- values of a column e.g. old value and new value. There is the special case
  -- of null comparisison in Oracle,what means null compared with null is
  -- never true. That is the reason to compare:
  --     coalesce(old value,surrogate) = coalesce(new value,surrogate)
  -- that is true,if both sides are null.
  -----------------------------------------------------------------------------
  FUNCTION util_get_attribute_surrogate(p_data_type IN user_tab_cols.data_type%TYPE) RETURN VARCHAR2 IS
    v_return t_vc2_100;
  BEGIN
    v_return := CASE
                  WHEN p_data_type = 'NUMBER' THEN
                   '-999999999999999.999999999999999'
                  WHEN p_data_type LIKE '%CHAR%' THEN
                   '''@@@@@@@@@@@@@@@'''
                  WHEN p_data_type = 'DATE' THEN
                   'TO_DATE(''01.01.1900'',''DD.MM.YYYY'')'
                  WHEN p_data_type LIKE 'TIMESTAMP%' THEN
                   'TO_TIMESTAMP(''01.01.1900'',''dd.mm.yyyy'')'
                  WHEN p_data_type = 'CLOB' THEN
                   'TO_CLOB(''@@@@@@@@@@@@@@@'')'
                  WHEN p_data_type = 'BLOB' THEN
                   'TO_BLOB(UTL_RAW.cast_to_raw(''@@@@@@@@@@@@@@@''))'
                  WHEN p_data_type = 'XMLTYPE' THEN
                   'XMLTYPE(''<NULL/>'')'
                  ELSE
                   '''@@@@@@@@@@@@@@@'''
                END;
    RETURN v_return;
  END util_get_attribute_surrogate;

  -----------------------------------------------------------------------------
  -- util_get_attribute_compare is a private helper function to deliver the
  -- described (take a look at function util_get_attribute_surrogate) compare
  -- code for two attributes. In addition to that, the compare operation must
  -- be dynamically, because e.g. "=" or "<>" or other operations are required.
  -----------------------------------------------------------------------------
  FUNCTION util_get_attribute_compare
  (
    p_data_type         IN user_tab_cols.data_type%TYPE,
    p_nullable          IN BOOLEAN,
    p_first_attribute   IN VARCHAR2,
    p_second_attribute  IN VARCHAR2,
    p_compare_operation IN VARCHAR2 DEFAULT '<>'
  ) RETURN VARCHAR2 IS
    --
    FUNCTION get_coalesce(p_attribute IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
      RETURN
        CASE
          WHEN NOT p_nullable THEN
           p_attribute
          ELSE
           'COALESCE(' || p_attribute || ', ' || util_get_attribute_surrogate(p_data_type) || ')'
        END;
    END get_coalesce;
    --
  BEGIN
    RETURN
      CASE
        WHEN p_data_type = 'XMLTYPE' THEN
         'util_xml_compare( ' || get_coalesce(p_first_attribute) || ', ' || get_coalesce(p_second_attribute) || ') ' ||
         p_compare_operation || ' 0'
        WHEN p_data_type IN ('BLOB', 'CLOB') THEN
         'sys.dbms_lob.compare( ' || get_coalesce(p_first_attribute) || ',' || get_coalesce(p_second_attribute) || ') ' ||
         p_compare_operation || ' 0'
        ELSE
         get_coalesce(p_first_attribute) || ' ' || p_compare_operation || ' ' ||
         get_coalesce(p_second_attribute)
      END;
  END util_get_attribute_compare;

  -----------------------------------------------------------------------------
  -- util_get_vc2_4000_operation is a private helper function to deliver a
  -- varchar2 representation of an attribute in dependency of its datatype.
  -----------------------------------------------------------------------------
  FUNCTION util_get_vc2_4000_operation
  (
    p_data_type      IN all_tab_cols.data_type%TYPE,
    p_attribute_name IN VARCHAR2
  ) RETURN VARCHAR2 IS
  BEGIN
    RETURN
      CASE
        WHEN p_data_type IN ('NUMBER', 'FLOAT', 'INTEGER') THEN
         'to_char(' || p_attribute_name || ')'
        WHEN p_data_type = 'DATE' THEN
         'to_char(' || p_attribute_name || ',''yyyy.mm.dd hh24:mi:ss'')'
        WHEN p_data_type LIKE 'TIMESTAMP%' THEN
         'to_char(' || p_attribute_name || ',''yyyy.mm.dd hh24:mi:ss.ff'')'
        WHEN p_data_type = 'BLOB' THEN
         '''Data type "BLOB" is not supported for generic change log'''
        WHEN p_data_type = 'XMLTYPE' THEN
         'substr( CASE WHEN ' || p_attribute_name || ' IS NULL THEN NULL ELSE ' || p_attribute_name ||
         '.getStringVal() END,1,4000)'
        ELSE
         'substr(' || p_attribute_name || ',1,4000)'
      END;
  END util_get_vc2_4000_operation;

  -----------------------------------------------------------------------------
  -- util_get_user_name is a private helper function to deliver the current
  -- username. If a valid APEX session exists,then the APEX application user
  -- is taken,otherwise the current connected operation system user.
  -----------------------------------------------------------------------------
  FUNCTION util_get_user_name RETURN all_users.username%TYPE IS
  BEGIN
    RETURN upper (coalesce(
      sys_context('apex$session', 'app_user'),
      sys_context('userenv', 'os_user'),
      sys_context('userenv', 'session_user')));
  END util_get_user_name;

  -----------------------------------------------------------------------------
  -- util_get_parameter_name is a private helper function to deliver a cleaned
  -- normalized parameter name.
  -----------------------------------------------------------------------------
  FUNCTION util_get_parameter_name
  (
    p_column_name IN VARCHAR2,
    p_rpad        IN INTEGER
  ) RETURN VARCHAR2 IS
    v_return user_objects.object_name%TYPE;
  BEGIN
    v_return := regexp_replace(lower(p_column_name), '[^a-z0-9_]', NULL);

    IF g_params.enable_parameter_prefixes THEN
      v_return := 'p_' || substr(v_return, 1, c_ora_max_name_len - 2);
    END IF;

    IF p_rpad IS NOT NULL THEN
      v_return := rpad(v_return,
                       CASE
                         WHEN g_params.enable_parameter_prefixes THEN
                          p_rpad + 2
                         ELSE
                          p_rpad
                       END);
    END IF;

    RETURN v_return;
  END util_get_parameter_name;

  -----------------------------------------------------------------------------
  -- util_get_column_name is a private helper function to deliver a cleaned
  -- normalized column name.
  -----------------------------------------------------------------------------
  FUNCTION util_get_column_name
  (
    p_column_name IN VARCHAR2,
    p_rpad        IN INTEGER
  ) RETURN VARCHAR2 IS
    v_return user_objects.object_name%TYPE;
  BEGIN
    v_return := regexp_replace(lower(p_column_name), '[^a-z0-9_]', NULL);

    IF p_rpad IS NOT NULL THEN
      v_return := rpad(v_return,
                       CASE
                         WHEN g_params.enable_parameter_prefixes THEN
                          p_rpad + 2
                         ELSE
                          p_rpad
                       END);
    END IF;

    RETURN v_return;
  END util_get_column_name;

  -----------------------------------------------------------------------------
  -- util_get_method_name is a private helper function to deliver a cleaned
  -- normalized method name for the getter and setter functions/procedures.
  -----------------------------------------------------------------------------
  FUNCTION util_get_method_name(p_column_name IN VARCHAR2) RETURN VARCHAR2 IS
    v_return user_objects.object_name%TYPE;
  BEGIN
    v_return := regexp_replace(lower(p_column_name), '[^a-z0-9_]', NULL);
    v_return := CASE
                  WHEN g_params.col_prefix_in_method_names THEN
                   substr(v_return, 1, c_ora_max_name_len - 4)
                  ELSE
                   substr(v_return, length(g_status.column_prefix) + 2, c_ora_max_name_len - 4)
                END;

    RETURN v_return;
  END util_get_method_name;

  -----------------------------------------------------------------------------

  FUNCTION util_get_substituted_name(p_name_template IN VARCHAR2) RETURN VARCHAR2 IS
    v_return         all_objects.object_name%TYPE;
    v_base_name      all_objects.object_name%TYPE;
    v_replace_string all_objects.object_name%TYPE;
    v_position       PLS_INTEGER;
    v_length         PLS_INTEGER;
  BEGIN
    -- Get replace string
    v_replace_string := regexp_substr(p_name_template, '#[A-Za-z0-9_-]+#', 1, 1);

    -- Check,if we have to do a replacement
    IF v_replace_string IS NULL THEN
      -- Without replacement we return simply the input
      v_return := p_name_template;
    ELSE
      -- Replace possible placeholders in name template
      v_base_name := rtrim(regexp_substr(upper(v_replace_string), '[A-Z_]+', 1, 1), '_');

      -- logger.log('v_base_name: ' || v_base_name);

      -- Check,if we have a valid base name

      IF v_base_name NOT IN ('TABLE_NAME', 'PK_COLUMN', 'COLUMN_PREFIX') THEN
        -- Without a valid base name we return simply the input
        v_return := p_name_template;
      ELSE
        -- Search for start and stop positions
        v_position := regexp_substr(v_replace_string, '-?\d+', 1, 1);
        v_length   := regexp_substr(v_replace_string, '\d+', 1, 2);

        -- 1. To be backward compatible we have to support things like this TABLE_NAME_26.
        -- 2. If someone want to use the substr version he has always to provide position and length.
        -- 3. Negative position is supported like this #TABLE_NAME_-15_15# (the second number can not be omitted like in substr,see 1.)
        IF v_position IS NULL AND v_length IS NULL THEN
          v_length   := 200;
          v_position := 1;
        ELSIF v_position IS NOT NULL AND v_length IS NULL THEN
          v_length   := v_position;
          v_position := 1;
        END IF;

        v_return := replace(p_name_template,
                            v_replace_string,
                            substr(CASE v_base_name
                                     WHEN 'TABLE_NAME' THEN
                                      g_params.table_name
                                     WHEN 'PK_COLUMN' THEN
                                      g_pk_columns(1).column_name
                                     WHEN 'COLUMN_PREFIX' THEN
                                      g_status.column_prefix
                                   END,
                                   v_position,
                                   v_length));
      END IF;
    END IF;

    RETURN v_return;
  END util_get_substituted_name;

  -----------------------------------------------------------------------------

  FUNCTION util_get_column_data_default
  (
    p_table_name  IN VARCHAR2,
    p_column_name IN VARCHAR2,
    p_owner       IN VARCHAR2 DEFAULT USER
  ) RETURN VARCHAR2 AS
    v_return all_tab_columns.data_default%TYPE;

    CURSOR c_utc IS
      SELECT data_default
        FROM all_tab_columns
       WHERE owner = p_owner
         AND table_name = p_table_name
         AND column_name = p_column_name;
  BEGIN
    OPEN c_utc;

    FETCH c_utc
      INTO v_return;

    CLOSE c_utc;

    RETURN substr(v_return, 1, 4000);
  END util_get_column_data_default;

  --------------------------------------------------------------------------------

  FUNCTION util_get_cons_search_condition
  (
    p_constraint_name IN VARCHAR2,
    p_owner           IN VARCHAR2 DEFAULT USER
  ) RETURN VARCHAR2 AS
    v_return all_constraints.search_condition%TYPE;

    CURSOR c_search_condition IS
      SELECT search_condition
        FROM all_constraints
       WHERE owner = p_owner
         AND constraint_name = p_constraint_name;
  BEGIN
    OPEN c_search_condition;

    FETCH c_search_condition
      INTO v_return;

    CLOSE c_search_condition;

    RETURN substr(v_return, 1, 4000);
  END util_get_cons_search_condition;

  -----------------------------------------------------------------------------

  FUNCTION util_get_ora_max_name_len RETURN INTEGER IS
  BEGIN
    RETURN c_ora_max_name_len;
  END util_get_ora_max_name_len;

  -----------------------------------------------------------------------------

  FUNCTION util_split_to_table
  (
    p_string    IN VARCHAR2,
    p_delimiter IN VARCHAR2 DEFAULT ','
  ) RETURN t_tab_vc2_4k
    PIPELINED IS
    v_offset           PLS_INTEGER := 1;
    v_index            PLS_INTEGER;
    v_delimiter_length PLS_INTEGER;
    v_string_length CONSTANT PLS_INTEGER := length(p_string);
  BEGIN
    v_index            := instr(p_string, p_delimiter, v_offset);
    v_delimiter_length := length(p_delimiter);
    WHILE v_index > 0 LOOP
      PIPE ROW(TRIM(substr(p_string, v_offset, v_index - v_offset)));
      v_offset := v_index + v_delimiter_length;
      v_index  := instr(p_string, p_delimiter, v_offset);
    END LOOP;

    IF v_string_length - v_offset + 1 > 0 THEN
      PIPE ROW(TRIM(substr(p_string, v_offset, v_string_length - v_offset + 1)));
    END IF;

    RETURN;
  END util_split_to_table;

  -----------------------------------------------------------------------------

  FUNCTION util_serialize_xml(p_xml IN XMLTYPE) RETURN VARCHAR2 IS
    v_return t_vc2_32k;
  BEGIN
    SELECT xmlserialize(document p_xml no indent) INTO v_return FROM dual;

    RETURN v_return;
  END util_serialize_xml;

  --------------------------------------------------------------------------------

  PROCEDURE util_set_debug_on IS
  BEGIN
    g_debug_enabled := TRUE;
    g_debug_run     := 0;
    g_debug_step    := 0;
    g_debug.delete;
  END util_set_debug_on;

  --------------------------------------------------------------------------------

  PROCEDURE util_set_debug_off IS
  BEGIN
    g_debug_enabled := FALSE;
  END util_set_debug_off;

  --------------------------------------------------------------------------------

  PROCEDURE util_debug_start_one_run
  (
    p_generator_action IN VARCHAR2,
    p_table_name       IN VARCHAR2,
    p_owner            IN VARCHAR2
  ) IS
  BEGIN
    g_debug_module := c_generator || ' v' || c_generator_version || ': ' || p_generator_action;
    IF g_debug_enabled THEN
      g_debug_run := g_debug_run + 1;
      IF g_debug_run <= c_debug_max_runs THEN
        g_debug_step := 0;
        g_debug(g_debug_run).run := g_debug_run;
        g_debug(g_debug_run).owner := p_owner;
        g_debug(g_debug_run).table_name := p_table_name;
        g_debug(g_debug_run).start_time := systimestamp;
      END IF;
    END IF;
  END util_debug_start_one_run;

  -----------------------------------------------------------------------------

  PROCEDURE util_debug_stop_one_run IS
  BEGIN
    IF g_debug_enabled AND g_debug_run <= c_debug_max_runs THEN
      g_debug(g_debug_run).stop_time := systimestamp;
    END IF;
  END util_debug_stop_one_run;

  -----------------------------------------------------------------------------

  PROCEDURE util_debug_start_one_step(p_action IN VARCHAR2) IS
  BEGIN
    sys.dbms_application_info.set_module(module_name => g_debug_module, action_name => p_action);
    IF g_debug_enabled AND g_debug_run <= c_debug_max_runs THEN
      g_debug_step := g_debug_step + 1;
      g_debug(g_debug_run).details(g_debug_step).step := g_debug_step;
      g_debug(g_debug_run).details(g_debug_step).module := g_debug_module;
      g_debug(g_debug_run).details(g_debug_step).action := p_action;
      g_debug(g_debug_run).details(g_debug_step).start_time := systimestamp;
    END IF;
  END util_debug_start_one_step;

  -----------------------------------------------------------------------------

  PROCEDURE util_debug_stop_one_step IS
  BEGIN
    sys.dbms_application_info.set_module(module_name => NULL, action_name => NULL);
    IF g_debug_enabled AND g_debug_run <= c_debug_max_runs THEN
      g_debug(g_debug_run).details(g_debug_step).stop_time := systimestamp;
    END IF;
  END util_debug_stop_one_step;

  -----------------------------------------------------------------------------

  FUNCTION util_view_debug_log RETURN t_tab_debug_data
    PIPELINED IS
    v_return t_rec_debug_data;
  BEGIN
    FOR i IN 1 .. g_debug.count LOOP
      v_return.run        := g_debug(i).run;
      v_return.run_time   := round(SYSDATE + ((g_debug(i).stop_time - g_debug(i).start_time) * 86400) - SYSDATE, 6);
      v_return.owner      := g_debug(i).owner;
      v_return.table_name := g_debug(i).table_name;
      FOR j IN 1 .. g_debug(i).details.count LOOP
        v_return.step       := g_debug(i).details(j).step;
        v_return.elapsed    := round(SYSDATE + ((g_debug(i).details(j).stop_time - g_debug(i).start_time) * 86400) -
                                     SYSDATE,
                                     6);
        v_return.execution  := round(SYSDATE +
                                     ((g_debug(i).details(j).stop_time - g_debug(i).details(j).start_time) * 86400) -
                                     SYSDATE,
                                     6);
        v_return.action     := g_debug(i).details(j).action;
        v_return.start_time := g_debug(i).details(j).start_time;
        --sysdate + (interval_difference * 86400) - sysdate
        --https://stackoverflow.com/questions/10092032/extracting-the-total-number-of-seconds-from-an-interval-data-type
        PIPE ROW(v_return);
      END LOOP;
    END LOOP;

  END util_view_debug_log;

  -----------------------------------------------------------------------------

  FUNCTION util_view_columns_array RETURN t_tab_debug_columns
    PIPELINED IS
    v_row t_rec_columns;
  BEGIN
    FOR i IN 1 .. g_columns.count LOOP
      v_row.column_name            := g_columns(i).column_name;
      v_row.data_type              := g_columns(i).data_type;
      v_row.char_length            := g_columns(i).char_length;
      v_row.data_length            := g_columns(i).data_length;
      v_row.data_precision         := g_columns(i).data_precision;
      v_row.data_scale             := g_columns(i).data_scale;
      v_row.data_default           := g_columns(i).data_default;
      v_row.data_custom_default    := g_columns(i).data_custom_default;
      v_row.custom_default_source  := g_columns(i).custom_default_source;
      v_row.identity_type          := g_columns(i).identity_type;
      v_row.default_on_null_yn     := g_columns(i).default_on_null_yn;
      v_row.is_pk_yn               := g_columns(i).is_pk_yn;
      v_row.is_uk_yn               := g_columns(i).is_uk_yn;
      v_row.is_fk_yn               := g_columns(i).is_fk_yn;
      v_row.is_nullable_yn         := g_columns(i).is_nullable_yn;
      v_row.is_excluded_yn         := g_columns(i).is_excluded_yn;
      v_row.audit_type             := g_columns(i).audit_type;
      v_row.row_version_expression := g_columns(i).row_version_expression;
      v_row.r_owner                := g_columns(i).r_owner;
      v_row.r_table_name           := g_columns(i).r_table_name;
      v_row.r_column_name          := g_columns(i).r_column_name;
      PIPE ROW(v_row);
    END LOOP;
  END util_view_columns_array;

  -----------------------------------------------------------------------------

  FUNCTION util_view_package_state
  RETURN t_tab_package_state pipelined IS
    v_row t_rec_package_state;
  BEGIN
    v_row.package_status_key := 'generator_action';
    v_row.value              := g_status.generator_action;
    pipe row(v_row);
    --
    v_row.package_status_key := 'api_name';
    v_row.value              := g_params.api_name;
    pipe row(v_row);
    --
    v_row.package_status_key := 'column_prefix';
    v_row.value              := g_status.column_prefix;
    pipe row(v_row);
    --
    v_row.package_status_key := 'pk_is_multi_column';
    v_row.value              := util_bool_to_string(g_status.pk_is_multi_column);
    pipe row(v_row);
    --
    v_row.package_status_key := 'identity_column';
    v_row.value              := g_status.identity_column;
    pipe row(v_row);
    --
    v_row.package_status_key := 'identity_type';
    v_row.value              := g_status.identity_type;
    pipe row(v_row);
    --
    v_row.package_status_key := 'xmltype_column_present';
    v_row.value              := util_bool_to_string(g_status.xmltype_column_present);
    pipe row(v_row);
    --
    v_row.package_status_key := 'number_of_data_columns';
    v_row.value              := to_char(g_status.number_of_data_columns);
    pipe row(v_row);
    --
    v_row.package_status_key := 'number_of_pk_columns';
    v_row.value              := to_char(g_status.number_of_pk_columns);
    pipe row(v_row);
    --
    v_row.package_status_key := 'number_of_uk_columns';
    v_row.value              := to_char(g_status.number_of_uk_columns);
    pipe row(v_row);
    --
    v_row.package_status_key := 'number_of_fk_columns';
    v_row.value              := to_char(g_status.number_of_fk_columns);
    pipe row(v_row);
    --
    v_row.package_status_key := 'rpad_columns';
    v_row.value              := to_char(g_status.rpad_columns);
    pipe row(v_row);
    --
    v_row.package_status_key := 'rpad_pk_columns';
    v_row.value              := to_char(g_status.rpad_pk_columns);
    pipe row(v_row);
    --
    v_row.package_status_key := 'rpad_uk_columns';
    v_row.value              := to_char(g_status.rpad_uk_columns);
    pipe row(v_row);
  END util_view_package_state;

  -----------------------------------------------------------------------------

  FUNCTION util_get_fk_value
  (
    p_table_name  IN VARCHAR2,
    p_column_name IN VARCHAR2,
    p_owner       IN VARCHAR2 DEFAULT USER
  ) RETURN VARCHAR2 IS
    v_cur               SYS_REFCURSOR;
    v_return            t_vc2_4k;
    v_column_expression t_vc2_4k;
  BEGIN
    FOR i IN (SELECT data_type
                FROM all_tab_columns
               WHERE owner = p_owner
                 AND table_name = p_table_name
                 AND column_name = p_column_name) LOOP
      v_column_expression :=
        CASE
          WHEN i.data_type LIKE '%CHAR%' THEN
          '''''''''||substr(' || p_column_name || ',1,4000)||'''''''''
          WHEN i.data_type IN ('NUMBER', 'INTEGER', 'FLOAT') THEN
          'to_char(' || p_column_name || ')'
          ELSE
          NULL
        END;
      IF v_column_expression IS NOT NULL THEN
        OPEN v_cur FOR 'SELECT ' || v_column_expression || ' FROM ' || p_table_name;
        FETCH v_cur
          INTO v_return;
        CLOSE v_cur;
      END IF;
    END LOOP;
    RETURN(v_return);
  END util_get_fk_value;

  -----------------------------------------------------------------------------

  FUNCTION util_generate_list(p_list_name IN VARCHAR2) RETURN t_tab_vc2_2k IS

    -----------------------------------------------------------------------------

    FUNCTION get_audit_value (
      p_column_index IN INTEGER)
    RETURN VARCHAR2 IS
    BEGIN
      RETURN
        CASE
          WHEN g_columns(p_column_index).audit_type in ('CREATED', 'UPDATED') THEN
            CASE
              WHEN g_columns(p_column_index).data_type LIKE '%DATE%' THEN
                'sysdate'
              WHEN g_columns(p_column_index).data_type LIKE '%TIMESTAMP%' THEN
                'systimestamp'
              ELSE
                NULL
            END
          ELSE
            g_params.audit_user_expression
        END;
    END get_audit_value;

    -----------------------------------------------------------------------------

    FUNCTION get_column_comment (
      p_column_index IN INTEGER)
    RETURN VARCHAR2 is
    BEGIN
      RETURN
        CASE WHEN g_columns(p_column_index).is_pk_yn = 'Y' THEN ' /*PK*/' END ||
        CASE WHEN g_columns(p_column_index).is_uk_yn = 'Y' THEN ' /*UK*/' END ||
        CASE WHEN g_columns(p_column_index).is_fk_yn = 'Y' THEN ' /*FK*/' END ||
        CASE WHEN g_template_options.crud_mode = 'CREATE' AND g_columns(p_column_index).identity_type IS NOT NULL THEN
          ' /*GENERATED ' || g_columns(p_column_index).identity_type ||
          CASE WHEN g_columns(p_column_index).default_on_null_yn = 'Y' THEN
            ' ON NULL'
          END ||
          ' AS IDENTITY*/'
        END;
    END get_column_comment;

    -----------------------------------------------------------------------------

    FUNCTION check_identity_visibility (
      p_column_index IN INTEGER)
    RETURN BOOLEAN IS
    BEGIN
      RETURN
        CASE
          WHEN g_columns(p_column_index).identity_type IS NULL
            or g_template_options.crud_mode IS NULL
            or g_template_options.crud_mode = 'CREATE' AND g_columns(p_column_index).identity_type = 'BY DEFAULT'
          THEN true
          ELSE false
        END;
    END check_identity_visibility;

    -----------------------------------------------------------------------------

    FUNCTION check_audit_visibility_create (
      p_column_index IN INTEGER)
    RETURN BOOLEAN IS
    BEGIN
      RETURN
        CASE
          WHEN g_columns(p_column_index).audit_type IS NULL
            or g_columns(p_column_index).audit_type LIKE 'CREATED%'
            or g_columns(p_column_index).audit_type LIKE 'UPDATED%' AND g_columns(p_column_index).is_nullable_yn = 'N'
          THEN true
          ELSE false
        END;
    END check_audit_visibility_create;

    -----------------------------------------------------------------------------

    FUNCTION check_audit_visibility_update (
      p_column_index IN INTEGER)
    RETURN BOOLEAN IS
    BEGIN
      RETURN
        CASE
          WHEN g_columns(p_column_index).audit_type IS NULL
            OR g_columns(p_column_index).audit_type LIKE 'UPDATED%'
          THEN true
          ELSE false
        END;
    END check_audit_visibility_update;

    -----------------------------------------------------------------------------

    PROCEDURE trim_list(p_list in out nocopy t_tab_vc2_2k) is
    BEGIN
      IF p_list.count > 0 THEN
        p_list(p_list.first) := ltrim(p_list(p_list.first));
        IF substr(p_list(p_list.first), 1, 4) = 'AND ' THEN
            p_list(p_list.first) := substr(p_list(p_list.first), 5);
        END IF;
        IF substr(p_list(p_list.first), 1, 2) = ', ' THEN
            p_list(p_list.first) := substr(p_list(p_list.first), 3);
        END IF;
        p_list(p_list.last) := rtrim(p_list(p_list.last), c_lf || c_list_delimiter);
      END IF;
    END trim_list;

    -----------------------------------------------------------------------------

    FUNCTION list_insert_columns RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND check_identity_visibility(i)
          AND check_audit_visibility_create(i)
        THEN
          v_result(v_result.count + 1) :=
            '      ' || util_double_quote(g_columns(i).column_name) ||
            get_column_comment(i) || c_list_delimiter;
        END IF;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_insert_columns;

    -----------------------------------------------------------------------------
    -- Columns as flat list for insert - without p_column_exclude_list:
    -- {% LIST_INSERT_PARAMS %}
    -- Example:
    --   p_col2,
    --   p_col3,
    --   p_col4,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_insert_params RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND check_identity_visibility(i)
          AND check_audit_visibility_create(i)
        THEN
          v_result(v_result.count + 1) :=
            '      ' ||
            CASE
              WHEN g_columns(i).is_pk_yn = 'Y' AND NOT g_status.pk_is_multi_column AND
              g_params.sequence_name IS NOT NULL THEN
                'COALESCE( ' || util_get_parameter_name(g_columns(i).column_name, NULL)
                || ', ' || util_double_quote(g_params.sequence_name) || '.nextval )'
              WHEN g_columns(i).audit_type IS NOT NULL THEN
                get_audit_value(i)
              WHEN g_columns(i).row_version_expression IS NOT NULL THEN
                g_columns(i).row_version_expression
              ELSE
                util_get_parameter_name(g_columns(i).column_name, NULL)
            END
            || c_list_delimiter;
        END IF;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_insert_params;

    -----------------------------------------------------------------------------
    -- Columns as flat list for insert - without p_column_exclude_list:
    -- {% LIST_INSERT_BULK_PARAMS %}
    -- Example:
    --   p_col2,
    --   p_col3,
    --   p_col4,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_insert_bulk_params RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND check_identity_visibility(i)
          AND check_audit_visibility_create(i)
        THEN
          v_result(v_result.count + 1) :=
            '      ' ||
            CASE
              WHEN g_columns(i).is_pk_yn = 'Y' AND NOT g_status.pk_is_multi_column AND g_params.sequence_name IS NOT NULL THEN
                'coalesce( p_rows_tab(i).' || util_double_quote(g_columns(i).column_name) || ', '
                || util_double_quote(g_params.sequence_name) || '.nextval )'
              WHEN g_columns(i).audit_type IS NOT NULL THEN
                get_audit_value(i)
              WHEN g_columns(i).row_version_expression IS NOT NULL THEN
                g_columns(i).row_version_expression
              ELSE
                'p_rows_tab(i).' || util_double_quote(g_columns(i).column_name)
            END || c_list_delimiter;
        END IF;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_insert_bulk_params;

    -----------------------------------------------------------------------------
    -- Columns as flat list - with p_column_exclude_list:
    -- {% LIST_COLUMNS_W_PK_FULL %}
    -- Example:
    --   col1,
    --   col2,
    --   col3,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_columns_w_pk_full RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_columns.count LOOP
        v_result(v_result.count + 1) :=
          '      ' || util_double_quote(g_columns(i).column_name) ||
          get_column_comment(i) || c_list_delimiter;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_columns_w_pk_full;


    -----------------------------------------------------------------------------
    -- Columns as parameter definition for create_row,update_row with PK:
    -- {% LIST_PARAMS_W_PK %}
    -- Example:
    --   p_col1 IN table.col1%TYPE,
    --   p_col2 IN table.col2%TYPE,
    --   p_col3 IN table.col3%TYPE,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_params_w_pk RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND g_columns(i).audit_type IS NULL
          AND g_columns(i).row_version_expression IS NULL
          AND check_identity_visibility(i)
        THEN
          v_result(v_result.count + 1) :=
          CASE
            WHEN g_template_options.padding IS NOT NULL THEN
              rpad(' ', g_template_options.padding)
            ELSE
              '    '
          END ||
          util_get_parameter_name(g_columns(i).column_name, g_status.rpad_columns) ||
          ' IN ' || util_double_quote(g_params.table_name) || '.' ||
          CASE
            WHEN g_params.enable_column_defaults AND g_template_options.use_column_defaults THEN
              rpad( util_double_quote(g_columns(i).column_name) || '%TYPE', g_status.rpad_columns + 6)
            ELSE
              util_double_quote(g_columns(i).column_name) || '%TYPE'
          END ||
          CASE
            WHEN g_columns(i).is_pk_yn = 'Y'
            AND NOT g_status.pk_is_multi_column
            AND (g_columns(i).data_default IS NULL OR g_columns(i).identity_type IS NOT NULL) THEN
              ' DEFAULT NULL'
            WHEN g_params.enable_column_defaults
            AND g_template_options.use_column_defaults THEN
              CASE
                WHEN g_columns(i).data_default IS NOT NULL THEN
                  ' DEFAULT ' || g_columns(i).data_default
                WHEN g_columns(i).is_nullable_yn = 'Y' THEN
                  ' DEFAULT NULL'
                ELSE
                  ' '
              END
          END || get_column_comment(i) || c_list_delimiter;
        END IF;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_params_w_pk;

    -----------------------------------------------------------------------------
    -- A parameter list with column defaults:
    -- {% LIST_PARAMS_W_PK_CUST_DEFAULTS %}
    -- Example:
    --   p_employee_id IN employees.employee_id%TYPE DEFAULT get_a_row()."EMPLOYEE_ID",
    --   p_first_name  IN employees.first_name%TYPE  DEFAULT get_a_row()."FIRST_NAME",
    --   p_last_name   IN employees.last_name%TYPE   DEFAULT get_a_row()."LAST_NAME",
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_params_w_pk_cust_defaults RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND g_columns(i).audit_type IS NULL
          AND g_columns(i).row_version_expression IS NULL
          AND check_identity_visibility(i)
        THEN
          v_result(v_result.count + 1) :=
            '    ' ||
            util_get_parameter_name(g_columns(i).column_name, g_status.rpad_columns) ||
            ' IN ' || util_double_quote(g_params.table_name) || '.' ||
            rpad(util_double_quote(g_columns(i).column_name) || '%TYPE', g_status.rpad_columns + 7) ||
            ' DEFAULT get_a_row().' || util_double_quote(g_columns(i).column_name) ||
            get_column_comment(i) || c_list_delimiter;
        END IF;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_params_w_pk_cust_defaults;

    -----------------------------------------------------------------------------
    -- Columns as parameter IN OUT definition for read_row with PK:
    -- {% LIST_PARAMS_W_PK_IO %}
    -- Example:
    --   p_col1 IN            table.col1%TYPE,
    --   p_col2 IN OUT NOCOPY table.col2%TYPE,
    --   p_col3 IN OUT NOCOPY table.col3%TYPE,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_params_w_pk_io RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_columns.count LOOP
        v_result(v_result.count + 1) := '    ' ||
          util_get_parameter_name(g_columns(i).column_name, g_status.rpad_columns) ||
          CASE
            WHEN g_columns(i).is_pk_yn = 'Y' THEN
              ' IN            '
            ELSE
              '    OUT NOCOPY '
          END || util_double_quote(g_params.table_name) || '.' ||
          util_double_quote(g_columns(i).column_name) || '%TYPE' ||
          get_column_comment(i) || c_list_delimiter;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_params_w_pk_io;

    -----------------------------------------------------------------------------
    -- Map :new values to parameter for IOIUD-Trigger with PK:
    -- {% LIST_MAP_PAR_EQ_NEWCOL_W_PK %}
    -- Example:
    --   p_col1 => :new.col1,
    --   p_col2 => :new.col2,
    --   p_col3 => :new.col3,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_map_par_eq_newcol_w_pk RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND g_columns(i).audit_type IS NULL
          AND g_columns(i).row_version_expression IS NULL
          AND check_identity_visibility(i)
        THEN
          v_result(v_result.count + 1) :=
            '      ' ||
            util_get_parameter_name(g_columns(i).column_name, g_status.rpad_columns) ||
            ' => :new.' || util_double_quote(g_columns(i).column_name) ||
            get_column_comment(i) || c_list_delimiter;
        END IF;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_map_par_eq_newcol_w_pk;

    -----------------------------------------------------------------------------
    --  Map parameter to parameter as pass-through parameter with PK:
    -- {% LIST_MAP_PAR_EQ_PARAM_W_PK %}
    -- Example:
    --   p_col1 => p_col1,
    --   p_col2 => p_col2,
    --   p_col3 => p_col3,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_map_par_eq_param_w_pk RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND g_columns(i).audit_type IS NULL
          AND g_columns(i).row_version_expression IS NULL
          AND check_identity_visibility(i)
        THEN
          v_result(v_result.count + 1) :=
            CASE WHEN g_template_options.padding IS NOT NULL
              THEN rpad(' ', g_template_options.padding)
              ELSE '      '
            END ||
            util_get_parameter_name(g_columns(i).column_name, g_status.rpad_columns) ||
            ' => ' || util_get_parameter_name(g_columns(i).column_name, NULL) ||
            get_column_comment(i) || c_list_delimiter;
        END IF;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_map_par_eq_param_w_pk;

    -----------------------------------------------------------------------------
    -- map rowtype columns to parameter for rowtype handling with PK:
    -- {% LIST_MAP_PAR_EQ_ROWTYPCOL_W_PK %}
    -- Example:
    --   p_col1 => p_row.col1,
    --   p_col2 => p_row.col2,
    --   p_col3 => p_row.col3,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_map_par_eq_rowtypcol_w_pk RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND g_columns(i).audit_type IS NULL
          AND g_columns(i).row_version_expression IS NULL
          AND check_identity_visibility(i)
        THEN
          v_result(v_result.count + 1) :=
            '      ' ||
            util_get_parameter_name(g_columns(i).column_name, g_status.rpad_columns) ||
            ' => p_row.' || util_double_quote(g_columns(i).column_name) ||
            get_column_comment(i) || c_list_delimiter;
        END IF;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_map_par_eq_rowtypcol_w_pk;

    -----------------------------------------------------------------------------
    -- A column list for updating a row without PK:
    -- {% LIST_SET_COL_EQ_PARAM_WO_PK %}
    -- Example:
    --   test_number   = p_test_number,
    --   test_varchar2 = p_test_varchar2,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_set_col_eq_param_wo_pk RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND g_columns(i).is_pk_yn = 'N'
          AND check_audit_visibility_update(i)
        THEN
          v_result(v_result.count + 1) :=
            '           ' ||
            rpad(util_double_quote(g_columns(i).column_name), g_status.rpad_columns + 2) ||
            ' = ' ||
            CASE
              WHEN g_columns(i).audit_type IS NOT NULL THEN
                get_audit_value(i)
              WHEN g_columns(i).row_version_expression IS NOT NULL THEN
                g_columns(i).row_version_expression
              ELSE
                util_get_parameter_name(g_columns(i).column_name, NULL)
            END ||
            get_column_comment(i) || c_list_delimiter;
        END IF;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_set_col_eq_param_wo_pk;

    -----------------------------------------------------------------------------
    -- A column list for updating a row without PK in bulk mode:
    -- {% LIST_SET_COL_EQ_PAR_BULK_WO_PK %}
    -- Example:
    -- "FIRST_NAME" = p_rows_tab(i)."FIRST_NAME",
    -- "LAST_NAME"  = p_rows_tab(i)."LAST_NAME",
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_set_col_eq_par_bulk_wo_pk RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND g_columns(i).is_pk_yn = 'N'
          AND check_audit_visibility_update(i)
        THEN
          v_result(v_result.count + 1) :=
            '             ' ||
            rpad(util_double_quote(g_columns(i).column_name), g_status.rpad_columns + 2) ||
            ' = ' ||
            CASE
              WHEN g_columns(i).audit_type IS NOT NULL THEN
                get_audit_value(i)
              WHEN g_columns(i).row_version_expression IS NOT NULL THEN
                g_columns(i).row_version_expression
              ELSE
                'p_rows_tab(i).' || util_double_quote(g_columns(i).column_name)
            END ||
            get_column_comment(i) || c_list_delimiter;
        END IF;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_set_col_eq_par_bulk_wo_pk;

    -----------------------------------------------------------------------------
    -- A column list without pk for setting parameter to row columns:
    -- {% LIST_SET_PAR_EQ_ROWTYCOL_WO_PK %}
    -- Example:
    --   p_test_number   := v_row.test_number;
    --   p_test_varchar2 := v_row.test_varchar2;
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_set_par_eq_rowtycol_wo_pk RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND g_columns(i).audit_type IS NULL
          AND g_columns(i).row_version_expression IS NULL
          AND g_columns(i).is_pk_yn = 'N'
        THEN
          v_result(v_result.count + 1) :=
            '    ' ||
            util_get_parameter_name(g_columns(i).column_name, g_status.rpad_columns) ||
            ' := v_row.' ||
            util_double_quote(g_columns(i).column_name) || '; ' || c_lf;
        END IF;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_set_par_eq_rowtycol_wo_pk;

    -----------------------------------------------------------------------------
    -- Primary key parameter definition for create_row:
    -- {% LIST_PARAMS_PK %}
    -- Example:
    --   p_col1 IN table.col1%TYPE,
    --   p_col2 IN table.col2%TYPE,
    --   p_col3 IN table.col3%TYPE,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_pk_params RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_pk_columns.count LOOP
        v_result(v_result.count + 1) :=
          '    ' ||
          util_get_parameter_name(g_pk_columns(i).column_name, g_status.rpad_columns) ||
          ' IN ' ||
          util_double_quote(g_params.table_name) || '.' ||
          util_double_quote(g_pk_columns(i).column_name) || '%TYPE /*PK*/' ||
          c_list_delimiter;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_pk_params;

    -----------------------------------------------------------------------------
    -- Primary key column definition for create_row:
    -- {% LIST_PARAMS_PK %}
    -- Example:
    --   col1 table.col1%TYPE,
    --   col2 table.col2%TYPE,
    --   col3 table.col3%TYPE,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_pk_columns RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_pk_columns.count LOOP
        v_result(v_result.count + 1) :=
          '    ' ||
          util_double_quote(g_pk_columns(i).column_name) || ' ' ||
          util_double_quote(g_params.table_name) || '.' ||
          util_double_quote(g_pk_columns(i).column_name) || '%TYPE /*PK*/' ||
          c_list_delimiter;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_pk_columns;

    -----------------------------------------------------------------------------
    -- Primary key column definition for create_row:
    -- {% LIST_PARAMS_PK %}
    -- Example:
    --   col1,
    --   col2,
    --   col3,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_pk_names RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_pk_columns.count LOOP
        v_result(v_result.count + 1) :=
          '      ' || util_double_quote(g_pk_columns(i).column_name) ||
          ' /*PK*/' || c_list_delimiter;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_pk_names;

    -----------------------------------------------------------------------------
    -- Primary key columns for return clause:
    -- {% LIST_PK_RETURN_COLUMNS %}
    -- Example:
    --   v_return.col1,
    --   v_return.col2,
    --   v_return.col3,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_pk_return_columns RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_pk_columns.count LOOP
        v_result(v_result.count + 1) :=
          '      v_return.' ||
          util_double_quote(g_pk_columns(i).column_name) || c_list_delimiter;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_pk_return_columns;

    -----------------------------------------------------------------------------
    -- Primary key column definition for create_rows:
    -- {% LIST_PK_RETURN_COLUMNS_BULK %}
    -- Example:
    --   v_return(i).col1 := v_pk_tab.col1;
    --   v_return(i).col2 := v_pk_tab.col2;
    --   v_return(i).col3 := v_pk_tab.col3;
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_pk_return_columns_bulk RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_pk_columns.count LOOP
        v_result(v_result.count + 1) :=
          '    v_return(i).' ||
          util_double_quote(g_pk_columns(i).column_name) ||
          ' := v_pk_tab(i).' ||
          util_double_quote(g_pk_columns(i).column_name) ||
          '; /*PK*/' || c_lf;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_pk_return_columns_bulk;

    -----------------------------------------------------------------------------
    -- Primary key columns parameter compare for get_pk_by_unique_cols functions:
    -- {% LIST_PK_COLUMNS_WHERE_CLAUSE %}
    -- Example:
    --       COALESCE( "COL1",'@@@@@@@@@@@@@@@' ) = COALESCE( p_col1,'@@@@@@@@@@@@@@@' )
    --   AND COALESCE( "COL2",'@@@@@@@@@@@@@@@' ) = COALESCE( p_col2,'@@@@@@@@@@@@@@@' )
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_pk_columns_where_clause RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_pk_columns.count LOOP
        v_result(v_result.count + 1) :=
          '       AND ' ||
          util_get_attribute_compare(
            p_data_type         => g_pk_columns(i).data_type,
            p_nullable          => util_string_to_bool(g_columns(g_columns_reverse_index(g_pk_columns(i).column_name)).is_nullable_yn),
            p_first_attribute   => util_double_quote(g_pk_columns(i).column_name),
            p_second_attribute  => util_get_parameter_name(g_pk_columns(i).column_name, NULL),
            p_compare_operation => '=') || c_lf;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_pk_columns_where_clause;

    -----------------------------------------------------------------------------
    -- Primary key columns parameter compare for get_pk_by_unique_cols functions:
    -- {% LIST_PK_COLUMN_BULK_COMPARE %}
    -- Example:
    --       COALESCE( "COL1",'@@@@@@@@@@@@@@@' ) = COALESCE( p_col1,'@@@@@@@@@@@@@@@' )
    --   AND COALESCE( "COL2",'@@@@@@@@@@@@@@@' ) = COALESCE( p_col2,'@@@@@@@@@@@@@@@' )
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_pk_column_bulk_compare RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_pk_columns.count LOOP
        v_result(v_result.count + 1) :=
          '         AND ' ||
          util_get_attribute_compare(
            p_data_type         => g_pk_columns(i).data_type,
            p_nullable          => util_string_to_bool(g_columns(g_columns_reverse_index(g_pk_columns(i).column_name)).is_nullable_yn),
            p_first_attribute   => util_double_quote(g_pk_columns(i).column_name),
            p_second_attribute  => 'p_rows_tab(i).' || util_double_quote(g_pk_columns(i).column_name),
            p_compare_operation => '=') || c_lf;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_pk_column_bulk_compare;

    -----------------------------------------------------------------------------
    -- Primary key columns list for read_row parameters
    -- {% LIST_PK_COLUMN_FETCH %}
    -- Example:
    --   p_au_id => v_pk_rec."AU_ID"
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_pk_column_fetch RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_pk_columns.count LOOP
        v_result(v_result.count + 1) :=
          ', ' ||
          util_get_attribute_compare(
            p_data_type         => g_pk_columns(i).data_type,
            p_nullable          => util_string_to_bool(g_columns(g_columns_reverse_index(g_pk_columns(i).column_name)).is_nullable_yn),
            p_first_attribute   => util_get_parameter_name(g_pk_columns(i).column_name, NULL),
            p_second_attribute  => 'v_pk_rec.' || util_double_quote(g_pk_columns(i).column_name),
            p_compare_operation => '=>');
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_pk_column_fetch;

    -----------------------------------------------------------------------------
    -- Primary key columns parameter compare for get_pk_by_unique_cols functions:
    -- {% LIST_PK_COLUMN_BULK_COMPARE %}
    -- Example:
    --       COALESCE( "COL1",'@@@@@@@@@@@@@@@' ) = COALESCE( p_col1,'@@@@@@@@@@@@@@@' )
    --   AND COALESCE( "COL2",'@@@@@@@@@@@@@@@' ) = COALESCE( p_col2,'@@@@@@@@@@@@@@@' )
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_pk_column_bulk_fetch RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_pk_columns.count LOOP
        v_result(v_result.count + 1) :=
          '                                    AND ' ||
          util_get_attribute_compare(
            p_data_type         => g_pk_columns(i).data_type,
            p_nullable          => util_string_to_bool(g_columns(g_columns_reverse_index(g_pk_columns(i).column_name)).is_nullable_yn),
            p_first_attribute   => 'data_table.' || util_double_quote(g_pk_columns(i).column_name),
            p_second_attribute  => 'pk_collection.' || util_double_quote(g_pk_columns(i).column_name),
            p_compare_operation => '=') || c_lf;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_pk_column_bulk_fetch;

    -----------------------------------------------------------------------------
    -- Primary key columns as "parameter => parameter" mapping for read_row functions:
    -- {% LIST_PK_MAP_PARAM_EQ_PARAM %}
    -- Example:
    --   p_col1 => p_col1,
    --   p_col2 => p_col2,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_pk_map_param_eq_param RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_pk_columns.count LOOP
        v_result(v_result.count + 1) :=
          CASE WHEN g_template_options.padding IS NOT NULL
            THEN rpad(' ', g_template_options.padding)
            ELSE '      '
          END ||
          util_get_parameter_name(
            g_pk_columns(i).column_name,
            CASE WHEN g_status.pk_is_multi_column
              THEN g_status.rpad_pk_columns
              ELSE NULL
            END) ||
          ' => ' ||
          util_get_parameter_name(g_pk_columns(i).column_name, NULL) ||
          c_list_delimiter;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_pk_map_param_eq_param;

    -----------------------------------------------------------------------------
    -- Primary key columns as "parameter => parameter" mapping for read_row functions:
    -- {% LIST_PK_MAP_PARAM_EQ_PARAM %}
    -- Example:
    --   p_col1 => p_col1,
    --   p_col2 => p_col2,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_pk_map_param_eq_return RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_pk_columns.count LOOP
        v_result(v_result.count + 1) :=
          '      ' ||
          util_get_parameter_name(
            g_pk_columns(i).column_name,
            CASE WHEN g_status.pk_is_multi_column
              THEN g_status.rpad_pk_columns
              ELSE NULL
            END) ||
          ' => v_return.' ||
          util_double_quote(g_pk_columns(i).column_name) ||
          c_list_delimiter;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_pk_map_param_eq_return;

    -----------------------------------------------------------------------------
    -- Primary key columns as "parameter => :old.column" mapping for DML view trigger:
    -- {% LIST_PK_MAP_PARAM_EQ_OLDCOL %}
    -- Example:
    --   p_col1 => :old.col1,
    --   p_col2 => :old.col2,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_pk_map_param_eq_oldcol RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_pk_columns.count LOOP
        v_result(v_result.count + 1) :=
          '      ' ||
          util_get_parameter_name(
            g_pk_columns(i).column_name,
            CASE WHEN g_status.pk_is_multi_column
              THEN g_status.rpad_pk_columns
              ELSE NULL
            END) ||
          ' => ' || ':old.' ||
          util_double_quote(g_pk_columns(i).column_name) ||
          c_list_delimiter;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_pk_map_param_eq_oldcol;

    -----------------------------------------------------------------------------
    -- Unique columns as parameter definition for get_pk_by_unique_cols/read_row functions:
    -- {% LIST_UK_PARAMS %}
    -- Example:
    --   p_col1 IN table.col1%TYPE,
    --   p_col2 IN table.col2%TYPE,
    --   p_col3 IN table.col3%TYPE,
    --   ...
    -----------------------------------------------------------------------------

    FUNCTION list_uk_params RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_uk_columns.count LOOP
        IF g_uk_columns(i).constraint_name = g_iterator.current_uk_constraint THEN
          v_result(v_result.count + 1) :=
            '    ' ||
            util_get_parameter_name(g_uk_columns(i).column_name, g_status.rpad_columns) ||
            ' IN ' || util_double_quote(g_params.table_name) || '.' ||
            util_double_quote(g_uk_columns(i).column_name) ||
            '%TYPE /*UK*/' || c_list_delimiter;
        END IF;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_uk_params;

    -----------------------------------------------------------------------------
    -- Unique columns parameter compare for get_pk_by_unique_cols functions:
    -- {% LIST_UK_COLUMN_COMPARE %}
    -- Example:
    --       COALESCE( "COL1",'@@@@@@@@@@@@@@@' ) = COALESCE( p_COL1,'@@@@@@@@@@@@@@@' )
    --   AND COALESCE( "COL2",'@@@@@@@@@@@@@@@' ) = COALESCE( p_COL2,'@@@@@@@@@@@@@@@' )
    --   ...
    -----------------------------------------------------------------------------

    FUNCTION list_uk_column_compare RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_uk_columns.count LOOP
        IF g_uk_columns(i).constraint_name = g_iterator.current_uk_constraint THEN
          v_result(v_result.count + 1) :=
            '         AND ' ||
            util_get_attribute_compare(
              p_data_type         => g_uk_columns(i).data_type,
              p_nullable          => util_string_to_bool(g_columns(g_columns_reverse_index(g_uk_columns(i).column_name)).is_nullable_yn),
              p_first_attribute   => util_double_quote(g_uk_columns(i).column_name),
              p_second_attribute  => util_get_parameter_name(g_uk_columns(i).column_name, NULL),
              p_compare_operation => '=') || c_lf;
        END IF;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_uk_column_compare;

    -----------------------------------------------------------------------------
    -- Unique key columns as "parameter => parameter" mapping for read_row functions:
    -- {% LIST_UK_MAP_PARAM_EQ_PARAM %}
    -- Example:
    --   p_col1 => p_col1,
    --   p_col2 => p_col2,
    --   ...
    -----------------------------------------------------------------------------

    FUNCTION list_uk_map_param_eq_param RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_uk_columns.count LOOP
        IF g_uk_columns(i).constraint_name = g_iterator.current_uk_constraint THEN
          v_result(v_result.count + 1) :=
            '    ' ||
            util_get_parameter_name(
              g_uk_columns(i).column_name,
              CASE WHEN g_status.pk_is_multi_column
                THEN g_status.rpad_uk_columns
                ELSE NULL
              END) ||
            ' => ' ||
            util_get_parameter_name(g_uk_columns(i).column_name, NULL) ||
            c_list_delimiter;
        END IF;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_uk_map_param_eq_param;

    -----------------------------------------------------------------------------
    -- A list of column defaults - used in the function get_a_row:
    -- {% LIST_ROWCOLS_W_CUST_DEFAULTS %}
    -- Example:
    --   v_row.employee_id := employees_seq.nextval; --generated from SEQ
    --   v_row.first_name  := 'Rowan';
    --   v_row.last_name   := 'Atkinson';
    --   ...
    -----------------------------------------------------------------------------

    FUNCTION list_rowcols_w_cust_defaults RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).data_custom_default IS NOT NULL THEN
          v_result(v_result.count + 1) :=
            '    ' || 'v_row.' ||
            rpad(util_double_quote(g_columns(i).column_name), g_status.rpad_columns + 2) ||
            ' := ' || coalesce(g_columns(i).data_custom_default, g_columns(i).data_default) ||
             get_column_comment(i) || ';' || c_lf;
        END IF;
      END LOOP;
      trim_list(v_result);
      RETURN v_result;
    END list_rowcols_w_cust_defaults;

    -----------------------------------------------------------------------------
    -- A list of custom column defaults - used to save the defaults in the spec:
    -- {% LIST_SPEC_CUSTOM_DEFAULTS %}
    -- Example:
    --   v_row.employee_id := employees_seq.nextval; --generated from SEQ
    --   v_row.first_name  := 'Rowan';
    --   v_row.last_name   := 'Atkinson';
    --   ...
    -----------------------------------------------------------------------------

    FUNCTION list_spec_custom_defaults RETURN t_tab_vc2_2k IS
      v_result t_tab_vc2_2k;
    BEGIN
      v_result(v_result.count + 1) := '<custom_defaults>' || c_lf;
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).data_custom_default IS NOT NULL THEN
          v_result(v_result.count + 1) :=
            '    <column source="' ||
            rpad(g_columns(i).custom_default_source || '"', 8) ||
            ' name="' || g_columns(i).column_name || '"><![CDATA[' ||
            g_columns(i).data_custom_default || ']]></column>' || c_lf;
        END IF;
      END LOOP;
      v_result(v_result.count + 1) := '  </custom_defaults>' || c_lf;
      IF v_result.count > 2 THEN
        v_result(v_result.last) := rtrim(v_result(v_result.last), c_lf);
      ELSE
        -- no data available, only the empty <custom_defaults> element
        v_result.delete;
      END IF;
      RETURN v_result;
    END list_spec_custom_defaults;

    -----------------------------------------------------------------------------

  BEGIN
    CASE p_list_name
      WHEN 'LIST_INSERT_COLUMNS' THEN
        RETURN list_insert_columns;
      WHEN 'LIST_COLUMNS_W_PK_FULL' THEN
        RETURN list_columns_w_pk_full;
      WHEN 'LIST_ROWCOLS_W_CUST_DEFAULTS' THEN
        RETURN list_rowcols_w_cust_defaults;
      WHEN 'LIST_MAP_PAR_EQ_NEWCOL_W_PK' THEN
        RETURN list_map_par_eq_newcol_w_pk;
      WHEN 'LIST_MAP_PAR_EQ_PARAM_W_PK' THEN
        RETURN list_map_par_eq_param_w_pk;
      WHEN 'LIST_MAP_PAR_EQ_ROWTYPCOL_W_PK' THEN
        RETURN list_map_par_eq_rowtypcol_w_pk;
      WHEN 'LIST_PARAMS_W_PK' THEN
        RETURN list_params_w_pk;
      WHEN 'LIST_PARAMS_W_PK_IO' THEN
        RETURN list_params_w_pk_io;
      WHEN 'LIST_PARAMS_W_PK_CUST_DEFAULTS' THEN
        RETURN list_params_w_pk_cust_defaults;
      WHEN 'LIST_INSERT_PARAMS' THEN
        RETURN list_insert_params;
      WHEN 'LIST_INSERT_BULK_PARAMS' THEN
        RETURN list_insert_bulk_params;
      WHEN 'LIST_SET_COL_EQ_PARAM_WO_PK' THEN
        RETURN list_set_col_eq_param_wo_pk;
      WHEN 'LIST_SET_COL_EQ_PAR_BULK_WO_PK' THEN
        RETURN list_set_col_eq_par_bulk_wo_pk;
      WHEN 'LIST_SET_PAR_EQ_ROWTYCOL_WO_PK' THEN
        RETURN list_set_par_eq_rowtycol_wo_pk;
      WHEN 'LIST_PK_PARAMS' THEN
        RETURN list_pk_params;
      WHEN 'LIST_PK_COLUMNS' THEN
        RETURN list_pk_columns;
      WHEN 'LIST_PK_NAMES' THEN
        RETURN list_pk_names;
      WHEN 'LIST_PK_RETURN_COLUMNS' THEN
        RETURN list_pk_return_columns;
      WHEN 'LIST_PK_RETURN_COLUMNS_BULK' THEN
        RETURN list_pk_return_columns_bulk;
      WHEN 'LIST_PK_COLUMNS_WHERE_CLAUSE' THEN
        RETURN list_pk_columns_where_clause;
      WHEN 'LIST_PK_COLUMN_FETCH' THEN
        RETURN list_pk_column_fetch;
      WHEN 'LIST_PK_COLUMN_BULK_COMPARE' THEN
        RETURN list_pk_column_bulk_compare;
      WHEN 'LIST_PK_COLUMN_BULK_FETCH' THEN
        RETURN list_pk_column_bulk_fetch;
      WHEN 'LIST_PK_MAP_PARAM_EQ_PARAM' THEN
        RETURN list_pk_map_param_eq_param;
      WHEN 'LIST_PK_MAP_PARAM_EQ_RETURN' THEN
        RETURN list_pk_map_param_eq_return;
      WHEN 'LIST_PK_MAP_PARAM_EQ_OLDCOL' THEN
        RETURN list_pk_map_param_eq_oldcol;
      WHEN 'LIST_UK_PARAMS' THEN
        RETURN list_uk_params;
      WHEN 'LIST_UK_COLUMN_COMPARE' THEN
        RETURN list_uk_column_compare;
      WHEN 'LIST_UK_MAP_PARAM_EQ_PARAM' THEN
        RETURN list_uk_map_param_eq_param;
      WHEN 'LIST_SPEC_CUSTOM_DEFAULTS' THEN
        RETURN list_spec_custom_defaults;
      ELSE
        raise_application_error(c_generator_error_number, 'FIXME: Bug - list ' || p_list_name || ' not defined');
    END CASE;
  END util_generate_list;

  -----------------------------------------------------------------------------
  -- util_clob_append is a private helper procedure to append a varchar2 value
  -- to an existing clob. The idea is to increase performance by avoiding the
  -- slow DBMS_LOB.append call. Only for the final append or if the varchar
  -- cache is fullfilled,this call is done.
  -----------------------------------------------------------------------------
  PROCEDURE util_clob_append
  (
    p_clob               IN OUT NOCOPY CLOB,
    p_clob_varchar_cache IN OUT NOCOPY VARCHAR2,
    p_varchar_to_append  IN VARCHAR2,
    p_final_call         IN BOOLEAN DEFAULT FALSE
  ) IS
  BEGIN
    p_clob_varchar_cache := p_clob_varchar_cache || p_varchar_to_append;

    IF p_final_call THEN
      IF p_clob IS NULL THEN
        p_clob := p_clob_varchar_cache;
      ELSE
        sys.dbms_lob.append(p_clob, p_clob_varchar_cache);
      END IF;

      -- clear cache on final call

      p_clob_varchar_cache := NULL;
    END IF;
  EXCEPTION
    WHEN value_error THEN
      IF p_clob IS NULL THEN
        p_clob := p_clob_varchar_cache;
      ELSE
        sys.dbms_lob.append(p_clob, p_clob_varchar_cache);
      END IF;

      p_clob_varchar_cache := p_varchar_to_append;

      IF p_final_call THEN
        sys.dbms_lob.append(p_clob, p_clob_varchar_cache);
        -- clear cache on final call
        p_clob_varchar_cache := NULL;
      END IF;
  END util_clob_append;

  -----------------------------------------------------------------------------
  -- util_template_replace is a private helper procedure:
  -- * processes static or dynamic replacements
  -- * slices the templates in blocks of code at the replacement positions
  -- * appends the slices to the resulting clobs for spec, body, view and trigger
  -- * uses a varchar2 cache to speed up the clob processing
  -----------------------------------------------------------------------------
  PROCEDURE util_template_replace(
    p_scope                 IN VARCHAR2 DEFAULT NULL) IS
    v_current_pos       PLS_INTEGER := 1;
    v_match_pos_static  PLS_INTEGER := 0;
    v_match_pos_dynamic PLS_INTEGER := 0;
    v_match_len         PLS_INTEGER := 0;
    v_match             t_vc2_200;
    v_tpl_len           PLS_INTEGER;
    v_dynamic_result    t_tab_vc2_2k;

    -----------------------------------------------------------------------------

    PROCEDURE get_match_pos IS
      -- finds the first position of a substitution string like
      -- {{ TABLE_NAME }} or {% dynamic code %}
    BEGIN
      v_match_pos_static  := instr(g_code_blocks.template, '{{', v_current_pos);
      v_match_pos_dynamic := instr(g_code_blocks.template, '{%', v_current_pos);
    END get_match_pos;

    -----------------------------------------------------------------------------

    PROCEDURE code_append(p_code_snippet IN VARCHAR2) IS
    BEGIN
      CASE p_scope
        WHEN 'API SPEC' THEN
          util_clob_append(g_code_blocks.api_spec, g_code_blocks.api_spec_varchar_cache, p_code_snippet);
        WHEN 'API BODY' THEN
          util_clob_append(g_code_blocks.api_body, g_code_blocks.api_body_varchar_cache, p_code_snippet);
        WHEN 'VIEW' THEN
          util_clob_append(g_code_blocks.dml_view, g_code_blocks.dml_view_varchar_cache, p_code_snippet);
        WHEN 'TRIGGER' THEN
          util_clob_append(g_code_blocks.dml_view_trigger, g_code_blocks.dml_view_trigger_varchar_cache, p_code_snippet);
        WHEN '1:1 VIEW' THEN
          util_clob_append(g_code_blocks.one_to_one_view, g_code_blocks.one_to_one_view_varchar_cache, p_code_snippet);
      END CASE;
    END code_append;

    -----------------------------------------------------------------------------

    PROCEDURE process_static_match IS
    BEGIN
      v_match_len := instr(g_code_blocks.template, '}}', v_match_pos_static) - v_match_pos_static - 2;

      IF v_match_len <= 0 THEN
        raise_application_error(c_generator_error_number, 'FIXME: Bug - static substitution not properly closed');
      END IF;

      v_match := upper(TRIM(substr(g_code_blocks.template, v_match_pos_static + 2, v_match_len)));
      -- (1) process text before the match

      code_append(substr(g_code_blocks.template, v_current_pos, v_match_pos_static - v_current_pos));

      -- (2) process the match
      CASE v_match
        WHEN 'GENERATOR' THEN
          code_append(c_generator);
        WHEN 'GENERATOR_VERSION' THEN
          code_append(c_generator_version);
        WHEN 'GENERATOR_ACTION' THEN
          code_append(g_status.generator_action);
        WHEN 'GENERATOR_ERROR_NUMBER' THEN
          code_append(c_generator_error_number);
        WHEN 'GENERATED_AT' THEN
          code_append(to_char(SYSDATE, 'yyyy-mm-dd hh24:mi:ss'));
        WHEN 'GENERATED_BY' THEN
          code_append(util_get_user_name);
        WHEN 'SPEC_OPTIONS_MIN_LINE' THEN
          code_append(c_spec_options_min_line);
        WHEN 'SPEC_OPTIONS_MAX_LINE' THEN
          code_append(c_spec_options_max_line);
        WHEN 'OWNER' THEN
          code_append(util_double_quote(g_params.owner));
        WHEN 'OWNER_XML' THEN
          code_append(g_params.owner);
        WHEN 'TABLE_NAME' THEN
          code_append(util_double_quote(g_params.table_name));
        WHEN 'TABLE_NAME_XML' THEN
          code_append(g_params.table_name);
        WHEN 'SEQUENCE_NAME' THEN
          code_append(util_double_quote(g_params.sequence_name));
        WHEN 'SEQUENCE_NAME_XML' THEN
          code_append(g_params.sequence_name);
        WHEN 'API_NAME' THEN
          code_append(util_double_quote(g_params.api_name));
        WHEN 'API_NAME_XML' THEN
          code_append(g_params.api_name);
        WHEN 'DML_VIEW_NAME' THEN
          code_append(util_double_quote(substr(g_params.table_name, 1, c_ora_max_name_len - 6)||'_DML_V'));
        WHEN 'TRIGGER_NAME' THEN
          code_append(util_double_quote(substr(g_params.table_name, 1, c_ora_max_name_len - 6)||'_IOIUD'));
        WHEN 'ONE_TO_ONE_VIEW_NAME' THEN
          code_append(util_double_quote(substr(g_params.table_name, 1, c_ora_max_name_len - 2)||'_V'));
        WHEN 'IDENTITY_TYPE' THEN
          IF g_status.identity_type IS NOT NULL THEN
            code_append(' with column '||g_status.identity_column||' generated '||g_status.identity_type||' as identity');
          END IF;
        WHEN 'COLUMN_PREFIX' THEN
          code_append(g_status.column_prefix);
        WHEN 'PK_COLUMN' THEN
          code_append(util_double_quote(g_pk_columns(1).column_name));
        WHEN 'PARAMETER_PK_FIRST_COLUMN' THEN
          code_append(CASE
                        WHEN NOT g_status.pk_is_multi_column THEN
                         util_get_parameter_name(g_pk_columns(1).column_name, NULL)
                        ELSE
                         NULL
                      END);
        WHEN 'COL_PREFIX_IN_METHOD_NAMES' THEN
          code_append(util_bool_to_string(g_params.col_prefix_in_method_names));
        WHEN 'ENABLE_INSERTION_OF_ROWS' THEN
          code_append(util_bool_to_string(g_params.enable_insertion_of_rows));
        WHEN 'ENABLE_COLUMN_DEFAULTS' THEN
          code_append(util_bool_to_string(g_params.enable_column_defaults));
        WHEN 'ENABLE_CUSTOM_DEFAULTS' THEN
          code_append(util_bool_to_string(g_params.enable_custom_defaults));
        WHEN 'ENABLE_UPDATE_OF_ROWS' THEN
          code_append(util_bool_to_string(g_params.enable_update_of_rows));
        WHEN 'ENABLE_DELETION_OF_ROWS' THEN
          code_append(util_bool_to_string(g_params.enable_deletion_of_rows));
        WHEN 'ENABLE_DML_VIEW' THEN
          code_append(util_bool_to_string(g_params.enable_dml_view));
        WHEN 'ENABLE_ONE_TO_ONE_VIEW' THEN
          code_append(util_bool_to_string(g_params.enable_one_to_one_view));
        WHEN 'ENABLE_GETTER_AND_SETTER' THEN
          code_append(util_bool_to_string(g_params.enable_getter_and_setter));
        WHEN 'ENABLE_PROC_WITH_OUT_PARAMS' THEN
          code_append(util_bool_to_string(g_params.enable_proc_with_out_params));
        WHEN 'ENABLE_PARAMETER_PREFIXES' THEN
          code_append(util_bool_to_string(g_params.enable_parameter_prefixes));
        WHEN 'RETURN_ROW_INSTEAD_OF_PK' THEN
          code_append(util_bool_to_string(g_params.return_row_instead_of_pk));
        WHEN 'DOUBLE_QUOTE_NAMES' THEN
          code_append(util_bool_to_string(g_params.double_quote_names));
        WHEN 'DEFAULT_BULK_LIMIT' THEN
          code_append(to_char(g_params.default_bulk_limit));
        WHEN 'CUSTOM_DEFAULTS' THEN
          code_append(CASE
                        WHEN g_params.custom_default_values IS NOT NULL THEN
                        -- We set only a placeholder to signal that column defaults are given.
                        -- Column defaults itself could be very large XML and are saved at
                        -- the end of the package spec.
                         c_custom_defaults_present_msg
                        ELSE
                         NULL
                      END);
        WHEN 'EXCLUDE_COLUMN_LIST' THEN
          code_append(g_params.exclude_column_list);
        WHEN 'AUDIT_COLUMN_MAPPINGS' THEN
          code_append(g_params.audit_column_mappings);
        WHEN 'AUDIT_USER_EXPRESSION' THEN
          code_append(g_params.audit_user_expression);
        WHEN 'ROW_VERSION_COLUMN_MAPPING' THEN
          code_append(g_params.row_version_column_mapping);
        WHEN 'RETURN_TYPE' THEN
          code_append(util_double_quote(g_params.table_name) || CASE
                        WHEN g_params.return_row_instead_of_pk OR g_status.pk_is_multi_column THEN
                         '%ROWTYPE'
                        ELSE
                         '.' || util_double_quote(g_pk_columns(1).column_name) || '%TYPE'
                      END);
        WHEN 'RETURN_TYPE_PK_SINGLE_COLUMN' THEN
          code_append('v_return' || CASE
                        WHEN g_params.return_row_instead_of_pk OR g_status.pk_is_multi_column THEN
                         '.' || util_double_quote(g_pk_columns(1).column_name)
                        ELSE
                         NULL
                      END);
        WHEN 'RETURN_TYPE_READ_ROW' THEN
          code_append(CASE
                        WHEN NOT g_params.return_row_instead_of_pk AND NOT g_status.pk_is_multi_column THEN
                          '.' || util_double_quote(g_pk_columns(1).column_name)
                        ELSE
                          NULL
                      END);
        WHEN 'ROWTYPE_PARAM' THEN
          code_append(rpad('p_row', g_status.rpad_columns + 2) || ' IN ' || util_double_quote(g_params.table_name) || '%ROWTYPE');
        WHEN 'BULK_LIMIT_PARAM' THEN
          code_append(rpad('p_bulk_limit', g_status.rpad_columns + 2) || ' IN PLS_INTEGER');
        WHEN 'TABTYPE_PARAM' THEN
          code_append(rpad('p_rows_tab', g_status.rpad_columns + 2) || ' IN t_rows_tab');
        WHEN 'REFCURSOR_PARAM' THEN
          code_append(rpad('p_ref_cursor', g_status.rpad_columns + 2) || ' IN t_strong_ref_cursor');
        WHEN 'I_COLUMN_NAME' THEN
          code_append(g_iterator.column_name);
        WHEN 'I_METHOD_NAME' THEN
          code_append(g_iterator.method_name);
        WHEN 'I_PARAMETER_NAME' THEN
          code_append(g_iterator.parameter_name);
        WHEN 'I_OLD_VALUE' THEN
          code_append(g_iterator.old_value);
        WHEN 'I_NEW_VALUE' THEN
          code_append(g_iterator.new_value);
        WHEN 'COLUMN_DEFAULTS_SERIALIZED' THEN
          code_append(g_params.custom_defaults_serialized);
        ELSE
          raise_application_error(c_generator_error_number,
                                  'FIXME: Bug - static substitution ' || v_match || ' not defined');
      END CASE;

      v_current_pos := v_match_pos_static + v_match_len + 4;
    END process_static_match;

    -----------------------------------------------------------------------------

    PROCEDURE process_dynamic_match IS
    BEGIN
      v_match_len := instr(g_code_blocks.template, '%}', v_match_pos_dynamic) - v_match_pos_dynamic - 2;

      IF v_match_len <= 0 THEN
        raise_application_error(c_generator_error_number, 'FIXME: Bug - dynamic substitution not properly closed');
      END IF;

      v_match := upper(TRIM(substr(g_code_blocks.template, v_match_pos_dynamic + 2, v_match_len)));

      g_template_options.use_column_defaults :=
        nvl(
          util_string_to_bool(regexp_substr(
            srcstr        => v_match,
            pattern       => 'USE_COLUMN_DEFAULTS=([A-Z]+)',
            position      => 1,
            occurrence    => 1,
            modifier      => 'i',
            subexpression => 1)),
          FALSE);
      g_template_options.crud_mode :=
        regexp_substr(
          srcstr        => v_match,
          pattern       => 'CRUD_MODE=([A-Z]+)',
          position      => 1,
          occurrence    => 1,
          modifier      => 'i',
          subexpression => 1);
      g_template_options.padding := to_number(regexp_substr(
        srcstr        => v_match,
        pattern       => 'PADDING=([0-9]+)',
        position      => 1,
        occurrence    => 1,
        modifier      => 'i',
        subexpression => 1));
      v_match := regexp_substr(
        srcstr        => v_match,
        pattern       => '^ *([A-Z_0-9]+)',
        position      => 1,
        occurrence    => 1,
        modifier      => 'i',
        subexpression => 1);

      -- (1) process text before the match
      code_append(substr(g_code_blocks.template, v_current_pos, v_match_pos_dynamic - v_current_pos));

      -- (2) process the match
      v_dynamic_result.delete;

      IF v_match LIKE 'LIST%' THEN
        v_dynamic_result := util_generate_list(v_match);

      ELSE
        raise_application_error(c_generator_error_number,
                                'FIXME: Bug - dynamic substitution ' || v_match || ' not defined');
      END IF;

      IF v_dynamic_result.count > 0 THEN
        FOR i IN 1 .. v_dynamic_result.count LOOP
          code_append(v_dynamic_result(i));
        END LOOP;
      END IF;

      v_current_pos := v_match_pos_dynamic + v_match_len + 4;
    END process_dynamic_match;

    -----------------------------------------------------------------------------

  BEGIN
    -- add a blank line before each template block
    code_append(c_lf);

    -- plus one is needed to correct difference between length and position
    v_tpl_len := length(g_code_blocks.template) + 1;
    get_match_pos;

    WHILE v_current_pos < v_tpl_len LOOP
      get_match_pos;

      IF v_match_pos_static > 0 OR v_match_pos_dynamic > 0 THEN
        IF v_match_pos_static > 0 AND (v_match_pos_dynamic = 0 OR v_match_pos_static < v_match_pos_dynamic) THEN
          process_static_match;
        ELSE
          process_dynamic_match;
        END IF;
      ELSE
        -- (3) process the rest of the text
        code_append(substr(g_code_blocks.template, v_current_pos));
        v_current_pos := v_tpl_len;
      END IF;
    END LOOP;
  END util_template_replace;

  -----------------------------------------------------------------------------

  PROCEDURE main_init
  (
    p_generator_action            IN VARCHAR2,
    p_table_name                  IN VARCHAR2,
    p_owner                       IN VARCHAR2,
    p_enable_insertion_of_rows    IN BOOLEAN,
    p_enable_column_defaults      IN BOOLEAN,
    p_enable_update_of_rows       IN BOOLEAN,
    p_enable_deletion_of_rows     IN BOOLEAN,
    p_enable_parameter_prefixes   IN BOOLEAN,
    p_enable_proc_with_out_params IN BOOLEAN,
    p_enable_getter_and_setter    IN BOOLEAN,
    p_col_prefix_in_method_names  IN BOOLEAN,
    p_return_row_instead_of_pk    IN BOOLEAN,
    p_double_quote_names          IN BOOLEAN,
    p_default_bulk_limit          IN INTEGER,
    p_enable_dml_view             IN BOOLEAN,
    p_enable_one_to_one_view      IN BOOLEAN,
    p_api_name                    IN VARCHAR2,
    p_sequence_name               IN VARCHAR2,
    p_exclude_column_list         IN VARCHAR2,
    p_audit_column_mappings       IN VARCHAR2,
    p_audit_user_expression       IN VARCHAR2,
    p_row_version_column_mapping  IN VARCHAR2,
    p_enable_custom_defaults      IN BOOLEAN,
    p_custom_default_values       IN XMLTYPE
  ) IS

    -----------------------------------------------------------------------------

    PROCEDURE init_reset_globals IS
    BEGIN
      util_debug_start_one_step(p_action => 'init_reset_globals');
      -- global records
      g_params              := NULL;
      g_iterator            := NULL;
      g_code_blocks         := NULL;
      g_status              := NULL;
      -- global collections
      g_columns.delete;
      g_columns_reverse_index.delete;
      g_uk_constraints.delete;
      g_fk_constraints.delete;
      g_pk_columns.delete;
      g_uk_columns.delete;
      g_fk_columns.delete;
      util_debug_stop_one_step;
    END init_reset_globals;

    -----------------------------------------------------------------------------

    PROCEDURE init_process_parameters IS
    BEGIN
      util_debug_start_one_step(p_action => 'init_process_parameters');
      g_params.enable_insertion_of_rows    := p_enable_insertion_of_rows;
      g_params.enable_column_defaults      := p_enable_column_defaults;
      g_params.enable_update_of_rows       := p_enable_update_of_rows;
      g_params.enable_deletion_of_rows     := p_enable_deletion_of_rows;
      g_params.enable_parameter_prefixes   := p_enable_parameter_prefixes;
      g_params.enable_proc_with_out_params := p_enable_proc_with_out_params;
      g_params.enable_getter_and_setter    := p_enable_getter_and_setter;
      g_params.col_prefix_in_method_names  := p_col_prefix_in_method_names;
      g_params.return_row_instead_of_pk    := p_return_row_instead_of_pk;
      g_params.double_quote_names          := p_double_quote_names;
      g_params.default_bulk_limit          := p_default_bulk_limit;
      g_params.enable_dml_view             := p_enable_dml_view;
      g_params.enable_one_to_one_view      := p_enable_one_to_one_view;
      g_params.api_name                    := util_get_substituted_name(coalesce(p_api_name,'#TABLE_NAME_1_' || to_char(c_ora_max_name_len - 4) || '#_API'));
      g_params.sequence_name               := CASE WHEN p_sequence_name IS NOT NULL THEN util_get_substituted_name(p_sequence_name) ELSE NULL END;
      g_params.exclude_column_list         := p_exclude_column_list;
      g_params.audit_column_mappings       := p_audit_column_mappings;
      g_params.audit_user_expression       := p_audit_user_expression;
      g_params.row_version_column_mapping  := p_row_version_column_mapping;
      g_params.enable_custom_defaults      := p_enable_custom_defaults;
      g_params.custom_default_values       :=  p_custom_default_values;
      IF g_params.custom_default_values IS NOT NULL THEN
        g_params.custom_defaults_serialized := util_serialize_xml(g_params.custom_default_values);
      END IF;
      -- check for empty XML element
      IF g_params.custom_defaults_serialized = '<defaults/>' THEN
        g_params.custom_default_values      := NULL;
        g_params.custom_defaults_serialized := NULL;
      END IF;
      util_debug_stop_one_step;
    END init_process_parameters;

    -----------------------------------------------------------------------------

    PROCEDURE init_check_if_table_exists IS
      v_object_name all_objects.object_name%TYPE;

      CURSOR v_cur IS
        SELECT table_name
          FROM all_tables
         WHERE owner = g_params.owner
           AND table_name = g_params.table_name;
    BEGIN
      util_debug_start_one_step(p_action => 'init_check_if_table_exists');
      OPEN v_cur;
      FETCH v_cur
        INTO v_object_name;
      CLOSE v_cur;
      IF (v_object_name IS NULL) THEN
        raise_application_error(c_generator_error_number, 'Table "' || g_params.table_name || '" does not exist.');
      END IF;
      util_debug_stop_one_step;
    END init_check_if_table_exists;

    -----------------------------------------------------------------------------

    PROCEDURE init_check_if_api_name_exists IS
      v_object_type all_objects.object_type%TYPE;

      CURSOR v_cur IS
        SELECT object_type
          FROM all_objects
         WHERE owner = g_params.owner
           AND object_name = g_params.api_name
           AND object_type NOT IN ('PACKAGE', 'PACKAGE BODY');
    BEGIN
      util_debug_start_one_step(p_action => 'init_check_if_api_name_exists');
      OPEN v_cur;
      FETCH v_cur
        INTO v_object_type;
      CLOSE v_cur;
      IF (v_object_type IS NOT NULL) THEN
        raise_application_error(c_generator_error_number,
                                'API name "' || g_params.api_name || '" does already exist as an object type "' ||
                                v_object_type || '". Please provide a different API name.');
      END IF;
      util_debug_stop_one_step;
    END init_check_if_api_name_exists;

    -----------------------------------------------------------------------------

    PROCEDURE init_check_if_sequence_exists IS
      v_object_name all_objects.object_name%TYPE;

      CURSOR v_cur IS
        SELECT sequence_name
          FROM all_sequences
         WHERE sequence_owner = g_params.owner
           AND sequence_name = g_params.sequence_name;
    BEGIN
      util_debug_start_one_step(p_action => 'init_check_if_sequence_exists');
      OPEN v_cur;
      FETCH v_cur
        INTO v_object_name;
      CLOSE v_cur;
      IF (v_object_name IS NULL) THEN
        raise_application_error(c_generator_error_number,
                                'Sequence ' || g_params.sequence_name ||
                                ' does not exist. Please provide correct sequence name or create missing sequence.');
      END IF;
      util_debug_stop_one_step;
    END init_check_if_sequence_exists;

    -----------------------------------------------------------------------------

    PROCEDURE init_create_temporary_lobs IS
    BEGIN
      util_debug_start_one_step(p_action => 'init_create_temporary_lobs');
      sys.dbms_lob.createtemporary(lob_loc => g_code_blocks.api_spec,         cache => true);
      sys.dbms_lob.createtemporary(lob_loc => g_code_blocks.api_body,         cache => true);
      sys.dbms_lob.createtemporary(lob_loc => g_code_blocks.dml_view,         cache => true);
      sys.dbms_lob.createtemporary(lob_loc => g_code_blocks.dml_view_trigger, cache => true);
      sys.dbms_lob.createtemporary(lob_loc => g_code_blocks.one_to_one_view,  cache => true);
      util_debug_stop_one_step;
    END init_create_temporary_lobs;

    -----------------------------------------------------------------------------

    PROCEDURE init_fetch_columns IS
    BEGIN
      util_debug_start_one_step(p_action => 'init_fetch_columns');
      OPEN g_cur_columns;
      FETCH g_cur_columns BULK COLLECT
        INTO g_columns;
      CLOSE g_cur_columns;
      util_debug_stop_one_step;
    EXCEPTION
      WHEN OTHERS THEN
        CLOSE g_cur_columns;
        RAISE;
    END init_fetch_columns;

    -----------------------------------------------------------------------------

    PROCEDURE init_fetch_constraints IS
    BEGIN
      util_debug_start_one_step(p_action => 'init_fetch_constraints');
      FOR i IN (SELECT constraint_name, constraint_type
                  FROM all_constraints
                 WHERE owner = g_params.owner
                   AND table_name = g_params.table_name
                   AND constraint_type IN ('U', 'R')
                   AND status = 'ENABLED') LOOP
        CASE i.constraint_type
          WHEN 'U' THEN
            g_uk_constraints(g_uk_constraints.count + 1).constraint_name := i.constraint_name;
          WHEN 'R' THEN
            g_fk_constraints(g_fk_constraints.count + 1).constraint_name := i.constraint_name;
        END CASE;
      END LOOP;
      util_debug_stop_one_step;
    END init_fetch_constraints;

    -----------------------------------------------------------------------------
    /* constraint columns
    constraint_name
    column_name
    column_name_length
    data_type         */

    -----------------------------------------------------------------------------

    PROCEDURE init_fetch_constraint_columns IS
      v_idx PLS_INTEGER;
    BEGIN
      util_debug_start_one_step(p_action => 'init_fetch_constraint_columns');
      FOR i IN (WITH ac AS
                   (SELECT owner, constraint_name, constraint_type, r_owner, r_constraint_name
                     FROM all_constraints
                    WHERE owner = g_params.owner
                      AND table_name = g_params.table_name
                      AND constraint_type IN ('P', 'U', 'R')
                      AND status = 'ENABLED'),
                  acc AS
                   (SELECT acc.owner,
                          acc.constraint_name,
                          ac.constraint_type,
                          acc.table_name,
                          acc.column_name,
                          length(acc.column_name) AS column_name_length,
                          acc.position,
                          ac.r_owner,
                          ac.r_constraint_name
                     FROM ac
                     JOIN all_cons_columns acc ON ac.owner = acc.owner
                                              AND ac.constraint_name = acc.constraint_name),
                  acc_r AS
                   (SELECT acc_r.owner           AS r_owner,
                          acc_r.constraint_name AS r_constraint_name,
                          acc_r.table_name      AS r_table_name,
                          acc_r.column_name     AS r_column_name,
                          acc_r.position        AS r_position
                     FROM ac
                     JOIN all_cons_columns acc_r ON ac.r_owner = acc_r.owner
                                                AND ac.r_constraint_name = acc_r.constraint_name)
                  SELECT acc.owner,
                         acc.constraint_name,
                         acc.constraint_type,
                         acc.table_name,
                         acc.column_name,
                         acc.column_name_length,
                         atc.data_type,
                         acc.position,
                         acc_r.r_owner,
                         acc_r.r_constraint_name,
                         acc_r.r_table_name,
                         acc_r.r_column_name,
                         acc_r.r_position
                    FROM acc
                    JOIN all_tab_columns atc ON acc.owner = atc.owner
                                            AND acc.table_name = atc.table_name
                                            AND acc.column_name = atc.column_name
                    LEFT JOIN acc_r ON acc.r_owner = acc_r.r_owner
                                   AND acc.r_constraint_name = acc_r.r_constraint_name
                                   AND acc.position = acc_r.r_position
                   ORDER BY acc.constraint_name, acc.position) LOOP
        CASE i.constraint_type
          WHEN 'P' THEN
            v_idx := g_pk_columns.count + 1;
            g_pk_columns(v_idx).constraint_name := i.constraint_name;
            g_pk_columns(v_idx).position := i.position;
            g_pk_columns(v_idx).column_name := i.column_name;
            g_pk_columns(v_idx).column_name_length := i.column_name_length;
            g_pk_columns(v_idx).data_type := i.data_type;
          WHEN 'U' THEN
            v_idx := g_uk_columns.count + 1;
            g_uk_columns(v_idx).constraint_name := i.constraint_name;
            g_uk_columns(v_idx).position := i.position;
            g_uk_columns(v_idx).column_name := i.column_name;
            g_uk_columns(v_idx).column_name_length := i.column_name_length;
            g_uk_columns(v_idx).data_type := i.data_type;
          WHEN 'R' THEN
            v_idx := g_fk_columns.count + 1;
            g_fk_columns(v_idx).constraint_name := i.constraint_name;
            g_fk_columns(v_idx).position := i.position;
            g_fk_columns(v_idx).column_name := i.column_name;
            g_fk_columns(v_idx).column_name_length := i.column_name_length;
            g_fk_columns(v_idx).data_type := i.data_type;
            g_fk_columns(v_idx).r_owner := i.r_owner;
            g_fk_columns(v_idx).r_table_name := i.r_table_name;
            g_fk_columns(v_idx).r_column_name := i.r_column_name;
        END CASE;
      END LOOP;
      util_debug_stop_one_step;
    END init_fetch_constraint_columns;

    -----------------------------------------------------------------------------

    PROCEDURE init_process_columns IS
      v_column_prefix t_ora_max_name_len;
      type v_varchar_tab is
        table of t_ora_max_name_len
        index by t_ora_max_name_len;
      v_column_prefix_tab v_varchar_tab;
    BEGIN
      util_debug_start_one_step(p_action => 'init_process_columns');
      -- init
      g_status.rpad_columns := 0;
      g_status.xmltype_column_present := FALSE;

      FOR i IN 1 .. g_columns.count LOOP
        -- calc rpad length
        IF length(g_columns(i).column_name) > g_status.rpad_columns THEN
          g_status.rpad_columns := length(g_columns(i).column_name);
        END IF;
        -- create reverse index to get collection id by column name
        g_columns_reverse_index(g_columns(i).column_name) := i;
        -- check, if we have a xmltype column present (we have then to provide a XML compare function)
        IF g_columns(i).data_type = 'XMLTYPE' THEN
          g_status.xmltype_column_present := TRUE;
        END IF;
        -- check, if we have an identity column present
        IF g_columns(i).identity_type IS NOT NULL THEN
          g_status.identity_column := g_columns(i).column_name;
          g_status.identity_type := g_columns(i).identity_type ||
            CASE WHEN g_columns(i).default_on_null_yn = 'Y' THEN ' ON NULL' END;
        END IF;
        -- Calc column prefix by saving the found prefix as tab index and count afterwards
        -- the length of the tab: if it is greater then 1 we have NO distinct column prefix.
        v_column_prefix := substr(g_columns(i).column_name, 1,
            CASE WHEN instr(g_columns(i).column_name, '_') = 0
              THEN length(g_columns(i).column_name)
              ELSE instr(g_columns(i).column_name, '_') - 1
            END);
        v_column_prefix_tab(v_column_prefix) := v_column_prefix;
      END LOOP;

      IF g_params.enable_insertion_of_rows AND g_status.identity_type = 'BY DEFAULT' THEN
        raise_application_error(c_generator_error_number,
          'Your table '||g_params.table_name||' has an identity type BY DEFAULT.' || c_lf ||
          'We can not generate an API for this table. Please change your identity' || c_lf ||
          'type either to ALWAYS or BY DEFAULT ON NULL. For the API create methods' || c_lf ||
          'we need to decide if the parameter for your identity column should be' || c_lf ||
          'shown or not. If it is shown we need to set the default for the parameter' || c_lf ||
          'to NULL for you, so you will be able to omit the identity information' || c_lf ||
          'and the table will care about to generate one for you. You will also' || c_lf ||
          'be able to provide an own identity for e.g loading existing data.' || c_lf ||
          'Please refer to this article by Tim Hall for more informations about' || c_lf ||
          'identity columns: ' || c_lf ||
          'https://oracle-base.com/articles/12c/identity-columns-in-oracle-12cr1');
      END IF;

      IF v_column_prefix_tab.count > 1 THEN
        g_status.column_prefix := NULL;
      ELSE
        g_status.column_prefix := v_column_prefix_tab.first;
      END IF;
      IF g_params.col_prefix_in_method_names = FALSE AND g_status.column_prefix IS NULL THEN
        raise_application_error(c_generator_error_number,
          'The prefix of your column names (example: prefix_rest_of_column_name)' || c_lf ||
          'is not unique and you requested to cut off the prefix for getter and' || c_lf ||
          'setter method names. Please ensure either your column names have a' || c_lf ||
          'unique prefix or switch the parameter p_col_prefix_in_method_names' || c_lf ||
          'to true (SQL Developer oddgen integration: check option "Keep column' || c_lf ||
          'prefix in method names").');
      END IF;
      util_debug_stop_one_step;
    EXCEPTION
      WHEN others THEN
        util_debug_stop_one_step;
        raise;
    END init_process_columns;

    -----------------------------------------------------------------------------

    PROCEDURE init_process_pk_columns IS
      v_count PLS_INTEGER;
      v_idx   PLS_INTEGER;
    BEGIN
      util_debug_start_one_step(p_action => 'init_process_pk_columns');
      v_count := g_pk_columns.count;
      IF v_count = 0 THEN
        raise_application_error(c_generator_error_number,
                                'Unable to generate API - no primary key present for table ' || g_params.table_name);
      ELSIF v_count = 1 THEN
        g_status.pk_is_multi_column := FALSE;
      ELSIF v_count > 1 THEN
        g_status.pk_is_multi_column := TRUE;
      END IF;
      g_status.rpad_pk_columns := 0;
      FOR i IN 1 .. g_pk_columns.count LOOP
        v_idx := g_columns_reverse_index(g_pk_columns(i).column_name);
        g_columns(v_idx).is_pk_yn := 'Y';
        g_columns(v_idx).is_nullable_yn := 'N';
        IF g_pk_columns(i).column_name_length > g_status.rpad_pk_columns THEN
          g_status.rpad_pk_columns := g_pk_columns(i).column_name_length;
        END IF;
      END LOOP;
      util_debug_stop_one_step;
    END init_process_pk_columns;

    -----------------------------------------------------------------------------

    PROCEDURE init_process_uk_columns IS
      v_count PLS_INTEGER;
      v_idx   PLS_INTEGER;
    BEGIN
      util_debug_start_one_step(p_action => 'init_process_uk_columns');
      v_count := g_uk_columns.count;
      IF v_count > 0 THEN
        g_status.rpad_uk_columns := 0;
        FOR i IN 1 .. g_uk_columns.count LOOP
          v_idx := g_columns_reverse_index(g_uk_columns(i).column_name);
          g_columns(v_idx).is_uk_yn := 'Y';
          IF g_uk_columns(i).column_name_length > g_status.rpad_uk_columns THEN
            g_status.rpad_uk_columns := g_uk_columns(i).column_name_length;
          END IF;
        END LOOP;
      END IF;
      util_debug_stop_one_step;
    END init_process_uk_columns;

    -----------------------------------------------------------------------------

    PROCEDURE init_process_fk_columns IS
      v_count PLS_INTEGER;
      v_idx   PLS_INTEGER;
    BEGIN
      util_debug_start_one_step(p_action => 'init_process_fk_columns');
      v_count := g_fk_columns.count;
      IF v_count > 0 THEN
        FOR i IN 1 .. g_fk_columns.count LOOP
          v_idx := g_columns_reverse_index(g_fk_columns(i).column_name);
          g_columns(v_idx).is_fk_yn := 'Y';
          g_columns(v_idx).r_owner := g_fk_columns(i).r_owner;
          g_columns(v_idx).r_table_name := g_fk_columns(i).r_table_name;
          g_columns(v_idx).r_column_name := g_fk_columns(i).r_column_name;
        END LOOP;
      END IF;
      util_debug_stop_one_step;
    END init_process_fk_columns;

    -----------------------------------------------------------------------------

    PROCEDURE init_process_audit_columns IS
      --
      PROCEDURE process_audit_type(
        p_audit_type IN VARCHAR2)
      IS
        v_idx         PLS_INTEGER;
        v_column_name all_tab_cols.column_name%TYPE;
      BEGIN
        v_column_name := regexp_substr(
          g_params.audit_column_mappings,
          p_audit_type || '="?([^,"]*)"?',1,1,'i',1);
        IF v_column_name IS NOT NULL THEN
          v_column_name := replace(v_column_name, '#PREFIX#', g_status.column_prefix);
          BEGIN
            v_idx := g_columns_reverse_index(v_column_name);
            g_columns(v_idx).audit_type := p_audit_type;
          EXCEPTION
            WHEN no_data_found THEN NULL;
            WHEN others THEN raise;
          END;
        END IF;
      END process_audit_type;
      --
    BEGIN
      IF instr(g_params.audit_column_mappings, '#PREFIX#') > 0 AND g_status.column_prefix IS NULL THEN
        raise_application_error(c_generator_error_number,
          'The prefix of your column names (example: prefix_rest_of_column_name)' || c_lf ||
          'is not unique and you used the placeholder #PREFIX# in the parameter' || c_lf ||
          'p_audit_column_mappings. Please ensure either your column names have a' || c_lf ||
          'unique prefix or do not use the placeholder #PREFIX# in the parameter' || c_lf ||
          'p_audit_column_mappings.');
      ELSE
        util_debug_start_one_step(p_action => 'init_process_audit_columns');
        process_audit_type('CREATED');
        process_audit_type('CREATED_BY');
        process_audit_type('UPDATED');
        process_audit_type('UPDATED_BY');
        util_debug_stop_one_step;
      END IF;
    END init_process_audit_columns;

    -----------------------------------------------------------------------------

    PROCEDURE init_process_row_version_column IS
      v_idx         PLS_INTEGER;
      v_column_name all_tab_cols.column_name%TYPE;
      v_expression  t_vc2_4k;
    BEGIN
      IF instr(g_params.row_version_column_mapping, '#PREFIX#') > 0 AND g_status.column_prefix IS NULL THEN
        raise_application_error(c_generator_error_number,
          'The prefix of your column names (example: prefix_rest_of_column_name)' || c_lf ||
          'is not unique and you used the placeholder #PREFIX# in the parameter' || c_lf ||
          'p_row_version_column_mapping. Please ensure either your column names' || c_lf ||
          'have a unique prefix or do not use the placeholder #PREFIX# in the' || c_lf ||
          'parameter p_row_version_column_mapping.');
      ELSE
        util_debug_start_one_step(p_action => 'init_process_row_version_column');
        v_idx := instr(g_params.row_version_column_mapping, '=');
        IF v_idx > 0 THEN
          v_column_name := trim(substr(g_params.row_version_column_mapping, 1, v_idx - 1));
          v_expression :=  trim(substr(g_params.row_version_column_mapping, v_idx + 1));
          v_column_name := replace(v_column_name, '#PREFIX#', g_status.column_prefix);
          IF v_column_name IS NULL OR v_expression IS NULL THEN
            raise_application_error(c_generator_error_number,
              'Invalid parameter p_row_version_column_mapping - the resulting' || c_lf ||
              'column name or SQL expression is null. Please have a look in' || c_lf ||
              'the docs and provide a valid string e.g.' || c_lf ||
              '#PREFIX#_MY_COLUMN_NAME=my_version_sequence.nextval');
          END IF;
          BEGIN
            v_idx := g_columns_reverse_index(v_column_name);
            g_columns(v_idx).row_version_expression := v_expression;
          EXCEPTION
            WHEN no_data_found THEN NULL;
            WHEN others THEN raise;
          END;
          IF v_idx IS NULL THEN
            raise_application_error(c_generator_error_number,
              'Invalid column name provided in the parameter' || c_lf ||
              'p_row_version_column_mapping.' || c_lf ||
              '#PREFIX#_MY_COLUMN_NAME=my_version_sequence.nextval');
          END IF;
          util_debug_stop_one_step;
        END IF;
      END IF;
    END init_process_row_version_column;

    -----------------------------------------------------------------------------

    PROCEDURE init_count_column_types IS
    BEGIN
      util_debug_start_one_step(p_action => 'init_count_column_types');
      g_status.number_of_data_columns := 0;
      g_status.number_of_pk_columns := 0;
      g_status.number_of_uk_columns := 0;
      g_status.number_of_fk_columns := 0;
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).is_pk_yn = 'N'
        AND g_columns(i).is_excluded_yn = 'N'
        AND g_columns(i).audit_type IS NULL
        AND g_columns(i).row_version_expression IS NULL THEN
          g_status.number_of_data_columns := g_status.number_of_data_columns + 1;
        END IF;
        IF g_columns(i).is_pk_yn = 'Y' THEN
          g_status.number_of_pk_columns := g_status.number_of_pk_columns + 1;
        END IF;
        IF g_columns(i).is_uk_yn = 'Y' THEN
          g_status.number_of_uk_columns := g_status.number_of_uk_columns + 1;
        END IF;
        IF g_columns(i).is_fk_yn = 'Y' THEN
          g_status.number_of_fk_columns := g_status.number_of_fk_columns + 1;
        END IF;
      END LOOP;
      util_debug_stop_one_step;
    END init_count_column_types;

    -----------------------------------------------------------------------------

    PROCEDURE init_process_custom_defaults IS
      v_index INTEGER;
    BEGIN
      util_debug_start_one_step(p_action => 'init_process_custom_defaults');

      -- process user provided custom defaults
      IF g_params.custom_default_values IS NOT NULL THEN
        FOR i IN (SELECT x.column_name AS column_name, x.data_default AS data_default
                    FROM xmltable('for $i in /custom_defaults/column return $i' passing g_params.custom_default_values
                                  columns --
                                  column_name VARCHAR2(200 CHAR) path '@name', --
                                  data_default VARCHAR2(4000 CHAR) path 'text()') x) LOOP
          BEGIN
            v_index := g_columns_reverse_index(i.column_name);
            IF v_index IS NOT NULL THEN
              g_columns(v_index).data_custom_default := i.data_default;
              g_columns(v_index).custom_default_source := 'USER';
            END IF;
          EXCEPTION
            WHEN no_data_found THEN
              NULL;
          END;
        END LOOP;
      END IF;

      -- generate standard custom defaults for the users convenience...
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).data_custom_default IS NULL -- do not override users defaults from the processing step above
          AND g_columns(i).is_excluded_yn = 'N'
          AND g_columns(i).identity_type IS NULL
          AND g_columns(i).audit_type IS NULL
          AND g_columns(i).row_version_expression IS NULL
        THEN
          IF g_columns(i).data_default IS NOT NULL THEN
            g_columns(i).data_custom_default := g_columns(i).data_default;
            g_columns(i).custom_default_source := 'TABLE';
          ELSE
            g_columns(i).data_custom_default :=
              CASE
                WHEN g_columns(i).is_pk_yn = 'Y' AND NOT g_status.pk_is_multi_column AND
                      g_params.sequence_name IS NOT NULL THEN
                  '"' || g_params.sequence_name || '"' || '.nextval'
                WHEN g_columns(i).is_fk_yn = 'Y' THEN
                  util_get_fk_value(p_table_name  => g_columns(i).r_table_name,
                                    p_column_name => g_columns(i).r_column_name,
                                    p_owner       => g_columns(i).r_owner)
                WHEN g_columns(i).data_type IN ('NUMBER', 'FLOAT') THEN
                  'round(sys.dbms_random.value(0, ' ||
                  rpad('9', least(nvl(g_columns(i).data_precision, 12), 24) - nvl(g_columns(i).data_scale, 0), '9') ||
                  CASE
                    WHEN nvl(g_columns(i).data_scale, 0) > 0 THEN
                      '.' || rpad('9', g_columns(i).data_scale, '9')
                    ELSE
                      NULL
                  END || '), ' ||
                  CASE
                    WHEN g_columns(i).data_type = 'NUMBER' THEN
                      to_char(nvl(g_columns(i).data_scale, 0))
                    WHEN g_columns(i).data_type = 'FLOAT' THEN
                      to_char(least(g_columns(i).data_precision / 2, 12))
                  END || ')'
                WHEN g_columns(i).data_type LIKE '%CHAR%' THEN
                  CASE
                    WHEN lower(g_columns(i).column_name) LIKE '%mail%' THEN
                      q'[sys.dbms_random.string('L', round(sys.dbms_random.value(6, ]' || to_char(least(g_columns(i).char_length - 18, 24)) || ')))' ||
                      q'[ || '@' || ]' ||
                      q'[sys.dbms_random.string('L', round(sys.dbms_random.value(6, 12)))]' ||
                      q'[ || '.' || ]' ||
                      q'[sys.dbms_random.string('L', round(sys.dbms_random.value(2, 4)))]'
                    WHEN lower(g_columns(i).column_name) LIKE '%phone%' THEN
                      q'[substr('+' || ]' ||
                      q'[to_char(round(sys.dbms_random.value(1, 99))) || ' ' || ]' ||
                      q'[to_char(round(sys.dbms_random.value(10, 9999))) || ' ' || ]' ||
                      q'[to_char(round(sys.dbms_random.value(100, 999))) || ' ' || ]' ||
                      q'[to_char(round(sys.dbms_random.value(100, 9999))), 1, ]' ||
                      to_char(g_columns(i).char_length) || ')'
                    WHEN lower(g_columns(i).column_name) LIKE '%name%'
                      OR lower(g_columns(i).column_name) LIKE '%city%'
                      OR lower(g_columns(i).column_name) LIKE '%country%'
                    THEN
                      q'[initcap(sys.dbms_random.string('L', round(sys.dbms_random.value(3, ]' || to_char(g_columns(i).char_length) || '))))'
                    WHEN lower(g_columns(i).column_name) LIKE '%street%' THEN
                      q'[initcap(sys.dbms_random.string('L', round(sys.dbms_random.value(3, ]' || to_char(g_columns(i).char_length - 4) || '))))' ||
                      q'[ || ' ' || ]' ||
                      q'[to_char(round(sys.dbms_random.value(1, 200)))]'
                    ELSE
                      q'[sys.dbms_random.string('A', round(sys.dbms_random.value(1, ]' || to_char(g_columns(i).char_length) || ')))'
                  END
                WHEN g_columns(i).data_type = 'DATE' THEN
                  q'[to_date(round(sys.dbms_random.value(to_char(date '1900-01-01', 'j'), to_char(date '2099-12-31', 'j'))), 'j')]'
                WHEN g_columns(i).data_type LIKE 'TIMESTAMP%' THEN
                  'systimestamp'
                WHEN g_columns(i).data_type = 'CLOB' THEN
                  q'[to_clob('Dummy clob for API method get_a_row: ' || sys.dbms_random.string('A', round(sys.dbms_random.value(30, 100))))]'
                WHEN g_columns(i).data_type = 'BLOB' THEN
                  q'[to_blob(utl_raw.cast_to_raw('Dummy clob for API method get_a_row: ' || sys.dbms_random.string('A', round(sys.dbms_random.value(30, 100)))))]'
                WHEN g_columns(i).data_type = 'XMLTYPE' THEN
                  q'[xmltype('<dummy>Dummy XML for API method get_a_row: ' || sys.dbms_random.string('A', round(sys.dbms_random.value(30, 100))) || '</dummy>')]'
                ELSE
                  'NULL'
              END;
            g_columns(i).custom_default_source := 'TAPIGEN';
          END IF;
        END IF;
      END LOOP;

      util_debug_stop_one_step;
    END init_process_custom_defaults;

    -----------------------------------------------------------------------------

  BEGIN
    init_reset_globals;
    g_status.generator_action := p_generator_action;
    g_params.owner := p_owner;
    g_params.table_name := p_table_name;
    init_check_if_table_exists;
    init_process_parameters;
    IF g_params.api_name IS NOT NULL THEN
      init_check_if_api_name_exists;
    END IF;
    IF g_params.sequence_name IS NOT NULL THEN
      init_check_if_sequence_exists;
    END IF;
    init_create_temporary_lobs;
    init_fetch_columns;
    init_fetch_constraints;
    init_fetch_constraint_columns;
    init_process_columns;
    init_process_pk_columns;
    init_process_uk_columns;
    init_process_fk_columns;
    IF g_params.audit_column_mappings IS NOT NULL THEN
      init_process_audit_columns;
    END IF;
    IF g_params.row_version_column_mapping IS NOT NULL THEN
      init_process_row_version_column;
    END IF;
    init_count_column_types;
    IF g_params.enable_custom_defaults THEN
      init_process_custom_defaults;
    END IF;
  END main_init;

  -----------------------------------------------------------------------------

  PROCEDURE main_generate_code IS

    -----------------------------------------------------------------------------

    PROCEDURE gen_header IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_header');

      g_code_blocks.template := '
CREATE OR REPLACE PACKAGE {{ OWNER }}.{{ API_NAME }} IS
  /*
  This is the API for the table {{ TABLE_NAME }}{{ IDENTITY_TYPE }}.

  GENERATION OPTIONS
  - Must be in the lines {{ SPEC_OPTIONS_MIN_LINE }}-{{ SPEC_OPTIONS_MAX_LINE }} to be reusable by the generator
  - DO NOT TOUCH THIS until you know what you do
  - Read the docs under github.com/OraMUC/table-api-generator ;-)
  <options
    generator="{{ GENERATOR }}"
    generator_version="{{ GENERATOR_VERSION }}"
    generator_action="{{ GENERATOR_ACTION }}"
    generated_at="{{ GENERATED_AT }}"
    generated_by="{{ GENERATED_BY }}"
    p_table_name="{{ TABLE_NAME_XML }}"
    p_owner="{{ OWNER_XML }}"
    p_enable_insertion_of_rows="{{ ENABLE_INSERTION_OF_ROWS }}"
    p_enable_column_defaults="{{ ENABLE_COLUMN_DEFAULTS }}"
    p_enable_update_of_rows="{{ ENABLE_UPDATE_OF_ROWS }}"
    p_enable_deletion_of_rows="{{ ENABLE_DELETION_OF_ROWS }}"
    p_enable_parameter_prefixes="{{ ENABLE_PARAMETER_PREFIXES }}"
    p_enable_proc_with_out_params="{{ ENABLE_PROC_WITH_OUT_PARAMS }}"
    p_enable_getter_and_setter="{{ ENABLE_GETTER_AND_SETTER }}"
    p_col_prefix_in_method_names="{{ COL_PREFIX_IN_METHOD_NAMES }}"
    p_return_row_instead_of_pk="{{ RETURN_ROW_INSTEAD_OF_PK }}"
    p_double_quote_names="{{ DOUBLE_QUOTE_NAMES }}"
    p_default_bulk_limit="{{ DEFAULT_BULK_LIMIT }}"
    p_enable_dml_view="{{ ENABLE_DML_VIEW }}"
    p_enable_one_to_one_view="{{ ENABLE_ONE_TO_ONE_VIEW }}"
    p_api_name="{{ API_NAME_XML }}"
    p_sequence_name="{{ SEQUENCE_NAME_XML }}"
    p_exclude_column_list="{{ EXCLUDE_COLUMN_LIST }}"
    p_audit_column_mappings="{{ AUDIT_COLUMN_MAPPINGS }}"
    p_audit_user_expression="{{ AUDIT_USER_EXPRESSION }}"
    p_row_version_column_mapping="{{ ROW_VERSION_COLUMN_MAPPING }}"
    p_enable_custom_defaults="{{ ENABLE_CUSTOM_DEFAULTS }}"
    p_custom_default_values="{{ CUSTOM_DEFAULTS }}"/>
  */' || CASE WHEN g_status.xmltype_column_present THEN '

  /*this is required to handle XMLTYPE column for single row processing*/
  TYPE t_pk_rec IS RECORD (
    {% LIST_PK_COLUMNS %} );' END;
      util_template_replace('API SPEC');

      g_code_blocks.template := '
CREATE OR REPLACE PACKAGE BODY {{ OWNER }}.{{ API_NAME }} IS
  /*
  This is the API for the table {{ TABLE_NAME }}{{ IDENTITY_TYPE }}.
  - generator: {{ GENERATOR }}
  - generator_version: {{ GENERATOR_VERSION }}
  - generator_action: {{ GENERATOR_ACTION }}
  - generated_at: {{ GENERATED_AT }}
  - generated_by: {{ GENERATED_BY }}
  */';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_header;

    -----------------------------------------------------------------------------

    PROCEDURE gen_bulk_types IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_bulk_types');

      g_code_blocks.template := CASE WHEN g_status.xmltype_column_present THEN '
  /*this is required to handle XMLTYPE column for bulk processing*/
  TYPE t_pk_tab            IS TABLE OF t_pk_rec;
  ' END || '
  TYPE t_rows_tab          IS TABLE OF {{ TABLE_NAME }}%ROWTYPE;
  TYPE t_strong_ref_cursor IS REF CURSOR RETURN {{ TABLE_NAME }}%ROWTYPE;';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  g_bulk_limit     PLS_INTEGER := {{ DEFAULT_BULK_LIMIT }};
  g_bulk_completed BOOLEAN     := FALSE;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_bulk_types;

    -----------------------------------------------------------------------------

    PROCEDURE gen_bulk_is_complete_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_bulk_is_complete_fnc');

      g_code_blocks.template := '
  FUNCTION bulk_is_complete
  RETURN BOOLEAN;';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  FUNCTION bulk_is_complete
  RETURN BOOLEAN IS
  BEGIN
    RETURN g_bulk_completed;
  END bulk_is_complete;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_bulk_is_complete_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_get_bulk_limit_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_get_bulk_limit_fnc');

      g_code_blocks.template := '
  FUNCTION get_bulk_limit
  RETURN PLS_INTEGER;';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  FUNCTION get_bulk_limit
  RETURN PLS_INTEGER IS
  BEGIN
    RETURN g_bulk_limit;
  END get_bulk_limit;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_get_bulk_limit_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_set_bulk_limit_prc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_set_bulk_limit_prc');

      g_code_blocks.template := '
  PROCEDURE set_bulk_limit (
    {{ BULK_LIMIT_PARAM }} );';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  PROCEDURE set_bulk_limit (
    {{ BULK_LIMIT_PARAM }} )
  IS
  BEGIN
    g_bulk_limit := p_bulk_limit;
  END set_bulk_limit;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_set_bulk_limit_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_xml_compare_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_xml_compare_fnc');

      g_code_blocks.template := q'[
  FUNCTION util_xml_compare (
    p_doc1 XMLTYPE,
    p_doc2 XMLTYPE )
  RETURN NUMBER IS
    v_return NUMBER;
  BEGIN
    SELECT CASE
             WHEN XMLEXISTS(
                    'declare default element namespace "http://xmlns.oracle.com/xdb/xdiff.xsd"; /xdiff/*'
                    PASSING XMLDIFF( p_doc1, p_doc2 ) )
             THEN 1
             ELSE 0
           END
      INTO v_return
      FROM DUAL;
    RETURN v_return;
  END util_xml_compare;]';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_xml_compare_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_row_exists_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_row_exists_fnc');

      g_code_blocks.template := '
  FUNCTION row_exists (
    {% LIST_PK_PARAMS %} )
  RETURN BOOLEAN;';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  FUNCTION row_exists (
    {% LIST_PK_PARAMS %} )
  RETURN BOOLEAN
  IS
    v_return BOOLEAN := FALSE;
    v_dummy  PLS_INTEGER;
    CURSOR   cur_bool IS
      SELECT 1
        FROM {{ TABLE_NAME }}
       WHERE {% LIST_PK_COLUMNS_WHERE_CLAUSE %};
  BEGIN
    OPEN cur_bool;
    FETCH cur_bool INTO v_dummy;
    IF cur_bool%FOUND THEN
      v_return := TRUE;
    END IF;
    CLOSE cur_bool;
    RETURN v_return;
  END;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_row_exists_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_row_exists_yn_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_row_exists_yn_fnc');

      g_code_blocks.template := '
  FUNCTION row_exists_yn (
    {% LIST_PK_PARAMS %} )
  RETURN VARCHAR2;';
      util_template_replace('API SPEC');

      g_code_blocks.template := q'[
  FUNCTION row_exists_yn (
    {% LIST_PK_PARAMS %} )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN
      CASE WHEN row_exists(
        {% LIST_PK_MAP_PARAM_EQ_PARAM %} )
        THEN 'Y'
        ELSE 'N'
      END;
  END;]';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_row_exists_yn_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_get_pk_by_unique_cols_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_get_pk_by_unique_cols_fnc');
      IF g_uk_constraints.count > 0 THEN
        FOR i IN 1 .. g_uk_constraints.count LOOP
          g_iterator.current_uk_constraint := g_uk_constraints(i).constraint_name;

          g_code_blocks.template           := '
  FUNCTION get_pk_by_unique_cols (
    {% LIST_UK_PARAMS %} )
  RETURN {{ RETURN_TYPE }};';
          util_template_replace('API SPEC');

          g_code_blocks.template := '
  FUNCTION get_pk_by_unique_cols (
    {% LIST_UK_PARAMS %} )
  RETURN {{ RETURN_TYPE }} IS
    v_return {{ RETURN_TYPE }};
  BEGIN
    v_return := read_row ( {% LIST_UK_MAP_PARAM_EQ_PARAM %} ){{ RETURN_TYPE_READ_ROW }};
    RETURN v_return;
  END get_pk_by_unique_cols;';
          util_template_replace('API BODY');

        END LOOP;
      END IF;
      util_debug_stop_one_step;
    END gen_get_pk_by_unique_cols_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_create_row_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_create_row_fnc');

      g_code_blocks.template := '
  FUNCTION create_row (
    {% LIST_PARAMS_W_PK use_column_defaults=true crud_mode=create %} )
  RETURN {{ RETURN_TYPE }};';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  FUNCTION create_row (
    {% LIST_PARAMS_W_PK use_column_defaults=true crud_mode=create %} )
  RETURN {{ RETURN_TYPE }} IS
    v_return {{ RETURN_TYPE }}; ' || CASE WHEN g_status.xmltype_column_present
                                          AND g_params.return_row_instead_of_pk THEN '
    /*this is required to handle column of datatype XMLTYPE for single row processing*/
    v_pk_rec t_pk_rec;' END || '
  BEGIN
    INSERT INTO {{ TABLE_NAME }} (
      {% LIST_INSERT_COLUMNS crud_mode=create %} )
    VALUES (
      {% LIST_INSERT_PARAMS crud_mode=create %} )
    RETURN '  || CASE WHEN (g_params.return_row_instead_of_pk OR g_status.pk_is_multi_column)
                      AND NOT g_status.xmltype_column_present THEN '
      {% LIST_COLUMNS_W_PK_FULL %}
    INTO
      v_return; ' WHEN (g_params.return_row_instead_of_pk OR g_status.pk_is_multi_column)
                  AND g_status.xmltype_column_present THEN '
      {% LIST_PK_NAMES %}
    INTO
      {% LIST_PK_RETURN_COLUMNS %};
    /* return clause does not support XMLTYPE column, so we have to do here an extra fetch */
    v_return := read_row (
      {% LIST_PK_MAP_PARAM_EQ_RETURN %} ); '
                  ELSE '
      {{ PK_COLUMN }}
    INTO
      v_return;' END || '
    RETURN v_return;
  END create_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_create_row_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_create_row_prc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_create_row_prc');

      g_code_blocks.template := '
  PROCEDURE create_row (
    {% LIST_PARAMS_W_PK use_column_defaults=true crud_mode=create %} );';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  PROCEDURE create_row (
    {% LIST_PARAMS_W_PK use_column_defaults=true crud_mode=create %} )
  IS
    v_return {{ RETURN_TYPE }};
  BEGIN
    v_return := create_row (
      {% LIST_MAP_PAR_EQ_PARAM_W_PK crud_mode=create %} );
  END create_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_create_row_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_create_rowtype_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_create_rowtype_fnc');

      g_code_blocks.template := '
  FUNCTION create_row (
    {{ ROWTYPE_PARAM }} )
  RETURN {{ RETURN_TYPE }};';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  FUNCTION create_row (
    {{ ROWTYPE_PARAM }} )
  RETURN {{ RETURN_TYPE }} IS
    v_return {{ RETURN_TYPE }};
  BEGIN
    v_return := create_row (
      {% LIST_MAP_PAR_EQ_ROWTYPCOL_W_PK crud_mode=create %} );
    RETURN v_return;
  END create_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_create_rowtype_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_create_rowtype_prc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_create_rowtype_prc');

      g_code_blocks.template := '
  PROCEDURE create_row (
    {{ ROWTYPE_PARAM }} );';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  PROCEDURE create_row (
    {{ ROWTYPE_PARAM }} )
  IS
    v_return {{ RETURN_TYPE }};
  BEGIN
    v_return := create_row (
      {% LIST_MAP_PAR_EQ_ROWTYPCOL_W_PK crud_mode=create %} );
  END create_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_create_rowtype_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_create_rows_bulk_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_create_rows_bulk_fnc');
      g_code_blocks.template := '
  FUNCTION create_rows (
    {{ TABTYPE_PARAM }} )
  RETURN t_rows_tab;';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  FUNCTION create_rows (
    {{ TABTYPE_PARAM }} )
  RETURN t_rows_tab IS
    v_return t_rows_tab;' || CASE WHEN g_status.xmltype_column_present THEN '

    /*This is required to handle column of datatype XMLTYPE for bulk processing*/
    v_pk_tab t_pk_tab;
    v_strong_ref_cursor t_strong_ref_cursor;' END || '
  BEGIN
    FORALL i IN INDICES OF p_rows_tab
    INSERT INTO {{ TABLE_NAME }} (
      {% LIST_INSERT_COLUMNS crud_mode=create %} )
    VALUES (
      {% LIST_INSERT_BULK_PARAMS crud_mode=create %} )
    RETURN ' || CASE WHEN NOT g_status.xmltype_column_present THEN '
      {% LIST_COLUMNS_W_PK_FULL %}
    BULK COLLECT INTO v_return;'
                ELSE '
      {% LIST_PK_NAMES %}
    BULK COLLECT INTO v_pk_tab;

    /*records have to be bulk-fetched again, because XMLType column can not be returned*/
    OPEN v_strong_ref_cursor FOR
      SELECT
        data_table.*
      FROM
        {{ TABLE_NAME }} data_table
        INNER JOIN TABLE(v_pk_tab) pk_collection
          ON {% LIST_PK_COLUMN_BULK_FETCH %};

    /*no loop required here, because maximum bulk limit already given by the size of p_rows_tab*/
    v_return := read_rows (
      p_ref_cursor => v_strong_ref_cursor );

    CLOSE v_strong_ref_cursor;' END || '
    RETURN v_return;
  END create_rows;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_create_rows_bulk_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_create_rows_bulk_prc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_create_rows_bulk_prc');

      g_code_blocks.template := '
  PROCEDURE create_rows (
    {{ TABTYPE_PARAM }} );';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  PROCEDURE create_rows (
    {{ TABTYPE_PARAM }} )
  IS
    v_return t_rows_tab;
  BEGIN
    v_return := create_rows(p_rows_tab => p_rows_tab);
  END create_rows;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_create_rows_bulk_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_read_row_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_read_row_fnc');

      g_code_blocks.template := '
  FUNCTION read_row (
    {% LIST_PK_PARAMS %} )
  RETURN {{ TABLE_NAME }}%ROWTYPE;';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  FUNCTION read_row (
    {% LIST_PK_PARAMS %} )
  RETURN {{ TABLE_NAME }}%ROWTYPE IS
    v_row {{ TABLE_NAME }}%ROWTYPE;
    CURSOR cur_row IS
      SELECT *
        FROM {{ TABLE_NAME }}
       WHERE {% LIST_PK_COLUMNS_WHERE_CLAUSE %};
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_row;
    CLOSE cur_row;
    RETURN v_row;
  END read_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_read_row_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_read_rows_bulk_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_read_rows_bulk_fnc');

      g_code_blocks.template := '
  FUNCTION read_rows (
    {{ REFCURSOR_PARAM }} )
  RETURN t_rows_tab;';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  FUNCTION read_rows (
    {{ REFCURSOR_PARAM }} )
  RETURN t_rows_tab
  IS
    v_return t_rows_tab;
  BEGIN
    IF (p_ref_cursor%ISOPEN) THEN
      g_bulk_completed := FALSE;
      FETCH p_ref_cursor BULK COLLECT INTO v_return LIMIT g_bulk_limit;
      IF (v_return.COUNT < g_bulk_limit) THEN
        g_bulk_completed := TRUE;
      END IF;
    END IF;
    RETURN v_return;
  END read_rows;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_read_rows_bulk_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_read_row_prc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_read_row_prc');

      g_code_blocks.template := '
  PROCEDURE read_row (
    {% LIST_PARAMS_W_PK_IO %} );';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  PROCEDURE read_row (
    {% LIST_PARAMS_W_PK_IO %} )
  IS
    v_row {{ TABLE_NAME }}%ROWTYPE;
  BEGIN
    v_row := read_row (
      {% LIST_PK_MAP_PARAM_EQ_PARAM %} );
    {% LIST_SET_PAR_EQ_ROWTYCOL_WO_PK %}
  END read_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_read_row_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_read_row_by_uk_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_read_row_by_uk_fnc');
      IF g_uk_constraints.count > 0 THEN
        FOR i IN 1 .. g_uk_constraints.count LOOP
          g_iterator.current_uk_constraint := g_uk_constraints(i).constraint_name;

          g_code_blocks.template           := '
  FUNCTION read_row (
    {% LIST_UK_PARAMS %} )
  RETURN {{ TABLE_NAME }}%ROWTYPE;';
          util_template_replace('API SPEC');

          g_code_blocks.template := '
  FUNCTION read_row (
    {% LIST_UK_PARAMS %} )
  RETURN {{ TABLE_NAME }}%ROWTYPE IS
    v_row {{ TABLE_NAME }}%ROWTYPE;
    CURSOR cur_row IS
      SELECT *
        FROM {{ TABLE_NAME }}
       WHERE {% LIST_UK_COLUMN_COMPARE %};
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_row;
    CLOSE cur_row;
    RETURN v_row;
  END;';
          util_template_replace('API BODY');

        END LOOP;
      END IF;
      util_debug_stop_one_step;
    END gen_read_row_by_uk_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_update_row_prc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_update_row_prc');

      g_code_blocks.template := '
  PROCEDURE update_row (
    {% LIST_PARAMS_W_PK %} );';
        util_template_replace('API SPEC');

        g_code_blocks.template := '
  PROCEDURE update_row (
    {% LIST_PARAMS_W_PK %} )
  IS
  BEGIN' || CASE WHEN g_status.number_of_data_columns > 0 THEN '
    UPDATE {{ TABLE_NAME }}
       SET {% LIST_SET_COL_EQ_PARAM_WO_PK %}
     WHERE {% LIST_PK_COLUMNS_WHERE_CLAUSE %};'
            ELSE '
    /*
    There is no column anymore to update! All remaining columns are part of the
    primary key, audit columns or excluded via exclude column list
    */
    NULL;'  END || '
  END update_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_update_row_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_update_rowtype_prc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_update_rowtype_prc');

      g_code_blocks.template := '
  PROCEDURE update_row (
    {{ ROWTYPE_PARAM }} );';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  PROCEDURE update_row (
    {{ ROWTYPE_PARAM }} )
  IS
  BEGIN
    update_row(
      {% LIST_MAP_PAR_EQ_ROWTYPCOL_W_PK %} );
  END update_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_update_rowtype_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_update_rows_bulk_prc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_update_rows_bulk_prc');

      g_code_blocks.template := '
  PROCEDURE update_rows (
    {{ TABTYPE_PARAM }} );';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  PROCEDURE update_rows (
    {{ TABTYPE_PARAM }} )
  IS
  BEGIN' || CASE WHEN g_status.number_of_data_columns > 0 THEN '
    FORALL i IN INDICES OF p_rows_tab
      UPDATE {{ TABLE_NAME }}
         SET {% LIST_SET_COL_EQ_PAR_BULK_WO_PK %}
       WHERE {% LIST_PK_COLUMN_BULK_COMPARE %};'
            ELSE '
    /*
    There is no column anymore to update! All remaining columns are part of the
    primary key, audit columns or excluded via exclude column list.
    */
    NULL;'  END || '
  END update_rows;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_update_rows_bulk_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_createorupdate_row_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_createorupdate_row_fnc');

      g_code_blocks.template := '
  FUNCTION create_or_update_row (
    {% LIST_PARAMS_W_PK %} )
  RETURN {{ RETURN_TYPE }};';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  FUNCTION create_or_update_row (
    {% LIST_PARAMS_W_PK %} )
  RETURN {{ RETURN_TYPE }} IS
    v_return {{ RETURN_TYPE }};
  BEGIN
    IF row_exists(
      {% LIST_PK_MAP_PARAM_EQ_PARAM %}
    )
    THEN
      update_row(
        {% LIST_MAP_PAR_EQ_PARAM_W_PK padding=8 %} );
      v_return := read_row (
        {% LIST_PK_MAP_PARAM_EQ_PARAM padding=8 %}
      ){{ RETURN_TYPE_READ_ROW }};
    ELSE
      v_return := create_row (
        {% LIST_MAP_PAR_EQ_PARAM_W_PK crud_mode=create padding=8 %} );
    END IF;
    RETURN v_return;
  END create_or_update_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_createorupdate_row_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_createorupdate_row_prc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_createorupdate_row_prc');

      g_code_blocks.template := '
  PROCEDURE create_or_update_row (
    {% LIST_PARAMS_W_PK %} );';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  PROCEDURE create_or_update_row (
    {% LIST_PARAMS_W_PK %} )
  IS
    v_return {{ RETURN_TYPE }};
  BEGIN
    v_return := create_or_update_row(
      {% LIST_MAP_PAR_EQ_PARAM_W_PK %} );
  END create_or_update_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_createorupdate_row_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_createorupdate_rowtype_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_createorupdate_rowtype_fnc');

      g_code_blocks.template := '
  FUNCTION create_or_update_row (
    {{ ROWTYPE_PARAM }} )
  RETURN {{ RETURN_TYPE }};';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  FUNCTION create_or_update_row (
    {{ ROWTYPE_PARAM }} )
  RETURN {{ RETURN_TYPE }} IS
    v_return {{ RETURN_TYPE }};
  BEGIN
    v_return := create_or_update_row(
      {% LIST_MAP_PAR_EQ_ROWTYPCOL_W_PK %} );
    RETURN v_return;
  END create_or_update_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_createorupdate_rowtype_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_createorupdate_rowtype_prc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_createorupdate_rowtype_prc');

      g_code_blocks.template := '
  PROCEDURE create_or_update_row (
    {{ ROWTYPE_PARAM }} );';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  PROCEDURE create_or_update_row (
    {{ ROWTYPE_PARAM }} )
  IS
    v_return {{ RETURN_TYPE }};
  BEGIN
    v_return := create_or_update_row(
      {% LIST_MAP_PAR_EQ_ROWTYPCOL_W_PK %} );
  END create_or_update_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_createorupdate_rowtype_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_delete_row_prc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_delete_row_prc');

      g_code_blocks.template := '
  PROCEDURE delete_row (
    {% LIST_PK_PARAMS %} );';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  PROCEDURE delete_row (
    {% LIST_PK_PARAMS %} )
  IS
  BEGIN
    DELETE FROM {{ TABLE_NAME }}
     WHERE {% LIST_PK_COLUMNS_WHERE_CLAUSE %};' || '
  END delete_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_delete_row_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_delete_rows_bulk_prc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_delete_row_prc');

      g_code_blocks.template := '
  PROCEDURE delete_rows (
    {{ TABTYPE_PARAM }} );';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  PROCEDURE delete_rows (
    {{ TABTYPE_PARAM }} )
  IS
  BEGIN
    FORALL i IN INDICES OF p_rows_tab
      DELETE FROM {{ TABLE_NAME }}
       WHERE {% LIST_PK_COLUMN_BULK_COMPARE %};
  END delete_rows;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_delete_rows_bulk_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_getter_functions IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_getter_functions');
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).is_pk_yn = 'N' THEN
          g_iterator.column_name := util_double_quote(g_columns(i).column_name);
          g_iterator.method_name := util_get_method_name(g_columns(i).column_name);

          g_code_blocks.template := '
  FUNCTION get_{{ I_METHOD_NAME }}(
    {% LIST_PK_PARAMS %} )
  RETURN {{ TABLE_NAME }}.{{ I_COLUMN_NAME }}%TYPE;';
          util_template_replace('API SPEC');

          g_code_blocks.template := '
  FUNCTION get_{{ I_METHOD_NAME }}(
    {% LIST_PK_PARAMS %} )
  RETURN {{ TABLE_NAME }}.{{ I_COLUMN_NAME }}%TYPE IS
  BEGIN
    RETURN read_row (
      {% LIST_PK_MAP_PARAM_EQ_PARAM %}
    ).{{ I_COLUMN_NAME }};
  END get_{{ I_METHOD_NAME }};';
          util_template_replace('API BODY');

        END IF;
      END LOOP;
      util_debug_stop_one_step;
    END gen_getter_functions;

    ------------------------------------------------------------------------

    PROCEDURE gen_setter_procedures IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_setter_procedures');
      FOR i IN 1 .. g_columns.count LOOP
        IF g_columns(i).is_excluded_yn = 'N'
        AND g_columns(i).is_pk_yn = 'N'
        AND g_columns(i).audit_type IS NULL
        AND g_columns(i).row_version_expression IS NULL THEN
          g_iterator.column_name    := util_double_quote(g_columns(i).column_name);
          g_iterator.method_name    := util_get_method_name(g_columns(i).column_name);
          g_iterator.parameter_name := util_get_parameter_name(g_columns(i).column_name, g_status.rpad_columns);
          g_iterator.old_value := util_get_vc2_4000_operation(p_data_type      => g_columns(i).data_type,
                                                              p_attribute_name => 'v_row.' || util_double_quote(g_columns(i).column_name));
          g_iterator.new_value := util_get_vc2_4000_operation(p_data_type      => g_columns(i).data_type,
                                                              p_attribute_name => g_iterator.parameter_name);

          g_code_blocks.template := '
  PROCEDURE set_{{ I_METHOD_NAME }} (
    {% LIST_PK_PARAMS %},
    {{ I_PARAMETER_NAME }} IN {{ TABLE_NAME }}.{{ I_COLUMN_NAME }}%TYPE );';
          util_template_replace('API SPEC');

          g_code_blocks.template := '
  PROCEDURE set_{{ I_METHOD_NAME }} (
    {% LIST_PK_PARAMS %},
    {{ I_PARAMETER_NAME }} IN {{ TABLE_NAME }}.{{ I_COLUMN_NAME }}%TYPE )
  IS
    v_row {{ TABLE_NAME }}%ROWTYPE;
  BEGIN
    UPDATE {{ TABLE_NAME }}
       SET {{ I_COLUMN_NAME }} = {{ I_PARAMETER_NAME }}
     WHERE {% LIST_PK_COLUMNS_WHERE_CLAUSE %};' || '
  END set_{{ I_METHOD_NAME }};';
          util_template_replace('API BODY');

        END IF;
      END LOOP;
      util_debug_stop_one_step;
    END gen_setter_procedures;

    -----------------------------------------------------------------------------

    PROCEDURE gen_get_a_row_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_get_a_row_fnc');

      g_code_blocks.template := '
  FUNCTION get_a_row
  RETURN {{ TABLE_NAME }}%ROWTYPE;
  /*
  Helper mainly for testing and dummy data generation purposes.
  Returns a row with (hopefully) complete default data.
  */';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  FUNCTION get_a_row
  RETURN {{ TABLE_NAME }}%ROWTYPE IS
    v_row {{ TABLE_NAME }}%ROWTYPE;
  BEGIN
    {% LIST_ROWCOLS_W_CUST_DEFAULTS %}
    return v_row;
  END get_a_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_get_a_row_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_create_a_row_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_create_a_row_fnc');

      g_code_blocks.template := '
  FUNCTION create_a_row (
    {% LIST_PARAMS_W_PK_CUST_DEFAULTS crud_mode=create %} )
  RETURN {{ RETURN_TYPE }};
  /*
  Helper mainly for testing and dummy data generation purposes.
  Create a new row without (hopefully) providing any parameters.
  */';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  FUNCTION create_a_row (
    {% LIST_PARAMS_W_PK_CUST_DEFAULTS crud_mode=create %} )
  RETURN {{ RETURN_TYPE }} IS
    v_return {{ RETURN_TYPE }};
  BEGIN
    v_return := create_row (
      {% LIST_MAP_PAR_EQ_PARAM_W_PK crud_mode=create %} );
    RETURN v_return;
  END create_a_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_create_a_row_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_create_a_row_prc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_create_a_row_prc');

      g_code_blocks.template := '
  PROCEDURE create_a_row (
    {% LIST_PARAMS_W_PK_CUST_DEFAULTS crud_mode=create %} );
  /*
  Helper mainly for testing and dummy data generation purposes.
  Create a new row without (hopefully) providing any parameters.
  */';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  PROCEDURE create_a_row (
    {% LIST_PARAMS_W_PK_CUST_DEFAULTS crud_mode=create %} )
  IS
    v_return {{ RETURN_TYPE }};
  BEGIN
    v_return := create_row (
      {% LIST_MAP_PAR_EQ_PARAM_W_PK crud_mode=create %} );
  END create_a_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_create_a_row_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_read_a_row_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_read_a_row_fnc');

      g_code_blocks.template := '
  FUNCTION read_a_row
  RETURN {{ TABLE_NAME }}%ROWTYPE;
  /*
  Helper mainly for testing and dummy data generation purposes.
  Fetch one row (the first the database delivers) without providing
  a primary key parameter.
  */';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
  FUNCTION read_a_row
  RETURN {{ TABLE_NAME }}%ROWTYPE IS
    v_row  {{ TABLE_NAME }}%ROWTYPE;
    CURSOR cur_row IS SELECT * FROM {{ TABLE_NAME }};
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_row;
    CLOSE cur_row;
    RETURN v_row;
  END read_a_row;';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_read_a_row_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_footer IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_footer');

      g_code_blocks.template := CASE WHEN g_params.enable_custom_defaults THEN '
  /*
  You can simply copy over the defaults to your generator call - the attribute "source" is ignored then.
  {% LIST_SPEC_CUSTOM_DEFAULTS %}
  */'                           END || '
END {{ API_NAME }};';
      util_template_replace('API SPEC');

      g_code_blocks.template := '
END {{ API_NAME }};';
      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_footer;

    -----------------------------------------------------------------------------

    PROCEDURE gen_dml_view IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_dml_view');

      g_code_blocks.template := '
CREATE OR REPLACE VIEW {{ OWNER }}.{{ DML_VIEW_NAME }} AS
SELECT {% LIST_COLUMNS_W_PK_FULL %}
  FROM {{ TABLE_NAME }}
  /*
  This is the DML view for the table {{ TABLE_NAME }}.
  - Generator:         {{ GENERATOR }}
  - Generator version: {{ GENERATOR_VERSION }}
  - Generator action:  {{ GENERATOR_ACTION }}
  - Generated at:      {{ GENERATED_AT }}
  - Generated by:      {{ GENERATED_BY }}
  */
  ';
      util_template_replace('VIEW');

      util_debug_stop_one_step;
    END gen_dml_view;

    -----------------------------------------------------------------------------

    PROCEDURE gen_dml_view_trigger IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_dml_view_trigger');

      g_code_blocks.template := '
CREATE OR REPLACE TRIGGER {{ OWNER }}.{{ TRIGGER_NAME }}
  INSTEAD OF INSERT OR UPDATE OR DELETE
  ON {{ DML_VIEW_NAME }}
  FOR EACH ROW
  /*
  This is the instead of trigger for the DML view of the table {{ TABLE_NAME }}.
  - Generator:         {{ GENERATOR }}
  - Generator version: {{ GENERATOR_VERSION }}
  - Generator action:  {{ GENERATOR_ACTION }}
  - Generated at:      {{ GENERATED_AT }}
  - Generated by:      {{ GENERATED_BY }}
  */
BEGIN
  IF INSERTING THEN' || CASE WHEN g_params.enable_insertion_of_rows THEN '
    {{ API_NAME }}.create_row (
      {% LIST_MAP_PAR_EQ_NEWCOL_W_PK crud_mode=create %} );'
                        ELSE '
    raise_application_error ({{ GENERATOR_ERROR_NUMBER }}, ''Insertion of a row is not allowed.'');'
                        END || '
  ELSIF UPDATING THEN' || CASE WHEN g_params.enable_update_of_rows THEN '
    {{ API_NAME }}.update_row (
      {% LIST_MAP_PAR_EQ_NEWCOL_W_PK %} );'
                          ELSE '
    raise_application_error ({{ GENERATOR_ERROR_NUMBER }}, ''Update of a row is not allowed.'');'
                          END || '
  ELSIF DELETING THEN' || CASE WHEN g_params.enable_deletion_of_rows THEN '
    {{ API_NAME }}.delete_row (
      {% LIST_PK_MAP_PARAM_EQ_OLDCOL %} );'
                          ELSE '
    raise_application_error ({{ GENERATOR_ERROR_NUMBER }}, ''Deletion of a row is not allowed.'');'
                          END || '
  END IF;
END {{ TRIGGER_NAME }};';
      util_template_replace('TRIGGER');

      util_debug_stop_one_step;
    END gen_dml_view_trigger;

    -----------------------------------------------------------------------------

    PROCEDURE gen_one_to_one_view IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_one_to_one_view');

      g_code_blocks.template := '
CREATE OR REPLACE VIEW {{ OWNER }}.{{ ONE_TO_ONE_VIEW_NAME }} AS
SELECT {% LIST_COLUMNS_W_PK_FULL %}
  FROM {{ TABLE_NAME }}
  WITH READ ONLY
  /*
  This is the 1:1 view for the table {{ TABLE_NAME }}.
  - Generator:         {{ GENERATOR }}
  - Generator version: {{ GENERATOR_VERSION }}
  - Generator action:  {{ GENERATOR_ACTION }}
  - Generated at:      {{ GENERATED_AT }}
  - Generated by:      {{ GENERATED_BY }}
  */
  ';
      util_template_replace('1:1 VIEW');

      util_debug_stop_one_step;
    END gen_one_to_one_view;

    -----------------------------------------------------------------------------

    PROCEDURE gen_finalize_clob_vc2_caching IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_finalize_clob_vc2_caching');
      util_clob_append(p_clob               => g_code_blocks.api_spec,
                       p_clob_varchar_cache => g_code_blocks.api_spec_varchar_cache,
                       p_varchar_to_append  => NULL,
                       p_final_call         => TRUE);

      util_clob_append(p_clob               => g_code_blocks.api_body,
                       p_clob_varchar_cache => g_code_blocks.api_body_varchar_cache,
                       p_varchar_to_append  => NULL,
                       p_final_call         => TRUE);

      IF g_params.enable_dml_view THEN
        util_clob_append(p_clob               => g_code_blocks.dml_view,
                         p_clob_varchar_cache => g_code_blocks.dml_view_varchar_cache,
                         p_varchar_to_append  => NULL,
                         p_final_call         => TRUE);

        util_clob_append(p_clob               => g_code_blocks.dml_view_trigger,
                         p_clob_varchar_cache => g_code_blocks.dml_view_trigger_varchar_cache,
                         p_varchar_to_append  => NULL,
                         p_final_call         => TRUE);
      END IF;
      IF g_params.enable_one_to_one_view THEN
        util_clob_append(p_clob               => g_code_blocks.one_to_one_view,
                         p_clob_varchar_cache => g_code_blocks.one_to_one_view_varchar_cache,
                         p_varchar_to_append  => NULL,
                         p_final_call         => TRUE);
      END IF;
      util_debug_stop_one_step;
    END gen_finalize_clob_vc2_caching;
  BEGIN
    gen_header;

    -- bulk header if choosen
    gen_bulk_types;
    gen_bulk_is_complete_fnc;
    gen_set_bulk_limit_prc;
    gen_get_bulk_limit_fnc;

    IF g_status.xmltype_column_present THEN
      gen_xml_compare_fnc;
    END IF;

    gen_row_exists_fnc;
    gen_row_exists_yn_fnc;

    -- GET_PK_BY_UNIQUE_COLS methods only if no multi row pk is present
    -- use overloaded READ_ROW methods with unique params instead
    IF NOT g_status.pk_is_multi_column THEN
      gen_get_pk_by_unique_cols_fnc;
    END IF;

    -- CREATE methods
    IF g_params.enable_insertion_of_rows THEN
      gen_create_row_fnc;
      gen_create_row_prc;
      gen_create_rowtype_fnc;
      gen_create_rowtype_prc;
      gen_create_rows_bulk_fnc;
      gen_create_rows_bulk_prc;
    END IF;

    -- READ methods
    gen_read_row_fnc;
    gen_read_row_by_uk_fnc;
    IF g_params.enable_proc_with_out_params THEN
      gen_read_row_prc;
    END IF;
    gen_read_rows_bulk_fnc;

    -- UPDATE methods
    IF g_params.enable_update_of_rows THEN
      gen_update_row_prc;
      gen_update_rowtype_prc;
      gen_update_rows_bulk_prc;
    END IF;

    -- DELETE methods
    IF g_params.enable_deletion_of_rows THEN
      gen_delete_row_prc;
      gen_delete_rows_bulk_prc;
    END IF;

    -- CREATE or UPDATE methods
    IF g_params.enable_insertion_of_rows AND g_params.enable_update_of_rows THEN
      gen_createorupdate_row_fnc;
      gen_createorupdate_row_prc;
      gen_createorupdate_rowtype_fnc;
      gen_createorupdate_rowtype_prc;
    END IF;

    -- GETTER methods
    IF g_params.enable_getter_and_setter THEN
      gen_getter_functions;
    END IF;

    -- SETTER methods
    IF g_params.enable_update_of_rows AND g_params.enable_getter_and_setter THEN
      gen_setter_procedures;
    END IF;

    -- Some special stuff for the testing folks - thanks to Jacek Gębal ;-)
    IF g_params.enable_custom_defaults THEN
      gen_get_a_row_fnc;
      gen_create_a_row_fnc;
      gen_create_a_row_prc;
      gen_read_a_row_fnc;
    END IF;

    gen_footer;

    -- DML View and Trigger
    IF g_params.enable_dml_view THEN
      gen_dml_view;
      gen_dml_view_trigger;
    END IF;

    -- 1:1 View
    IF g_params.enable_one_to_one_view THEN
      gen_one_to_one_view;
    END IF;

    gen_finalize_clob_vc2_caching;

  END main_generate_code;

  -----------------------------------------------------------------------------

  PROCEDURE main_compile_code IS
    --
    PROCEDURE compile_api_spec IS
    BEGIN
      util_debug_start_one_step(p_action => 'compile_api_spec');
      util_execute_sql(g_code_blocks.api_spec);
      util_debug_stop_one_step;
    EXCEPTION
      WHEN OTHERS THEN
        util_debug_stop_one_step;
    END compile_api_spec;
    --
    PROCEDURE compile_api_body IS
    BEGIN
      util_debug_start_one_step(p_action => 'compile_api_body');
      util_execute_sql(g_code_blocks.api_body);
      util_debug_stop_one_step;
    EXCEPTION
      WHEN OTHERS THEN
        util_debug_stop_one_step;
    END compile_api_body;
    --
    PROCEDURE compile_dml_view IS
    BEGIN
      util_debug_start_one_step(p_action => 'compile_dml_view');
      util_execute_sql(g_code_blocks.dml_view);
      util_debug_stop_one_step;
    EXCEPTION
      WHEN OTHERS THEN
        util_debug_stop_one_step;
    END compile_dml_view;
    --
    PROCEDURE compile_dml_view_trigger IS
    BEGIN
      util_debug_start_one_step(p_action => 'compile_dml_view_trigger');
      util_execute_sql(g_code_blocks.dml_view_trigger);
      util_debug_stop_one_step;
    EXCEPTION
      WHEN OTHERS THEN
        util_debug_stop_one_step;
    END compile_dml_view_trigger;
    --
    PROCEDURE compile_one_to_one_view IS
    BEGIN
      util_debug_start_one_step(p_action => 'compile_one_to_one_view');
      util_execute_sql(g_code_blocks.one_to_one_view);
      util_debug_stop_one_step;
    EXCEPTION
      WHEN OTHERS THEN
        util_debug_stop_one_step;
    END compile_one_to_one_view;
    --
  BEGIN
    compile_api_spec;
    compile_api_body;
    IF g_params.enable_dml_view THEN
      compile_dml_view;
      compile_dml_view_trigger;
    END IF;
    IF g_params.enable_one_to_one_view THEN
      compile_one_to_one_view;
    END IF;
  END main_compile_code;

  -----------------------------------------------------------------------------

  FUNCTION main_return_code RETURN CLOB IS
    terminator t_vc2_5 := c_lf || '/' || c_lflf;
  BEGIN
    RETURN
      g_code_blocks.api_spec || terminator ||
      g_code_blocks.api_body || terminator ||
      CASE WHEN g_params.enable_dml_view THEN
        g_code_blocks.dml_view || terminator ||
        g_code_blocks.dml_view_trigger || terminator
      END ||
      CASE WHEN g_params.enable_one_to_one_view THEN
        g_code_blocks.one_to_one_view || terminator
      END;
  END main_return_code;

  -----------------------------------------------------------------------------

  PROCEDURE compile_api
  (
    p_table_name                  IN VARCHAR2,
    p_owner                       IN VARCHAR2 DEFAULT USER,
    p_enable_insertion_of_rows    IN BOOLEAN DEFAULT TRUE,
    p_enable_column_defaults      IN BOOLEAN DEFAULT FALSE,
    p_enable_update_of_rows       IN BOOLEAN DEFAULT TRUE,
    p_enable_deletion_of_rows     IN BOOLEAN DEFAULT FALSE,
    p_enable_parameter_prefixes   IN BOOLEAN DEFAULT TRUE,
    p_enable_proc_with_out_params IN BOOLEAN DEFAULT TRUE,
    p_enable_getter_and_setter    IN BOOLEAN DEFAULT TRUE,
    p_col_prefix_in_method_names  IN BOOLEAN DEFAULT TRUE,
    p_return_row_instead_of_pk    IN BOOLEAN DEFAULT FALSE,
    p_double_quote_names          IN BOOLEAN DEFAULT TRUE,
    p_default_bulk_limit          IN INTEGER DEFAULT 1000,
    p_enable_dml_view             IN BOOLEAN DEFAULT FALSE,
    p_enable_one_to_one_view      IN BOOLEAN DEFAULT FALSE,
    p_api_name                    IN VARCHAR2 DEFAULT NULL,
    p_sequence_name               IN VARCHAR2 DEFAULT NULL,
    p_exclude_column_list         IN VARCHAR2 DEFAULT NULL,
    p_audit_column_mappings       IN VARCHAR2 DEFAULT NULL,
    p_audit_user_expression       IN VARCHAR2 DEFAULT c_audit_user_expression,
    p_row_version_column_mapping  IN VARCHAR2 DEFAULT NULL,
    p_enable_custom_defaults      IN BOOLEAN DEFAULT FALSE,
    p_custom_default_values       IN XMLTYPE DEFAULT NULL
  ) IS
  BEGIN
    util_debug_start_one_run(p_generator_action => 'compile API', p_table_name => p_table_name, p_owner => p_owner);
    main_init(p_generator_action            => 'COMPILE_API',
              p_table_name                  => p_table_name,
              p_owner                       => p_owner,
              p_enable_insertion_of_rows    => p_enable_insertion_of_rows,
              p_enable_column_defaults      => p_enable_column_defaults,
              p_enable_update_of_rows       => p_enable_update_of_rows,
              p_enable_deletion_of_rows     => p_enable_deletion_of_rows,
              p_enable_parameter_prefixes   => p_enable_parameter_prefixes,
              p_enable_proc_with_out_params => p_enable_proc_with_out_params,
              p_enable_getter_and_setter    => p_enable_getter_and_setter,
              p_col_prefix_in_method_names  => p_col_prefix_in_method_names,
              p_return_row_instead_of_pk    => p_return_row_instead_of_pk,
              p_double_quote_names          => p_double_quote_names,
              p_default_bulk_limit          => p_default_bulk_limit,
              p_enable_dml_view             => p_enable_dml_view,
              p_enable_one_to_one_view      => p_enable_one_to_one_view,
              p_api_name                    => p_api_name,
              p_sequence_name               => p_sequence_name,
              p_exclude_column_list         => p_exclude_column_list,
              p_audit_column_mappings       => p_audit_column_mappings,
              p_audit_user_expression       => p_audit_user_expression,
              p_row_version_column_mapping  => p_row_version_column_mapping,
              p_enable_custom_defaults      => p_enable_custom_defaults,
              p_custom_default_values       => p_custom_default_values);
    main_generate_code;
    main_compile_code;
    util_debug_stop_one_run;
  END compile_api;

  -----------------------------------------------------------------------------

  FUNCTION compile_api_and_get_code
  (
    p_table_name                  IN VARCHAR2,
    p_owner                       IN VARCHAR2 DEFAULT USER,
    p_enable_insertion_of_rows    IN BOOLEAN DEFAULT TRUE,
    p_enable_column_defaults      IN BOOLEAN DEFAULT FALSE,
    p_enable_update_of_rows       IN BOOLEAN DEFAULT TRUE,
    p_enable_deletion_of_rows     IN BOOLEAN DEFAULT FALSE,
    p_enable_parameter_prefixes   IN BOOLEAN DEFAULT TRUE,
    p_enable_proc_with_out_params IN BOOLEAN DEFAULT TRUE,
    p_enable_getter_and_setter    IN BOOLEAN DEFAULT TRUE,
    p_col_prefix_in_method_names  IN BOOLEAN DEFAULT TRUE,
    p_return_row_instead_of_pk    IN BOOLEAN DEFAULT FALSE,
    p_double_quote_names          IN BOOLEAN DEFAULT TRUE,
    p_default_bulk_limit          IN INTEGER DEFAULT 1000,
    p_enable_dml_view             IN BOOLEAN DEFAULT FALSE,
    p_enable_one_to_one_view      IN BOOLEAN DEFAULT FALSE,
    p_api_name                    IN VARCHAR2 DEFAULT NULL,
    p_sequence_name               IN VARCHAR2 DEFAULT NULL,
    p_exclude_column_list         IN VARCHAR2 DEFAULT NULL,
    p_audit_column_mappings       IN VARCHAR2 DEFAULT NULL,
    p_audit_user_expression       IN VARCHAR2 DEFAULT c_audit_user_expression,
    p_row_version_column_mapping  IN VARCHAR2 DEFAULT NULL,
    p_enable_custom_defaults      IN BOOLEAN DEFAULT FALSE,
    p_custom_default_values       IN XMLTYPE DEFAULT NULL
  ) RETURN CLOB IS
  BEGIN
    util_debug_start_one_run(p_generator_action => 'compile API, get code',
                             p_table_name       => p_table_name,
                             p_owner            => p_owner);

    main_init(p_generator_action            => 'COMPILE_API_AND_GET_CODE',
              p_table_name                  => p_table_name,
              p_owner                       => p_owner,
              p_enable_insertion_of_rows    => p_enable_insertion_of_rows,
              p_enable_column_defaults      => p_enable_column_defaults,
              p_enable_update_of_rows       => p_enable_update_of_rows,
              p_enable_deletion_of_rows     => p_enable_deletion_of_rows,
              p_enable_parameter_prefixes   => p_enable_parameter_prefixes,
              p_enable_proc_with_out_params => p_enable_proc_with_out_params,
              p_enable_getter_and_setter    => p_enable_getter_and_setter,
              p_col_prefix_in_method_names  => p_col_prefix_in_method_names,
              p_return_row_instead_of_pk    => p_return_row_instead_of_pk,
              p_double_quote_names          => p_double_quote_names,
              p_default_bulk_limit          => p_default_bulk_limit,
              p_enable_dml_view             => p_enable_dml_view,
              p_enable_one_to_one_view      => p_enable_one_to_one_view,
              p_api_name                    => p_api_name,
              p_sequence_name               => p_sequence_name,
              p_exclude_column_list         => p_exclude_column_list,
              p_audit_column_mappings       => p_audit_column_mappings,
              p_audit_user_expression       => p_audit_user_expression,
              p_row_version_column_mapping  => p_row_version_column_mapping,
              p_enable_custom_defaults      => p_enable_custom_defaults,
              p_custom_default_values       => p_custom_default_values);
    main_generate_code;
    main_compile_code;
    util_debug_stop_one_run;
    RETURN main_return_code;
  END compile_api_and_get_code;

  -----------------------------------------------------------------------------

  FUNCTION get_code
  (
    p_table_name                  IN VARCHAR2,
    p_owner                       IN VARCHAR2 DEFAULT USER,
    p_enable_insertion_of_rows    IN BOOLEAN DEFAULT TRUE,
    p_enable_column_defaults      IN BOOLEAN DEFAULT FALSE,
    p_enable_update_of_rows       IN BOOLEAN DEFAULT TRUE,
    p_enable_deletion_of_rows     IN BOOLEAN DEFAULT FALSE,
    p_enable_parameter_prefixes   IN BOOLEAN DEFAULT TRUE,
    p_enable_proc_with_out_params IN BOOLEAN DEFAULT TRUE,
    p_enable_getter_and_setter    IN BOOLEAN DEFAULT TRUE,
    p_col_prefix_in_method_names  IN BOOLEAN DEFAULT TRUE,
    p_return_row_instead_of_pk    IN BOOLEAN DEFAULT FALSE,
    p_double_quote_names          IN BOOLEAN DEFAULT TRUE,
    p_default_bulk_limit          IN INTEGER DEFAULT 1000,
    p_enable_dml_view             IN BOOLEAN DEFAULT FALSE,
    p_enable_one_to_one_view      IN BOOLEAN DEFAULT FALSE,
    p_api_name                    IN VARCHAR2 DEFAULT NULL,
    p_sequence_name               IN VARCHAR2 DEFAULT NULL,
    p_exclude_column_list         IN VARCHAR2 DEFAULT NULL,
    p_audit_column_mappings       IN VARCHAR2 DEFAULT NULL,
    p_audit_user_expression       IN VARCHAR2 DEFAULT c_audit_user_expression,
    p_row_version_column_mapping  IN VARCHAR2 DEFAULT NULL,
    p_enable_custom_defaults      IN BOOLEAN DEFAULT FALSE,
    p_custom_default_values       IN XMLTYPE DEFAULT NULL
  ) RETURN CLOB IS
  BEGIN
    util_debug_start_one_run(p_generator_action => 'get code', p_table_name => p_table_name, p_owner => p_owner);
    main_init(p_generator_action            => 'GET_CODE',
              p_table_name                  => p_table_name,
              p_owner                       => p_owner,
              p_enable_insertion_of_rows    => p_enable_insertion_of_rows,
              p_enable_column_defaults      => p_enable_column_defaults,
              p_enable_update_of_rows       => p_enable_update_of_rows,
              p_enable_deletion_of_rows     => p_enable_deletion_of_rows,
              p_enable_parameter_prefixes   => p_enable_parameter_prefixes,
              p_enable_proc_with_out_params => p_enable_proc_with_out_params,
              p_enable_getter_and_setter    => p_enable_getter_and_setter,
              p_col_prefix_in_method_names  => p_col_prefix_in_method_names,
              p_return_row_instead_of_pk    => p_return_row_instead_of_pk,
              p_double_quote_names          => p_double_quote_names,
              p_default_bulk_limit          => p_default_bulk_limit,
              p_enable_dml_view             => p_enable_dml_view,
              p_enable_one_to_one_view      => p_enable_one_to_one_view,
              p_api_name                    => p_api_name,
              p_sequence_name               => p_sequence_name,
              p_exclude_column_list         => p_exclude_column_list,
              p_audit_column_mappings       => p_audit_column_mappings,
              p_audit_user_expression       => p_audit_user_expression,
              p_row_version_column_mapping  => p_row_version_column_mapping,
              p_enable_custom_defaults      => p_enable_custom_defaults,
              p_custom_default_values       => p_custom_default_values);
    main_generate_code;
    util_debug_stop_one_run;
    RETURN main_return_code;
  END get_code;

  -----------------------------------------------------------------------------

  FUNCTION view_existing_apis
  (
    p_table_name IN VARCHAR2 DEFAULT NULL,
    p_owner      IN VARCHAR2 DEFAULT USER
  ) RETURN t_tab_existing_apis
    PIPELINED IS
    v_tab t_tab_existing_apis;
    v_row t_rec_existing_apis;
    v_sql t_vc2_16k;
  BEGIN
    -- I was not able to compile without execute immediate - got a strange ORA-03113.
    -- Direct execution of the statement in SQL tool works :-(
    v_sql := q'[
-- ATTENTION: query columns need to match the global row definition om_tapigen.g_row_existing_apis.
-- Creating a cursor was not possible - database throws an error

WITH api_names AS (
         SELECT owner,
                NAME AS api_name
           FROM all_source
          WHERE     owner = :p_owner
                AND TYPE = 'PACKAGE'
                AND line BETWEEN :spec_options_min_line
                             AND :spec_options_max_line
                AND INSTR (text,'generator="OM_TAPIGEN"') > 0
     ) -- select * from api_names;
     , sources AS (
         SELECT owner,
                package_name,
                XMLTYPE (
                   NVL (REGEXP_SUBSTR (REPLACE (source_code, '*', NULL), -- replace needed for backward compatibility of old comment style
                                       '<options.*>',
                                       1,
                                       1,
                                       'ni'),
                        '<no_data_found/>'))
                   AS options
           FROM (SELECT owner,
                        NAME AS package_name,
                        LISTAGG (text, ' ')
                           WITHIN GROUP (ORDER BY NAME, line)
                           OVER (PARTITION BY NAME)
                           AS source_code
                   FROM all_source
                  WHERE     owner = :p_owner
                        AND name  IN (SELECT api_name FROM api_names)
                        AND TYPE  = 'PACKAGE'
                        AND line  BETWEEN :spec_options_min_line
                                      AND :spec_options_max_line)
          GROUP BY owner, package_name, source_code
     ) -- select * from sources;
     , apis AS (
         SELECT t.owner,
                x.p_table_name AS table_name,
                t.package_name,
                x.generator,
                x.generator_version,
                x.generator_action,
                TO_DATE (x.generated_at,'yyyy-mm-dd hh24:mi:ss') AS generated_at,
                x.generated_by,
                x.p_owner,
                x.p_table_name,
                x.p_enable_insertion_of_rows,
                x.p_enable_column_defaults,
                x.p_enable_update_of_rows,
                x.p_enable_deletion_of_rows,
                x.p_enable_parameter_prefixes,
                x.p_enable_proc_with_out_params,
                x.p_enable_getter_and_setter,
                x.p_col_prefix_in_method_names,
                x.p_return_row_instead_of_pk,
                x.p_double_quote_names,
                x.p_default_bulk_limit,
                x.p_enable_dml_view,
                x.p_enable_one_to_one_view,
                x.p_api_name,
                x.p_sequence_name,
                x.p_exclude_column_list,
                x.p_audit_column_mappings,
                x.p_audit_user_expression,
                x.p_row_version_column_mapping,
                x.p_enable_custom_defaults,
                x.p_custom_default_values
           FROM sources t
                CROSS JOIN
                XMLTABLE (
                   '/options'
                   PASSING options
                   COLUMNS generator                     VARCHAR2 (30 CHAR)   PATH '@generator',
                           generator_version             VARCHAR2 (10 CHAR)   PATH '@generator_version',
                           generator_action              VARCHAR2 (30 CHAR)   PATH '@generator_action',
                           generated_at                  VARCHAR2 (30 CHAR)   PATH '@generated_at',
                           generated_by                  VARCHAR2 (128 CHAR)  PATH '@generated_by',
                           p_owner                       VARCHAR2 (128 CHAR)  PATH '@p_owner',
                           p_table_name                  VARCHAR2 (128 CHAR)  PATH '@p_table_name',
                           p_enable_insertion_of_rows    VARCHAR2 (5 CHAR)    PATH '@p_enable_insertion_of_rows',
                           p_enable_column_defaults      VARCHAR2 (5 CHAR)    PATH '@p_enable_column_defaults',
                           p_enable_update_of_rows       VARCHAR2 (5 CHAR)    PATH '@p_enable_update_of_rows',
                           p_enable_deletion_of_rows     VARCHAR2 (5 CHAR)    PATH '@p_enable_deletion_of_rows',
                           p_enable_parameter_prefixes   VARCHAR2 (5 CHAR)    PATH '@p_enable_parameter_prefixes',
                           p_enable_proc_with_out_params VARCHAR2 (5 CHAR)    PATH '@p_enable_proc_with_out_params',
                           p_enable_getter_and_setter    VARCHAR2 (5 CHAR)    PATH '@p_enable_getter_and_setter',
                           p_col_prefix_in_method_names  VARCHAR2 (5 CHAR)    PATH '@p_col_prefix_in_method_names',
                           p_return_row_instead_of_pk    VARCHAR2 (5 CHAR)    PATH '@p_return_row_instead_of_pk',
                           p_double_quote_names          VARCHAR2 (5 CHAR)    PATH '@p_double_quote_names',
                           p_default_bulk_limit          INTEGER              PATH '@p_default_bulk_limit',
                           p_enable_dml_view             VARCHAR2 (5 CHAR)    PATH '@p_enable_dml_view',
                           p_enable_one_to_one_view      VARCHAR2 (5 CHAR)    PATH '@p_enable_one_to_one_view',
                           p_api_name                    VARCHAR2 (128 CHAR)  PATH '@p_api_name',
                           p_sequence_name               VARCHAR2 (128 CHAR)  PATH '@p_sequence_name',
                           p_exclude_column_list         VARCHAR2 (4000 CHAR) PATH '@p_exclude_column_list',
                           p_audit_column_mappings       VARCHAR2 (4000 CHAR) PATH '@p_audit_column_mappings',
                           p_audit_user_expression       VARCHAR2 (4000 CHAR) PATH '@p_audit_user_expression',
                           p_row_version_column_mapping  VARCHAR2 (4000 CHAR) PATH '@p_row_version_column_mapping',
                           p_enable_custom_defaults      VARCHAR2 (5 CHAR)    PATH '@p_enable_custom_defaults',
                           p_custom_default_values       VARCHAR2 (30 CHAR)   PATH '@p_custom_default_values') x
     ) -- select * from apis;
     , objects AS (
         SELECT specs.object_name   AS package_name,
                specs.status        AS spec_status,
                specs.last_ddl_time AS spec_last_ddl_time,
                bodys.status        AS body_status,
                bodys.last_ddl_time AS body_last_ddl_time
           FROM (SELECT object_name,
                        object_type,
                        status,
                        last_ddl_time
                   FROM all_objects
                  WHERE     owner       = :p_owner
                        AND object_type = 'PACKAGE'
                        AND object_name IN (SELECT api_name FROM api_names))
                specs
                LEFT JOIN
                (SELECT object_name,
                        object_type,
                        status,
                        last_ddl_time
                   FROM all_objects
                  WHERE     owner       = :p_owner
                        AND object_type = 'PACKAGE BODY'
                        AND object_name IN (SELECT api_name FROM api_names))
                bodys
                   ON     specs.object_name              = bodys.object_name
                      AND specs.object_type || ' BODY' = bodys.object_type
     ) -- select * from objects;
SELECT NULL AS errors,
       apis.owner,
       apis.table_name,
       objects.package_name,
       objects.spec_status,
       objects.spec_last_ddl_time,
       objects.body_status,
       objects.body_last_ddl_time,
       apis.generator,
       apis.generator_version,
       apis.generator_action,
       apis.generated_at,
       apis.generated_by,
       apis.p_owner,
       apis.p_table_name,
       apis.p_enable_insertion_of_rows,
       apis.p_enable_column_defaults,
       apis.p_enable_update_of_rows,
       apis.p_enable_deletion_of_rows,
       apis.p_enable_parameter_prefixes,
       apis.p_enable_proc_with_out_params,
       apis.p_enable_getter_and_setter,
       apis.p_col_prefix_in_method_names,
       apis.p_return_row_instead_of_pk,
       apis.p_double_quote_names,
       apis.p_default_bulk_limit,
       apis.p_enable_dml_view,
       apis.p_enable_one_to_one_view,
       apis.p_api_name,
       apis.p_sequence_name,
       apis.p_exclude_column_list,
       apis.p_audit_column_mappings,
       apis.p_audit_user_expression,
       apis.p_row_version_column_mapping,
       apis.p_enable_custom_defaults,
       apis.p_custom_default_values
  FROM apis JOIN objects ON apis.package_name = objects.package_name
 WHERE table_name = NVL ( :p_table_name, table_name)
      ]';
      EXECUTE IMMEDIATE v_sql
      BULK COLLECT
      INTO v_tab
      USING p_owner, c_spec_options_min_line, c_spec_options_max_line, p_owner, c_spec_options_min_line, c_spec_options_max_line, p_owner, p_owner, p_table_name;
    IF v_tab.count > 0 THEN
      FOR i IN 1 .. v_tab.count LOOP
        PIPE ROW(v_tab(i));
      END LOOP;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      v_row.errors := substr('Incomplete resultset! ' ||
                             'This is the last correct proccessed row from the pipelined function. ' ||
                             'Did you change the params XML in one of the API packages? Original error message: ' ||
                             c_lflf || SQLERRM || c_lflf || sys.dbms_utility.format_error_backtrace,
                             1,
                             4000);

      PIPE ROW(v_row);
  END view_existing_apis;

  -----------------------------------------------------------------------------

  FUNCTION view_naming_conflicts(p_owner IN VARCHAR2 DEFAULT USER) RETURN t_tab_naming_conflicts
    PIPELINED IS
  BEGIN
    FOR i IN (
      WITH
      ut AS (
        SELECT
          table_name,
          (SELECT om_tapigen.util_get_ora_max_name_len FROM dual) AS max_name_len
        FROM
          all_tables
        WHERE
          owner = p_owner
      ),
      temp AS (
        SELECT substr(table_name, 1, max_name_len - 4) || '_API' AS object_name FROM ut
        UNION ALL
        SELECT substr(table_name, 1, max_name_len - 6) || '_DML_V' FROM ut
        UNION ALL
        SELECT substr(table_name, 1, max_name_len - 6) || '_IOIUD' FROM ut
        UNION ALL
        SELECT substr(table_name, 1, max_name_len - 2) || '_V' FROM ut
      )
      SELECT
        uo.object_name,
        uo.object_type,
        uo.status,
        uo.last_ddl_time
      FROM
        all_objects uo
      WHERE
        owner = p_owner
        AND uo.object_name IN (SELECT t.object_name FROM temp t)
      ORDER BY
        uo.object_name
    ) LOOP
      PIPE ROW(i);
    END LOOP;
  END view_naming_conflicts;
END om_tapigen;
/
