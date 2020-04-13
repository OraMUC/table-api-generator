CREATE OR REPLACE PACKAGE BODY om_tapigen IS

  -----------------------------------------------------------------------------
  -- private global constants (c_*)
  -----------------------------------------------------------------------------
  c_generator_error_number      CONSTANT PLS_INTEGER := -20000;
  c_bulk_collect_limit          CONSTANT NUMBER := 10000;
  c_lf                          CONSTANT VARCHAR2(2 CHAR) := chr(10);
  c_lflf                        CONSTANT VARCHAR2(3 CHAR) := chr(10) || chr(10);
  c_list_delimiter              CONSTANT VARCHAR2(3 CHAR) := ',' || c_lf;
  c_custom_defaults_present_msg CONSTANT VARCHAR2(30) := 'SEE_END_OF_API_PACKAGE_SPEC';
  c_spec_options_min_line       CONSTANT NUMBER := 5;
  c_spec_options_max_line       CONSTANT NUMBER := 38;
  c_debug_max_runs              CONSTANT NUMBER := 1000;

  -----------------------------------------------------------------------------
  -- private record (t_rec_*) and collection (t_tab_*) types
  -----------------------------------------------------------------------------
  TYPE t_rec_params IS RECORD(
    table_name                  all_objects.object_name%TYPE,
    owner                       all_users.username%TYPE,
    reuse_existing_api_params   BOOLEAN,
    enable_insertion_of_rows    BOOLEAN,
    enable_column_defaults      BOOLEAN,
    enable_update_of_rows       BOOLEAN,
    enable_deletion_of_rows     BOOLEAN,
    enable_parameter_prefixes   BOOLEAN,
    enable_proc_with_out_params BOOLEAN,
    enable_getter_and_setter    BOOLEAN,
    col_prefix_in_method_names  BOOLEAN,
    return_row_instead_of_pk    BOOLEAN,
    enable_dml_view             BOOLEAN,
    enable_generic_change_log   BOOLEAN,
    api_name                    all_objects.object_name%TYPE,
    sequence_name               all_sequences.sequence_name%TYPE,
    exclude_column_list         VARCHAR2(4000 CHAR),
    audit_column_mappings       VARCHAR2(4000 CHAR),
    audit_user_expression       VARCHAR2(4000 CHAR),
    enable_custom_defaults      BOOLEAN,
    custom_default_values       xmltype,
    custom_defaults_serialized  VARCHAR2(32767 CHAR),
    enable_bulk_methods         BOOLEAN);

  TYPE t_rec_status IS RECORD(
    pk_is_multi_column     BOOLEAN,
    column_prefix          all_tab_cols.column_name%TYPE,
    xmltype_column_present BOOLEAN,
    generator_action       VARCHAR2(30 CHAR),
    api_exists             BOOLEAN,
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
    template                       VARCHAR2(32767 CHAR),
    api_spec                       CLOB,
    api_spec_varchar_cache         VARCHAR2(32767 CHAR),
    api_body                       CLOB,
    api_body_varchar_cache         VARCHAR2(32767 CHAR),
    dml_view                       CLOB,
    dml_view_varchar_cache         VARCHAR2(32767 CHAR),
    dml_view_trigger               CLOB,
    dml_view_trigger_varchar_cache VARCHAR2(32767 CHAR));

  --

  TYPE t_rec_template_options IS RECORD(
    use_column_defaults   BOOLEAN,
    hide_identity_columns BOOLEAN,
    padding               INTEGER);

  --

  TYPE t_tab_vc2_5k IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;

  --

  TYPE t_rec_iterator IS RECORD(
    column_name           all_tab_cols.column_name%TYPE,
    method_name           all_tab_cols.column_name%TYPE,
    parameter_name        all_tab_cols.column_name%TYPE,
    column_compare        VARCHAR2(512 CHAR),
    old_value             VARCHAR2(512 CHAR),
    new_value             VARCHAR2(512 CHAR),
    current_uk_constraint all_objects.object_name%TYPE);

  --

  TYPE t_rec_debug_details IS RECORD(
    step       INTEGER(4),
    module     st_session_module,
    action     st_session_action,
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
  g_debug_module  st_session_module;

  -- records
  g_params              t_rec_params;
  g_params_existing_api t_rec_existing_apis;
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
  CURSOR g_cur_columns IS
    WITH not_null_columns AS
     (SELECT CASE
               WHEN instr(column_name_nn, '"') = 0 THEN
                upper(column_name_nn)
               ELSE
                TRIM(both '"' FROM column_name_nn)
             END AS column_name_nn
        FROM (SELECT regexp_substr(
                                   $IF dbms_db_version.ver_le_11_1 $THEN om_tapigen.util_get_cons_search_condition(p_owner           => USER,
                                                                              p_constraint_name => constraint_name)
                                   $ELSE
                                   $IF dbms_db_version.ver_le_11_2 $THEN
                                    om_tapigen.util_get_cons_search_condition(p_owner           => USER,
                                                                              p_constraint_name => constraint_name)
                                   $ELSE search_condition_vc
                                   $END
                                   $END,
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
     (
      $IF dbms_db_version.ver_le_11_1 $THEN
      SELECT 'DUMMY_COLUMN_NAME' AS column_name_identity, NULL AS identity_type
        FROM dual
              $ELSE
              $IF dbms_db_version.ver_le_11_2 $THEN
                SELECT 'DUMMY_COLUMN_NAME' AS column_name_identity, NULL AS identity_type
                  FROM dual
                       $ELSE
                         SELECT column_name AS column_name_identity, generation_type AS identity_type
                           FROM all_tab_identity_cols
                          WHERE owner = g_params.owner
                            AND table_name = g_params.table_name
                         $END
                         $END



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
           'N' AS is_pk_yn,
           'N' AS is_uk_yn,
           'N' AS is_fk_yn,
           is_nullable_yn,
           is_excluded_yn,
           NULL AS audit_type,
           NULL AS r_owner,
           NULL AS r_table_name,
           NULL AS r_column_name
      FROM t;

  -----------------------------------------------------------------------------
  -- util_execute_sql is a private helper procedure that parses and executes
  -- generated code with the help of DBMS_SQL package. Execute immediate is not
  -- used here directly, because of the missing possibility of parsing a
  -- statement in a performant way. Executing immediate and catching
  -- the error is more expensive than parsing the statement and catching the
  -- error.
  -----------------------------------------------------------------------------
  PROCEDURE util_execute_sql(p_sql IN OUT NOCOPY CLOB) IS
    v_cursor      NUMBER;
    v_exec_result PLS_INTEGER;
  BEGIN
    v_cursor := dbms_sql.open_cursor;
    dbms_sql.parse(v_cursor, p_sql, dbms_sql.native);
    v_exec_result := dbms_sql.execute(v_cursor);
    dbms_sql.close_cursor(v_cursor);
  EXCEPTION
    WHEN OTHERS THEN
      dbms_sql.close_cursor(v_cursor);
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
    v_return VARCHAR2(100 CHAR);
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
  -- code for two attributes. In addition to that,the compare operation must
  -- be dynamically,because e.g. "=" or "<>" or other operations are required.
  -----------------------------------------------------------------------------
  FUNCTION util_get_attribute_compare
  (
    p_data_type         IN user_tab_cols.data_type%TYPE,
    p_nullable          IN BOOLEAN,
    p_first_attribute   IN VARCHAR2,
    p_second_attribute  IN VARCHAR2,
    p_compare_operation IN VARCHAR2 DEFAULT '<>'
  ) RETURN VARCHAR2 IS
    v_return VARCHAR2(1000 CHAR);
    FUNCTION get_coalesce(p_attribute VARCHAR2) RETURN VARCHAR2 IS
      v_return VARCHAR2(1000 CHAR);
    BEGIN
      v_return := CASE
                    WHEN NOT p_nullable THEN
                     p_attribute
                    ELSE
                     'COALESCE(' || p_attribute || ', ' || util_get_attribute_surrogate(p_data_type) || ')'
                  END;
      RETURN v_return;
    END;
  BEGIN
    v_return := CASE
                  WHEN p_data_type = 'XMLTYPE' THEN
                   'util_xml_compare( ' || get_coalesce(p_first_attribute) || ', ' || get_coalesce(p_second_attribute) || ') ' ||
                   p_compare_operation || ' 0'
                  WHEN p_data_type IN ('BLOB', 'CLOB') THEN
                   'DBMS_LOB.compare( ' || get_coalesce(p_first_attribute) || ',' || get_coalesce(p_second_attribute) || ') ' ||
                   p_compare_operation || ' 0'
                  ELSE
                   get_coalesce(p_first_attribute) || ' ' || p_compare_operation || ' ' ||
                   get_coalesce(p_second_attribute)
                END;

    RETURN v_return;
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
    v_return VARCHAR2(1000 CHAR);
  BEGIN
    v_return := CASE
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
    RETURN v_return;
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
    p_column_name VARCHAR2,
    p_rpad        INTEGER
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
    p_column_name VARCHAR2,
    p_rpad        INTEGER
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
  FUNCTION util_get_method_name(p_column_name VARCHAR2) RETURN VARCHAR2 IS
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
  END;

  -----------------------------------------------------------------------------

  FUNCTION util_get_substituted_name(p_name_template VARCHAR2) RETURN VARCHAR2 IS
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

        v_return := REPLACE(p_name_template,
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
    p_owner       VARCHAR2 DEFAULT USER
  ) RETURN VARCHAR2 AS
    v_return LONG;

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
  END;

  --------------------------------------------------------------------------------

  FUNCTION util_get_cons_search_condition
  (
    p_constraint_name IN VARCHAR2,
    p_owner           IN VARCHAR2 DEFAULT USER
  ) RETURN VARCHAR2 AS
    v_return LONG;

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
  END;

  -----------------------------------------------------------------------------

  FUNCTION util_get_ora_max_name_len RETURN INTEGER IS
  BEGIN
    RETURN c_ora_max_name_len;
  END;

  -----------------------------------------------------------------------------

  FUNCTION util_split_to_table
  (
    p_string    IN VARCHAR2,
    p_delimiter IN VARCHAR2 DEFAULT ','
  ) RETURN t_tab_vc2_4k
    PIPELINED IS
    v_offset           PLS_INTEGER := 1;
    v_index            PLS_INTEGER := instr(p_string, p_delimiter, v_offset);
    v_delimiter_length PLS_INTEGER := length(p_delimiter);
    v_string_length CONSTANT PLS_INTEGER := length(p_string);
  BEGIN
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

  FUNCTION util_serialize_xml(p_xml xmltype) RETURN VARCHAR2 IS
    v_return VARCHAR2(32767);
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
  END;

  --------------------------------------------------------------------------------

  PROCEDURE util_set_debug_off IS
  BEGIN
    g_debug_enabled := FALSE;
  END;

  PROCEDURE util_debug_start_one_run
  (
    p_generator_action VARCHAR2,
    p_table_name       all_objects.object_name%TYPE,
    p_owner            all_users.username%TYPE
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
  END;

  -----------------------------------------------------------------------------

  PROCEDURE util_debug_stop_one_run IS
  BEGIN
    IF g_debug_enabled AND g_debug_run <= c_debug_max_runs THEN
      g_debug(g_debug_run).stop_time := systimestamp;
    END IF;
  END;

  -----------------------------------------------------------------------------

  PROCEDURE util_debug_start_one_step(p_action VARCHAR2) IS
  BEGIN
    dbms_application_info.set_module(module_name => g_debug_module, action_name => p_action);
    IF g_debug_enabled AND g_debug_run <= c_debug_max_runs THEN
      g_debug_step := g_debug_step + 1;
      g_debug(g_debug_run).details(g_debug_step).step := g_debug_step;
      g_debug(g_debug_run).details(g_debug_step).module := g_debug_module;
      g_debug(g_debug_run).details(g_debug_step).action := p_action;
      g_debug(g_debug_run).details(g_debug_step).start_time := systimestamp;
    END IF;
  END;

  -----------------------------------------------------------------------------

  PROCEDURE util_debug_stop_one_step IS
  BEGIN
    dbms_application_info.set_module(module_name => NULL, action_name => NULL);
    IF g_debug_enabled AND g_debug_run <= c_debug_max_runs THEN
      g_debug(g_debug_run).details(g_debug_step).stop_time := systimestamp;
    END IF;
  END;

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

  END;

  -----------------------------------------------------------------------------

  FUNCTION util_view_columns_array RETURN t_tab_debug_columns
    PIPELINED IS
    v_return t_rec_columns;
  BEGIN
    FOR i IN 1 .. g_columns.count LOOP
      v_return.column_name           := g_columns(i).column_name;
      v_return.data_type             := g_columns(i).data_type;
      v_return.char_length           := g_columns(i).char_length;
      v_return.data_length           := g_columns(i).data_length;
      v_return.data_precision        := g_columns(i).data_precision;
      v_return.data_scale            := g_columns(i).data_scale;
      v_return.data_default          := g_columns(i).data_default;
      v_return.data_custom_default   := g_columns(i).data_custom_default;
      v_return.custom_default_source := g_columns(i).custom_default_source;
      v_return.identity_type         := g_columns(i).identity_type;
      v_return.is_pk_yn              := g_columns(i).is_pk_yn;
      v_return.is_uk_yn              := g_columns(i).is_uk_yn;
      v_return.is_fk_yn              := g_columns(i).is_fk_yn;
      v_return.is_nullable_yn        := g_columns(i).is_nullable_yn;
      v_return.is_excluded_yn        := g_columns(i).is_excluded_yn;
      v_return.audit_type            := g_columns(i).audit_type;
      v_return.r_owner               := g_columns(i).r_owner;
      v_return.r_table_name          := g_columns(i).r_table_name;
      v_return.r_column_name         := g_columns(i).r_column_name;
      PIPE ROW(v_return);
    END LOOP;
  END util_view_columns_array;

  --------------------------------------------------------------------------------

  FUNCTION util_get_ddl
  (
    p_object_type VARCHAR2,
    p_object_name VARCHAR2,
    p_owner       VARCHAR2 DEFAULT USER
  ) RETURN CLOB IS
    v_return CLOB;
    v_count  PLS_INTEGER;
  BEGIN
    IF p_object_type IN ('PACKAGE', 'PACKAGE BODY', 'VIEW', 'TRIGGER') THEN
      SELECT COUNT(*)
        INTO v_count
        FROM all_objects
       WHERE owner = p_owner
         AND object_type = p_object_type
         AND object_name = p_object_name;
      IF v_count = 1 THEN
        dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'SQLTERMINATOR', TRUE);
        dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'PRETTY', TRUE);
        CASE p_object_type
          WHEN 'PACKAGE' THEN
            v_return := dbms_metadata.get_ddl(object_type => 'PACKAGE_SPEC', NAME => p_object_name, SCHEMA => p_owner);
--            v_return := ltrim(substr(v_return, 1, instr(v_return, 'CREATE OR REPLACE PACKAGE') - 1),
--                              ' ' || chr(10));
          WHEN 'PACKAGE BODY' THEN
            v_return := dbms_metadata.get_ddl(object_type => 'PACKAGE_BODY', NAME => p_object_name, SCHEMA => p_owner);
--            v_return := substr(v_return, instr(v_return, 'CREATE OR REPLACE PACKAGE BODY'));
          WHEN 'VIEW' THEN
            v_return := ltrim(regexp_replace(regexp_replace(dbms_metadata.get_ddl(object_type => p_object_type,
                                                                                  NAME        => p_object_name,
                                                                                  SCHEMA      => p_owner),
                                                            '\(.*\) ', -- remove additional column list from the compiler
                                                            NULL,
                                                            1,
                                                            1),
                                             '^  SELECT', -- remove additional whitespace from the compiler
                                             'SELECT',
                                             1,
                                             1,
                                             'im'),
                              ' ' || chr(10));
          WHEN 'TRIGGER' THEN
            v_return := ltrim(dbms_metadata.get_ddl(object_type => p_object_type,
                                                    NAME        => p_object_name,
                                                    SCHEMA      => p_owner),
                              ' ' || chr(10));
          ELSE
            NULL;
        END CASE;
      END IF;
    ELSE
      v_return := 'ERROR: unsupported object type "' || p_object_type || '"';
    END IF;
    RETURN v_return;
  END;

  -----------------------------------------------------------------------------

  FUNCTION util_get_fk_value
  (
    p_table_name  VARCHAR2,
    p_column_name VARCHAR2,
    p_owner       VARCHAR2 DEFAULT USER
  ) RETURN VARCHAR2 IS
    v_cur               SYS_REFCURSOR;
    v_return            VARCHAR2(4000);
    v_column_expression VARCHAR2(4000);
  BEGIN
    FOR i IN (SELECT data_type
                FROM all_tab_columns
               WHERE owner = p_owner
                 AND table_name = p_table_name
                 AND column_name = p_column_name) LOOP
      v_column_expression := CASE
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

  FUNCTION util_generate_list(p_list_name VARCHAR2) RETURN t_tab_vc2_5k IS

    -----------------------------------------------------------------------------
    -- Columns as flat list for insert - without p_column_exclude_list:
    -- {% LIST_INSERT_COLUMNS %}
    -- Example:
    --   col1,
    --   col2,
    --   col3,
    --   ...
    -----------------------------------------------------------------------------
    function get_audit_value (
      p_column_index integer)
    return varchar2 is
    begin
      return
        case
          when g_columns(p_column_index).audit_type in ('CREATED', 'UPDATED') then
            case
              when g_columns(p_column_index).data_type LIKE '%DATE%' then
                'sysdate'
              when g_columns(p_column_index).data_type LIKE '%TIMESTAMP%' then
                'systimestamp'
              else
                null
            end
          else
            g_params.audit_user_expression
        end;
    end;

    FUNCTION list_insert_columns RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_columns.first .. g_columns.last LOOP
        IF
          g_columns(i).is_excluded_yn = 'N'
        AND (
          g_columns(i).audit_type is null or
          g_columns(i).audit_type like 'CREATED%' or
          (g_columns(i).audit_type like 'UPDATED%' and g_columns(i).is_nullable_yn = 'N'))
        AND NOT (
          g_template_options.hide_identity_columns
          AND nvl(g_columns(i).identity_type, 'NULL') IN ('ALWAYS', 'BY DEFAULT'))
        THEN
          v_result(v_result.count + 1) :=
            '      ' || '"' || g_columns(i).column_name || '"' ||
            CASE WHEN g_columns(i).is_pk_yn = 'Y' THEN ' /*PK*/' END ||
            CASE WHEN g_columns(i).is_uk_yn = 'Y' THEN ' /*UK*/' END ||
            CASE WHEN g_columns(i).is_fk_yn = 'Y' THEN ' /*FK*/' END ||
            c_list_delimiter;
        END IF;
      END LOOP;

      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);

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
    FUNCTION list_insert_params RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_columns.first .. g_columns.last LOOP
        IF
          g_columns(i).is_excluded_yn = 'N'
        AND (
          g_columns(i).audit_type is null or
          g_columns(i).audit_type like 'CREATED%' or
          (g_columns(i).audit_type like 'UPDATED%' and g_columns(i).is_nullable_yn = 'N'))
        AND NOT (
          g_template_options.hide_identity_columns AND
          nvl(g_columns(i).identity_type, 'NULL') IN ('ALWAYS', 'BY DEFAULT'))
        THEN
          v_result(v_result.count + 1) :=
            '      ' ||
            CASE
              WHEN g_columns(i).is_pk_yn = 'Y' AND NOT g_status.pk_is_multi_column AND
              g_params.sequence_name IS NOT NULL THEN
                'COALESCE( ' || util_get_parameter_name(g_columns(i).column_name, NULL)
                || ', "' || g_params.sequence_name || '".nextval )'
              when g_columns(i).audit_type is not null then
                get_audit_value(i)
              else
                util_get_parameter_name(g_columns(i).column_name, NULL)
            END
            || c_list_delimiter;
        END IF;
      END LOOP;
      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last)  := rtrim(v_result(v_result.last), c_list_delimiter);
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
    FUNCTION list_insert_bulk_params RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_columns.first .. g_columns.last LOOP
        IF
          g_columns(i).is_excluded_yn = 'N'
        AND (
          g_columns(i).audit_type is null or
          g_columns(i).audit_type like 'CREATED%' or
          (g_columns(i).audit_type like 'UPDATED%' and g_columns(i).is_nullable_yn = 'N'))
        AND NOT (
          g_template_options.hide_identity_columns AND
          nvl(g_columns(i).identity_type, 'NULL') IN ('ALWAYS', 'BY DEFAULT'))
        THEN
          v_result(v_result.count + 1) :=
            '      ' ||
            CASE
              WHEN
                g_columns(i).is_pk_yn = 'Y' AND
                NOT g_status.pk_is_multi_column AND
                g_params.sequence_name IS NOT NULL
              THEN
                'COALESCE( p_rows_tab(i)."' || g_columns(i).column_name || '", "'
                || g_params.sequence_name || '".nextval )'
              when
                g_columns(i).audit_type is not null
              then
                get_audit_value(i)
              ELSE
                'p_rows_tab(i)."' || g_columns(i).column_name || '"'
            END || c_list_delimiter;
        END IF;
      END LOOP;

      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);

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
    FUNCTION list_columns_w_pk_full RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_columns.first .. g_columns.last LOOP
        v_result(v_result.count + 1) :=
          '       ' || '"' || g_columns(i).column_name || '"' ||
          CASE WHEN g_columns(i).is_pk_yn = 'Y' THEN ' /*PK*/' END ||
          CASE WHEN g_columns(i).is_uk_yn = 'Y' THEN ' /*UK*/' END ||
          CASE WHEN g_columns(i).is_fk_yn = 'Y' THEN ' /*FK*/' END ||
          c_list_delimiter;
      END LOOP;

      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);

      RETURN v_result;
    END list_columns_w_pk_full;

    -----------------------------------------------------------------------------
    -- A block of code which compares new and old column values (without PK column) and
    -- counts the number  of differences:
    --    {% LIST_COLUMNS_WO_PK_COMPARE %}
    -- Example:
    --    IF COALESCE( v_row.test_number,-9999.9999 ) <> COALESCE( p_test_number,-9999.9999 ) THEN
    --        v_count := v_count + 1;
    --        create_change_log_entry( p_table     => 'map_users_roles'
    --                         ,p_column    => 'mur_u_id'
    --                         ,p_pk_id     => v_row.mur_id
    --                         ,p_old_value => to_char(v_row.mur_u_id)
    --                         ,p_new_value => to_char(p_mur_u_id) );
    --    END IF;
    --    IF DBMS_LOB.compare(COALESCE(v_row.test_clob,TO_CLOB('$$$$')),COALESCE(p_test_clob,TO_CLOB('$$$$'))) <> 0 THEN
    --        v_count := v_count + 1;
    --        create_change_log_entry( p_table     => 'map_users_roles'
    --                         ,p_column    => 'mur_u_id'
    --                         ,p_pk_id     => v_row.mur_id
    --                         ,p_old_value => to_char(v_row.mur_u_id)
    --                         ,p_new_value => to_char(p_mur_u_id) );
    --    END IF;
    --    ...
    -----------------------------------------------------------------------------
    FUNCTION list_columns_wo_pk_compare RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_columns.first .. g_columns.last LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND g_columns(i).audit_type is null
          AND g_columns(i).is_pk_yn = 'N'
        THEN
          v_result(v_result.count + 1) := CASE
                                            WHEN i != v_result.first THEN
                                             CASE
                                               WHEN g_params.enable_generic_change_log AND NOT g_status.pk_is_multi_column THEN
                                                '      IF '
                                               ELSE
                                                '      OR '
                                             END
                                          END || util_get_attribute_compare(p_data_type         => g_columns(i).data_type,
                                                                            p_nullable          => util_string_to_bool(g_columns(i).is_nullable_yn),
                                                                            p_first_attribute   => 'v_row."' || g_columns(i).column_name || '"',
                                                                            p_second_attribute  => util_get_parameter_name(g_columns(i).column_name,
                                                                                                                           NULL),
                                                                            p_compare_operation => '<>') || CASE
                                            WHEN g_params.enable_generic_change_log AND NOT g_status.pk_is_multi_column THEN
                                             ' THEN'
                                          END || c_lf;

          IF g_params.enable_generic_change_log AND NOT g_status.pk_is_multi_column THEN
            v_result(v_result.count + 1) := '        v_count := v_count + 1;' || c_lf;
            v_result(v_result.count + 1) := '        create_change_log_entry (' || c_lf;
            v_result(v_result.count + 1) := '          p_table     => ''' || g_params.table_name || ''',' || c_lf;

            v_result(v_result.count + 1) := '          p_column    => ''' || g_columns(i).column_name || ''',' || c_lf;

            v_result(v_result.count + 1) := '          p_pk_id     => v_row."' || g_pk_columns(1).column_name || '",' || c_lf;

            v_result(v_result.count + 1) := '          p_old_value => ' ||
                                            util_get_vc2_4000_operation(p_data_type      => g_columns(i).data_type,
                                                                        p_attribute_name => 'v_row."' || g_columns(i).column_name || '"') || ',' || c_lf;

            v_result(v_result.count + 1) := '          p_new_value => ' ||
                                            util_get_vc2_4000_operation(p_data_type      => g_columns(i).data_type,
                                                                        p_attribute_name => util_get_parameter_name(g_columns(i).column_name,
                                                                                                                    NULL)) ||
                                            ' );' || c_lf;

            v_result(v_result.count + 1) := '      END IF;' || c_lf;
          END IF;
        END IF;
      END LOOP;

      IF g_params.enable_generic_change_log AND NOT g_status.pk_is_multi_column THEN
        v_result(v_result.count + 1) := '      IF v_count > 0';
      END IF;

      RETURN v_result;
    END list_columns_wo_pk_compare;

    -----------------------------------------------------------------------------
    -- Columns as parameter definition for create_row,update_row with PK:
    -- {% LIST_PARAMS_W_PK %}
    -- Example:
    --   p_col1 IN table.col1%TYPE,
    --   p_col2 IN table.col2%TYPE,
    --   p_col3 IN table.col3%TYPE,
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_params_w_pk RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_columns.first .. g_columns.last LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND g_columns(i).audit_type is null
          AND NOT (
            g_template_options.hide_identity_columns
            AND nvl(g_columns(i).identity_type, 'NULL') IN ('ALWAYS', 'BY DEFAULT'))
        THEN
          v_result(v_result.count + 1) := CASE
                                            WHEN g_template_options.padding IS NOT NULL THEN
                                             rpad(' ', g_template_options.padding)
                                            ELSE
                                             '    '
                                          END ||
                                          util_get_parameter_name(g_columns(i).column_name, g_status.rpad_columns) ||
                                          ' IN "' || g_params.table_name || '"."' || CASE
                                            WHEN g_params.enable_column_defaults AND g_template_options.use_column_defaults THEN
                                             rpad(g_columns(i).column_name || '"%TYPE', g_status.rpad_columns + 6)
                                            ELSE
                                             g_columns(i).column_name || '"%TYPE'
                                          END || CASE
                                            WHEN g_columns(i).is_pk_yn = 'Y' AND NOT g_status.pk_is_multi_column AND g_columns(i).data_default IS NULL THEN
                                             ' DEFAULT NULL'
                                            WHEN g_params.enable_column_defaults AND g_template_options.use_column_defaults THEN
                                             CASE
                                               WHEN g_columns(i).data_default IS NOT NULL THEN
                                                ' DEFAULT ' || g_columns(i).data_default
                                               WHEN g_columns(i).is_nullable_yn = 'Y' THEN
                                                ' DEFAULT NULL'
                                               ELSE
                                                ' '
                                             END
                                          END || CASE
                                            WHEN g_columns(i).is_pk_yn = 'Y' THEN
                                             ' /*PK*/'
                                          END || CASE
                                            WHEN g_columns(i).is_uk_yn = 'Y' THEN
                                             ' /*UK*/'
                                          END || CASE
                                            WHEN g_columns(i).is_fk_yn = 'Y' THEN
                                             ' /*FK*/'
                                          END || c_list_delimiter;
        END IF;
      END LOOP;

      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);

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
    FUNCTION list_params_w_pk_cust_defaults RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_columns.first .. g_columns.last LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND g_columns(i).audit_type is null
          AND NOT (
            g_template_options.hide_identity_columns
            AND nvl(g_columns(i).identity_type, 'NULL') IN ('ALWAYS', 'BY DEFAULT'))
        THEN
          v_result(v_result.count + 1) := '    ' ||
                                          util_get_parameter_name(g_columns(i).column_name, g_status.rpad_columns) ||
                                          ' IN "' || g_params.table_name || '".' ||
                                          rpad('"' || g_columns(i).column_name || '"%TYPE', g_status.rpad_columns + 7) ||
                                          ' DEFAULT get_a_row()."' || g_columns(i).column_name || '"' || CASE
                                            WHEN g_columns(i).is_pk_yn = 'Y' THEN
                                             ' /*PK*/'
                                          END || CASE
                                            WHEN g_columns(i).is_uk_yn = 'Y' THEN
                                             ' /*UK*/'
                                          END || CASE
                                            WHEN g_columns(i).is_fk_yn = 'Y' THEN
                                             ' /*FK*/'
                                          END || c_list_delimiter;
        END IF;
      END LOOP;

      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);

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
    FUNCTION list_params_w_pk_io RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_columns.first .. g_columns.last LOOP
        v_result(v_result.count + 1) := '    ' ||
                                        util_get_parameter_name(g_columns(i).column_name, g_status.rpad_columns) || CASE
                                          WHEN g_columns(i).is_pk_yn = 'Y' THEN
                                           ' IN            '
                                          ELSE
                                           '    OUT NOCOPY '
                                        END || '"' || g_params.table_name || '"."' || g_columns(i).column_name ||
                                        '"%TYPE' || CASE
                                          WHEN g_columns(i).is_pk_yn = 'Y' THEN
                                           ' /*PK*/'
                                        END || CASE
                                          WHEN g_columns(i).is_uk_yn = 'Y' THEN
                                           ' /*UK*/'
                                        END || CASE
                                          WHEN g_columns(i).is_fk_yn = 'Y' THEN
                                           ' /*FK*/'
                                        END || c_list_delimiter;
      END LOOP;

      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);

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
    FUNCTION list_map_par_eq_newcol_w_pk RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_columns.first .. g_columns.last LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND g_columns(i).audit_type is null
        THEN
          v_result(v_result.count + 1) := '      ' ||
                                          util_get_parameter_name(g_columns(i).column_name, g_status.rpad_columns) ||
                                          ' => :new."' || g_columns(i).column_name || '"' || CASE
                                            WHEN g_columns(i).is_pk_yn = 'Y' THEN
                                             ' /*PK*/'
                                          END || CASE
                                            WHEN g_columns(i).is_uk_yn = 'Y' THEN
                                             ' /*UK*/'
                                          END || CASE
                                            WHEN g_columns(i).is_fk_yn = 'Y' THEN
                                             ' /*FK*/'
                                          END || c_list_delimiter;
        END IF;
      END LOOP;

      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);

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
    FUNCTION list_map_par_eq_param_w_pk RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_columns.first .. g_columns.last LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND g_columns(i).audit_type is null
          AND NOT (
            g_template_options.hide_identity_columns
            AND nvl(g_columns(i).identity_type, 'NULL') IN ('ALWAYS', 'BY DEFAULT'))
        THEN
          v_result(v_result.count + 1) := CASE
                                            WHEN g_template_options.padding IS NOT NULL THEN
                                             rpad(' ', g_template_options.padding)
                                            ELSE
                                             '      '
                                          END ||
                                          util_get_parameter_name(g_columns(i).column_name, g_status.rpad_columns) ||
                                          ' => ' || util_get_parameter_name(g_columns(i).column_name, NULL) || CASE
                                            WHEN g_columns(i).is_pk_yn = 'Y' THEN
                                             ' /*PK*/'
                                          END || CASE
                                            WHEN g_columns(i).is_uk_yn = 'Y' THEN
                                             ' /*UK*/'
                                          END || CASE
                                            WHEN g_columns(i).is_fk_yn = 'Y' THEN
                                             ' /*FK*/'
                                          END || c_list_delimiter;
        END IF;
      END LOOP;

      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);

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
    FUNCTION list_map_par_eq_rowtypcol_w_pk RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_columns.first .. g_columns.last LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND g_columns(i).audit_type is null
          AND NOT (
            g_template_options.hide_identity_columns
            AND nvl(g_columns(i).identity_type, 'NULL') IN ('ALWAYS', 'BY DEFAULT'))
        THEN
          v_result(v_result.count + 1) :=
            '      '
            || util_get_parameter_name(g_columns(i).column_name, g_status.rpad_columns)
            || ' => p_row."' || g_columns(i).column_name || '"'
            || CASE WHEN g_columns(i).is_pk_yn = 'Y' THEN ' /*PK*/' END
            || CASE WHEN g_columns(i).is_uk_yn = 'Y' THEN ' /*UK*/' END
            || CASE WHEN g_columns(i).is_fk_yn = 'Y' THEN ' /*FK*/' END
            || c_list_delimiter;
        END IF;
      END LOOP;

      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);

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
    FUNCTION list_set_col_eq_param_wo_pk RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_columns.first .. g_columns.last LOOP
        IF g_columns(i).is_excluded_yn = 'N'
        AND g_columns(i).is_pk_yn = 'N'
        AND (
          g_columns(i).audit_type is null or
          g_columns(i).audit_type like 'UPDATED%')
        THEN
          v_result(v_result.count + 1) :=
            '             ' ||
            rpad('"' || g_columns(i).column_name || '"', g_status.rpad_columns + 2) ||
            ' = ' ||
            case
              when g_columns(i).audit_type is not null then
                get_audit_value(i)
              else
                util_get_parameter_name(g_columns(i).column_name, NULL)
            end ||
            CASE WHEN g_columns(i).is_pk_yn = 'Y' THEN ' /*PK*/' END ||
            CASE WHEN g_columns(i).is_uk_yn = 'Y' THEN ' /*UK*/' END ||
            CASE WHEN g_columns(i).is_fk_yn = 'Y' THEN ' /*FK*/' END ||
            c_list_delimiter;
        END IF;
      END LOOP;

      IF v_result.count > 0 THEN -- e.g. if table has only PK columns
        v_result(v_result.first) := ltrim(v_result(v_result.first));
        v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);
      END IF;
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
    FUNCTION list_set_col_eq_par_bulk_wo_pk RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_columns.first .. g_columns.last LOOP
        IF g_columns(i).is_excluded_yn = 'N'
        AND g_columns(i).is_pk_yn = 'N'
        AND (
          g_columns(i).audit_type is null or
          g_columns(i).audit_type like 'UPDATED%')
        THEN
          v_result(v_result.count + 1) :=
            '             ' ||
            rpad('"' || g_columns(i).column_name || '"', g_status.rpad_columns + 2) ||
            ' = ' ||
            case
              when g_columns(i).audit_type is not null then
                get_audit_value(i)
              else
                'p_rows_tab(i)."' || g_columns(i).column_name || '"'
            end ||
            CASE WHEN g_columns(i).is_pk_yn = 'Y' THEN ' /*PK*/' END ||
            CASE WHEN g_columns(i).is_uk_yn = 'Y' THEN ' /*UK*/' END ||
            CASE WHEN g_columns(i).is_fk_yn = 'Y' THEN ' /*FK*/' END ||
            c_list_delimiter;
        END IF;
      END LOOP;

      IF v_result.count > 0 THEN -- e.g. if table has only PK columns
        v_result(v_result.first) := ltrim(v_result(v_result.first));
        v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);
      END IF;

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
    FUNCTION list_set_par_eq_rowtycol_wo_pk RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_columns.first .. g_columns.last LOOP
        IF g_columns(i).is_excluded_yn = 'N'
          AND g_columns(i).audit_type is null
          AND g_columns(i).is_pk_yn = 'N'
        THEN
          v_result(v_result.count + 1) :=
            '      '
            || util_get_parameter_name(g_columns(i).column_name, g_status.rpad_columns)
            || ' := v_row."' || g_columns(i).column_name || '"; ' || c_lf;
        END IF;
      END LOOP;


      IF v_result.count > 0 THEN -- e.g. if table has only PK columns
        v_result(v_result.first) := ltrim(v_result(v_result.first));
        v_result(v_result.last) := rtrim(v_result(v_result.last), c_lf);
      END IF;

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
    FUNCTION list_pk_params RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_pk_columns.first .. g_pk_columns.last LOOP
        v_result(v_result.count + 1) :=
          '    '
          || util_get_parameter_name(g_pk_columns(i).column_name, g_status.rpad_columns)
          || ' IN "' || g_params.table_name || '"."' || g_pk_columns(i).column_name
          || '"%TYPE /*PK*/' || c_list_delimiter;
      END LOOP;

      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);

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
    FUNCTION list_pk_columns RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_pk_columns.first .. g_pk_columns.last LOOP
        v_result(v_result.count + 1) :=
          '    "' || g_pk_columns(i).column_name || '" "'
          || g_params.table_name || '"."' || g_pk_columns(i).column_name
          || '"%TYPE /*PK*/' || c_list_delimiter;
      END LOOP;
      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);
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
    FUNCTION list_pk_names RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_pk_columns.first .. g_pk_columns.last LOOP
        v_result(v_result.count + 1) :=
          '     "' || g_pk_columns(i).column_name
          || '" /*PK*/' || c_list_delimiter;
      END LOOP;
      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);
      RETURN v_result;
    END list_pk_names;

    -----------------------------------------------------------------------------
    -- Primary key column definition for create_row:
    -- {% LIST_PARAMS_PK %}
    -- Example:
    --   v_return(i).col1 := v_pk_tab.col1;
    --   v_return(i).col2 := v_pk_tab.col2;
    --   v_return(i).col3 := v_pk_tab.col3;
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_pk_return_columns_bulk RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_pk_columns.first .. g_pk_columns.last LOOP
        v_result(v_result.count + 1) :=
          '    v_return(i)."' || g_pk_columns(i).column_name
          || '" := v_pk_tab(i)."' || g_pk_columns(i).column_name || '"; /*PK*/';
      END LOOP;
      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);
      RETURN v_result;
    END list_pk_return_columns_bulk;


    -----------------------------------------------------------------------------
    -- Primary key columns parameter compare for get_pk_by_unique_cols functions:
    -- {% LIST_PK_COLUMN_COMPARE %}
    -- Example:
    --       COALESCE( "COL1",'@@@@@@@@@@@@@@@' ) = COALESCE( p_col1,'@@@@@@@@@@@@@@@' )
    --   AND COALESCE( "COL2",'@@@@@@@@@@@@@@@' ) = COALESCE( p_col2,'@@@@@@@@@@@@@@@' )
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_pk_column_compare RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_pk_columns.first .. g_pk_columns.last LOOP
        v_result(v_result.count + 1) :=
          '         AND '
          || util_get_attribute_compare(
            p_data_type         => g_pk_columns(i).data_type,
            p_nullable          => util_string_to_bool(g_columns(g_columns_reverse_index(g_pk_columns(i).column_name)).is_nullable_yn),
            p_first_attribute   => '"' || g_pk_columns(i).column_name || '"',
            p_second_attribute  => util_get_parameter_name(g_pk_columns(i).column_name, NULL),
            p_compare_operation => '=') || c_lf;
      END LOOP;
      v_result(v_result.first) := ltrim(ltrim(v_result(v_result.first)), 'AND ');
      v_result(v_result.last)  := rtrim(v_result(v_result.last), c_lf);
      RETURN v_result;
    END list_pk_column_compare;

    -----------------------------------------------------------------------------
    -- Primary key columns parameter compare for get_pk_by_unique_cols functions:
    -- {% LIST_PK_COLUMN_BULK_COMPARE %}
    -- Example:
    --       COALESCE( "COL1",'@@@@@@@@@@@@@@@' ) = COALESCE( p_col1,'@@@@@@@@@@@@@@@' )
    --   AND COALESCE( "COL2",'@@@@@@@@@@@@@@@' ) = COALESCE( p_col2,'@@@@@@@@@@@@@@@' )
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_pk_column_bulk_compare RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_pk_columns.first .. g_pk_columns.last LOOP
        v_result(v_result.count + 1) :=
          '         AND '
          || util_get_attribute_compare(
            p_data_type         => g_pk_columns(i).data_type,
            p_nullable          => util_string_to_bool(g_columns(g_columns_reverse_index(g_pk_columns(i).column_name)).is_nullable_yn),
            p_first_attribute   => '"' || g_pk_columns(i).column_name || '"',
            p_second_attribute  => 'p_rows_tab(i)."' || g_pk_columns(i).column_name || '"',
            p_compare_operation => '=') || c_lf;
      END LOOP;
      v_result(v_result.first) := ltrim(ltrim(v_result(v_result.first)), 'AND ');
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_lf);
      RETURN v_result;
    END list_pk_column_bulk_compare;

    -----------------------------------------------------------------------------
    -- Primary key columns parameter compare for get_pk_by_unique_cols functions:
    -- {% LIST_PK_COLUMN_COMPARE %}
    -- Example:
    --       COALESCE( "COL1",'@@@@@@@@@@@@@@@' ) = COALESCE( p_col1,'@@@@@@@@@@@@@@@' )
    --   AND COALESCE( "COL2",'@@@@@@@@@@@@@@@' ) = COALESCE( p_col2,'@@@@@@@@@@@@@@@' )
    --   ...
    -----------------------------------------------------------------------------
    FUNCTION list_pk_column_fetch RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_pk_columns.first .. g_pk_columns.last LOOP
        v_result(v_result.count + 1) :=
          ', '
          || util_get_attribute_compare(
            p_data_type         => g_pk_columns(i).data_type,
            p_nullable          => util_string_to_bool(g_columns(g_columns_reverse_index(g_pk_columns(i).column_name)).is_nullable_yn),
            p_first_attribute   => util_get_parameter_name(g_pk_columns(i).column_name, NULL),
            p_second_attribute  => 'v_pk_rec."' || g_pk_columns(i).column_name || '"',
            p_compare_operation => '=>');
      END LOOP;
      v_result(v_result.first) := ltrim(ltrim(v_result(v_result.first)), ', ');
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_lf);
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
    FUNCTION list_pk_column_bulk_fetch RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_pk_columns.first .. g_pk_columns.last LOOP
        v_result(v_result.count + 1) :=
          '                                    AND '
          || util_get_attribute_compare(
            p_data_type         => g_pk_columns(i).data_type,
            p_nullable          => util_string_to_bool(g_columns(g_columns_reverse_index(g_pk_columns(i).column_name)).is_nullable_yn),
            p_first_attribute   => 'data_table."' || g_pk_columns(i).column_name || '"',
            p_second_attribute  => 'pk_collection."' || g_pk_columns(i).column_name || '"',
            p_compare_operation => '=') || c_lf;
      END LOOP;
      v_result(v_result.first) := ltrim(ltrim(v_result(v_result.first)), '                     AND ');
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_lf);
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

    FUNCTION list_pk_map_param_eq_param RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_pk_columns.first .. g_pk_columns.last LOOP
        v_result(v_result.count + 1) :=
          '    '
          || util_get_parameter_name(
            g_pk_columns(i).column_name,
            CASE WHEN g_status.pk_is_multi_column THEN g_status.rpad_pk_columns ELSE NULL END)
          || ' => '
          || util_get_parameter_name(g_pk_columns(i).column_name, NULL)
          || c_list_delimiter;
      END LOOP;
      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);
      RETURN v_result;
    END list_pk_map_param_eq_param;

    -----------------------------------------------------------------------------
    -- Primary key columns as "parameter => :old.column" mapping for DML view trigger:
    -- {% LIST_PK_MAP_PARAM_EQ_OLDCOL %}
    -- Example:
    --   p_col1 => :old.col1,
    --   p_col2 => :old.col2,
    --   ...
    -----------------------------------------------------------------------------

    FUNCTION list_pk_map_param_eq_oldcol RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_pk_columns.first .. g_pk_columns.last LOOP
        v_result(v_result.count + 1) :=
          '      '
          || util_get_parameter_name(
            g_pk_columns(i).column_name,
            CASE WHEN g_status.pk_is_multi_column THEN g_status.rpad_pk_columns ELSE NULL END)
          || ' => ' || ':old."' || g_pk_columns(i).column_name || '"'
          || c_list_delimiter;
      END LOOP;
      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);
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

    FUNCTION list_uk_params RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_uk_columns.first .. g_uk_columns.last LOOP
        IF g_uk_columns(i).constraint_name = g_iterator.current_uk_constraint THEN
          v_result(v_result.count + 1) :=
            '    '
            || util_get_parameter_name(g_uk_columns(i).column_name, g_status.rpad_columns)
            || ' IN "' || g_params.table_name || '"."' || g_uk_columns(i).column_name
            || '"%TYPE /*UK*/' || c_list_delimiter;
        END IF;
      END LOOP;
      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);
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

    FUNCTION list_uk_column_compare RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_uk_columns.first .. g_uk_columns.last LOOP
        IF g_uk_columns(i).constraint_name = g_iterator.current_uk_constraint THEN
          v_result(v_result.count + 1) :=
            '         AND '
            || util_get_attribute_compare(
              p_data_type         => g_uk_columns(i).data_type,
              p_nullable          => util_string_to_bool(g_columns(g_columns_reverse_index(g_uk_columns(i).column_name)).is_nullable_yn),
              p_first_attribute   => '"' || g_uk_columns(i).column_name || '"',
              p_second_attribute  => util_get_parameter_name(g_uk_columns(i).column_name, NULL),
              p_compare_operation => '=') || c_lf;
        END IF;
      END LOOP;
      v_result(v_result.first) := ltrim(ltrim(v_result(v_result.first)), 'AND ');
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_lf);
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

    FUNCTION list_uk_map_param_eq_param RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      FOR i IN g_uk_columns.first .. g_uk_columns.last LOOP
        IF g_uk_columns(i).constraint_name = g_iterator.current_uk_constraint THEN
          v_result(v_result.count + 1) :=
            '    '
            || util_get_parameter_name(
              g_uk_columns(i).column_name,
              CASE WHEN g_status.pk_is_multi_column THEN g_status.rpad_uk_columns ELSE NULL END)
              || ' => ' || util_get_parameter_name(g_uk_columns(i).column_name, NULL)
              || c_list_delimiter;
        END IF;
      END LOOP;
      v_result(v_result.first) := ltrim(v_result(v_result.first));
      v_result(v_result.last) := rtrim(v_result(v_result.last), c_list_delimiter);
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

    FUNCTION list_rowcols_w_cust_defaults RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN

      FOR i IN g_columns.first .. g_columns.last LOOP
        IF g_columns(i).data_custom_default IS NOT NULL THEN
          v_result(v_result.count + 1) :=
            '    ' || 'v_row.'
            || rpad('"' || g_columns(i).column_name || '"', g_status.rpad_columns + 2)
            || ' := ' || nvl(g_columns(i).data_custom_default, g_columns(i).data_default)
            || CASE WHEN g_columns(i).is_pk_yn = 'Y' THEN ' /*PK*/' END
            || CASE WHEN g_columns(i).is_uk_yn = 'Y' THEN ' /*UK*/' END
            || CASE WHEN g_columns(i).is_fk_yn = 'Y' THEN ' /*FK*/' END
            || ';' || c_lf;
        END IF;
      END LOOP;
      IF v_result.count > 0 THEN
        v_result(v_result.first) := ltrim(v_result(v_result.first));
        v_result(v_result.last) := rtrim(v_result(v_result.last), c_lf);
      END IF;
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

    FUNCTION list_spec_custom_defaults RETURN t_tab_vc2_5k IS
      v_result t_tab_vc2_5k;
    BEGIN
      v_result(v_result.count + 1) := '<custom_defaults>' || c_lf;
      FOR i IN g_columns.first .. g_columns.last LOOP
        IF g_columns(i).data_custom_default IS NOT NULL THEN
          v_result(v_result.count + 1) :=
            '    <column source="' || rpad(g_columns(i).custom_default_source || '"', 8)
            || ' name="' || g_columns(i).column_name || '"><![CDATA['
            || g_columns(i).data_custom_default
            || ']]></column>' || c_lf;
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
      WHEN 'LIST_COLUMNS_WO_PK_COMPARE' THEN
        RETURN list_columns_wo_pk_compare;
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
      WHEN 'LIST_PK_RETURN_COLUMNS_BULK' THEN
        RETURN list_pk_return_columns_bulk;
      WHEN 'LIST_PK_COLUMN_COMPARE' THEN
        RETURN list_pk_column_compare;
      WHEN 'LIST_PK_COLUMN_FETCH' THEN
        RETURN list_pk_column_fetch;
      WHEN 'LIST_PK_COLUMN_BULK_COMPARE' THEN
        RETURN list_pk_column_bulk_compare;
      WHEN 'LIST_PK_COLUMN_BULK_FETCH' THEN
        RETURN list_pk_column_bulk_fetch;
      WHEN 'LIST_PK_MAP_PARAM_EQ_PARAM' THEN
        RETURN list_pk_map_param_eq_param;
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
  END;

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
        dbms_lob.append(p_clob, p_clob_varchar_cache);
      END IF;

      -- clear cache on final call

      p_clob_varchar_cache := NULL;
    END IF;
  EXCEPTION
    WHEN value_error THEN
      IF p_clob IS NULL THEN
        p_clob := p_clob_varchar_cache;
      ELSE
        dbms_lob.append(p_clob, p_clob_varchar_cache);
      END IF;

      p_clob_varchar_cache := p_varchar_to_append;

      IF p_final_call THEN
        dbms_lob.append(p_clob, p_clob_varchar_cache);
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
  PROCEDURE util_template_replace(p_scope IN VARCHAR2 DEFAULT NULL) IS
    v_current_pos       PLS_INTEGER := 1;
    v_match_pos_static  PLS_INTEGER := 0;
    v_match_pos_dynamic PLS_INTEGER := 0;
    v_match_len         PLS_INTEGER := 0;
    v_match             VARCHAR2(256 CHAR);
    v_tpl_len           PLS_INTEGER;
    v_dynamic_result    t_tab_vc2_5k;

    -----------------------------------------------------------------------------

    PROCEDURE get_match_pos IS
      -- finds the first position of a substitution string like
      -- {{ TABLE_NAME }} or {% dynamic code %}
    BEGIN
      v_match_pos_static  := instr(g_code_blocks.template, '{{', v_current_pos);
      v_match_pos_dynamic := instr(g_code_blocks.template, '{%', v_current_pos);
    END get_match_pos;

    -----------------------------------------------------------------------------

    PROCEDURE code_append(p_code_snippet VARCHAR2) IS
    BEGIN
      IF p_scope = 'API SPEC' THEN
        util_clob_append(g_code_blocks.api_spec, g_code_blocks.api_spec_varchar_cache, p_code_snippet);
      ELSIF p_scope = 'API BODY' THEN
        util_clob_append(g_code_blocks.api_body, g_code_blocks.api_body_varchar_cache, p_code_snippet);
      ELSIF p_scope = 'VIEW' THEN
        util_clob_append(g_code_blocks.dml_view, g_code_blocks.dml_view_varchar_cache, p_code_snippet);
      ELSIF p_scope = 'TRIGGER' THEN
        util_clob_append(g_code_blocks.dml_view_trigger, g_code_blocks.dml_view_trigger_varchar_cache, p_code_snippet);
      END IF;
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
        WHEN 'GENERATED_AT' THEN
          code_append(to_char(SYSDATE, 'yyyy-mm-dd hh24:mi:ss'));
        WHEN 'GENERATED_BY' THEN
          code_append(util_get_user_name);
        WHEN 'SPEC_OPTIONS_MIN_LINE' THEN
          code_append(c_spec_options_min_line);
        WHEN 'SPEC_OPTIONS_MAX_LINE' THEN
          code_append(c_spec_options_max_line);
        WHEN 'OWNER' THEN
          code_append(g_params.owner);
        WHEN 'TABLE_NAME' THEN
          code_append(g_params.table_name);
        WHEN 'TABLE_NAME_MINUS_6' THEN
          code_append(substr(g_params.table_name, 1, c_ora_max_name_len - 6));
        WHEN 'COLUMN_PREFIX' THEN
          code_append(g_status.column_prefix);
        WHEN 'PK_COLUMN' THEN
          code_append(g_pk_columns(1).column_name);
        WHEN 'PARAMETER_PK_FIRST_COLUMN' THEN
          code_append(CASE
                        WHEN NOT g_status.pk_is_multi_column THEN
                         util_get_parameter_name(g_pk_columns(1).column_name, NULL)
                        ELSE
                         NULL
                      END);
        WHEN 'REUSE_EXISTING_API_PARAMS' THEN
          code_append(util_bool_to_string(g_params.reuse_existing_api_params));
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
        WHEN 'ENABLE_GENERIC_CHANGE_LOG' THEN
          code_append(util_bool_to_string(g_params.enable_generic_change_log));
        WHEN 'ENABLE_DML_VIEW' THEN
          code_append(util_bool_to_string(g_params.enable_dml_view));
        WHEN 'ENABLE_GETTER_AND_SETTER' THEN
          code_append(util_bool_to_string(g_params.enable_getter_and_setter));
        WHEN 'ENABLE_PROC_WITH_OUT_PARAMS' THEN
          code_append(util_bool_to_string(g_params.enable_proc_with_out_params));
        WHEN 'ENABLE_BULK_METHODS' THEN
          code_append(util_bool_to_string(g_params.enable_bulk_methods));
        WHEN 'ENABLE_PARAMETER_PREFIXES' THEN
          code_append(util_bool_to_string(g_params.enable_parameter_prefixes));
        WHEN 'RETURN_ROW_INSTEAD_OF_PK' THEN
          code_append(util_bool_to_string(g_params.return_row_instead_of_pk));
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
        WHEN 'SEQUENCE_NAME' THEN
          code_append(g_params.sequence_name);
        WHEN 'API_NAME' THEN
          code_append(g_params.api_name);
        WHEN 'EXCLUDE_COLUMN_LIST' THEN
          code_append(g_params.exclude_column_list);
        WHEN 'AUDIT_COLUMN_MAPPINGS' THEN
          code_append(g_params.audit_column_mappings);
        WHEN 'AUDIT_USER_EXPRESSION' THEN
          code_append(g_params.audit_user_expression);
        WHEN 'RETURN_TYPE' THEN
          code_append('"' || g_params.table_name || '"' || CASE
                        WHEN g_params.return_row_instead_of_pk OR g_status.pk_is_multi_column THEN
                         '%ROWTYPE'
                        ELSE
                         '."' || g_pk_columns(1).column_name || '"%TYPE'
                      END);
        WHEN 'RETURN_TYPE_PK_SINGLE_COLUMN' THEN
          code_append('v_return' || CASE
                        WHEN g_params.return_row_instead_of_pk OR g_status.pk_is_multi_column THEN
                         '."' || g_pk_columns(1).column_name || '"'
                        ELSE
                         NULL
                      END);
        WHEN 'RETURN_TYPE_READ_ROW' THEN
          code_append(CASE
                        WHEN NOT g_params.return_row_instead_of_pk AND NOT g_status.pk_is_multi_column THEN
                         '."' || g_pk_columns(1).column_name || '"'
                        ELSE
                         NULL
                      END);
        WHEN 'COUNTER_DECLARATION' THEN
          code_append(CASE
                        WHEN g_params.enable_generic_change_log AND NOT g_status.pk_is_multi_column THEN
                         'v_count PLS_INTEGER := 0;'
                        ELSE
                         NULL
                      END);
        WHEN 'ROWTYPE_PARAM' THEN
          code_append(rpad('p_row', g_status.rpad_columns + 2) || ' IN "' || g_params.table_name || '"%ROWTYPE )');
        WHEN 'I_COLUMN_NAME' THEN
          code_append(g_iterator.column_name);
        WHEN 'I_METHOD_NAME' THEN
          code_append(g_iterator.method_name);
        WHEN 'I_PARAMETER_NAME' THEN
          code_append(g_iterator.parameter_name);
        WHEN 'I_COLUMN_COMPARE' THEN
          code_append(g_iterator.column_compare);
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

      g_template_options.use_column_defaults := nvl(util_string_to_bool(regexp_substr(srcstr        => v_match,
                                                                                      pattern       => 'DEFAULTS=([A-Z0-9]+)',
                                                                                      position      => 1,
                                                                                      occurrence    => 1,
                                                                                      modifier      => 'i',
                                                                                      subexpression => 1)),
                                                    FALSE);

      g_template_options.hide_identity_columns := nvl(util_string_to_bool(regexp_substr(srcstr        => v_match,
                                                                                        pattern       => 'HIDE_IDENTITY_COLUMNS=([A-Z0-9]+)',
                                                                                        position      => 1,
                                                                                        occurrence    => 1,
                                                                                        modifier      => 'i',
                                                                                        subexpression => 1)),
                                                      FALSE);
      g_template_options.padding               := to_number(regexp_substr(srcstr        => v_match,
                                                                          pattern       => 'PADDING=([0-9]+)',
                                                                          position      => 1,
                                                                          occurrence    => 1,
                                                                          modifier      => 'i',
                                                                          subexpression => 1));
      v_match                                  := regexp_substr(srcstr        => v_match,
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

      ELSIF v_match = 'RETURN_VALUE' THEN
        IF g_params.return_row_instead_of_pk OR g_status.pk_is_multi_column THEN
          v_dynamic_result := util_generate_list('LIST_COLUMNS_W_PK_FULL');
        ELSE
          v_dynamic_result(1) := '"' || g_pk_columns(1).column_name || '"';
        END IF;
      ELSIF v_match = 'RETURN_VALUE_BULK' THEN
        v_dynamic_result := util_generate_list('LIST_COLUMNS_W_PK_FULL');
      ELSE
        raise_application_error(c_generator_error_number,
                                'FIXME: Bug - dynamic substitution ' || v_match || ' not defined');
      END IF;

      IF v_dynamic_result.count > 0 THEN
        FOR i IN v_dynamic_result.first .. v_dynamic_result.last LOOP
          code_append(v_dynamic_result(i));
        END LOOP;
      END IF;

      v_current_pos := v_match_pos_dynamic + v_match_len + 4;
    END process_dynamic_match;

    -----------------------------------------------------------------------------

  BEGIN
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
    p_table_name                  IN all_objects.object_name%TYPE,
    p_owner                       IN all_users.username%TYPE,
    p_reuse_existing_api_params   IN BOOLEAN,
    p_enable_insertion_of_rows    IN BOOLEAN,
    p_enable_column_defaults      IN BOOLEAN,
    p_enable_update_of_rows       IN BOOLEAN,
    p_enable_deletion_of_rows     IN BOOLEAN,
    p_enable_parameter_prefixes   IN BOOLEAN,
    p_enable_proc_with_out_params IN BOOLEAN,
    p_enable_getter_and_setter    IN BOOLEAN,
    p_col_prefix_in_method_names  IN BOOLEAN,
    p_return_row_instead_of_pk    IN BOOLEAN,
    p_enable_dml_view             IN BOOLEAN,
    p_enable_generic_change_log   IN BOOLEAN,
    p_api_name                    IN all_objects.object_name%TYPE,
    p_sequence_name               IN all_objects.object_name%TYPE,
    p_exclude_column_list         IN VARCHAR2,
    p_audit_column_mappings       IN VARCHAR2,
    p_audit_user_expression       IN VARCHAR2,
    p_enable_custom_defaults      IN BOOLEAN,
    p_custom_default_values       IN xmltype,
    p_enable_bulk_methods         IN BOOLEAN
  ) IS

    -----------------------------------------------------------------------------

    PROCEDURE init_reset_globals IS
    BEGIN
      util_debug_start_one_step(p_action => 'init_reset_globals');
      -- global records
      g_params              := NULL;
      g_params_existing_api := NULL;
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
      g_params.enable_insertion_of_rows := CASE
                                             WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                              coalesce(util_string_to_bool(g_params_existing_api.p_enable_insertion_of_rows),
                                                       c_true_enable_insertion_of_row)
                                             ELSE
                                              p_enable_insertion_of_rows
                                           END;

      g_params.enable_column_defaults := CASE
                                           WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                            coalesce(util_string_to_bool(g_params_existing_api.p_enable_column_defaults),
                                                     c_false_enable_column_defaults)
                                           ELSE
                                            p_enable_column_defaults
                                         END;

      g_params.enable_update_of_rows := CASE
                                          WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                           coalesce(util_string_to_bool(g_params_existing_api.p_enable_update_of_rows),
                                                    c_true_enable_update_of_rows)
                                          ELSE
                                           p_enable_update_of_rows
                                        END;

      g_params.enable_deletion_of_rows := CASE
                                            WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                             coalesce(util_string_to_bool(g_params_existing_api.p_enable_deletion_of_rows),
                                                      c_false_enable_deletion_of_row)
                                            ELSE
                                             p_enable_deletion_of_rows
                                          END;

      g_params.enable_parameter_prefixes := CASE
                                              WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                               coalesce(util_string_to_bool(g_params_existing_api.p_enable_parameter_prefixes),
                                                        c_true_enable_parameter_prefix)
                                              ELSE
                                               p_enable_parameter_prefixes
                                            END;

      g_params.enable_proc_with_out_params := CASE
                                                WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                                 coalesce(util_string_to_bool(g_params_existing_api.p_enable_proc_with_out_params),
                                                          c_true_enable_proc_with_out_pa)
                                                ELSE
                                                 p_enable_proc_with_out_params
                                              END;

      g_params.enable_getter_and_setter := CASE
                                             WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                              coalesce(util_string_to_bool(g_params_existing_api.p_enable_getter_and_setter),
                                                       c_true_enable_getter_and_sette)
                                             ELSE
                                              p_enable_getter_and_setter
                                           END;

      g_params.col_prefix_in_method_names := CASE
                                               WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                                coalesce(util_string_to_bool(g_params_existing_api.p_col_prefix_in_method_names),
                                                         c_true_col_prefix_in_method_na)
                                               ELSE
                                                p_col_prefix_in_method_names
                                             END;

      g_params.return_row_instead_of_pk := CASE
                                             WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                              coalesce(util_string_to_bool(g_params_existing_api.p_return_row_instead_of_pk),
                                                       c_false_return_row_instead_of_)
                                             ELSE
                                              p_return_row_instead_of_pk
                                           END;

      g_params.enable_dml_view := CASE
                                    WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                     coalesce(util_string_to_bool(g_params_existing_api.p_enable_dml_view),
                                              c_false_enable_dml_view)
                                    ELSE
                                     p_enable_dml_view
                                  END;

      g_params.enable_generic_change_log := CASE
                                              WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                               coalesce(util_string_to_bool(g_params_existing_api.p_enable_generic_change_log),
                                                        c_false_enable_generic_change_)
                                              ELSE
                                               p_enable_generic_change_log
                                            END;

      g_params.api_name := CASE
                             WHEN g_params.reuse_existing_api_params AND g_status.api_exists AND
                                  g_params_existing_api.p_api_name IS NOT NULL THEN
                              g_params_existing_api.p_api_name
                             ELSE
                              util_get_substituted_name(nvl(p_api_name,
                                                            '#TABLE_NAME_1_' || to_char(c_ora_max_name_len - 4) || '#_API'))
                           END;

      g_params.sequence_name := CASE
                                  WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                   g_params_existing_api.p_sequence_name
                                  ELSE
                                   CASE
                                     WHEN p_sequence_name IS NOT NULL THEN
                                      util_get_substituted_name(p_sequence_name)
                                     ELSE
                                      NULL
                                   END
                                END;

      g_params.exclude_column_list := CASE
                                        WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                         g_params_existing_api.p_exclude_column_list
                                        ELSE
                                         p_exclude_column_list
                                      END;

      g_params.audit_column_mappings := CASE
                                        WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                         g_params_existing_api.p_audit_column_mappings
                                        ELSE
                                         p_audit_column_mappings
                                      END;

      g_params.audit_user_expression := CASE
                                        WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                         g_params_existing_api.p_audit_user_expression
                                        ELSE
                                         p_audit_user_expression
                                      END;

      g_params.enable_custom_defaults := CASE
                                           WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                            coalesce(util_string_to_bool(g_params_existing_api.p_enable_custom_defaults),
                                                     c_false_enable_custom_defaults)
                                           ELSE
                                            p_enable_custom_defaults
                                         END;

      g_params.enable_bulk_methods := CASE
                                        WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                         coalesce(util_string_to_bool(g_params_existing_api.p_enable_bulk_methods),
                                                  c_true_enable_bulk_methods)
                                        ELSE
                                         p_enable_bulk_methods
                                      END;
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

    PROCEDURE init_fetch_existing_api_params IS
      CURSOR v_cur IS
        SELECT * FROM TABLE(view_existing_apis(p_table_name => g_params.table_name, p_owner => g_params.owner));
    BEGIN
      util_debug_start_one_step(p_action => 'init_fetch_existing_api_params');
      OPEN v_cur;
      FETCH v_cur
        INTO g_params_existing_api;
      IF v_cur%FOUND THEN
        g_status.api_exists := TRUE;
      END IF;
      CLOSE v_cur;
      util_debug_stop_one_step;
    EXCEPTION
      WHEN OTHERS THEN
        CLOSE v_cur;
        util_debug_stop_one_step;
        RAISE;
    END init_fetch_existing_api_params;

    -----------------------------------------------------------------------------

    PROCEDURE init_check_if_log_table_exists IS
      v_count PLS_INTEGER;
    BEGIN
      util_debug_start_one_step(p_action => 'init_check_if_log_table_exists');
      FOR i IN (SELECT 'GENERIC_CHANGE_LOG'
                  FROM dual
                MINUS
                SELECT table_name
                  FROM all_tables
                 WHERE owner = g_params.owner
                   AND table_name = 'GENERIC_CHANGE_LOG') LOOP
        -- check constraint
        SELECT COUNT(*)
          INTO v_count
          FROM all_objects
         WHERE owner = g_params.owner
           AND object_name = 'GENERIC_CHANGE_LOG_PK';

        IF v_count > 0 THEN
          raise_application_error(c_generator_error_number,
                                  'Stop trying to create generic change log table: Object with the name GENERIC_CHANGE_LOG_PK already exists.');
        END IF;

        -- check sequence
        SELECT COUNT(*)
          INTO v_count
          FROM all_objects
         WHERE owner = g_params.owner
           AND object_name = 'GENERIC_CHANGE_LOG_SEQ';

        IF v_count > 0 THEN
          raise_application_error(c_generator_error_number,
                                  'Stop trying to create generic change log table: Object with the name GENERIC_CHANGE_LOG_SEQ already exists.');
        END IF;

        -- check index
        SELECT COUNT(*)
          INTO v_count
          FROM all_objects
         WHERE owner = g_params.owner
           AND object_name = 'GENERIC_CHANGE_LOG_IDX';

        IF v_count > 0 THEN
          raise_application_error(c_generator_error_number,
                                  'Stop trying to create generic change log table: Object with the name GENERIC_CHANGE_LOG_IDX already exists.');
        END IF;

        EXECUTE IMMEDIATE q'[
create table generic_change_log (
  gcl_id        NUMBER not null,
  gcl_table     VARCHAR2(128 CHAR) not null,
  gcl_column    VARCHAR2(128 CHAR) not null,
  gcl_pk_id     VARCHAR2(128 CHAR) not null,
  gcl_old_value VARCHAR2(4000 CHAR),
  gcl_new_value VARCHAR2(4000 CHAR),
  gcl_user      VARCHAR2(30 CHAR),
  gcl_timestamp TIMESTAMP(6) default systimestamp,
  constraint generic_change_log_pk primary key (gcl_id)
)
]';

        EXECUTE IMMEDIATE q'[
create sequence generic_change_log_seq nocache noorder nocycle]';
        EXECUTE IMMEDIATE q'[
create index generic_change_log_idx on generic_change_log (gcl_table,gcl_column,gcl_pk_id)]';
        EXECUTE IMMEDIATE q'[
comment on column generic_change_log.gcl_id is 'Primary key of the table']';
        EXECUTE IMMEDIATE q'[
comment on column generic_change_log.gcl_table is 'Table on which the change occured']';
        EXECUTE IMMEDIATE q'[
comment on column generic_change_log.gcl_column is 'Column on which the change occured']';
        EXECUTE IMMEDIATE q'[
comment on column generic_change_log.gcl_pk_id is 'We assume that the pk column of the changed table has a number type']';
        EXECUTE IMMEDIATE q'[
comment on column generic_change_log.gcl_old_value is 'The old value before the change']';
        EXECUTE IMMEDIATE q'[
comment on column generic_change_log.gcl_new_value is 'The new value after the change']';
        EXECUTE IMMEDIATE q'[
comment on column generic_change_log.gcl_user is 'The user,who changed the data']';
        EXECUTE IMMEDIATE q'[
comment on column generic_change_log.gcl_timestamp is 'The time when the change occured']';
      END LOOP;
      util_debug_stop_one_step;
    END init_check_if_log_table_exists;

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
      dbms_lob.createtemporary(lob_loc => g_code_blocks.api_spec, cache => FALSE);
      dbms_lob.createtemporary(lob_loc => g_code_blocks.api_body, cache => FALSE);
      dbms_lob.createtemporary(lob_loc => g_code_blocks.dml_view, cache => FALSE);
      dbms_lob.createtemporary(lob_loc => g_code_blocks.dml_view_trigger, cache => FALSE);
      util_debug_stop_one_step;
    END init_create_temporary_lobs;

    -----------------------------------------------------------------------------

    PROCEDURE init_fetch_columns IS
    BEGIN
      util_debug_start_one_step(p_action => 'init_fetch_columns');
      OPEN g_cur_columns;
      FETCH g_cur_columns BULK COLLECT
        INTO g_columns LIMIT c_bulk_collect_limit;
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
      v_column_prefix varchar2(c_ora_max_name_len);
      type v_varchar_tab is
        table of varchar2(c_ora_max_name_len)
        index by varchar2(c_ora_max_name_len);
      v_column_prefix_tab v_varchar_tab;
    BEGIN
      util_debug_start_one_step(p_action => 'init_process_columns');
      -- init rpad
      g_status.rpad_columns := 0;
      g_status.xmltype_column_present := FALSE;

      FOR i IN g_columns.first .. g_columns.last LOOP
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
        -- Calc column prefix by saving the found prefix as tab index and count afterwards
        -- the length of the tab: if it is greater then 1 we have NO distinct column prefix.
        v_column_prefix := substr(g_columns(i).column_name, 1,
            CASE WHEN instr(g_columns(i).column_name, '_') = 0
              THEN length(g_columns(i).column_name)
              ELSE instr(g_columns(i).column_name, '_') - 1
            END);
        v_column_prefix_tab(v_column_prefix) := v_column_prefix;
      END LOOP;

      if v_column_prefix_tab.count > 1 then
        g_status.column_prefix := null;
      else
        g_status.column_prefix := v_column_prefix_tab.first;
      end if;
      IF g_params.col_prefix_in_method_names = FALSE and g_status.column_prefix IS NULL THEN
        raise_application_error(c_generator_error_number,
          'The prefix of your column names (example: prefix_rest_of_column_name)' || c_lf ||
          'is not unique and you requested to cut off the prefix for getter and' || c_lf ||
          'setter method names. Please ensure either your column names have a' || c_lf ||
          'unique prefix or switch the parameter p_col_prefix_in_method_names' || c_lf ||
          'to true (SQL Developer oddgen integration: check option "Keep column' || c_lf ||
          'prefix in method names").');
      END IF;
      util_debug_stop_one_step;
    exception
      when others then
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
      IF g_params.enable_generic_change_log AND g_status.pk_is_multi_column THEN
        raise_application_error(c_generator_error_number,
                                'Unable to generate API - you requested to use the generic change log and your table "' ||
                                g_params.table_name ||
                                '" has a multi column primary key. This combination is not supported.');
      END IF;
      g_status.rpad_pk_columns := 0;
      FOR i IN g_pk_columns.first .. g_pk_columns.last LOOP
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
        FOR i IN g_uk_columns.first .. g_uk_columns.last LOOP
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
        FOR i IN g_fk_columns.first .. g_fk_columns.last LOOP
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
      procedure process_audit_type(
        p_audit_type varchar2)
      is
        v_idx         PLS_INTEGER;
        v_column_name all_tab_cols.column_name%TYPE;
      begin
        v_column_name := regexp_substr(
          g_params.audit_column_mappings,
          p_audit_type || '="?([^,"]*)"?',1,1,'i',1);
        if v_column_name is not null then
          v_column_name := replace(v_column_name, '#PREFIX#', g_status.column_prefix);
          begin
            v_idx := g_columns_reverse_index(v_column_name);
            g_columns(v_idx).audit_type := p_audit_type;
          exception
            when no_data_found then null;
            when others then raise;
          end;
        end if;
      end;
    BEGIN
      if instr(g_params.audit_column_mappings, '#PREFIX#') > 0 and g_status.column_prefix is null then
        raise_application_error(c_generator_error_number,
          'The prefix of your column names (example: prefix_rest_of_column_name)' || c_lf ||
          'is not unique and you used the placeholder #PREFIX# in the parameter' || c_lf ||
          'p_audit_column_mappings. Please ensure either your column names have a' || c_lf ||
          'unique prefix or do not use the placeholder #PREFIX# in the parameter' || c_lf ||
          'p_audit_column_mappings.');
      else
        util_debug_start_one_step(p_action => 'init_process_audit_columns');
        process_audit_type('CREATED');
        process_audit_type('CREATED_BY');
        process_audit_type('UPDATED');
        process_audit_type('UPDATED_BY');
        util_debug_stop_one_step;
      end if;
    END init_process_audit_columns;

    -----------------------------------------------------------------------------

    PROCEDURE init_fetch_custom_defaults IS
      FUNCTION get_spec_custom_defaults RETURN xmltype IS
        v_return VARCHAR2(32767);
      BEGIN
        FOR i IN (SELECT text
                    FROM all_source
                   WHERE owner = g_params.owner
                     AND NAME = g_params.api_name
                     AND TYPE = 'PACKAGE'
                     AND line >= (SELECT MIN(line) AS line
                                    FROM all_source
                                   WHERE owner = g_params.owner
                                     AND NAME = g_params.api_name
                                     AND TYPE = 'PACKAGE'
                                     AND instr(text, '<custom_defaults>') > 0)) LOOP
          IF instr(i.text, 'source="USER"') > 0 OR instr(i.text, 'custom_defaults') > 0 THEN
            v_return := v_return || ltrim(i.text, -- needed for backward compatibility of old comment style
                                          ' *');
          END IF;
          EXIT WHEN instr(i.text, '</custom_defaults>') > 0;
        END LOOP;
        RETURN CASE WHEN v_return IS NULL THEN NULL ELSE xmltype(v_return) END;
      END;

    BEGIN
      util_debug_start_one_step(p_action => 'init_fetch_custom_defaults');
      g_params.custom_default_values := CASE
                                          WHEN g_params.reuse_existing_api_params AND g_status.api_exists THEN
                                           CASE
                                             WHEN g_params_existing_api.p_custom_default_values IS NOT NULL THEN
                                             -- g_params_existing_api.p_custom_default_values contains only a
                                             -- placeholder to signal that custom defaults exists, because the
                                             -- defaults could be very large. We have to fetch the xml encoded
                                             -- custom defaults from the end of the package spec.
                                              get_spec_custom_defaults
                                           END
                                          ELSE
                                           p_custom_default_values
                                        END;

      IF g_params.custom_default_values IS NOT NULL THEN
        g_params.custom_defaults_serialized := util_serialize_xml(g_params.custom_default_values);
      END IF;

      -- check for empty XML element
      IF g_params.custom_defaults_serialized = '<defaults/>' THEN
        g_params.custom_default_values      := NULL;
        g_params.custom_defaults_serialized := NULL;
      END IF;
      util_debug_stop_one_step;
    END init_fetch_custom_defaults;

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
                                  column_name VARCHAR2(200) path '@name', --
                                  data_default VARCHAR2(4000) path 'text()') x) LOOP
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
      FOR i IN g_columns.first .. g_columns.last LOOP
        IF g_columns(i).data_custom_default IS NULL -- do not override users defaults from the processing step above
         THEN
          IF g_columns(i).data_default IS NOT NULL THEN
            g_columns(i).data_custom_default := g_columns(i).data_default;
            g_columns(i).custom_default_source := 'TABLE';
          ELSE
            g_columns(i).data_custom_default := CASE
                                                  WHEN g_columns(i).is_pk_yn = 'Y' AND NOT g_status.pk_is_multi_column AND
                                                        g_params.sequence_name IS NOT NULL THEN
                                                   '"' || g_params.sequence_name || '"' || '.nextval'
                                                  WHEN g_columns(i).is_fk_yn = 'Y' THEN
                                                   util_get_fk_value(p_table_name  => g_columns(i).r_table_name,
                                                                     p_column_name => g_columns(i).r_column_name,
                                                                     p_owner       => g_columns(i).r_owner)
                                                  WHEN g_columns(i).data_type IN ('NUMBER', 'INTEGER', 'FLOAT') THEN

                                                   'round(dbms_random.value(0,' ||
                                                   rpad('9',
                                                        nvl(g_columns(i).data_precision, 9) - nvl(g_columns(i).data_scale, 0),
                                                        '9') || CASE
                                                     WHEN nvl(g_columns(i).data_scale, 0) > 0 THEN
                                                      '.' || rpad('9', nvl(g_columns(i).data_scale, 0), '9')
                                                     ELSE
                                                      NULL
                                                   END || '),' || to_char(nvl(g_columns(i).data_scale, 0)) || ')'
                                                  WHEN g_columns(i).data_type LIKE '%CHAR%' THEN
                                                   CASE
                                                     WHEN lower(g_columns(i).column_name) LIKE '%mail%' THEN
                                                      'substr(sys_guid(),1,' || to_char(g_columns(i).char_length - 10) ||
                                                      ') || ''@dummy.com'''
                                                     WHEN lower(g_columns(i).column_name) LIKE '%phone%' THEN
                                                      'substr(''+1.'' || lpad(to_char(trunc(dbms_random.value(1,999))),3,''0'') || ''.'' || lpad(to_char(trunc(dbms_random.value(1,999))),3,''0'') || ''.'' || lpad(to_char(trunc(dbms_random.value(1,9999))),4,''0''),1,' ||
                                                      to_char(g_columns(i).char_length) || ')'
                                                     ELSE
                                                      'substr(sys_guid(),1,' || to_char(g_columns(i).char_length) || ')'
                                                   END
                                                  WHEN g_columns(i).data_type = 'DATE' THEN
                                                   'to_date(trunc(dbms_random.value(to_char(date''1900-01-01'',''j''),to_char(date''2099-12-31'',''j''))),''j'')'
                                                  WHEN g_columns(i).data_type LIKE 'TIMESTAMP%' THEN
                                                   'systimestamp'
                                                  WHEN g_columns(i).data_type = 'CLOB' THEN
                                                   'to_clob(''Dummy clob for API method get_a_row: '' || sys_guid())'
                                                  WHEN g_columns(i).data_type = 'BLOB' THEN
                                                   'to_blob(utl_raw.cast_to_raw(''Dummy clob for API method get_a_row: '' || sys_guid()))'
                                                  WHEN g_columns(i).data_type = 'XMLTYPE' THEN
                                                   'xmltype(''<dummy>Dummy XML for API method get_a_row: '' || sys_guid() || ''</dummy>'')'
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
    g_params.reuse_existing_api_params := p_reuse_existing_api_params;
    g_status.api_exists := FALSE;
    IF g_params.reuse_existing_api_params THEN
      init_fetch_existing_api_params;
    END IF;
    init_process_parameters;
    IF g_params.enable_generic_change_log THEN
      init_check_if_log_table_exists;
    END IF;
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
    init_process_audit_columns;
    IF g_params.enable_custom_defaults THEN
      init_fetch_custom_defaults;
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
CREATE OR REPLACE PACKAGE "{{ OWNER }}"."{{ API_NAME }}" IS
  /*
  This is the API for the table "{{ TABLE_NAME }}".

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
    p_table_name="{{ TABLE_NAME }}"
    p_owner="{{ OWNER }}"
    p_reuse_existing_api_params="{{ REUSE_EXISTING_API_PARAMS }}"
    p_enable_insertion_of_rows="{{ ENABLE_INSERTION_OF_ROWS }}"
    p_enable_column_defaults="{{ ENABLE_COLUMN_DEFAULTS }}"
    p_enable_update_of_rows="{{ ENABLE_UPDATE_OF_ROWS }}"
    p_enable_deletion_of_rows="{{ ENABLE_DELETION_OF_ROWS }}"
    p_enable_parameter_prefixes="{{ ENABLE_PARAMETER_PREFIXES }}"
    p_enable_proc_with_out_params="{{ ENABLE_PROC_WITH_OUT_PARAMS }}"
    p_enable_getter_and_setter="{{ ENABLE_GETTER_AND_SETTER }}"
    p_col_prefix_in_method_names="{{ COL_PREFIX_IN_METHOD_NAMES }}"
    p_return_row_instead_of_pk="{{ RETURN_ROW_INSTEAD_OF_PK }}"
    p_enable_dml_view="{{ ENABLE_DML_VIEW }}"
    p_enable_generic_change_log="{{ ENABLE_GENERIC_CHANGE_LOG }}"
    p_api_name="{{ API_NAME }}"
    p_sequence_name="{{ SEQUENCE_NAME }}"
    p_exclude_column_list="{{ EXCLUDE_COLUMN_LIST }}"
    p_audit_column_mappings="{{ AUDIT_COLUMN_MAPPINGS }}"
    p_audit_user_expression="{{ AUDIT_USER_EXPRESSION }}"
    p_enable_custom_defaults="{{ ENABLE_CUSTOM_DEFAULTS }}"
    p_custom_default_values="{{ CUSTOM_DEFAULTS }}"
    p_enable_bulk_methods="{{ ENABLE_BULK_METHODS }}"/>

  This API provides DML functionality that can be easily called from APEX.
  Target of the table API is to encapsulate the table DML source code for
  security (UI schema needs only the execute right for the API and the
  read/write right for the {{ TABLE_NAME_MINUS_6 }}_DML_V, tables can be
  hidden in extra data schema) and easy readability of the business logic
  (all DML is then written in the same style). For APEX automatic row
  processing like tabular forms you can optionally use the
  {{ TABLE_NAME_MINUS_6 }}_DML_V. The instead of trigger for this view
  is calling simply this "{{ API_NAME }}".
  */' || case when g_status.xmltype_column_present then '

  /*This is required to handle column of datatype XMLTYPE for single row processing*/
  TYPE t_pk_rec IS RECORD (
    {% LIST_PK_COLUMNS %}
  );' else null end;

      util_template_replace('API SPEC');
      g_code_blocks.template := '
CREATE OR REPLACE PACKAGE BODY "{{ OWNER }}"."{{ API_NAME }}" IS
  /**
   * generator="{{ GENERATOR }}"
   * generator_version="{{ GENERATOR_VERSION }}"
   * generator_action="{{ GENERATOR_ACTION }}"
   * generated_at="{{ GENERATED_AT }}"
   * generated_by="{{ GENERATED_BY }}"
   */';

      util_template_replace('API BODY');
      util_debug_stop_one_step;
    END gen_header;

    -----------------------------------------------------------------------------

    PROCEDURE gen_header_bulk IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_header_bulk');
      g_code_blocks.template := case when g_status.xmltype_column_present then '
  /*This is required to handle column of datatype XMLTYPE for bulk processing*/
  TYPE t_pk_tab IS TABLE OF t_pk_rec;' else null end || '

  TYPE t_strong_ref_cursor IS REF CURSOR RETURN "{{ TABLE_NAME }}"%ROWTYPE;
  TYPE t_rows_tab IS TABLE OF "{{ TABLE_NAME }}"%ROWTYPE; ';

      util_template_replace('API SPEC');

      g_code_blocks.template := '

  g_bulk_limit     PLS_INTEGER := 10000;
  g_bulk_completed BOOLEAN     := FALSE;';

      util_template_replace('API BODY');

      util_debug_stop_one_step;
    END gen_header_bulk;

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
    p_bulk_limit     IN PLS_INTEGER );';

      util_template_replace('API SPEC');

      g_code_blocks.template := '

  PROCEDURE set_bulk_limit (
    p_bulk_limit     IN PLS_INTEGER )
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
      g_code_blocks.template := '

  FUNCTION util_xml_compare (
    p_doc1 XMLTYPE,
    p_doc2 XMLTYPE )
  RETURN NUMBER IS
    v_return NUMBER;
  BEGIN
    SELECT CASE
             WHEN XMLEXISTS(
                    ''declare default element namespace "http://xmlns.oracle.com/xdb/xdiff.xsd"; /xdiff/*''
                    PASSING XMLDIFF( p_doc1, p_doc2 ) )
             THEN 1
             ELSE 0
           END
      INTO v_return
      FROM DUAL;
    RETURN v_return;
  END util_xml_compare;';

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
        FROM "{{ TABLE_NAME }}"
       WHERE {% LIST_PK_COLUMN_COMPARE %};
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
      g_code_blocks.template := '

  FUNCTION row_exists_yn (
    {% LIST_PK_PARAMS %} )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN CASE WHEN row_exists( {% LIST_PK_MAP_PARAM_EQ_PARAM %} )
             THEN ''Y''
             ELSE ''N''
           END;
  END;';
      util_template_replace('API BODY');
      util_debug_stop_one_step;
    END gen_row_exists_yn_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_get_pk_by_unique_cols_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_get_pk_by_unique_cols_fnc');
      IF g_uk_constraints.count > 0 THEN
        FOR i IN g_uk_constraints.first .. g_uk_constraints.last LOOP
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
    {% LIST_PARAMS_W_PK defaults=true hide_identity_columns=true %} )
  RETURN {{ RETURN_TYPE }};';
      util_template_replace('API SPEC');
      g_code_blocks.template := '

  FUNCTION create_row (
    {% LIST_PARAMS_W_PK defaults=true hide_identity_columns=true %} )
  RETURN {{ RETURN_TYPE }} IS
    v_return {{ RETURN_TYPE }}; ' || CASE WHEN g_status.xmltype_column_present AND g_params.return_row_instead_of_pk THEN '

    /*This is required to handle column of datatype XMLTYPE for single row processing*/
    v_pk_rec t_pk_rec;' ELSE NULL END || '
  BEGIN
    INSERT INTO "{{ TABLE_NAME }}" (
      {% LIST_INSERT_COLUMNS hide_identity_columns=true %} )
    VALUES (
      {% LIST_INSERT_PARAMS hide_identity_columns=true %} )
    RETURN ' || CASE WHEN NOT g_status.xmltype_column_present OR NOT g_params.return_row_instead_of_pk THEN '
      {% RETURN_VALUE %}
    INTO v_return;' ELSE '
      {% LIST_PK_NAMES %}
    INTO v_pk_rec;

    /*Record has to be fetched again, because
      XMLType column can not be returned*/
    v_return := read_row({% LIST_PK_COLUMN_FETCH %});' end || CASE WHEN g_params.enable_generic_change_log AND NOT g_status.pk_is_multi_column THEN
                                   '
    create_change_log_entry (
      p_table     => ''{{ TABLE_NAME }}'',
      p_column    => ''{{ PK_COLUMN }}'',
      p_pk_id     => {{ RETURN_TYPE_PK_SINGLE_COLUMN }},
      p_old_value => ''ROW CREATED'',
      p_new_value => ''ROW CREATED'' );'
                       END || '

    RETURN v_return;
  END create_row;';

      util_template_replace('API BODY');
      util_debug_stop_one_step;
    END gen_create_row_fnc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_create_rows_bulk_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_create_rows_bulk_fnc');
      g_code_blocks.template := '

  FUNCTION create_rows (
    p_rows_tab       IN t_rows_tab )
  RETURN t_rows_tab;';
      util_template_replace('API SPEC');
      g_code_blocks.template := '

  FUNCTION create_rows (
    p_rows_tab       IN t_rows_tab )
  RETURN t_rows_tab IS
    v_return t_rows_tab;' || CASE WHEN g_status.xmltype_column_present THEN '

    /*This is required to handle column of datatype XMLTYPE for bulk processing*/
    v_pk_tab t_pk_tab;
    v_strong_ref_cursor t_strong_ref_cursor;' ELSE NULL END || '
  BEGIN
    FORALL i IN INDICES OF p_rows_tab
    INSERT INTO "{{ TABLE_NAME }}" (
      {% LIST_INSERT_COLUMNS hide_identity_columns=true %} )
    VALUES (
      {% LIST_INSERT_BULK_PARAMS hide_identity_columns=true %} ) ' || CASE WHEN NOT g_status.xmltype_column_present THEN '
    RETURN
      {% RETURN_VALUE_BULK %}
    BULK COLLECT INTO v_return;' ELSE '
    RETURN
      {% LIST_PK_NAMES %}
    BULK COLLECT INTO v_pk_tab;

    /*Records have to be bulk-fetched again, because
      XMLType column can not be returned*/
    OPEN v_strong_ref_cursor FOR SELECT data_table.*
                                   FROM "{{ TABLE_NAME }}" data_table INNER JOIN TABLE(v_pk_tab) pk_collection
                                     ON {% LIST_PK_COLUMN_BULK_FETCH %};

    /*no loop required here, because maximum bulk limit already given by
      the size of p_rows_tab*/
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

  PROCEDURE create_rows(
    p_rows_tab       IN t_rows_tab );';
      util_template_replace('API SPEC');
      g_code_blocks.template := '

  PROCEDURE create_rows(
    p_rows_tab       IN t_rows_tab )
  IS
    v_return t_rows_tab;
  BEGIN
    v_return := create_rows(p_rows_tab => p_rows_tab);
  END create_rows;';

      util_template_replace('API BODY');
      util_debug_stop_one_step;
    END gen_create_rows_bulk_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_create_row_prc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_create_row_prc');
      g_code_blocks.template := '

  PROCEDURE create_row (
    {% LIST_PARAMS_W_PK defaults=true hide_identity_columns=true %} );';
      util_template_replace('API SPEC');
      g_code_blocks.template := '

  PROCEDURE create_row (
    {% LIST_PARAMS_W_PK defaults=true hide_identity_columns=true %} )
  IS
    v_return {{ RETURN_TYPE }};
  BEGIN
    v_return := create_row (
      {% LIST_MAP_PAR_EQ_PARAM_W_PK hide_identity_columns=true %} );
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
    {{ ROWTYPE_PARAM }}
  RETURN {{ RETURN_TYPE }};';
      util_template_replace('API SPEC');
      g_code_blocks.template := '

  FUNCTION create_row (
    {{ ROWTYPE_PARAM }}
  RETURN {{ RETURN_TYPE }} IS
    v_return {{ RETURN_TYPE }};
  BEGIN
    v_return := create_row (
      {% LIST_MAP_PAR_EQ_ROWTYPCOL_W_PK hide_identity_columns=true %} );
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
    {{ ROWTYPE_PARAM }};';
      util_template_replace('API SPEC');
      g_code_blocks.template := '

  PROCEDURE create_row (
    {{ ROWTYPE_PARAM }}
  IS
    v_return {{ RETURN_TYPE }};
  BEGIN
    v_return := create_row (
      {% LIST_MAP_PAR_EQ_ROWTYPCOL_W_PK hide_identity_columns=true %} );
  END create_row;';
      util_template_replace('API BODY');
      util_debug_stop_one_step;
    END gen_create_rowtype_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_read_row_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_read_row_fnc');
      g_code_blocks.template := '

  FUNCTION read_row (
    {% LIST_PK_PARAMS %} )
  RETURN "{{ TABLE_NAME }}"%ROWTYPE;';
      util_template_replace('API SPEC');
      g_code_blocks.template := '

  FUNCTION read_row (
    {% LIST_PK_PARAMS %} )
  RETURN "{{ TABLE_NAME }}"%ROWTYPE IS
    v_row "{{ TABLE_NAME }}"%ROWTYPE;
    CURSOR cur_row IS
      SELECT *
        FROM "{{ TABLE_NAME }}"
       WHERE {% LIST_PK_COLUMN_COMPARE %};
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
    p_ref_cursor     IN t_strong_ref_cursor )
  RETURN t_rows_tab;';

      util_template_replace('API SPEC');


      g_code_blocks.template := '

  FUNCTION read_rows (
    p_ref_cursor     IN t_strong_ref_cursor )
  RETURN t_rows_tab
  IS
    v_return t_rows_tab;
  BEGIN
    IF (p_ref_cursor%ISOPEN)
    THEN
      g_bulk_completed := FALSE;

      FETCH p_ref_cursor BULK COLLECT INTO v_return LIMIT g_bulk_limit;

      IF (v_return.COUNT < g_bulk_limit)
      THEN
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
    v_row "{{ TABLE_NAME }}"%ROWTYPE;
  BEGIN
    v_row := read_row ( {% LIST_PK_MAP_PARAM_EQ_PARAM %} );
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
        FOR i IN g_uk_constraints.first .. g_uk_constraints.last LOOP
          g_iterator.current_uk_constraint := g_uk_constraints(i).constraint_name;
          g_code_blocks.template           := '

  FUNCTION read_row (
    {% LIST_UK_PARAMS %} )
  RETURN "{{ TABLE_NAME }}"%ROWTYPE;';
          util_template_replace('API SPEC');
          g_code_blocks.template := '

  FUNCTION read_row (
    {% LIST_UK_PARAMS %} )
  RETURN "{{ TABLE_NAME }}"%ROWTYPE IS
    v_row "{{ TABLE_NAME }}"%ROWTYPE;
    CURSOR cur_row IS
      SELECT *
        FROM "{{ TABLE_NAME }}"
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
      v_other_cols t_tab_vc2_5k;
    BEGIN
      util_debug_start_one_step(p_action => 'gen_update_row_prc');
      v_other_cols := util_generate_list(p_list_name => 'LIST_SET_COL_EQ_PARAM_WO_PK');

      g_code_blocks.template := '

  PROCEDURE update_row (
    {% LIST_PARAMS_W_PK %} );';
        util_template_replace('API SPEC');

      -- check if additional columns exist that are
      -- a) not part of PK and
      -- b) not excluded columns
      -- if no additional column is available for updating, update API is
      -- will be generated with extra comments
      IF v_other_cols.count > 0 THEN
        g_code_blocks.template := '

  PROCEDURE update_row (
    {% LIST_PARAMS_W_PK %} )
  IS
    v_row   "{{ TABLE_NAME }}"%ROWTYPE;
    {{ COUNTER_DECLARATION }}
  BEGIN
    v_row := read_row ( {% LIST_PK_MAP_PARAM_EQ_PARAM %} );
    -- update only, if the column values really differ
    IF {% LIST_COLUMNS_WO_PK_COMPARE %}
    THEN
      UPDATE {{ TABLE_NAME }}
         SET {% LIST_SET_COL_EQ_PARAM_WO_PK %}
       WHERE {% LIST_PK_COLUMN_COMPARE %};
    END IF;
  END update_row;';
      ELSE
        g_code_blocks.template := '

  PROCEDURE update_row (
    {% LIST_PARAMS_W_PK %} )
  IS
  BEGIN
    -- there is no column anymore to update! All remaining columns are part
    -- of the primary key or excluded via exclude column list
    NULL;
  END update_row;';
      END IF;

      util_template_replace('API BODY');
      util_debug_stop_one_step;
    END gen_update_row_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_update_rowtype_prc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_update_rowtype_prc');
      g_code_blocks.template := '

  PROCEDURE update_row (
    {{ ROWTYPE_PARAM }};';
      util_template_replace('API SPEC');
      g_code_blocks.template := '

  PROCEDURE update_row (
    {{ ROWTYPE_PARAM }}
  IS
  BEGIN
    update_row(
      {% LIST_MAP_PAR_EQ_ROWTYPCOL_W_PK %} );
  END update_row;';
      util_template_replace('API BODY');
      util_debug_stop_one_step;
    END gen_update_rowtype_prc;

    PROCEDURE gen_update_rows_bulk_prc IS
      v_other_cols t_tab_vc2_5k;
    BEGIN
      util_debug_start_one_step(p_action => 'gen_update_rows_bulk_prc');
      v_other_cols := util_generate_list(p_list_name => 'LIST_SET_COL_EQ_PAR_BULK_WO_PK');

      g_code_blocks.template := '

  PROCEDURE update_rows (
    p_rows_tab       IN t_rows_tab );';
      util_template_replace('API SPEC');

      -- check if columns exist that are
      -- a) not part of PK and
      -- b) not excluded columns
      -- if no additional column is available, update API is
      -- useless and will be generated with extra comment

      IF v_other_cols.count > 0 THEN
        g_code_blocks.template := '

  PROCEDURE update_rows (
    p_rows_tab       IN t_rows_tab )
  IS
  BEGIN
    FORALL i IN INDICES OF p_rows_tab
      UPDATE {{ TABLE_NAME }}
         SET {% LIST_SET_COL_EQ_PAR_BULK_WO_PK %}
       WHERE {% LIST_PK_COLUMN_BULK_COMPARE %};
  END update_rows;';
      ELSE
        g_code_blocks.template := '

  PROCEDURE update_rows (
    p_rows_tab       IN t_rows_tab )
  IS
  BEGIN
    -- there is no column anymore to update! All remaining columns are part
    -- of the primary key or excluded via exclude column list
    NULL;
  END update_rows;';
      END IF;

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
    IF row_exists( {% LIST_PK_MAP_PARAM_EQ_PARAM %} ) THEN
      update_row(
        {% LIST_MAP_PAR_EQ_PARAM_W_PK padding=8 %} );
      v_return := read_row ( {% LIST_PK_MAP_PARAM_EQ_PARAM %} ){{ RETURN_TYPE_READ_ROW }};
    ELSE
      v_return := create_row (
        {% LIST_MAP_PAR_EQ_PARAM_W_PK padding=8 hide_identity_columns=true %} );
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
    {{ ROWTYPE_PARAM }}
  RETURN {{ RETURN_TYPE }};';
      util_template_replace('API SPEC');
      g_code_blocks.template := '

  FUNCTION create_or_update_row (
    {{ ROWTYPE_PARAM }}
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
    {{ ROWTYPE_PARAM }};';
      util_template_replace('API SPEC');
      g_code_blocks.template := '

  PROCEDURE create_or_update_row (
    {{ ROWTYPE_PARAM }}
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
     WHERE {% LIST_PK_COLUMN_COMPARE %};' || CASE
                                  WHEN g_params.enable_generic_change_log AND NOT g_status.pk_is_multi_column THEN
                                   '
    create_change_log_entry(
      p_table     => ''{{ TABLE_NAME }}'',
      p_column    => ''{{ PK_COLUMN }}'',
      p_pk_id     => {{ PARAMETER_PK_FIRST_COLUMN }},
      p_old_value => ''ROW DELETED'',
      p_new_value => ''ROW DELETED'' );'
                                END || '
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
    p_rows_tab       IN t_rows_tab );';
      util_template_replace('API SPEC');
      g_code_blocks.template := '

  PROCEDURE delete_rows (
    p_rows_tab       IN t_rows_tab )
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
      FOR i IN g_columns.first .. g_columns.last LOOP
        IF g_columns(i).is_pk_yn = 'N' THEN
          g_iterator.column_name := g_columns(i).column_name;
          g_iterator.method_name := util_get_method_name(g_columns(i).column_name);
          g_code_blocks.template := '

  FUNCTION get_{{ I_METHOD_NAME }}(
    {% LIST_PK_PARAMS %} )
  RETURN "{{ TABLE_NAME }}"."{{ I_COLUMN_NAME }}"%TYPE;';
          util_template_replace('API SPEC');
          g_code_blocks.template := '

  FUNCTION get_{{ I_METHOD_NAME }}(
    {% LIST_PK_PARAMS %} )
  RETURN "{{ TABLE_NAME }}"."{{ I_COLUMN_NAME }}"%TYPE IS
    v_row "{{ TABLE_NAME }}"%ROWTYPE;
  BEGIN
    v_row := read_row ( {% LIST_PK_MAP_PARAM_EQ_PARAM %} );
    RETURN v_row."{{ I_COLUMN_NAME }}";
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
      FOR i IN g_columns.first .. g_columns.last LOOP
        IF g_columns(i).is_excluded_yn = 'N' AND g_columns(i).is_pk_yn = 'N' THEN
          g_iterator.column_name    := g_columns(i).column_name;
          g_iterator.method_name    := util_get_method_name(g_columns(i).column_name);
          g_iterator.parameter_name := util_get_parameter_name(g_columns(i).column_name, g_status.rpad_columns);

          g_iterator.column_compare := util_get_attribute_compare(p_data_type         => g_columns(i).data_type,
                                                                  p_nullable          => util_string_to_bool(g_columns(i).is_nullable_yn),
                                                                  p_first_attribute   => 'v_row."' || g_columns(i).column_name || '"',
                                                                  p_second_attribute  => TRIM(g_iterator.parameter_name),
                                                                  p_compare_operation => '<>');

          g_iterator.old_value := util_get_vc2_4000_operation(p_data_type      => g_columns(i).data_type,
                                                              p_attribute_name => 'v_row."' || g_columns(i).column_name || '"');

          g_iterator.new_value := util_get_vc2_4000_operation(p_data_type      => g_columns(i).data_type,
                                                              p_attribute_name => g_iterator.parameter_name);

          g_code_blocks.template := '

  PROCEDURE set_{{ I_METHOD_NAME }} (
    {% LIST_PK_PARAMS %},
    {{ I_PARAMETER_NAME }} IN "{{ TABLE_NAME }}"."{{ I_COLUMN_NAME }}"%TYPE );';
          util_template_replace('API SPEC');
          g_code_blocks.template := '

  PROCEDURE set_{{ I_METHOD_NAME }} (
    {% LIST_PK_PARAMS %},
    {{ I_PARAMETER_NAME }} IN "{{ TABLE_NAME }}"."{{ I_COLUMN_NAME }}"%TYPE )
  IS
    v_row "{{ TABLE_NAME }}"%ROWTYPE;
  BEGIN
    v_row := read_row ( {% LIST_PK_MAP_PARAM_EQ_PARAM %} );
    -- update only,if the column value really differs
    IF {{ I_COLUMN_COMPARE }} THEN
      UPDATE {{ TABLE_NAME }}
         SET "{{ I_COLUMN_NAME }}" = {{ I_PARAMETER_NAME }}
       WHERE {% LIST_PK_COLUMN_COMPARE %};' || CASE
                                    WHEN g_params.enable_generic_change_log AND NOT g_status.pk_is_multi_column THEN
                                     '
      create_change_log_entry(
        p_table     => ''{{ TABLE_NAME }}'',
        p_column    => ''{{ I_COLUMN_NAME }}'',
        p_pk_id     => {{ PARAMETER_PK_FIRST_COLUMN }},
        p_old_value => {{ I_OLD_VALUE }},
        p_new_value => {{ I_NEW_VALUE }} );'
                                  END || '
    END IF;
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
  RETURN "{{ TABLE_NAME }}"%ROWTYPE;
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Returns a row with (hopefully) complete default data.
   */';
      util_template_replace('API SPEC');
      g_code_blocks.template := '

  FUNCTION get_a_row
  RETURN "{{ TABLE_NAME }}"%ROWTYPE IS
    v_row "{{ TABLE_NAME }}"%ROWTYPE;
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
    {% LIST_PARAMS_W_PK_CUST_DEFAULTS hide_identity_columns=true %} )
  RETURN {{ RETURN_TYPE }};
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Create a new row without (hopefully) providing any parameters.
   */';
      util_template_replace('API SPEC');
      g_code_blocks.template := '

  FUNCTION create_a_row (
    {% LIST_PARAMS_W_PK_CUST_DEFAULTS hide_identity_columns=true %} )
  RETURN {{ RETURN_TYPE }} IS
    v_return {{ RETURN_TYPE }};
  BEGIN
    v_return := create_row (
      {% LIST_MAP_PAR_EQ_PARAM_W_PK hide_identity_columns=true %} );
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
    {% LIST_PARAMS_W_PK_CUST_DEFAULTS hide_identity_columns=true %} );
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Create a new row without (hopefully) providing any parameters.
   */';
      util_template_replace('API SPEC');
      g_code_blocks.template := '

  PROCEDURE create_a_row (
    {% LIST_PARAMS_W_PK_CUST_DEFAULTS hide_identity_columns=true %} )
  IS
    v_return {{ RETURN_TYPE }};
  BEGIN
    v_return := create_row (
      {% LIST_MAP_PAR_EQ_PARAM_W_PK hide_identity_columns=true %} );
  END create_a_row;';
      util_template_replace('API BODY');
      util_debug_stop_one_step;
    END gen_create_a_row_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_create_change_log_prc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_create_a_row_prc');
      g_code_blocks.template := '

  PROCEDURE create_change_log_entry (
    p_table     IN generic_change_log.gcl_table%TYPE,
    p_column    IN generic_change_log.gcl_column%TYPE,
    p_pk_id     IN generic_change_log.gcl_pk_id%TYPE,
    p_old_value IN generic_change_log.gcl_old_value%TYPE,
    p_new_value IN generic_change_log.gcl_new_value%TYPE )
  IS
  BEGIN
    INSERT INTO generic_change_log (
      gcl_id,
      gcl_table,
      gcl_column,
      gcl_pk_id,
      gcl_old_value,
      gcl_new_value,
      gcl_user )
    VALUES (
      generic_change_log_seq.nextval,
      p_table,
      p_column,
      p_pk_id,
      p_old_value,
      p_new_value,
      coalesce(v(''APP_USER''),sys_context(''USERENV'',''OS_USER'')) );
  END;';
      util_template_replace('API BODY');
      util_debug_stop_one_step;
    END gen_create_change_log_prc;

    -----------------------------------------------------------------------------

    PROCEDURE gen_read_a_row_fnc IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_read_a_row_fnc');
      g_code_blocks.template := '

  FUNCTION read_a_row
  RETURN "{{ TABLE_NAME }}"%ROWTYPE;
  /**
   * Helper mainly for testing and dummy data generation purposes.
   * Fetch one row (the first the database delivers) without providing
   * a primary key parameter.
   */';
      util_template_replace('API SPEC');
      g_code_blocks.template := '

  FUNCTION read_a_row
  RETURN "{{ TABLE_NAME }}"%ROWTYPE IS
    v_row  "{{ TABLE_NAME }}"%ROWTYPE;
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
      g_code_blocks.template := CASE
                                  WHEN g_params.enable_custom_defaults THEN
                                   c_lf || '
  /*
  Only custom defaults with the source "USER" are used when "p_reuse_existing_api_params" is set to true.
  All other custom defaults are only listed for convenience and determined at runtime by the generator.
  You can simply copy over the defaults to your generator call - the attribute "source" is ignored then.
  {% LIST_SPEC_CUSTOM_DEFAULTS %}
  */'
                                END || '
END "{{ API_NAME }}";';

      util_template_replace('API SPEC');
      g_code_blocks.template := '

END "{{ API_NAME }}";';
      util_template_replace('API BODY');
      util_debug_stop_one_step;
    END gen_footer;

    -----------------------------------------------------------------------------

    PROCEDURE gen_dml_view IS
    BEGIN
      util_debug_start_one_step(p_action => 'gen_dml_view');
      g_code_blocks.template := '
CREATE OR REPLACE VIEW "{{ OWNER }}"."{{ TABLE_NAME_MINUS_6 }}_DML_V" AS
SELECT {% LIST_COLUMNS_W_PK_FULL %}
  FROM {{ TABLE_NAME }}
  /**
   * generator="{{ GENERATOR }}"
   * generator_version="{{ GENERATOR_VERSION }}"
   * generator_action="{{ GENERATOR_ACTION }}"
   * generated_at="{{ GENERATED_AT }}"
   * generated_by="{{ GENERATED_BY }}"
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
CREATE OR REPLACE TRIGGER "{{ OWNER }}"."{{ TABLE_NAME_MINUS_6 }}_IOIUD"
  INSTEAD OF INSERT OR UPDATE OR DELETE
  ON "{{ TABLE_NAME_MINUS_6 }}_DML_V"
  FOR EACH ROW
  /**
   * generator="{{ GENERATOR }}"
   * generator_version="{{ GENERATOR_VERSION }}"
   * generator_action="{{ GENERATOR_ACTION }}"
   * generated_at="{{ GENERATED_AT }}"
   * generated_by="{{ GENERATED_BY }}"
   */
BEGIN
  IF INSERTING THEN' || CASE
                                  WHEN g_params.enable_insertion_of_rows THEN
                                   '
    "{{ API_NAME }}".create_row (
      {% LIST_MAP_PAR_EQ_NEWCOL_W_PK %} );'
                                  ELSE
                                   '
    raise_application_error (' || c_generator_error_number ||
                                   ', ''Insertion of a row is not allowed.'');'
                                END || '
  ELSIF UPDATING THEN' || CASE
                                  WHEN g_params.enable_update_of_rows THEN
                                   '
    "{{ API_NAME }}".update_row (
      {% LIST_MAP_PAR_EQ_NEWCOL_W_PK %} );'
                                  ELSE
                                   '
    raise_application_error (' || c_generator_error_number ||
                                   ', ''Update of a row is not allowed.'');'
                                END || '
  ELSIF DELETING THEN' || CASE
                                  WHEN g_params.enable_deletion_of_rows THEN
                                   '
    "{{ API_NAME }}".delete_row (
      {% LIST_PK_MAP_PARAM_EQ_OLDCOL %} );'
                                  ELSE
                                   '
    raise_application_error (' || c_generator_error_number ||
                                   ', ''Deletion of a row is not allowed.'');'
                                END || '
  END IF;
END "{{ TABLE_NAME_MINUS_6 }}_IOIUD";';

      util_template_replace('TRIGGER');
      util_debug_stop_one_step;
    END gen_dml_view_trigger;

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
      util_debug_stop_one_step;
    END gen_finalize_clob_vc2_caching;
  BEGIN
    gen_header;

    -- bulk header if choosen
    IF g_params.enable_bulk_methods THEN
      gen_header_bulk;
      gen_bulk_is_complete_fnc;
      gen_set_bulk_limit_prc;
      gen_get_bulk_limit_fnc;
    END IF;

    IF g_status.xmltype_column_present THEN
      gen_xml_compare_fnc;
    END IF;

    IF g_params.enable_generic_change_log AND NOT g_status.pk_is_multi_column THEN
      gen_create_change_log_prc;
    END IF;

    gen_row_exists_fnc;
    gen_row_exists_yn_fnc;

    -- GET_PK_BY_UNIQUE_COLS functions only if no multi row pk is present
    -- use overloaded READ_ROW functions with unique params instead
    IF NOT g_status.pk_is_multi_column THEN
      gen_get_pk_by_unique_cols_fnc;
    END IF;

    -- CREATE procedures/functions only if allowed
    IF g_params.enable_insertion_of_rows THEN
      gen_create_row_fnc;
      gen_create_row_prc;
      gen_create_rowtype_fnc;
      gen_create_rowtype_prc;

      IF g_params.enable_bulk_methods THEN
        gen_create_rows_bulk_fnc;
        gen_create_rows_bulk_prc;
      END IF;
    END IF;

    -- READ procedures
    gen_read_row_fnc;

    gen_read_row_by_uk_fnc;
    IF g_params.enable_proc_with_out_params THEN
      gen_read_row_prc;
    END IF;

    -- bulk read_rows if choosen
    IF g_params.enable_bulk_methods THEN
      gen_read_rows_bulk_fnc;
    END IF;

    -- UPDATE procedures/functions only if allowed
    IF g_params.enable_update_of_rows THEN
      gen_update_row_prc;
      gen_update_rowtype_prc;

      IF g_params.enable_bulk_methods THEN
        gen_update_rows_bulk_prc;
      END IF;
    END IF;

    -- DELETE procedures only if allowed
    IF g_params.enable_deletion_of_rows THEN
      gen_delete_row_prc;

      IF g_params.enable_bulk_methods THEN
        gen_delete_rows_bulk_prc;
      END IF;
    END IF;

    -- CREATE or UPDATE procedures/functions only if both is allowed
    IF g_params.enable_insertion_of_rows AND g_params.enable_update_of_rows THEN
      gen_createorupdate_row_fnc;
      gen_createorupdate_row_prc;
      gen_createorupdate_rowtype_fnc;
      gen_createorupdate_rowtype_prc;
    END IF;

    -- GETTER procedures/functions always
    IF g_params.enable_getter_and_setter THEN
      gen_getter_functions;
    END IF;

    -- SETTER procedures/functions only if allowed
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

    -- DML View and Trigger only if allowed
    IF g_params.enable_dml_view THEN
      gen_dml_view;
      gen_dml_view_trigger;
    END IF;

    gen_finalize_clob_vc2_caching;

  END main_generate_code;

  -----------------------------------------------------------------------------

  PROCEDURE main_compile_code IS
  BEGIN
    -- compile package spec
    util_debug_start_one_step(p_action => 'compile_spec');
    BEGIN
      util_execute_sql(g_code_blocks.api_spec);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    util_debug_stop_one_step;

    -- compile package body
    util_debug_start_one_step(p_action => 'compile_body');
    BEGIN
      util_execute_sql(g_code_blocks.api_body);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    util_debug_stop_one_step;

    IF g_params.enable_dml_view THEN

      -- compile DML view
      util_debug_start_one_step(p_action => 'compile_dml_view');
      BEGIN
        util_execute_sql(g_code_blocks.dml_view);
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      util_debug_stop_one_step;

      -- compile DML view trigger
      util_debug_start_one_step(p_action => 'compile_dml_view_trigger');
      BEGIN
        util_execute_sql(g_code_blocks.dml_view_trigger);
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      util_debug_stop_one_step;

    END IF;
  END main_compile_code;

  -----------------------------------------------------------------------------

  FUNCTION main_return_code RETURN CLOB IS
    terminator VARCHAR2(10 CHAR) := c_lf || '/' || c_lflf;
  BEGIN
    RETURN g_code_blocks.api_spec || terminator || g_code_blocks.api_body || terminator || CASE WHEN g_params.enable_dml_view THEN g_code_blocks.dml_view || terminator || g_code_blocks.dml_view_trigger || terminator ELSE NULL END;
  END main_return_code;

  -----------------------------------------------------------------------------

  PROCEDURE compile_api
  (
    p_table_name                  IN all_objects.object_name%TYPE,
    p_owner                       IN all_users.username%TYPE DEFAULT USER,
    p_reuse_existing_api_params   IN BOOLEAN DEFAULT om_tapigen.c_true_reuse_existing_api_para,
    p_enable_insertion_of_rows    IN BOOLEAN DEFAULT om_tapigen.c_true_enable_insertion_of_row,
    p_enable_column_defaults      IN BOOLEAN DEFAULT om_tapigen.c_false_enable_column_defaults,
    p_enable_update_of_rows       IN BOOLEAN DEFAULT om_tapigen.c_true_enable_update_of_rows,
    p_enable_deletion_of_rows     IN BOOLEAN DEFAULT om_tapigen.c_false_enable_deletion_of_row,
    p_enable_parameter_prefixes   IN BOOLEAN DEFAULT om_tapigen.c_true_enable_parameter_prefix,
    p_enable_proc_with_out_params IN BOOLEAN DEFAULT om_tapigen.c_true_enable_proc_with_out_pa,
    p_enable_getter_and_setter    IN BOOLEAN DEFAULT om_tapigen.c_true_enable_getter_and_sette,
    p_col_prefix_in_method_names  IN BOOLEAN DEFAULT om_tapigen.c_true_col_prefix_in_method_na,
    p_return_row_instead_of_pk    IN BOOLEAN DEFAULT om_tapigen.c_false_return_row_instead_of_,
    p_enable_dml_view             IN BOOLEAN DEFAULT om_tapigen.c_false_enable_dml_view,
    p_enable_generic_change_log   IN BOOLEAN DEFAULT om_tapigen.c_false_enable_generic_change_,
    p_api_name                    IN all_objects.object_name%TYPE DEFAULT NULL,
    p_sequence_name               IN all_objects.object_name%TYPE DEFAULT NULL,
    p_exclude_column_list         IN VARCHAR2 DEFAULT NULL,
    p_audit_column_mappings       IN VARCHAR2 DEFAULT NULL,
    p_audit_user_expression       IN VARCHAR2 DEFAULT om_tapigen.c_audit_user_expression,
    p_enable_custom_defaults      IN BOOLEAN DEFAULT om_tapigen.c_false_enable_custom_defaults,
    p_custom_default_values       IN xmltype DEFAULT NULL,
    p_enable_bulk_methods         IN BOOLEAN DEFAULT om_tapigen.c_true_enable_bulk_methods
  ) IS
  BEGIN
    util_debug_start_one_run(p_generator_action => 'compile API', p_table_name => p_table_name, p_owner => p_owner);
    main_init(p_generator_action            => 'COMPILE_API',
              p_table_name                  => p_table_name,
              p_owner                       => p_owner,
              p_reuse_existing_api_params   => p_reuse_existing_api_params,
              p_enable_insertion_of_rows    => p_enable_insertion_of_rows,
              p_enable_column_defaults      => p_enable_column_defaults,
              p_enable_update_of_rows       => p_enable_update_of_rows,
              p_enable_deletion_of_rows     => p_enable_deletion_of_rows,
              p_enable_parameter_prefixes   => p_enable_parameter_prefixes,
              p_enable_proc_with_out_params => p_enable_proc_with_out_params,
              p_enable_getter_and_setter    => p_enable_getter_and_setter,
              p_col_prefix_in_method_names  => p_col_prefix_in_method_names,
              p_return_row_instead_of_pk    => p_return_row_instead_of_pk,
              p_enable_dml_view             => p_enable_dml_view,
              p_enable_generic_change_log   => p_enable_generic_change_log,
              p_api_name                    => p_api_name,
              p_sequence_name               => p_sequence_name,
              p_exclude_column_list         => p_exclude_column_list,
              p_audit_column_mappings       => p_audit_column_mappings,
              p_audit_user_expression       => p_audit_user_expression,
              p_enable_custom_defaults      => p_enable_custom_defaults,
              p_custom_default_values       => p_custom_default_values,
              p_enable_bulk_methods         => p_enable_bulk_methods);
    main_generate_code;
    main_compile_code;
    util_debug_stop_one_run;
  END compile_api;

  -----------------------------------------------------------------------------

  FUNCTION compile_api_and_get_code
  (
    p_table_name                  IN all_objects.object_name%TYPE,
    p_owner                       IN all_users.username%TYPE DEFAULT USER,
    p_reuse_existing_api_params   IN BOOLEAN DEFAULT om_tapigen.c_true_reuse_existing_api_para,
    p_enable_insertion_of_rows    IN BOOLEAN DEFAULT om_tapigen.c_true_enable_insertion_of_row,
    p_enable_column_defaults      IN BOOLEAN DEFAULT om_tapigen.c_false_enable_column_defaults,
    p_enable_update_of_rows       IN BOOLEAN DEFAULT om_tapigen.c_true_enable_update_of_rows,
    p_enable_deletion_of_rows     IN BOOLEAN DEFAULT om_tapigen.c_false_enable_deletion_of_row,
    p_enable_parameter_prefixes   IN BOOLEAN DEFAULT om_tapigen.c_true_enable_parameter_prefix,
    p_enable_proc_with_out_params IN BOOLEAN DEFAULT om_tapigen.c_true_enable_proc_with_out_pa,
    p_enable_getter_and_setter    IN BOOLEAN DEFAULT om_tapigen.c_true_enable_getter_and_sette,
    p_col_prefix_in_method_names  IN BOOLEAN DEFAULT om_tapigen.c_true_col_prefix_in_method_na,
    p_return_row_instead_of_pk    IN BOOLEAN DEFAULT om_tapigen.c_false_return_row_instead_of_,
    p_enable_dml_view             IN BOOLEAN DEFAULT om_tapigen.c_false_enable_dml_view,
    p_enable_generic_change_log   IN BOOLEAN DEFAULT om_tapigen.c_false_enable_generic_change_,
    p_api_name                    IN all_objects.object_name%TYPE DEFAULT NULL,
    p_sequence_name               IN all_objects.object_name%TYPE DEFAULT NULL,
    p_exclude_column_list         IN VARCHAR2 DEFAULT NULL,
    p_audit_column_mappings       IN VARCHAR2 DEFAULT NULL,
    p_audit_user_expression       IN VARCHAR2 DEFAULT om_tapigen.c_audit_user_expression,
    p_enable_custom_defaults      IN BOOLEAN DEFAULT om_tapigen.c_false_enable_custom_defaults,
    p_custom_default_values       IN xmltype DEFAULT NULL,
    p_enable_bulk_methods         IN BOOLEAN DEFAULT om_tapigen.c_true_enable_bulk_methods
  ) RETURN CLOB IS
  BEGIN
    util_debug_start_one_run(p_generator_action => 'compile API, get code',
                             p_table_name       => p_table_name,
                             p_owner            => p_owner);

    main_init(p_generator_action            => 'COMPILE_API_AND_GET_CODE',
              p_table_name                  => p_table_name,
              p_owner                       => p_owner,
              p_reuse_existing_api_params   => p_reuse_existing_api_params,
              p_enable_insertion_of_rows    => p_enable_insertion_of_rows,
              p_enable_column_defaults      => p_enable_column_defaults,
              p_enable_update_of_rows       => p_enable_update_of_rows,
              p_enable_deletion_of_rows     => p_enable_deletion_of_rows,
              p_enable_parameter_prefixes   => p_enable_parameter_prefixes,
              p_enable_proc_with_out_params => p_enable_proc_with_out_params,
              p_enable_getter_and_setter    => p_enable_getter_and_setter,
              p_col_prefix_in_method_names  => p_col_prefix_in_method_names,
              p_return_row_instead_of_pk    => p_return_row_instead_of_pk,
              p_enable_dml_view             => p_enable_dml_view,
              p_enable_generic_change_log   => p_enable_generic_change_log,
              p_api_name                    => p_api_name,
              p_sequence_name               => p_sequence_name,
              p_exclude_column_list         => p_exclude_column_list,
              p_audit_column_mappings       => p_audit_column_mappings,
              p_audit_user_expression       => p_audit_user_expression,
              p_enable_custom_defaults      => p_enable_custom_defaults,
              p_custom_default_values       => p_custom_default_values,
              p_enable_bulk_methods         => p_enable_bulk_methods);
    main_generate_code;
    main_compile_code;
    util_debug_stop_one_run;
    RETURN main_return_code;
  END compile_api_and_get_code;

  -----------------------------------------------------------------------------

  FUNCTION get_code
  (
    p_table_name                  IN all_objects.object_name%TYPE,
    p_owner                       IN all_users.username%TYPE DEFAULT USER,
    p_reuse_existing_api_params   IN BOOLEAN DEFAULT om_tapigen.c_true_reuse_existing_api_para,
    p_enable_insertion_of_rows    IN BOOLEAN DEFAULT om_tapigen.c_true_enable_insertion_of_row,
    p_enable_column_defaults      IN BOOLEAN DEFAULT om_tapigen.c_false_enable_column_defaults,
    p_enable_update_of_rows       IN BOOLEAN DEFAULT om_tapigen.c_true_enable_update_of_rows,
    p_enable_deletion_of_rows     IN BOOLEAN DEFAULT om_tapigen.c_false_enable_deletion_of_row,
    p_enable_parameter_prefixes   IN BOOLEAN DEFAULT om_tapigen.c_true_enable_parameter_prefix,
    p_enable_proc_with_out_params IN BOOLEAN DEFAULT om_tapigen.c_true_enable_proc_with_out_pa,
    p_enable_getter_and_setter    IN BOOLEAN DEFAULT om_tapigen.c_true_enable_getter_and_sette,
    p_col_prefix_in_method_names  IN BOOLEAN DEFAULT om_tapigen.c_true_col_prefix_in_method_na,
    p_return_row_instead_of_pk    IN BOOLEAN DEFAULT om_tapigen.c_false_return_row_instead_of_,
    p_enable_dml_view             IN BOOLEAN DEFAULT om_tapigen.c_false_enable_dml_view,
    p_enable_generic_change_log   IN BOOLEAN DEFAULT om_tapigen.c_false_enable_generic_change_,
    p_api_name                    IN all_objects.object_name%TYPE DEFAULT NULL,
    p_sequence_name               IN all_objects.object_name%TYPE DEFAULT NULL,
    p_exclude_column_list         IN VARCHAR2 DEFAULT NULL,
    p_audit_column_mappings       IN VARCHAR2 DEFAULT NULL,
    p_audit_user_expression       IN VARCHAR2 DEFAULT om_tapigen.c_audit_user_expression,
    p_enable_custom_defaults      IN BOOLEAN DEFAULT om_tapigen.c_false_enable_custom_defaults,
    p_custom_default_values       IN xmltype DEFAULT NULL,
    p_enable_bulk_methods         IN BOOLEAN DEFAULT om_tapigen.c_true_enable_bulk_methods
  ) RETURN CLOB IS
  BEGIN
    util_debug_start_one_run(p_generator_action => 'get code', p_table_name => p_table_name, p_owner => p_owner);
    main_init(p_generator_action            => 'GET_CODE',
              p_table_name                  => p_table_name,
              p_owner                       => p_owner,
              p_reuse_existing_api_params   => p_reuse_existing_api_params,
              p_enable_insertion_of_rows    => p_enable_insertion_of_rows,
              p_enable_column_defaults      => p_enable_column_defaults,
              p_enable_update_of_rows       => p_enable_update_of_rows,
              p_enable_deletion_of_rows     => p_enable_deletion_of_rows,
              p_enable_parameter_prefixes   => p_enable_parameter_prefixes,
              p_enable_proc_with_out_params => p_enable_proc_with_out_params,
              p_enable_getter_and_setter    => p_enable_getter_and_setter,
              p_col_prefix_in_method_names  => p_col_prefix_in_method_names,
              p_return_row_instead_of_pk    => p_return_row_instead_of_pk,
              p_enable_dml_view             => p_enable_dml_view,
              p_enable_generic_change_log   => p_enable_generic_change_log,
              p_api_name                    => p_api_name,
              p_sequence_name               => p_sequence_name,
              p_exclude_column_list         => p_exclude_column_list,
              p_audit_column_mappings       => p_audit_column_mappings,
              p_audit_user_expression       => p_audit_user_expression,
              p_enable_custom_defaults      => p_enable_custom_defaults,
              p_custom_default_values       => p_custom_default_values,
              p_enable_bulk_methods         => p_enable_bulk_methods);
    main_generate_code;
    util_debug_stop_one_run;
    RETURN main_return_code;
  END get_code;

  -----------------------------------------------------------------------------

  PROCEDURE recreate_existing_apis(p_owner IN all_users.username%TYPE DEFAULT USER) IS
    v_apis t_tab_existing_apis;

    CURSOR v_cur IS
      SELECT * FROM TABLE(view_existing_apis(p_owner => p_owner));
  BEGIN
    OPEN v_cur;

    FETCH v_cur BULK COLLECT
      INTO v_apis LIMIT c_bulk_collect_limit;

    CLOSE v_cur;

    IF v_apis.count > 0 THEN
      FOR i IN v_apis.first .. v_apis.last LOOP
        compile_api(p_table_name => v_apis(i).table_name, p_owner => v_apis(i).owner);
      END LOOP;
    END IF;
  END;

  -----------------------------------------------------------------------------

  FUNCTION view_existing_apis
  (
    p_table_name all_tables.table_name%TYPE DEFAULT NULL,
    p_owner      all_users.username%TYPE DEFAULT USER
  ) RETURN t_tab_existing_apis
    PIPELINED IS
    v_tab t_tab_existing_apis;
    v_row t_rec_existing_apis;
  BEGIN
    -- I was not able to compile without execute immediate - got a strange ORA-03113.
    -- Direct execution of the statement in SQL tool works :-(
    EXECUTE IMMEDIATE '
-- ATTENTION: query columns need to match the global row definition om_tapigen.g_row_existing_apis.
-- Creating a cursor was not possible - database throws an error

WITH api_names AS (
         SELECT owner,
                NAME AS api_name
           FROM all_source
          WHERE     owner = :p_owner
                AND TYPE = ''PACKAGE''
                AND line BETWEEN :spec_options_min_line
                             AND :spec_options_max_line
                AND INSTR (text,''generator="OM_TAPIGEN"'') > 0
     ) -- select * from api_names;
     , sources AS (
         SELECT owner,
                package_name,
                xmltype (
                   NVL (REGEXP_SUBSTR (REPLACE (source_code, ''*'', NULL), -- replace needed for backward compatibility of old comment style
                                       ''<options.*>'',
                                       1,
                                       1,
                                       ''ni''),
                        ''<no_data_found/>''))
                   AS options
           FROM (SELECT owner,
                        NAME AS package_name,
                        LISTAGG (text, '' '')
                           WITHIN GROUP (ORDER BY NAME, line)
                           OVER (PARTITION BY NAME)
                           AS source_code
                   FROM all_source
                  WHERE     owner = :p_owner
                        AND name  IN (SELECT api_name FROM api_names)
                        AND TYPE  = ''PACKAGE''
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
                TO_DATE (x.generated_at,''yyyy-mm-dd hh24:mi:ss'') AS generated_at,
                x.generated_by,
                x.p_owner,
                x.p_table_name,
                x.p_reuse_existing_api_params,
                x.p_enable_insertion_of_rows,
                x.p_enable_column_defaults,
                x.p_enable_update_of_rows,
                x.p_enable_deletion_of_rows,
                x.p_enable_parameter_prefixes,
                x.p_enable_proc_with_out_params,
                x.p_enable_getter_and_setter,
                x.p_col_prefix_in_method_names,
                x.p_return_row_instead_of_pk,
                x.p_enable_dml_view,
                x.p_enable_generic_change_log,
                x.p_api_name,
                x.p_sequence_name,
                x.p_exclude_column_list,
                x.p_audit_column_mappings,
                x.p_audit_user_expression,
                x.p_enable_custom_defaults,
                x.p_custom_default_values,
                x.p_enable_bulk_methods
           FROM sources t
                CROSS JOIN
                XMLTABLE (
                   ''/options''
                   PASSING options
                   COLUMNS generator                     VARCHAR2 (30 CHAR)   PATH ''@generator'',
                           generator_version             VARCHAR2 (10 CHAR)   PATH ''@generator_version'',
                           generator_action              VARCHAR2 (30 CHAR)   PATH ''@generator_action'',
                           generated_at                  VARCHAR2 (30 CHAR)   PATH ''@generated_at'',
                           generated_by                  VARCHAR2 (128 CHAR)  PATH ''@generated_by'',
                           p_owner                       VARCHAR2 (128 CHAR)  PATH ''@p_owner'',
                           p_table_name                  VARCHAR2 (128 CHAR)  PATH ''@p_table_name'',
                           p_reuse_existing_api_params   VARCHAR2 (5 CHAR)    PATH ''@p_reuse_existing_api_params'',
                           p_enable_insertion_of_rows    VARCHAR2 (5 CHAR)    PATH ''@p_enable_insertion_of_rows'',
                           p_enable_column_defaults      VARCHAR2 (5 CHAR)    PATH ''@p_enable_column_defaults'',
                           p_enable_update_of_rows       VARCHAR2 (5 CHAR)    PATH ''@p_enable_update_of_rows'',
                           p_enable_deletion_of_rows     VARCHAR2 (5 CHAR)    PATH ''@p_enable_deletion_of_rows'',
                           p_enable_parameter_prefixes   VARCHAR2 (5 CHAR)    PATH ''@p_enable_parameter_prefixes'',
                           p_enable_proc_with_out_params VARCHAR2 (5 CHAR)    PATH ''@p_enable_proc_with_out_params'',
                           p_enable_getter_and_setter    VARCHAR2 (5 CHAR)    PATH ''@p_enable_getter_and_setter'',
                           p_col_prefix_in_method_names  VARCHAR2 (5 CHAR)    PATH ''@p_col_prefix_in_method_names'',
                           p_return_row_instead_of_pk    VARCHAR2 (5 CHAR)    PATH ''@p_return_row_instead_of_pk'',
                           p_enable_dml_view             VARCHAR2 (5 CHAR)    PATH ''@p_enable_dml_view'',
                           p_enable_generic_change_log   VARCHAR2 (5 CHAR)    PATH ''@p_enable_generic_change_log'',
                           p_api_name                    VARCHAR2 (128 CHAR)  PATH ''@p_api_name'',
                           p_sequence_name               VARCHAR2 (128 CHAR)  PATH ''@p_sequence_name'',
                           p_exclude_column_list         VARCHAR2 (4000 CHAR) PATH ''@p_exclude_column_list'',
                           p_audit_column_mappings       VARCHAR2 (4000 CHAR) PATH ''@p_audit_column_mappings'',
                           p_audit_user_expression       VARCHAR2 (4000 CHAR) PATH ''@p_audit_user_expression'',
                           p_enable_custom_defaults      VARCHAR2 (5 CHAR)    PATH ''@p_enable_custom_defaults'',
                           p_custom_default_values       VARCHAR2 (30 CHAR)   PATH ''@p_custom_default_values'',
                           p_enable_bulk_methods         VARCHAR2 (5 CHAR)    PATH ''@p_enable_bulk_methods'') x
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
                        AND object_type = ''PACKAGE''
                        AND object_name IN (SELECT api_name FROM api_names))
                specs
                LEFT JOIN
                (SELECT object_name,
                        object_type,
                        status,
                        last_ddl_time
                   FROM all_objects
                  WHERE     owner       = :p_owner
                        AND object_type = ''PACKAGE BODY''
                        AND object_name IN (SELECT api_name FROM api_names))
                bodys
                   ON     specs.object_name              = bodys.object_name
                      AND specs.object_type || '' BODY'' = bodys.object_type
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
       apis.p_reuse_existing_api_params,
       apis.p_enable_insertion_of_rows,
       apis.p_enable_column_defaults,
       apis.p_enable_update_of_rows,
       apis.p_enable_deletion_of_rows,
       apis.p_enable_parameter_prefixes,
       apis.p_enable_proc_with_out_params,
       apis.p_enable_getter_and_setter,
       apis.p_col_prefix_in_method_names,
       apis.p_return_row_instead_of_pk,
       apis.p_enable_dml_view,
       apis.p_enable_generic_change_log,
       apis.p_api_name,
       apis.p_sequence_name,
       apis.p_exclude_column_list,
       apis.p_audit_column_mappings,
       apis.p_audit_user_expression,
       apis.p_enable_custom_defaults,
       apis.p_custom_default_values,
       apis.p_enable_bulk_methods
  FROM apis JOIN objects ON apis.package_name = objects.package_name
 WHERE table_name = NVL ( :p_table_name, table_name)
            ' BULK COLLECT
      INTO v_tab
      USING p_owner, c_spec_options_min_line, c_spec_options_max_line, p_owner, c_spec_options_min_line, c_spec_options_max_line, p_owner, p_owner, p_table_name;
    IF v_tab.count > 0 THEN
      FOR i IN v_tab.first .. v_tab.last LOOP
        PIPE ROW(v_tab(i));
      END LOOP;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      v_row.errors := substr('Incomplete resultset! ' ||
                             'This is the last correct proccessed row from the pipelined function. ' ||
                             'Did you change the params XML in one of the API packages? Original error message: ' ||
                             c_lflf || SQLERRM || c_lflf || dbms_utility.format_error_backtrace,
                             1,
                             4000);

      PIPE ROW(v_row);
  END view_existing_apis;

  -----------------------------------------------------------------------------

  FUNCTION view_naming_conflicts(p_owner all_users.username%TYPE DEFAULT USER) RETURN t_tab_naming_conflicts
    PIPELINED IS
  BEGIN
    FOR i IN (WITH ut AS
                 (SELECT table_name FROM all_tables WHERE owner = p_owner),
                temp AS
                 (SELECT substr(table_name, 1, (SELECT om_tapigen.util_get_ora_max_name_len FROM dual) - 4) || '_API' AS object_name
                   FROM ut
                 UNION ALL
                 SELECT substr(table_name, 1, (SELECT om_tapigen.util_get_ora_max_name_len FROM dual) - 6) || '_DML_V'
                   FROM ut
                 UNION ALL
                 SELECT substr(table_name, 1, (SELECT om_tapigen.util_get_ora_max_name_len FROM dual) - 6) || '_IOIUD'
                   FROM ut
                 UNION ALL
                 SELECT 'GENERIC_CHANGE_LOG'
                   FROM dual
                 UNION ALL
                 SELECT 'GENERIC_CHANGE_LOG_SEQ'
                   FROM dual
                 UNION ALL
                 SELECT 'GENERIC_CHANGE_LOG_PK'
                   FROM dual
                 UNION ALL
                 SELECT 'GENERIC_CHANGE_LOG_IDX'
                   FROM dual)
                SELECT uo.object_name, uo.object_type, uo.status, uo.last_ddl_time
                  FROM all_objects uo
                 WHERE owner = p_owner
                   AND uo.object_name IN (SELECT object_name FROM temp)
                 ORDER BY uo.object_name) LOOP
      PIPE ROW(i);
    END LOOP;
  END view_naming_conflicts;
END om_tapigen;
/
