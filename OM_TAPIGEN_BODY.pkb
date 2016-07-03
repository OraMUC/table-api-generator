CREATE OR REPLACE PACKAGE BODY om_tapigen IS
  --------------------------------------------------------------------------------
  c_generator_error_number CONSTANT PLS_INTEGER := -20000;
  c_list_delimiter         CONSTANT VARCHAR2(2 CHAR) := ', ';
  c_crlf                   CONSTANT VARCHAR2(2 CHAR) := chr(13) || chr(10);
  c_crlflf                 CONSTANT VARCHAR2(3 CHAR) := chr(13) || chr(10) ||
                                                        chr(10);
  --
  g_table_name                 user_tables.table_name%TYPE;
  g_reuse_existing_api_params  BOOLEAN;
  g_col_prefix_in_method_names BOOLEAN;
  g_enable_deletion_of_rows    BOOLEAN;
  g_enable_generic_change_log  BOOLEAN;
  g_sequence_name              user_sequences.sequence_name%TYPE;
  g_xmltype_column_present     BOOLEAN;
  --
  TYPE columns_rowtype IS RECORD(
    column_name    user_tab_columns.column_name%TYPE,
    column_name_26 user_tab_columns.column_name%TYPE,
    column_name_28 user_tab_columns.column_name%TYPE,
    data_type      user_tab_cols.data_type%TYPE);
  TYPE columns_tabtype IS TABLE OF columns_rowtype INDEX BY BINARY_INTEGER;
  --
  TYPE unique_constraints_rowtype IS RECORD(
    constraint_name user_constraints.constraint_name%TYPE);
  TYPE unique_constraints_tabtype IS TABLE OF unique_constraints_rowtype INDEX BY BINARY_INTEGER;
  --
  TYPE unique_cons_columns_rowtype IS RECORD(
    constraint_name user_cons_columns.constraint_name%TYPE,
    column_name     user_cons_columns.column_name%TYPE,
    column_name_28  user_cons_columns.column_name%TYPE,
    data_type       user_tab_columns.data_type%TYPE);
  TYPE unique_cons_columns_tabtype IS TABLE OF unique_cons_columns_rowtype INDEX BY BINARY_INTEGER;
  --
  SUBTYPE substitution_key IS VARCHAR2(100 CHAR);
  SUBTYPE substitution_value IS VARCHAR2(32767 CHAR);
  TYPE substitutions_array IS TABLE OF substitution_value INDEX BY substitution_key;
  --
  TYPE tapi_code_rowtype IS RECORD(
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
  g_columns             columns_tabtype;
  g_unique_constraints  unique_constraints_tabtype;
  g_unique_cons_columns unique_cons_columns_tabtype;
  g_substitutions       substitutions_array;
  g_code                tapi_code_rowtype;
  g_params_existing_api g_cur_existing_apis%ROWTYPE;
  --------------------------------------------------------------------------------
  CURSOR g_cur_table_exists IS
    SELECT table_name FROM user_tables WHERE table_name = g_table_name;
  --
  CURSOR g_cur_sequence_exists IS
    SELECT sequence_name
      FROM user_sequences
     WHERE sequence_name = g_sequence_name;
  --
  CURSOR g_cur_columns IS
    SELECT column_name AS column_name,
           NULL        AS column_name_26,
           NULL        AS column_name_28,
           data_type
      FROM user_tab_cols
     WHERE table_name = g_table_name
       AND hidden_column = 'NO'
     ORDER BY column_id;
  --
  CURSOR g_cur_unique_constraints IS
    SELECT constraint_name
      FROM user_constraints
     WHERE table_name = g_table_name
       AND constraint_type = 'U'
     ORDER BY constraint_name;
  --
  CURSOR g_cur_unique_cons_columns IS
    SELECT ucc.constraint_name,
           ucc.column_name     AS column_name,
           NULL                AS column_name_28,
           utc.data_type
      FROM user_constraints uc
      JOIN user_cons_columns ucc
        ON uc.constraint_name = ucc.constraint_name
      JOIN user_tab_columns utc
        ON ucc.table_name = utc.table_name
       AND ucc.column_name = utc.column_name
     WHERE uc.table_name = g_table_name
       AND uc.constraint_type = 'U'
     ORDER BY uc.constraint_name, ucc.position;
  --------------------------------------------------------------------------------
  PROCEDURE util_clob_append(p_clob               IN OUT NOCOPY CLOB,
                             p_clob_varchar_cache IN OUT NOCOPY VARCHAR2,
                             p_varchar_to_append  IN VARCHAR2,
                             p_final_call         IN BOOLEAN DEFAULT FALSE) IS
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
  --------------------------------------------------------------------------------
  PROCEDURE util_template_replace(p_scope IN VARCHAR2 DEFAULT NULL) IS
    v_pattern   VARCHAR2(30 CHAR) := '#\w+#';
    v_start_pos PLS_INTEGER := 1;
    v_match_pos PLS_INTEGER := 0;
    v_match_len PLS_INTEGER := 0;
    v_match     substitution_key;
    v_tpl_len   PLS_INTEGER;
    PROCEDURE get_match_pos IS
      -- finds the first position of a substitution string like #TABLE_NAME#
    BEGIN
      v_match_pos := regexp_instr(g_code.template, v_pattern, v_start_pos);
    END get_match_pos;
    PROCEDURE code_append(p_code_snippet VARCHAR2) IS
    BEGIN
      IF p_scope = 'API SPEC' THEN
        util_clob_append(g_code.api_spec,
                         g_code.api_spec_varchar_cache,
                         p_code_snippet);
      ELSIF p_scope = 'API BODY' THEN
        util_clob_append(g_code.api_body,
                         g_code.api_body_varchar_cache,
                         p_code_snippet);
      ELSIF p_scope = 'VIEW' THEN
        util_clob_append(g_code.dml_view,
                         g_code.dml_view_varchar_cache,
                         p_code_snippet);
      ELSIF p_scope = 'TRIGGER' THEN
        util_clob_append(g_code.dml_view_trigger,
                         g_code.dml_view_trigger_varchar_cache,
                         p_code_snippet);
      END IF;
    END code_append;
  BEGIN
    v_tpl_len := length(g_code.template);
    get_match_pos;
    WHILE v_start_pos < v_tpl_len LOOP
      get_match_pos;
      IF v_match_pos > 0 THEN
        v_match_len := instr(g_code.template, '#', v_match_pos, 2) -
                       v_match_pos;
        v_match     := substr(g_code.template, v_match_pos, v_match_len + 1);
        -- (1) process text before the match      
        code_append(substr(g_code.template,
                           v_start_pos,
                           v_match_pos - v_start_pos));
        -- (2) process the match
        BEGIN
          code_append(g_substitutions(v_match)); -- this could be a problem, if not initialized
          v_start_pos := v_match_pos + v_match_len + 1;
        EXCEPTION
          WHEN no_data_found THEN
            raise_application_error(c_generator_error_number,
                                    'FIXME: Bug - Substitution ' || v_match ||
                                    ' not initialized');
        END;
      ELSE
        -- (3) process the rest of the text
        code_append(substr(g_code.template, v_start_pos));
        v_start_pos := v_tpl_len;
      END IF;
    END LOOP;
  END util_template_replace;
  --------------------------------------------------------------------------------
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
  --------------------------------------------------------------------------------
  FUNCTION util_get_table_key(p_table_name IN user_tables.table_name%TYPE,
                              p_key_type   IN user_constraints.constraint_type%TYPE DEFAULT 'P',
                              p_delimiter  IN VARCHAR2 DEFAULT ', ')
    RETURN VARCHAR2 IS
    v_table_pk VARCHAR2(4000 CHAR);
  BEGIN
    FOR i IN (WITH cons AS
                 (SELECT constraint_name
                   FROM user_constraints
                  WHERE table_name = p_table_name
                    AND constraint_type = p_key_type),
                cols AS
                 (SELECT constraint_name, column_name, position
                   FROM user_cons_columns
                  WHERE table_name = p_table_name)
                SELECT column_name
                  FROM cons
                  JOIN cols
                    ON cons.constraint_name = cols.constraint_name
                 ORDER BY position) LOOP
      v_table_pk := v_table_pk || p_delimiter || i.column_name;
    END LOOP;
    RETURN ltrim(v_table_pk, p_delimiter);
  END util_get_table_key;
  --------------------------------------------------------------------------------
  FUNCTION util_get_table_column_prefix(p_table_name IN VARCHAR2)
    RETURN VARCHAR2 IS
    v_count  PLS_INTEGER := 0;
    v_return VARCHAR2(30 CHAR);
  BEGIN
    FOR i IN (SELECT DISTINCT substr(column_name,
                                     1,
                                     CASE
                                       WHEN instr(column_name, '_') = 0 THEN
                                        length(column_name)
                                       ELSE
                                        instr(column_name, '_') - 1
                                     END) AS prefix
                FROM user_tab_cols
               WHERE table_name = p_table_name
                 AND hidden_column = 'NO') LOOP
      v_count := v_count + 1;
      IF v_count > 1 THEN
        v_return := NULL;
        EXIT;
      END IF;
      v_return := i.prefix;
    END LOOP;
    RETURN v_return;
  END util_get_table_column_prefix;
  --------------------------------------------------------------------------------
  FUNCTION util_get_attribute_surrogate(p_data_type IN user_tab_cols.data_type%TYPE)
    RETURN VARCHAR2 IS
    v_return VARCHAR2(100 CHAR);
  BEGIN
    v_return := CASE
                  WHEN p_data_type = 'NUMBER' THEN
                   '-999999999999999.999999999999999'
                  WHEN p_data_type LIKE '%CHAR%' THEN
                   q'['@@@@@@@@@@@@@@@']'
                  WHEN p_data_type = 'DATE' THEN
                   q'[TO_DATE( '01.01.1900', 'DD.MM.YYYY' )]'
                  WHEN p_data_type LIKE 'TIMESTAMP%' THEN
                   q'[TO_TIMESTAMP( '01.01.1900', 'dd.mm.yyyy' )]'
                  WHEN p_data_type = 'CLOB' THEN
                   q'[TO_CLOB( '@@@@@@@@@@@@@@@' )]'
                  WHEN p_data_type = 'BLOB' THEN
                   q'[TO_BLOB( UTL_RAW.cast_to_raw( '@@@@@@@@@@@@@@@' ) )]'
                  WHEN p_data_type = 'XMLTYPE' THEN
                   q'[XMLTYPE( '<NULL/>' )]'
                  ELSE
                   q'['@@@@@@@@@@@@@@@']'
                END;
    RETURN v_return;
  END util_get_attribute_surrogate;
  --------------------------------------------------------------------------------
  FUNCTION util_get_attribute_compare(p_data_type         IN user_tab_cols.data_type%TYPE,
                                      p_first_attribute   IN VARCHAR2,
                                      p_second_attribute  IN VARCHAR2,
                                      p_compare_operation IN VARCHAR2 DEFAULT '<>')
    RETURN VARCHAR2 IS
    v_surrogate VARCHAR2(100 CHAR);
    v_return    VARCHAR2(1000 CHAR);
  BEGIN
    v_surrogate := util_get_attribute_surrogate(p_data_type);
    v_return := CASE
                  WHEN p_data_type = 'XMLTYPE' THEN
                   'util_xml_compare( COALESCE( ' || p_first_attribute || ', ' ||
                   v_surrogate || ' ), COALESCE( ' || p_second_attribute || ', ' ||
                   v_surrogate || ' ) ) ' || p_compare_operation || ' 0'
                  WHEN p_data_type IN ('BLOB', 'CLOB') THEN
                   'DBMS_LOB.compare( COALESCE( ' || p_first_attribute || ', ' ||
                   v_surrogate || ' ), COALESCE( ' || p_second_attribute || ', ' ||
                   v_surrogate || ' ) ) ' || p_compare_operation || ' 0'
                  ELSE
                   'COALESCE( ' || p_first_attribute || ', ' || v_surrogate ||
                   ' ) ' || p_compare_operation || ' COALESCE( ' ||
                   p_second_attribute || ', ' || v_surrogate || ' )'
                END;
    RETURN v_return;
  END util_get_attribute_compare;
  --------------------------------------------------------------------------------
  FUNCTION util_get_vc2_4000_operation(p_data_type      IN user_tab_cols.data_type%TYPE,
                                       p_attribute_name IN VARCHAR2)
    RETURN VARCHAR2 IS
    v_return VARCHAR2(1000 CHAR);
  BEGIN
    v_return := CASE
                  WHEN p_data_type IN ('NUMBER', 'FLOAT', 'INTEGER') THEN
                   ' to_char(' || p_attribute_name || ')'
                  WHEN p_data_type = 'DATE' THEN
                   ' to_char(' || p_attribute_name ||
                   q'[, 'yyyy.mm.dd hh24:mi:ss')]'
                  WHEN p_data_type LIKE 'TIMESTAMP%' THEN
                   ' to_char(' || p_attribute_name ||
                   q'[, 'yyyy.mm.dd hh24:mi:ss.ffffff')]'
                  WHEN p_data_type = 'BLOB' THEN
                   q'['Data type "BLOB" is not supported for generic change log']'
                  WHEN p_data_type = 'XMLTYPE' THEN
                   ' substr( CASE WHEN ' || p_attribute_name ||
                   ' IS NULL THEN NULL ELSE ' || p_attribute_name ||
                   '.getStringVal() END, 1, 4000)'
                  ELSE
                   ' substr(' || p_attribute_name || ', 1, 4000)'
                END;
    RETURN v_return;
  END util_get_vc2_4000_operation;
  --------------------------------------------------------------------------------
  FUNCTION util_string_to_bool(p_string IN VARCHAR2) RETURN BOOLEAN IS
  BEGIN
    RETURN CASE WHEN lower(p_string) IN('true', 'yes', 'y', '1') THEN TRUE WHEN lower(p_string) IN('false',
                                                                                                   'no',
                                                                                                   'n',
                                                                                                   '0') THEN FALSE ELSE NULL END;
  END util_string_to_bool;
  --------------------------------------------------------------------------------
  FUNCTION util_bool_to_string(p_bool IN BOOLEAN) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE WHEN p_bool THEN 'TRUE' WHEN NOT p_bool THEN 'FALSE' ELSE NULL END;
  END util_bool_to_string;
  --------------------------------------------------------------------------------
  FUNCTION util_get_user_name RETURN user_users.username%TYPE IS
    v_return user_users.username%TYPE;
  BEGIN
    v_return := upper(coalesce(v('APP_USER'),
                               sys_context('USERENV', 'OS_USER'),
                               USER));
    RETURN v_return;
  END util_get_user_name;
  --------------------------------------------------------------------------------
  PROCEDURE gen_header IS
  BEGIN
    g_code.template := ' 
CREATE OR REPLACE PACKAGE #TABLE_NAME_26#_api IS 
  /** 
   * This is the API for the table #TABLE_NAME#. 
   *
   * GENERATION OPTIONS 
   * - must be in the lines 5-25 to be reusable by the generator
   * - DO NOT TOUCH THIS until you know what you do - read the
   *   docs under github.com/OraMUC/table-api-generator ;-)
   * <options 
   *   generator="#GENERATOR#"
   *   generator_version="#GENERATOR_VERSION#"
   *   generator_action="#GENERATOR_ACTION#"
   *   generated_at="#GENERATED_AT#"
   *   generated_by="#GENERATED_BY#"
   *   p_table_name="#TABLE_NAME#"
   *   p_reuse_existing_api_params="' ||
                       util_bool_to_string(g_reuse_existing_api_params) || '"
   *   p_col_prefix_in_method_names="' ||
                       util_bool_to_string(g_col_prefix_in_method_names) || '"
   *   p_enable_deletion_of_rows="' ||
                       util_bool_to_string(g_enable_deletion_of_rows) || '"
   *   p_enable_generic_change_log="' ||
                       util_bool_to_string(g_enable_generic_change_log) || '"
   *   p_sequence_name="#SEQUENCE_NAME#"/>
   * 
   * This API provides DML functionality that can be easily called from APEX. Target  
   * of the table API is to encapsulate the table DML source code for security 
   * (UI schema needs only the execute right for the API and the read/write right
   * for the #TABLE_NAME_24#_dml_v, tables can be hidden in extra data schema) and 
   * easy readability of the business logic (all DML is then written in the same 
   * style). For APEX automatic row processing like tabular forms you can use the 
   * #TABLE_NAME_24#_dml_v, which has an instead of trigger who is also calling 
   * the #TABLE_NAME_26#_api.
   */
  ----------------------------------------';
    util_template_replace('API SPEC');
    ----------------------------------------
    g_code.template := ' 
CREATE OR REPLACE PACKAGE BODY #TABLE_NAME_26#_api IS
  ----------------------------------------' || CASE
                         WHEN g_xmltype_column_present THEN
                          q'[ 
  FUNCTION util_xml_compare( p_doc1 XMLTYPE, p_doc2 XMLTYPE )   
  RETURN NUMBER IS   
    v_return NUMBER;
  BEGIN     
    SELECT CASE WHEN XMLEXISTS( 'declare default element namespace "http://xmlns.oracle.com/xdb/xdiff.xsd"; /xdiff/*' PASSING XMLDIFF( p_doc1, p_doc2 ) ) THEN 1 ELSE 0 END 
      INTO v_return       
      FROM DUAL;   
    RETURN v_return;
  END util_xml_compare;
  ----------------------------------------]'
                         ELSE
                          NULL
                       END || CASE
                         WHEN g_enable_generic_change_log THEN
                          q'[
  PROCEDURE create_change_log_entry( p_table VARCHAR2, p_column VARCHAR2, p_pk_id NUMBER, p_old_value VARCHAR2, p_new_value VARCHAR2 )
  IS
  BEGIN
    INSERT INTO generic_change_log ( gcl_id, gcl_table, gcl_column, gcl_pk_id, gcl_old_value, gcl_new_value, gcl_user )
    VALUES ( generic_change_log_seq.nextval, p_table, p_column, p_pk_id, p_old_value, p_new_value, coalesce(v('APP_USER'),sys_context('USERENV','OS_USER')) );
  END;
  ----------------------------------------]'
                         ELSE
                          NULL
                       END;
    util_template_replace('API BODY');
  END gen_header;
  --------------------------------------------------------------------------------
  PROCEDURE gen_row_exists_fnc IS
  BEGIN
    g_code.template := ' 
  FUNCTION row_exists( p_#PK_COLUMN_28# IN #TABLE_NAME#.#PK_COLUMN#%TYPE )
  RETURN BOOLEAN;
  ----------------------------------------';
    util_template_replace('API SPEC');
    ----------------------------------------
    g_code.template := ' 
  FUNCTION row_exists( p_#PK_COLUMN_28# IN #TABLE_NAME#.#PK_COLUMN#%TYPE )
  RETURN BOOLEAN 
  IS
    v_return BOOLEAN := FALSE;
  BEGIN
    FOR i IN ( SELECT 1 FROM #TABLE_NAME# WHERE #PK_COLUMN# = p_#PK_COLUMN_28# ) LOOP
      v_return := TRUE;
    END LOOP;
    RETURN v_return;
  END;
  ----------------------------------------';
    util_template_replace('API BODY');
  END gen_row_exists_fnc;
  --------------------------------------------------------------------------------
  PROCEDURE gen_get_pk_by_unique_cols_fnc IS
  BEGIN
    IF g_unique_constraints.count > 0 THEN
      FOR i IN g_unique_constraints.first .. g_unique_constraints.last LOOP
        g_substitutions('#PARAM_LIST_UNIQUE#') := NULL;
        g_substitutions('#COLUMN_COMPARE_LIST_UNIQUE#') := NULL;
        FOR j IN g_unique_cons_columns.first .. g_unique_cons_columns.last LOOP
          IF g_unique_cons_columns(j)
           .constraint_name = g_unique_constraints(i).constraint_name THEN
            g_unique_cons_columns(j).column_name_28 := substr(g_unique_cons_columns(j)
                                                              .column_name,
                                                              1,
                                                              28);
            g_substitutions('#PARAM_LIST_UNIQUE#') := g_substitutions('#PARAM_LIST_UNIQUE#') ||
                                                      c_list_delimiter || 'p_' || g_unique_cons_columns(j)
                                                     .column_name_28 || ' ' ||
                                                      g_table_name || '.' || g_unique_cons_columns(j)
                                                     .column_name ||
                                                      '%TYPE';
            g_substitutions('#COLUMN_COMPARE_LIST_UNIQUE#') := g_substitutions('#COLUMN_COMPARE_LIST_UNIQUE#') ||
                                                               '         AND ' ||
                                                               util_get_attribute_compare(p_data_type         => g_unique_cons_columns(j)
                                                                                                                 .data_type,
                                                                                          p_first_attribute   => g_unique_cons_columns(j)
                                                                                                                 .column_name,
                                                                                          p_second_attribute  => 'p_' || g_unique_cons_columns(j)
                                                                                                                .column_name_28,
                                                                                          p_compare_operation => '=') ||
                                                               c_crlf;
          END IF;
        END LOOP;
        g_substitutions('#PARAM_LIST_UNIQUE#') := ltrim(g_substitutions('#PARAM_LIST_UNIQUE#'),
                                                        c_list_delimiter);
        g_substitutions('#COLUMN_COMPARE_LIST_UNIQUE#') := rtrim(ltrim(g_substitutions('#COLUMN_COMPARE_LIST_UNIQUE#'),
                                                                       '         AND '),
                                                                 c_crlf);
        g_code.template := ' 
  FUNCTION get_pk_by_unique_cols( #PARAM_LIST_UNIQUE# )
  RETURN #TABLE_NAME#.#PK_COLUMN#%TYPE;
  ----------------------------------------';
        util_template_replace('API SPEC');
        ----------------------------------------
        g_code.template := ' 
  FUNCTION get_pk_by_unique_cols( #PARAM_LIST_UNIQUE# )
  RETURN #TABLE_NAME#.#PK_COLUMN#%TYPE IS
    v_pk #TABLE_NAME#.#PK_COLUMN#%TYPE;
    CURSOR cur_row IS
      SELECT #PK_COLUMN# from #TABLE_NAME#
       WHERE #COLUMN_COMPARE_LIST_UNIQUE#;
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_pk;
    CLOSE cur_row;
    RETURN v_pk;
  END get_pk_by_unique_cols;
  ----------------------------------------';
        util_template_replace('API BODY');
      END LOOP;
    END IF;
  END gen_get_pk_by_unique_cols_fnc;
  --------------------------------------------------------------------------------
  PROCEDURE gen_create_row_fnc IS
  BEGIN
    g_code.template := ' 
  FUNCTION create_row( #PARAM_DEFINITION_W_PK# )
  RETURN #TABLE_NAME#.#PK_COLUMN#%TYPE;
  ----------------------------------------';
    util_template_replace('API SPEC');
    ----------------------------------------
    g_code.template := ' 
  FUNCTION create_row( #PARAM_DEFINITION_W_PK# ) 
  RETURN #TABLE_NAME#.#PK_COLUMN#%TYPE IS
    v_pk #TABLE_NAME#.#PK_COLUMN#%TYPE;
  BEGIN' || CASE
                         WHEN g_sequence_name IS NOT NULL THEN
                          '
    v_pk := COALESCE( p_#PK_COLUMN_28#, #SEQUENCE_NAME#.nextval );'
                         ELSE
                          NULL
                       END || '
    INSERT INTO #TABLE_NAME# ( #COLUMN_LIST_W_PK# )
      VALUES ( v_pk, #PARAM_LIST_WO_PK# )' || CASE
                         WHEN g_sequence_name IS NOT NULL THEN
                          ';'
                         ELSE
                          '
      RETURN #PK_COLUMN# INTO v_pk;'
                       END || CASE
                         WHEN g_enable_generic_change_log THEN
                          q'[
    create_change_log_entry( p_table     => '#TABLE_NAME#'
                           , p_column    => '#PK_COLUMN#'
                           , p_pk_id     => v_pk
                           , p_old_value => 'ROW CREATED'
                           , p_new_value => 'ROW CREATED' );]'
                         ELSE
                          NULL
                       END || ' 
    RETURN v_pk;
  END create_row;
  ----------------------------------------';
    util_template_replace('API BODY');
  END gen_create_row_fnc;
  --------------------------------------------------------------------------------
  PROCEDURE gen_create_row_prc IS
  BEGIN
    g_code.template := '
  PROCEDURE create_row( #PARAM_DEFINITION_W_PK# );
  ----------------------------------------';
    util_template_replace('API SPEC');
    ----------------------------------------
    g_code.template := '
  PROCEDURE create_row( #PARAM_DEFINITION_W_PK# )
  IS
    v_pk #TABLE_NAME#.#PK_COLUMN#%TYPE;
  BEGIN
    v_pk := create_row( #MAP_PARAM_TO_PARAM_W_PK# );
  END create_row;
  ----------------------------------------';
    util_template_replace('API BODY');
  END gen_create_row_prc;
  --------------------------------------------------------------------------------
  PROCEDURE gen_create_rowtype_fnc IS
  BEGIN
    g_code.template := ' 
  FUNCTION create_row( p_row IN #TABLE_NAME#%ROWTYPE )
  RETURN #TABLE_NAME#.#PK_COLUMN#%TYPE;
  ----------------------------------------';
    util_template_replace('API SPEC');
    ----------------------------------------
    g_code.template := ' 
  FUNCTION create_row( p_row IN #TABLE_NAME#%ROWTYPE ) 
  RETURN #TABLE_NAME#.#PK_COLUMN#%TYPE IS
    v_pk #TABLE_NAME#.#PK_COLUMN#%TYPE;
  BEGIN
    v_pk := create_row( #MAP_ROWTYPE_COL_TO_PARAM_W_PK# );
    RETURN v_pk;
  END create_row;
  ----------------------------------------';
    util_template_replace('API BODY');
  END gen_create_rowtype_fnc;
  --------------------------------------------------------------------------------
  PROCEDURE gen_create_rowtype_prc IS
  BEGIN
    g_code.template := ' 
  PROCEDURE create_row( p_row IN #TABLE_NAME#%ROWTYPE );
  ----------------------------------------';
    util_template_replace('API SPEC');
    ----------------------------------------
    g_code.template := ' 
  PROCEDURE create_row( p_row IN #TABLE_NAME#%ROWTYPE )
  IS
    v_pk #TABLE_NAME#.#PK_COLUMN#%TYPE;
  BEGIN
    v_pk := create_row( #MAP_ROWTYPE_COL_TO_PARAM_W_PK# );
  END create_row;
  ----------------------------------------';
    util_template_replace('API BODY');
  END gen_create_rowtype_prc;
  --------------------------------------------------------------------------------
  PROCEDURE gen_createorupdate_row_fnc IS
  BEGIN
    g_code.template := ' 
  FUNCTION create_or_update_row( #PARAM_DEFINITION_W_PK# )
  RETURN #TABLE_NAME#.#PK_COLUMN#%TYPE;
  ----------------------------------------';
    util_template_replace('API SPEC');
    ----------------------------------------
    g_code.template := ' 
  FUNCTION create_or_update_row( #PARAM_DEFINITION_W_PK# )
  RETURN #TABLE_NAME#.#PK_COLUMN#%TYPE IS
    v_pk #TABLE_NAME#.#PK_COLUMN#%TYPE;
  BEGIN
    IF p_#PK_COLUMN_28# IS NULL THEN
      v_pk := create_row( #MAP_PARAM_TO_PARAM_W_PK# );
    ELSE
      IF row_exists( p_#PK_COLUMN_28# => p_#PK_COLUMN_28# ) THEN
        v_pk := p_#PK_COLUMN_28#;
        update_row( #MAP_PARAM_TO_PARAM_W_PK# );
      ELSE
        v_pk := create_row( #MAP_PARAM_TO_PARAM_W_PK# );
      END IF;
    END IF;
    RETURN v_pk;
  END create_or_update_row;
  ----------------------------------------';
    util_template_replace('API BODY');
  END gen_createorupdate_row_fnc;
  --------------------------------------------------------------------------------
  PROCEDURE gen_createorupdate_row_prc IS
  BEGIN
    g_code.template := ' 
  PROCEDURE create_or_update_row( #PARAM_DEFINITION_W_PK# );
  ----------------------------------------';
    util_template_replace('API SPEC');
    ----------------------------------------
    g_code.template := ' 
  PROCEDURE create_or_update_row( #PARAM_DEFINITION_W_PK# )
  IS
    v_pk #TABLE_NAME#.#PK_COLUMN#%TYPE;
  BEGIN
    v_pk := create_or_update_row( #MAP_PARAM_TO_PARAM_W_PK# );
  END create_or_update_row;
  ----------------------------------------';
    util_template_replace('API BODY');
  END gen_createorupdate_row_prc;
  --------------------------------------------------------------------------------
  PROCEDURE gen_createorupdate_rowtype_fnc IS
  BEGIN
    g_code.template := ' 
  FUNCTION create_or_update_row( p_row IN #TABLE_NAME#%ROWTYPE )
  RETURN #TABLE_NAME#.#PK_COLUMN#%TYPE;
  ----------------------------------------';
    util_template_replace('API SPEC');
    ----------------------------------------
    g_code.template := ' 
  FUNCTION create_or_update_row( p_row IN #TABLE_NAME#%ROWTYPE )
  RETURN #TABLE_NAME#.#PK_COLUMN#%TYPE IS
    v_pk #TABLE_NAME#.#PK_COLUMN#%TYPE;
  BEGIN
    v_pk := create_or_update_row( #MAP_ROWTYPE_COL_TO_PARAM_W_PK# );
    RETURN v_pk;
  END create_or_update_row;
  ----------------------------------------';
    util_template_replace('API BODY');
  END gen_createorupdate_rowtype_fnc;
  --------------------------------------------------------------------------------
  PROCEDURE gen_createorupdate_rowtype_prc IS
  BEGIN
    g_code.template := ' 
  PROCEDURE create_or_update_row( p_row IN #TABLE_NAME#%ROWTYPE );
  ----------------------------------------';
    util_template_replace('API SPEC');
    ----------------------------------------
    g_code.template := ' 
  PROCEDURE create_or_update_row( p_row IN #TABLE_NAME#%ROWTYPE )
  IS
    v_pk #TABLE_NAME#.#PK_COLUMN#%TYPE;
  BEGIN
    v_pk := create_or_update_row( #MAP_ROWTYPE_COL_TO_PARAM_W_PK# );
  END create_or_update_row;
  ----------------------------------------';
    util_template_replace('API BODY');
  END gen_createorupdate_rowtype_prc;
  --------------------------------------------------------------------------------
  PROCEDURE gen_read_row_fnc IS
  BEGIN
    g_code.template := ' 
  FUNCTION read_row( p_#PK_COLUMN_28# IN #TABLE_NAME#.#PK_COLUMN#%TYPE )
  RETURN #TABLE_NAME#%ROWTYPE;
  ----------------------------------------';
    util_template_replace('API SPEC');
    ----------------------------------------
    g_code.template := ' 
  FUNCTION read_row( p_#PK_COLUMN_28# IN #TABLE_NAME#.#PK_COLUMN#%TYPE )
  RETURN #TABLE_NAME#%ROWTYPE IS
    CURSOR cur_row_by_pk( p_#PK_COLUMN_28# IN #TABLE_NAME#.#PK_COLUMN#%TYPE ) IS
      SELECT * FROM #TABLE_NAME# WHERE #PK_COLUMN# = p_#PK_COLUMN_28#;
    v_row #TABLE_NAME#%ROWTYPE;
  BEGIN
    OPEN cur_row_by_pk( p_#PK_COLUMN_28# );
    FETCH cur_row_by_pk INTO v_row;
    CLOSE cur_row_by_pk;
    RETURN v_row;
  END read_row;
  ----------------------------------------';
    util_template_replace('API BODY');
  END gen_read_row_fnc;
  --------------------------------------------------------------------------------
  PROCEDURE gen_read_row_prc IS
  BEGIN
    g_code.template := ' 
  PROCEDURE read_row( #PARAM_IO_DEFINITION_W_PK# );
  ----------------------------------------';
    util_template_replace('API SPEC');
    ----------------------------------------
    g_code.template := ' 
  PROCEDURE read_row( #PARAM_IO_DEFINITION_W_PK# )
  IS
    v_row #TABLE_NAME#%ROWTYPE;
  BEGIN
    v_row := read_row ( p_#PK_COLUMN_28# => p_#PK_COLUMN_28# );
    IF v_row.#PK_COLUMN# IS NOT NULL THEN 
      #SET_ROWTYPE_COL_TO_PARAM_WO_PK#
    END IF;
  END read_row;
  ----------------------------------------';
    util_template_replace('API BODY');
  END gen_read_row_prc;
  --------------------------------------------------------------------------------
  PROCEDURE gen_update_row_prc IS
  BEGIN
    g_code.template := ' 
  PROCEDURE update_row( #PARAM_DEFINITION_W_PK# );
  ----------------------------------------';
    util_template_replace('API SPEC');
    ----------------------------------------
    g_code.template := ' 
  PROCEDURE update_row( #PARAM_DEFINITION_W_PK# )
  IS
    v_row   #TABLE_NAME#%ROWTYPE;' || CASE
                         WHEN g_enable_generic_change_log THEN
                          '
    v_count PLS_INTEGER := 0;'
                         ELSE
                          NULL
                       END || '
  BEGIN
    v_row := read_row( p_#PK_COLUMN_28# => p_#PK_COLUMN_28# );
    IF v_row.#PK_COLUMN# IS NOT NULL THEN
      IF #COLUMN_COMPARE_LIST_WO_PK#
      THEN
        UPDATE #TABLE_NAME#
           SET #SET_PARAM_TO_COLUMN_WO_PK#
         WHERE #PK_COLUMN# = v_row.#PK_COLUMN#;
      END IF;
    END IF;
  END update_row;
  ----------------------------------------';
    util_template_replace('API BODY');
  END gen_update_row_prc;
  --------------------------------------------------------------------------------
  PROCEDURE gen_update_rowtype_prc IS
  BEGIN
    g_code.template := ' 
  PROCEDURE update_row( p_row IN #TABLE_NAME#%ROWTYPE );
  ----------------------------------------';
    util_template_replace('API SPEC');
    ----------------------------------------
    g_code.template := ' 
  PROCEDURE update_row( p_row IN #TABLE_NAME#%ROWTYPE )
  IS
  BEGIN
    update_row( #MAP_ROWTYPE_COL_TO_PARAM_W_PK# );
  END update_row;
  ----------------------------------------';
    util_template_replace('API BODY');
  END gen_update_rowtype_prc;
  --------------------------------------------------------------------------------
  PROCEDURE gen_delete_row_prc IS
  BEGIN
    IF g_enable_deletion_of_rows THEN
      g_code.template := ' 
  PROCEDURE delete_row( p_#PK_COLUMN_28# IN #TABLE_NAME#.#PK_COLUMN#%TYPE );
  ----------------------------------------';
      util_template_replace('API SPEC');
      ----------------------------------------
      g_code.template := ' 
  PROCEDURE delete_row( p_#PK_COLUMN_28# IN #TABLE_NAME#.#PK_COLUMN#%TYPE )
  IS
  BEGIN
    DELETE FROM #TABLE_NAME# WHERE #PK_COLUMN# = p_#PK_COLUMN_28#;' || CASE
                           WHEN g_enable_generic_change_log THEN
                            q'[
    create_change_log_entry( p_table     => '#TABLE_NAME#'
                           , p_column    => '#PK_COLUMN#'
                           , p_pk_id     => p_#PK_COLUMN_28#
                           , p_old_value => 'ROW DELETED'
                           , p_new_value => 'ROW DELETED' );]'
                           ELSE
                            NULL
                         END || '
  END delete_row;
  ----------------------------------------';
      util_template_replace('API BODY');
    END IF;
  END gen_delete_row_prc;
  --------------------------------------------------------------------------------
  PROCEDURE gen_getter_functions IS
  BEGIN
    FOR i IN g_columns.first .. g_columns.last LOOP
      IF (g_columns(i).column_name <> g_substitutions('#PK_COLUMN#')) THEN
        g_substitutions('#I_COLUMN_NAME#') := g_columns(i).column_name;
        g_substitutions('#I_COLUMN_NAME_26#') := g_columns(i).column_name_26;
        g_substitutions('#I_COLUMN_NAME_28#') := g_columns(i).column_name_28;
        g_code.template := ' 
  FUNCTION get_#I_COLUMN_NAME_26#( p_#PK_COLUMN_28# IN #TABLE_NAME#.#PK_COLUMN#%TYPE )
  RETURN #TABLE_NAME#.#I_COLUMN_NAME#%TYPE;
  ----------------------------------------';
        util_template_replace('API SPEC');
        ----------------------------------------
        g_code.template := ' 
  FUNCTION get_#I_COLUMN_NAME_26#( p_#PK_COLUMN_28# IN #TABLE_NAME#.#PK_COLUMN#%TYPE )
  RETURN #TABLE_NAME#.#I_COLUMN_NAME#%TYPE IS
    v_return #TABLE_NAME#.#I_COLUMN_NAME#%TYPE;
    v_row    #TABLE_NAME#%ROWTYPE;
  BEGIN
    v_row := read_row ( p_#PK_COLUMN_28# => p_#PK_COLUMN_28# );
    RETURN v_row.#I_COLUMN_NAME#;
  END get_#I_COLUMN_NAME_26#;
  ----------------------------------------';
        util_template_replace('API BODY');
      END IF;
    END LOOP;
  END gen_getter_functions;
  --------------------------------------------------------------------------------
  PROCEDURE gen_setter_procedures IS
  BEGIN
    FOR i IN g_columns.first .. g_columns.last LOOP
      IF (g_columns(i).column_name <> g_substitutions('#PK_COLUMN#')) THEN
        g_substitutions('#I_COLUMN_NAME#') := g_columns(i).column_name;
        g_substitutions('#I_COLUMN_NAME_26#') := g_columns(i).column_name_26;
        g_substitutions('#I_COLUMN_NAME_28#') := g_columns(i).column_name_28;
        g_substitutions('#I_COLUMN_COMPARE#') := util_get_attribute_compare(p_data_type         => g_columns(i)
                                                                                                   .data_type,
                                                                            p_first_attribute   => 'v_row.' || g_columns(i)
                                                                                                  .column_name,
                                                                            p_second_attribute  => 'p_' || g_columns(i)
                                                                                                  .column_name_28,
                                                                            p_compare_operation => '<>');
        g_substitutions('#I_OLD_VALUE#') := util_get_vc2_4000_operation(p_data_type      => g_columns(i)
                                                                                            .data_type,
                                                                        p_attribute_name => 'v_row.' || g_columns(i)
                                                                                           .column_name);
        g_substitutions('#I_NEW_VALUE#') := util_get_vc2_4000_operation(p_data_type      => g_columns(i)
                                                                                            .data_type,
                                                                        p_attribute_name => 'p_' || g_columns(i)
                                                                                           .column_name_28);
        g_code.template := ' 
  PROCEDURE set_#I_COLUMN_NAME_26#( p_#PK_COLUMN_28# IN #TABLE_NAME#.#PK_COLUMN#%TYPE, p_#I_COLUMN_NAME_28# IN #TABLE_NAME#.#I_COLUMN_NAME#%TYPE );
  ----------------------------------------';
        util_template_replace('API SPEC');
        ----------------------------------------
        g_code.template := ' 
  PROCEDURE set_#I_COLUMN_NAME_26#( p_#PK_COLUMN_28# IN #TABLE_NAME#.#PK_COLUMN#%TYPE, p_#I_COLUMN_NAME_28# IN #TABLE_NAME#.#I_COLUMN_NAME#%TYPE )
  IS
    v_#I_COLUMN_NAME_28# #TABLE_NAME#.#I_COLUMN_NAME#%TYPE;
    v_row #TABLE_NAME#%ROWTYPE;
  BEGIN
    v_row := read_row ( p_#PK_COLUMN_28# => p_#PK_COLUMN_28# );
    IF v_row.#PK_COLUMN# IS NOT NULL THEN
      IF #I_COLUMN_COMPARE# THEN
        UPDATE #TABLE_NAME#
           SET #I_COLUMN_NAME# = p_#I_COLUMN_NAME_28#
         WHERE #PK_COLUMN# = p_#PK_COLUMN_28#;' || CASE
                             WHEN g_enable_generic_change_log THEN
                              q'[
        create_change_log_entry( p_table     => '#TABLE_NAME#'
                               , p_column    => '#I_COLUMN_NAME#'
                               , p_pk_id     => p_#PK_COLUMN_28#
                               , p_old_value => #I_OLD_VALUE#
                               , p_new_value => #I_NEW_VALUE# );]'
                             ELSE
                              NULL
                           END || '
      END IF;
    END IF;
  END set_#I_COLUMN_NAME_26#;
  ----------------------------------------';
        util_template_replace('API BODY');
      END IF;
    END LOOP;
  END gen_setter_procedures;
  --------------------------------------------------------------------------------
  PROCEDURE gen_footer IS
  BEGIN
    g_code.template := ' 
END #TABLE_NAME_26#_api;';
    util_template_replace('API SPEC');
    ----------------------------------------
    g_code.template := ' 
END #TABLE_NAME_26#_api;';
    util_template_replace('API BODY');
  END gen_footer;
  --------------------------------------------------------------------------------
  PROCEDURE gen_dml_view IS
  BEGIN
    g_code.template := ' 
CREATE OR REPLACE VIEW #TABLE_NAME_24#_dml_v AS
SELECT #COLUMN_LIST_W_PK#
FROM #TABLE_NAME#';
    util_template_replace('VIEW');
  END gen_dml_view;
  --------------------------------------------------------------------------------
  PROCEDURE gen_dml_view_trigger IS
  BEGIN
    g_code.template := ' 
CREATE OR REPLACE TRIGGER #TABLE_NAME_24#_ioiud
  INSTEAD OF INSERT OR UPDATE OR DELETE
  ON #TABLE_NAME_24#_dml_v
  FOR EACH ROW
BEGIN
  IF INSERTING THEN
    #TABLE_NAME_26#_api.create_row( #MAP_NEW_TO_PARAM_W_PK# );
  ELSIF UPDATING THEN
    #TABLE_NAME_26#_api.update_row( #MAP_NEW_TO_PARAM_W_PK# );
  ELSIF DELETING THEN
    #DELETE_OR_THROW_EXCEPTION#
  END IF;
END #TABLE_NAME_24#_ioiud;';
    util_template_replace('TRIGGER');
  END gen_dml_view_trigger;
  --------------------------------------------------------------------------------
  PROCEDURE main_generate(p_generator_action           IN VARCHAR2,
                          p_table_name                 IN user_tables.table_name%TYPE,
                          p_reuse_existing_api_params  IN BOOLEAN,
                          p_col_prefix_in_method_names IN BOOLEAN,
                          p_enable_deletion_of_rows    IN BOOLEAN,
                          p_enable_generic_change_log  IN BOOLEAN,
                          p_sequence_name              IN user_sequences.sequence_name%TYPE) IS
    PROCEDURE initialize IS
      v_object_exists user_objects.object_name%TYPE;
      --
      PROCEDURE reset_globals IS
      BEGIN
        -- collections and records
        g_columns.delete;
        g_substitutions.delete;
        g_unique_constraints.delete;
        g_unique_cons_columns.delete;
        g_code                := NULL;
        g_params_existing_api := NULL;
        -- variables
        g_table_name                 := NULL;
        g_reuse_existing_api_params  := NULL;
        g_col_prefix_in_method_names := NULL;
        g_enable_deletion_of_rows    := NULL;
        g_enable_generic_change_log  := NULL;
        g_sequence_name              := NULL;
        g_xmltype_column_present     := NULL;
      END reset_globals;
      --
      PROCEDURE process_parameters IS
        v_api_found BOOLEAN;
      BEGIN
        -- save params as global package vars for later use
        g_table_name                := p_table_name;
        g_reuse_existing_api_params := p_reuse_existing_api_params;
        --
        v_api_found := FALSE;
        IF g_reuse_existing_api_params THEN
          OPEN g_cur_existing_apis(g_table_name);
          FETCH g_cur_existing_apis
            INTO g_params_existing_api;
          IF g_cur_existing_apis%FOUND THEN
            v_api_found := TRUE;
          END IF;
          CLOSE g_cur_existing_apis;
        END IF;
        g_col_prefix_in_method_names := CASE
                                          WHEN g_reuse_existing_api_params AND
                                               v_api_found AND
                                               g_params_existing_api.p_col_prefix_in_method_names IS NOT NULL THEN
                                           util_string_to_bool(g_params_existing_api.p_col_prefix_in_method_names)
                                          ELSE
                                           p_col_prefix_in_method_names
                                        END;
        g_enable_deletion_of_rows := CASE
                                       WHEN g_reuse_existing_api_params AND
                                            v_api_found AND
                                            g_params_existing_api.p_enable_deletion_of_rows IS NOT NULL THEN
                                        util_string_to_bool(g_params_existing_api.p_enable_deletion_of_rows)
                                       ELSE
                                        p_enable_deletion_of_rows
                                     END;
        g_enable_generic_change_log := CASE
                                         WHEN g_reuse_existing_api_params AND
                                              v_api_found AND
                                              g_params_existing_api.p_enable_generic_change_log IS NOT NULL THEN
                                          util_string_to_bool(g_params_existing_api.p_enable_generic_change_log)
                                         ELSE
                                          p_enable_generic_change_log
                                       END;
        g_sequence_name := CASE
                             WHEN g_reuse_existing_api_params AND v_api_found THEN
                              g_params_existing_api.p_sequence_name
                             ELSE
                              p_sequence_name
                           END;
      END process_parameters;
      --
      PROCEDURE set_substitutions_literal_base IS
      BEGIN
        -- check, if option "col_prefix_in_method_names" is set and check then if table's column prefix is unique
        g_substitutions('#COLUMN_PREFIX#') := util_get_table_column_prefix(g_table_name);
        IF g_col_prefix_in_method_names = FALSE AND
           g_substitutions('#COLUMN_PREFIX#') IS NULL THEN
          raise_application_error(c_generator_error_number,
                                  'The prefix of your column names (example: prefix_rest_of_column_name) is not unique and you requested to cut off the prefix for method names. Please ensure either your column names have a unique prefix or switch the parameter p_col_prefix_in_method_names to true (SQL Developer oddgen integration: check option "Keep column prefix in method names").');
        END IF;
        --
        g_substitutions('#TABLE_NAME#') := g_table_name;
        g_substitutions('#TABLE_NAME_24#') := substr(g_table_name, 1, 24);
        g_substitutions('#TABLE_NAME_26#') := substr(g_table_name, 1, 26);
        g_substitutions('#TABLE_NAME_28#') := substr(g_table_name, 1, 28);
        g_substitutions('#PK_COLUMN#') := util_get_table_key(p_table_name => g_table_name);
        g_substitutions('#PK_COLUMN_26#') := substr(g_substitutions('#PK_COLUMN#'),
                                                    1,
                                                    26);
        g_substitutions('#PK_COLUMN_28#') := substr(g_substitutions('#PK_COLUMN#'),
                                                    1,
                                                    28);
      
        -- replace possible placeholders in sequence name
        g_sequence_name := REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(g_sequence_name,
                                                                           '#TABLE_NAME_24#',
                                                                           g_substitutions('#TABLE_NAME_24#')),
                                                                   '#TABLE_NAME_26#',
                                                                   g_substitutions('#TABLE_NAME_26#')),
                                                           '#TABLE_NAME_28#',
                                                           g_substitutions('#TABLE_NAME_28#')),
                                                   '#PK_COLUMN_26#',
                                                   g_substitutions('#PK_COLUMN_26#')),
                                           '#PK_COLUMN_28#',
                                           g_substitutions('#PK_COLUMN_28#')),
                                   '#COLUMN_PREFIX#',
                                   g_substitutions('#COLUMN_PREFIX#'));
      
        g_substitutions('#SEQUENCE_NAME#') := g_sequence_name;
        --
        g_substitutions('#GENERATOR#') := c_generator;
        g_substitutions('#GENERATOR_VERSION#') := c_generator_version;
        g_substitutions('#GENERATOR_ACTION#') := p_generator_action;
        g_substitutions('#GENERATED_AT#') := to_char(SYSDATE,
                                                     'yyyy-mm-dd hh24:mi:ss');
        g_substitutions('#GENERATED_BY#') := util_get_user_name;
        --
        g_substitutions('#DELETE_OR_THROW_EXCEPTION#') := CASE
                                                            WHEN g_enable_deletion_of_rows THEN
                                                             g_substitutions('#TABLE_NAME_26#') ||
                                                             '_api.delete_row( p_' ||
                                                             g_substitutions('#PK_COLUMN_28#') ||
                                                             ' => :old.' ||
                                                             g_substitutions('#PK_COLUMN#') ||
                                                             ' );'
                                                            ELSE
                                                             'raise_application_error (-20000, ''Deletion of a row is not allowed.'');'
                                                          END;
      END set_substitutions_literal_base;
      --
      PROCEDURE check_if_table_exists IS
      BEGIN
        v_object_exists := NULL;
        OPEN g_cur_table_exists;
        FETCH g_cur_table_exists
          INTO v_object_exists;
        CLOSE g_cur_table_exists;
        IF (v_object_exists IS NULL) THEN
          raise_application_error(c_generator_error_number,
                                  'Table ' || g_table_name ||
                                  ' does not exist.');
        END IF;
      END check_if_table_exists;
    
      --
      PROCEDURE check_if_sequence_exists IS
      BEGIN
        IF g_sequence_name IS NOT NULL THEN
          v_object_exists := NULL;
          OPEN g_cur_sequence_exists;
          FETCH g_cur_sequence_exists
            INTO v_object_exists;
          CLOSE g_cur_sequence_exists;
          IF (v_object_exists IS NULL) THEN
            raise_application_error(c_generator_error_number,
                                    'Sequence ' || g_sequence_name ||
                                    ' does not exist. Please provide correct sequence name or create missing sequence.');
          END IF;
        END IF;
      END check_if_sequence_exists;
      --
      PROCEDURE check_if_log_table_exists IS
        v_count PLS_INTEGER;
      BEGIN
        IF g_enable_generic_change_log THEN
          FOR i IN (SELECT 'GENERIC_CHANGE_LOG'
                      FROM dual
                    MINUS
                    SELECT table_name
                      FROM user_tables
                     WHERE table_name = 'GENERIC_CHANGE_LOG') LOOP
            -- check constraint
            SELECT COUNT(*)
              INTO v_count
              FROM user_objects
             WHERE object_name = 'GENERIC_CHANGE_LOG_PK';
            IF v_count > 0 THEN
              raise_application_error(c_generator_error_number,
                                      'Stop trying to create generic change log table: Object with the name GENERIC_CHANGE_LOG_PK already exists.');
            END IF;
            -- check sequence
            SELECT COUNT(*)
              INTO v_count
              FROM user_objects
             WHERE object_name = 'GENERIC_CHANGE_LOG_SEQ';
            IF v_count > 0 THEN
              raise_application_error(c_generator_error_number,
                                      'Stop trying to create generic change log table: Object with the name GENERIC_CHANGE_LOG_SEQ already exists.');
            END IF;
            -- check index
            SELECT COUNT(*)
              INTO v_count
              FROM user_objects
             WHERE object_name = 'GENERIC_CHANGE_LOG_IDX';
            IF v_count > 0 THEN
              raise_application_error(c_generator_error_number,
                                      'Stop trying to create generic change log table: Object with the name GENERIC_CHANGE_LOG_IDX already exists.');
            END IF;
            EXECUTE IMMEDIATE q'[
create table generic_change_log (
  gcl_id        NUMBER not null,
  gcl_table     VARCHAR2(30 CHAR) not null,
  gcl_column    VARCHAR2(30 CHAR) not null,
  gcl_pk_id     NUMBER not null,
  gcl_old_value VARCHAR2(4000 CHAR),
  gcl_new_value VARCHAR2(4000 CHAR),
  gcl_user      VARCHAR2(20 CHAR),
  gcl_timestamp TIMESTAMP(6) default systimestamp,
  constraint generic_change_log_pk primary key (gcl_id)
)
]';
            EXECUTE IMMEDIATE q'[
create sequence generic_change_log_seq nocache noorder nocycle
]';
            EXECUTE IMMEDIATE q'[
create index generic_change_log_idx on generic_change_log (gcl_table, gcl_column, gcl_pk_id)
]';
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
comment on column generic_change_log.gcl_user is 'The user, who changed the data']';
            EXECUTE IMMEDIATE q'[
comment on column generic_change_log.gcl_timestamp is 'The time when the change occured']';
          END LOOP;
        END IF;
      END check_if_log_table_exists;
      --
      PROCEDURE create_temporary_lobs IS
      BEGIN
        dbms_lob.createtemporary(g_code.api_spec, TRUE);
        dbms_lob.createtemporary(g_code.api_body, TRUE);
        dbms_lob.createtemporary(g_code.dml_view, TRUE);
        dbms_lob.createtemporary(g_code.dml_view_trigger, TRUE);
      END create_temporary_lobs;
      --
      PROCEDURE set_substitutions_collect_base IS
        PROCEDURE init_substitutions IS
        BEGIN
          -- initialize some array key before concatenating in loop 
          -- first action in loop is read and this fails, if array key is not existing
          g_substitutions('#COLUMN_LIST_W_PK#') := NULL;
          g_substitutions('#MAP_NEW_TO_PARAM_W_PK#') := NULL;
          g_substitutions('#MAP_PARAM_TO_PARAM_W_PK#') := NULL;
          g_substitutions('#MAP_ROWTYPE_COL_TO_PARAM_W_PK#') := NULL;
          g_substitutions('#PARAM_DEFINITION_W_PK#') := NULL;
          g_substitutions('#PARAM_DEFINITION_W_PK#') := NULL;
          g_substitutions('#PARAM_IO_DEFINITION_W_PK#') := NULL;
          g_substitutions('#PARAM_LIST_WO_PK#') := NULL;
          g_substitutions('#SET_PARAM_TO_COLUMN_WO_PK#') := NULL;
          g_substitutions('#SET_ROWTYPE_COL_TO_PARAM_WO_PK#') := NULL;
          g_substitutions('#COLUMN_COMPARE_LIST_WO_PK#') := NULL;
        END init_substitutions;
        --
        PROCEDURE fetch_table_columns IS
        BEGIN
          OPEN g_cur_columns;
          FETCH g_cur_columns BULK COLLECT
            INTO g_columns;
          CLOSE g_cur_columns;
        END fetch_table_columns;
        --
        PROCEDURE fetch_unique_constraints IS
        BEGIN
          OPEN g_cur_unique_constraints;
          FETCH g_cur_unique_constraints BULK COLLECT
            INTO g_unique_constraints;
          CLOSE g_cur_unique_constraints;
        END fetch_unique_constraints;
        --
        PROCEDURE fetch_unique_cons_columns IS
        BEGIN
          OPEN g_cur_unique_cons_columns;
          FETCH g_cur_unique_cons_columns BULK COLLECT
            INTO g_unique_cons_columns;
          CLOSE g_cur_unique_cons_columns;
        END fetch_unique_cons_columns;
        -- 
        PROCEDURE check_if_column_is_xml_type(i PLS_INTEGER) IS
        BEGIN
          -- check, if we have a xmltype column present in our list
          -- if so, we have to provide a XML compare function
          IF g_columns(i).data_type = 'XMLTYPE' THEN
            g_xmltype_column_present := TRUE;
          END IF;
        END check_if_column_is_xml_type;
        --
        PROCEDURE calc_column_short_names(i PLS_INTEGER) IS
        BEGIN
          g_columns(i).column_name_26 := CASE
                                           WHEN g_col_prefix_in_method_names THEN
                                            substr(g_columns(i).column_name, 1, 26)
                                           ELSE
                                            substr(g_columns(i).column_name,
                                                   length(g_substitutions('#COLUMN_PREFIX#')) + 2,
                                                   26)
                                         END;
          g_columns(i).column_name_28 := substr(g_columns(i).column_name,
                                                1,
                                                28);
        END calc_column_short_names;
        --
        PROCEDURE column_list_w_pk(i PLS_INTEGER) IS
        BEGIN
          /* columns as flat list:
          #COLUMN_LIST_W_PK#
          e.g.
          col1
          , col2
          , col3
          , ... */
          g_substitutions('#COLUMN_LIST_W_PK#') := g_substitutions('#COLUMN_LIST_W_PK#') ||
                                                   c_list_delimiter || g_columns(i)
                                                  .column_name;
        END column_list_w_pk;
        --
        PROCEDURE map_new_to_param_w_pk(i PLS_INTEGER) IS
        BEGIN
          /* map :new values to parameter for IOIUD-Trigger with PK:
          #MAP_NEW_TO_PARAM_W_PK#
          e.g. p_col1 => :new.col1
          , p_col2 => :new.col2
          , p_col3 => :new.col3
          , ... */
          g_substitutions('#MAP_NEW_TO_PARAM_W_PK#') := g_substitutions('#MAP_NEW_TO_PARAM_W_PK#') ||
                                                        c_list_delimiter || 'p_' || g_columns(i)
                                                       .column_name_28 ||
                                                        ' => :new.' || g_columns(i)
                                                       .column_name;
        END map_new_to_param_w_pk;
        --
        PROCEDURE map_param_to_param_w_pk(i PLS_INTEGER) IS
        BEGIN
          /* map parameter to parameter as pass-through parameter with PK:
          #MAP_PARAM_TO_PARAM_W_PK#
          e.g. p_col1 => p_col1
          , p_col2 => p_col2
          , p_col3 => p_col3
          , ... */
          g_substitutions('#MAP_PARAM_TO_PARAM_W_PK#') := g_substitutions('#MAP_PARAM_TO_PARAM_W_PK#') ||
                                                          c_list_delimiter || 'p_' || g_columns(i)
                                                         .column_name_28 ||
                                                          ' => p_' || g_columns(i)
                                                         .column_name_28;
        END map_param_to_param_w_pk;
        --
        PROCEDURE map_rowtype_col_to_param_w_pk(i PLS_INTEGER) IS
        BEGIN
          /* map rowtype columns to parameter for rowtype handling with PK:
          #MAP_ROWTYPE_COL_TO_PARAM_W_PK#
          e.g. p_col1 => p_row.col1
          , p_col2 => p_row.col2
          , p_col3 => p_row.col3
          , ... */
          g_substitutions('#MAP_ROWTYPE_COL_TO_PARAM_W_PK#') := g_substitutions('#MAP_ROWTYPE_COL_TO_PARAM_W_PK#') ||
                                                                c_list_delimiter || 'p_' || g_columns(i)
                                                               .column_name_28 ||
                                                                ' => p_row.' || g_columns(i)
                                                               .column_name;
        END map_rowtype_col_to_param_w_pk;
        -- 
        PROCEDURE param_definition_w_pk(i PLS_INTEGER) IS
        BEGIN
          /* columns as parameter definition for create_row, update_row with PK:
          #PARAM_DEFINITION_W_PK#
          e.g. p_col1 IN table.col1%TYPE
          , p_col2 IN table.col2%TYPE
          , p_col3 IN table.col3%TYPE
          , ... */
          g_substitutions('#PARAM_DEFINITION_W_PK#') := g_substitutions('#PARAM_DEFINITION_W_PK#') ||
                                                        c_list_delimiter || 'p_' || g_columns(i)
                                                       .column_name_28 || ' IN ' ||
                                                        g_table_name || '.' || g_columns(i)
                                                       .column_name || '%TYPE' || CASE
                                                          WHEN (g_columns(i)
                                                               .column_name =
                                                                g_substitutions('#PK_COLUMN#')) THEN
                                                           ' DEFAULT NULL'
                                                          ELSE
                                                           NULL
                                                        END;
        END param_definition_w_pk;
        --
        PROCEDURE param_io_definition_w_pk(i PLS_INTEGER) IS
        BEGIN
          /* columns as parameter IN OUT definition for get_row_by_pk_and_fill with PK:
          #PARAM_IO_DEFINITION_W_PK#
          e.g. p_col1 IN            table.col1%TYPE
          , p_col2 IN OUT NOCOPY table.col2%TYPE
          , p_col3 IN OUT NOCOPY table.col3%TYPE
          , ... */
          g_substitutions('#PARAM_IO_DEFINITION_W_PK#') := g_substitutions('#PARAM_IO_DEFINITION_W_PK#') ||
                                                           c_list_delimiter || 'p_' || g_columns(i)
                                                          .column_name_28 || CASE
                                                             WHEN g_columns(i)
                                                              .column_name =
                                                                   g_substitutions('#PK_COLUMN#') THEN
                                                              ' IN '
                                                             ELSE
                                                              ' IN OUT NOCOPY '
                                                           END || g_table_name || '.' || g_columns(i)
                                                          .column_name || '%TYPE';
        END param_io_definition_w_pk;
        --
        PROCEDURE param_list_wo_pk(i PLS_INTEGER) IS
        BEGIN
          /* columns as flat parameter list without PK e.g. col1 is PK:
          #PARAM_LIST_WO_PK#
          e.g. p_col2
          , p_col3
          , p_col4
          , ... */
          IF (g_columns(i).column_name <> g_substitutions('#PK_COLUMN#')) THEN
            g_substitutions('#PARAM_LIST_WO_PK#') := g_substitutions('#PARAM_LIST_WO_PK#') ||
                                                     c_list_delimiter || 'p_' || g_columns(i)
                                                    .column_name_28;
          END IF;
        END param_list_wo_pk;
        --
        PROCEDURE set_param_to_column_wo_pk(i PLS_INTEGER) IS
        BEGIN
          /* a column list for updating a row without PK:
          #SET_PARAM_TO_COLUMN_WO_PK#
          e.g. test_number   = p_test_number
          , test_varchar2 = p_test_varchar2
          , ... */
          IF (g_columns(i).column_name <> g_substitutions('#PK_COLUMN#')) THEN
            g_substitutions('#SET_PARAM_TO_COLUMN_WO_PK#') := g_substitutions('#SET_PARAM_TO_COLUMN_WO_PK#') ||
                                                              c_list_delimiter || g_columns(i)
                                                             .column_name ||
                                                              ' = p_' || g_columns(i)
                                                             .column_name_28;
          END IF;
        END set_param_to_column_wo_pk;
        --
        PROCEDURE set_rowtype_col_to_param_wo_pk(i PLS_INTEGER) IS
        BEGIN
          /* a column list without pk for setting parameter to row columns:
          #SET_ROWTYPE_COL_TO_PARAM_WO_PK#
          e.g.
          p_test_number   := v_row.test_number;
          p_test_varchar2 := v_row.test_varchar2;
          , ... */
          IF (g_columns(i).column_name <> g_substitutions('#PK_COLUMN#')) THEN
            g_substitutions('#SET_ROWTYPE_COL_TO_PARAM_WO_PK#') := g_substitutions('#SET_ROWTYPE_COL_TO_PARAM_WO_PK#') || 'p_' || g_columns(i)
                                                                  .column_name_28 ||
                                                                   ' := v_row.' || g_columns(i)
                                                                  .column_name || '; ';
          END IF;
        END set_rowtype_col_to_param_wo_pk;
        --
        PROCEDURE column_compare_list_wo_pk(i PLS_INTEGER) IS
        BEGIN
          /* a block of code who compares new and old column values (without PK column) and counts the number
              of differences:
              #COLUMN_COMPARE_LIST_WO_PK#
              e.g.:
              IF COALESCE( v_row.test_number, -9999.9999 ) <> COALESCE( p_test_number, -9999.9999 ) THEN
              v_count := v_count + 1;
              create_change_log_entry( p_table     => 'map_users_roles'
                                     , p_column    => 'mur_u_id'
                                     , p_pk_id     => v_row.mur_id
                                     , p_old_value => to_char(v_row.mur_u_id)
                                     , p_new_value => to_char(p_mur_u_id) );
              END IF;
              IF DBMS_LOB.compare(COALESCE(v_row.test_clob, TO_CLOB('$$$$')), COALESCE(p_test_clob, TO_CLOB('$$$$'))) <> 0 THEN
              v_count := v_count + 1;
              create_change_log_entry( p_table     => 'map_users_roles'
                                     , p_column    => 'mur_u_id'
                                     , p_pk_id     => v_row.mur_id
                                     , p_old_value => to_char(v_row.mur_u_id)
                                     , p_new_value => to_char(p_mur_u_id) );
              END IF;
            IF COALESCE( v_row.mur_u_id, -9999.9999) <> COALESCE( p_mur_u_id, -9999.9999 ) THEN
            v_count := v_count + 1;
          END IF;          
              ... */
          IF (g_columns(i).column_name <> g_substitutions('#PK_COLUMN#')) THEN
            g_substitutions('#COLUMN_COMPARE_LIST_WO_PK#') := g_substitutions('#COLUMN_COMPARE_LIST_WO_PK#') || CASE
                                                                WHEN g_enable_generic_change_log THEN
                                                                 '      IF '
                                                                ELSE
                                                                 '      OR '
                                                              END ||
                                                              util_get_attribute_compare(p_data_type         => g_columns(i)
                                                                                                                .data_type,
                                                                                         p_first_attribute   => 'v_row.' || g_columns(i)
                                                                                                               .column_name,
                                                                                         p_second_attribute  => 'p_' || g_columns(i)
                                                                                                               .column_name_28,
                                                                                         p_compare_operation => '<>') || CASE
                                                                WHEN g_enable_generic_change_log THEN
                                                                 ' THEN 
      v_count := v_count + 1;
      create_change_log_entry( p_table     => ''' ||
                                                                 g_table_name || '''
                             , p_column    => ''' || g_columns(i)
                                                                .column_name || '''
                             , p_pk_id     => v_row.' ||
                                                                 g_substitutions('#PK_COLUMN#') || '
                             , p_old_value => ' ||
                                                                 util_get_vc2_4000_operation(p_data_type      => g_columns(i)
                                                                                                                 .data_type,
                                                                                             p_attribute_name => 'v_row.' || g_columns(i)
                                                                                                                .column_name) || '
                             , p_new_value => ' ||
                                                                 util_get_vc2_4000_operation(p_data_type      => g_columns(i)
                                                                                                                 .data_type,
                                                                                             p_attribute_name => 'p_' || g_columns(i)
                                                                                                                .column_name_28) || ' );
      END IF;' ||
                                                                 c_crlf
                                                                ELSE
                                                                 c_crlf
                                                              END;
          END IF;
        END column_compare_list_wo_pk;
        --
        PROCEDURE cut_off_first_last_delimiter IS
        BEGIN
          -- cut off the first and/or last delimiter
          g_substitutions('#SET_PARAM_TO_COLUMN_WO_PK#') := ltrim(g_substitutions('#SET_PARAM_TO_COLUMN_WO_PK#'),
                                                                  c_list_delimiter);
          g_substitutions('#COLUMN_LIST_W_PK#') := ltrim(g_substitutions('#COLUMN_LIST_W_PK#'),
                                                         c_list_delimiter);
          g_substitutions('#MAP_NEW_TO_PARAM_W_PK#') := ltrim(g_substitutions('#MAP_NEW_TO_PARAM_W_PK#'),
                                                              c_list_delimiter);
          g_substitutions('#MAP_PARAM_TO_PARAM_W_PK#') := ltrim(g_substitutions('#MAP_PARAM_TO_PARAM_W_PK#'),
                                                                c_list_delimiter);
          g_substitutions('#MAP_ROWTYPE_COL_TO_PARAM_W_PK#') := ltrim(g_substitutions('#MAP_ROWTYPE_COL_TO_PARAM_W_PK#'),
                                                                      c_list_delimiter);
          g_substitutions('#PARAM_DEFINITION_W_PK#') := ltrim(g_substitutions('#PARAM_DEFINITION_W_PK#'),
                                                              c_list_delimiter);
          g_substitutions('#PARAM_IO_DEFINITION_W_PK#') := ltrim(g_substitutions('#PARAM_IO_DEFINITION_W_PK#'),
                                                                 c_list_delimiter);
          g_substitutions('#PARAM_LIST_WO_PK#') := ltrim(g_substitutions('#PARAM_LIST_WO_PK#'),
                                                         c_list_delimiter);
          -- this has to be enhanced
          g_substitutions('#COLUMN_COMPARE_LIST_WO_PK#') := ltrim(ltrim(rtrim(g_substitutions('#COLUMN_COMPARE_LIST_WO_PK#'),
                                                                              c_crlf),
                                                                        '      IF '),
                                                                  '      OR ') || CASE
                                                              WHEN g_enable_generic_change_log THEN
                                                               c_crlf ||
                                                               '      IF v_count > 0'
                                                              ELSE
                                                               NULL
                                                            END;
        END cut_off_first_last_delimiter;
      
      BEGIN
        init_substitutions;
        fetch_table_columns;
        fetch_unique_constraints;
        fetch_unique_cons_columns;
        FOR i IN g_columns.first .. g_columns.last LOOP
          check_if_column_is_xml_type(i);
          calc_column_short_names(i);
          column_list_w_pk(i);
          map_new_to_param_w_pk(i);
          map_param_to_param_w_pk(i);
          map_rowtype_col_to_param_w_pk(i);
          param_definition_w_pk(i);
          param_io_definition_w_pk(i);
          param_list_wo_pk(i);
          set_param_to_column_wo_pk(i);
          set_rowtype_col_to_param_wo_pk(i);
          column_compare_list_wo_pk(i);
        END LOOP;
        cut_off_first_last_delimiter;
      END set_substitutions_collect_base;
      --
    BEGIN
      reset_globals;
      process_parameters;
      set_substitutions_literal_base;
      check_if_table_exists;
      check_if_sequence_exists;
      check_if_log_table_exists;
      create_temporary_lobs;
      set_substitutions_collect_base;
    END initialize;
    --
    PROCEDURE finalize IS
    BEGIN
      -- finalize CLOB varchar caches
      util_clob_append(p_clob               => g_code.api_spec,
                       p_clob_varchar_cache => g_code.api_spec_varchar_cache,
                       p_varchar_to_append  => NULL,
                       p_final_call         => TRUE);
      util_clob_append(p_clob               => g_code.api_body,
                       p_clob_varchar_cache => g_code.api_body_varchar_cache,
                       p_varchar_to_append  => NULL,
                       p_final_call         => TRUE);
      util_clob_append(p_clob               => g_code.dml_view,
                       p_clob_varchar_cache => g_code.dml_view_varchar_cache,
                       p_varchar_to_append  => NULL,
                       p_final_call         => TRUE);
      util_clob_append(p_clob               => g_code.dml_view_trigger,
                       p_clob_varchar_cache => g_code.dml_view_trigger_varchar_cache,
                       p_varchar_to_append  => NULL,
                       p_final_call         => TRUE);
    
    END finalize;
    --
  BEGIN
    initialize;
    gen_header;
    gen_row_exists_fnc;
    gen_get_pk_by_unique_cols_fnc;
    gen_create_row_fnc;
    gen_create_row_prc;
    gen_create_rowtype_fnc;
    gen_create_rowtype_prc;
    gen_createorupdate_row_fnc;
    gen_createorupdate_row_prc;
    gen_createorupdate_rowtype_fnc;
    gen_createorupdate_rowtype_prc;
    gen_read_row_fnc;
    gen_read_row_prc;
    gen_update_row_prc;
    gen_update_rowtype_prc;
    gen_delete_row_prc;
    gen_getter_functions;
    gen_setter_procedures;
    gen_footer;
    gen_dml_view;
    gen_dml_view_trigger;
    finalize;
  END main_generate;
  --------------------------------------------------------------------------------
  PROCEDURE main_compile IS
  
  BEGIN
    -- compile package spec
    BEGIN
      util_execute_sql(g_code.api_spec);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- compile package body
    BEGIN
      util_execute_sql(g_code.api_body);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- compile DML view
    BEGIN
      util_execute_sql(g_code.dml_view);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- compile DML view trigger
    BEGIN
      util_execute_sql(g_code.dml_view_trigger);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  END main_compile;
  --------------------------------------------------------------------------------  
  FUNCTION main_return RETURN CLOB IS
    terminator VARCHAR2(10 CHAR) := c_crlf || '/' || c_crlflf;
  BEGIN
    RETURN g_code.api_spec || terminator || g_code.api_body || terminator || g_code.dml_view || terminator || g_code.dml_view_trigger || terminator;
  END main_return;
  --------------------------------------------------------------------------------
  PROCEDURE compile_api(p_table_name                 IN user_tables.table_name%TYPE,
                        p_reuse_existing_api_params  IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params, --if true, the following params are ignored, if API package are already existing and params are extractable from spec source line 1
                        p_col_prefix_in_method_names IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names,
                        p_enable_deletion_of_rows    IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows,
                        p_enable_generic_change_log  IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log,
                        p_sequence_name              IN user_sequences.sequence_name%TYPE DEFAULT c_sequence_name) IS
  BEGIN
    main_generate(p_generator_action           => 'COMPILE_API',
                  p_table_name                 => p_table_name,
                  p_reuse_existing_api_params  => p_reuse_existing_api_params,
                  p_col_prefix_in_method_names => p_col_prefix_in_method_names,
                  p_enable_deletion_of_rows    => p_enable_deletion_of_rows,
                  p_enable_generic_change_log  => p_enable_generic_change_log,
                  p_sequence_name              => p_sequence_name);
    main_compile;
  END compile_api;
  --------------------------------------------------------------------------------
  FUNCTION compile_api_and_get_code(p_table_name                 IN user_tables.table_name%TYPE,
                                    p_reuse_existing_api_params  IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params, --if true, the following params are ignored, if API package are already existing and params are extractable from spec source line 1
                                    p_col_prefix_in_method_names IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names,
                                    p_enable_deletion_of_rows    IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows,
                                    p_enable_generic_change_log  IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log,
                                    p_sequence_name              IN user_sequences.sequence_name%TYPE DEFAULT c_sequence_name)
    RETURN CLOB IS
  BEGIN
    main_generate(p_generator_action           => 'COMPILE_API_AND_GET_CODE',
                  p_table_name                 => p_table_name,
                  p_reuse_existing_api_params  => p_reuse_existing_api_params,
                  p_col_prefix_in_method_names => p_col_prefix_in_method_names,
                  p_enable_deletion_of_rows    => p_enable_deletion_of_rows,
                  p_enable_generic_change_log  => p_enable_generic_change_log,
                  p_sequence_name              => p_sequence_name);
    main_compile;
    RETURN main_return;
  END compile_api_and_get_code;
  --------------------------------------------------------------------------------
  FUNCTION get_code(p_table_name                 IN user_tables.table_name%TYPE,
                    p_reuse_existing_api_params  IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params, --if true, the following params are ignored, if API package are already existing and params are extractable from spec source line 1
                    p_col_prefix_in_method_names IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names,
                    p_enable_deletion_of_rows    IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows,
                    p_enable_generic_change_log  IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log,
                    p_sequence_name              IN user_sequences.sequence_name%TYPE DEFAULT c_sequence_name)
    RETURN CLOB IS
  BEGIN
    main_generate(p_generator_action           => 'GET_CODE',
                  p_table_name                 => p_table_name,
                  p_reuse_existing_api_params  => p_reuse_existing_api_params,
                  p_col_prefix_in_method_names => p_col_prefix_in_method_names,
                  p_enable_deletion_of_rows    => p_enable_deletion_of_rows,
                  p_enable_generic_change_log  => p_enable_generic_change_log,
                  p_sequence_name              => p_sequence_name);
    RETURN main_return;
  END get_code;
  --------------------------------------------------------------------------------
  PROCEDURE recreate_existing_apis IS
    v_apis existing_apis_tabtype;
  BEGIN
    OPEN g_cur_existing_apis(NULL);
    FETCH g_cur_existing_apis BULK COLLECT
      INTO v_apis;
    CLOSE g_cur_existing_apis;
    IF v_apis.count > 0 THEN
      FOR i IN v_apis.first .. v_apis.last LOOP
        compile_api(v_apis(i).p_table_name);
      END LOOP;
    END IF;
  END;
  --------------------------------------------------------------------------------
  FUNCTION view_existing_apis(p_table_name user_tables.table_name%TYPE DEFAULT NULL)
    RETURN existing_apis_tabtype
    PIPELINED IS
    v_row g_cur_existing_apis%ROWTYPE;
  BEGIN
    OPEN g_cur_existing_apis(p_table_name);
    LOOP
      FETCH g_cur_existing_apis
        INTO v_row;
      EXIT WHEN g_cur_existing_apis%NOTFOUND;
      IF p_table_name IS NOT NULL THEN
        IF v_row.table_name = p_table_name THEN
          PIPE ROW(v_row);
        END IF;
      ELSE
        PIPE ROW(v_row);
      END IF;
    END LOOP;
    CLOSE g_cur_existing_apis;
  EXCEPTION
    WHEN OTHERS THEN
      v_row.errors := 'Incomplete resultset! This is the last correct proccessed row from the pipelined function. Did you change the params XML in one of the API packages? Original error message: ' ||
                      c_crlflf || SQLERRM || c_crlflf ||
                      dbms_utility.format_error_backtrace;
      PIPE ROW(v_row);
      CLOSE g_cur_existing_apis;
  END view_existing_apis;
  --------------------------------------------------------------------------------
  FUNCTION view_naming_conflicts RETURN naming_conflicts_tabtype
    PIPELINED IS
  BEGIN
    FOR i IN g_cur_naming_conflicts LOOP
      PIPE ROW(i);
    END LOOP;
  END view_naming_conflicts;
  --------------------------------------------------------------------------------
END om_tapigen;
/
