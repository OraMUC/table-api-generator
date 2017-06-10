CREATE OR REPLACE PACKAGE BODY om_tapigen
IS
   -----------------------------------------------------------------------------
   -- private global constants c_*
   -----------------------------------------------------------------------------
   c_generator_error_number   CONSTANT PLS_INTEGER := -20000;
   c_bulk_collect_limit       CONSTANT NUMBER := 10000;
   c_list_delimiter           CONSTANT VARCHAR2 (2 CHAR) := ', ';
   c_crlf                     CONSTANT VARCHAR2 (2 CHAR)
                                          := CHR (13) || CHR (10) ;
   c_crlflf                   CONSTANT VARCHAR2 (3 CHAR)
                                          := CHR (13) || CHR (10) || CHR (10) ;

   -----------------------------------------------------------------------------
   -- private global variables g_*
   -----------------------------------------------------------------------------
   g_table_name                        user_tables.table_name%TYPE;
   g_reuse_existing_api_params         BOOLEAN;
   g_col_prefix_in_method_names        BOOLEAN;
   g_enable_insertion_of_rows          BOOLEAN;
   g_enable_update_of_rows             BOOLEAN;
   g_enable_deletion_of_rows           BOOLEAN;
   g_enable_generic_change_log         BOOLEAN;
   g_enable_dml_view                   BOOLEAN;
   g_sequence_name                     user_sequences.sequence_name%TYPE;
   g_api_name                          user_objects.object_name%TYPE;
   g_enable_getter_and_setter          BOOLEAN;
   g_enable_parameter_prefixes         BOOLEAN;
   g_return_row_instead_of_pk          BOOLEAN;
   g_column_defaults                   XMLTYPE;

   g_xmltype_column_present            BOOLEAN;

   -----------------------------------------------------------------------------
   -- private types t_*, subtypes st_* and collections tab_*
   -----------------------------------------------------------------------------
   TYPE t_column_info IS RECORD
   (
      column_name      user_tab_columns.column_name%TYPE,
      column_name_26   user_tab_columns.column_name%TYPE,
      column_name_28   user_tab_columns.column_name%TYPE,
      data_type        user_tab_cols.data_type%TYPE
   );

   TYPE t_tab_column_info IS TABLE OF t_column_info
      INDEX BY BINARY_INTEGER;

   TYPE t_unique_constraint_info
      IS RECORD (constraint_name user_constraints.constraint_name%TYPE);

   TYPE t_tab_unique_constraint_info IS TABLE OF t_unique_constraint_info
      INDEX BY BINARY_INTEGER;

   TYPE t_unique_cons_column_info IS RECORD
   (
      constraint_name   user_cons_columns.constraint_name%TYPE,
      column_name       user_cons_columns.column_name%TYPE,
      parameter_name    user_cons_columns.column_name%TYPE,
      data_type         user_tab_columns.data_type%TYPE
   );

   TYPE t_tab_unique_cons_column_info IS TABLE OF t_unique_cons_column_info
      INDEX BY BINARY_INTEGER;

   SUBTYPE st_substitution_key IS VARCHAR2 (100 CHAR);

   SUBTYPE st_substitution_value IS VARCHAR2 (32767 CHAR);

   TYPE t_tab_substitutions_array IS TABLE OF st_substitution_value
      INDEX BY st_substitution_key;

   TYPE t_tapi_code_blocks IS RECORD
   (
      template                         VARCHAR2 (32767 CHAR),
      api_spec                         CLOB,
      api_spec_varchar_cache           VARCHAR2 (32767 CHAR),
      api_body                         CLOB,
      api_body_varchar_cache           VARCHAR2 (32767 CHAR),
      dml_view                         CLOB,
      dml_view_varchar_cache           VARCHAR2 (32767 CHAR),
      dml_view_trigger                 CLOB,
      dml_view_trigger_varchar_cache   VARCHAR2 (32767 CHAR)
   );

   g_tab_column_info                   t_tab_column_info;
   g_tab_unique_constraint_info        t_tab_unique_constraint_info;
   g_tab_unique_cons_column_info       t_tab_unique_cons_column_info;
   g_tab_substitutions_array           t_tab_substitutions_array;
   g_tapi_code_blocks                  t_tapi_code_blocks;
   g_params_existing_api               g_cur_existing_apis%ROWTYPE;

   -----------------------------------------------------------------------------
   -- private global cursors g_cur_*
   -----------------------------------------------------------------------------
   CURSOR g_cur_table_exists
   IS
      SELECT table_name
        FROM user_tables
       WHERE table_name = g_table_name;

   CURSOR g_cur_sequence_exists
   IS
      SELECT sequence_name
        FROM user_sequences
       WHERE sequence_name = g_sequence_name;

   CURSOR g_cur_columns
   IS
        SELECT column_name AS column_name,
               NULL AS column_name_26,
               NULL AS column_name_28,
               data_type
          FROM user_tab_cols
         WHERE table_name = g_table_name AND hidden_column = 'NO'
      ORDER BY column_id;

   CURSOR g_cur_unique_constraints
   IS
        SELECT constraint_name
          FROM user_constraints
         WHERE table_name = g_table_name AND constraint_type = 'U'
      ORDER BY constraint_name;

   CURSOR g_cur_unique_cons_columns
   IS
        SELECT ucc.constraint_name,
               ucc.column_name AS column_name,
               NULL AS column_name_28,
               utc.data_type
          FROM user_constraints uc
               JOIN user_cons_columns ucc
                  ON uc.constraint_name = ucc.constraint_name
               JOIN user_tab_columns utc
                  ON     ucc.table_name = utc.table_name
                     AND ucc.column_name = utc.column_name
         WHERE uc.table_name = g_table_name AND uc.constraint_type = 'U'
      ORDER BY uc.constraint_name, ucc.position;

   -----------------------------------------------------------------------------
   -- util_clob_append is a private helper procedure to append a varchar2 value
   -- to an existing clob. The idea is to increase performance by avoiding the
   -- slow DBMS_LOB.append call. Only for the final append or if the varchar
   -- cache is fullfilled, this call is done.
   -----------------------------------------------------------------------------
   PROCEDURE util_clob_append (
      p_clob                 IN OUT NOCOPY CLOB,
      p_clob_varchar_cache   IN OUT NOCOPY VARCHAR2,
      p_varchar_to_append    IN            VARCHAR2,
      p_final_call           IN            BOOLEAN DEFAULT FALSE)
   IS
   BEGIN
      p_clob_varchar_cache := p_clob_varchar_cache || p_varchar_to_append;

      IF p_final_call
      THEN
         IF p_clob IS NULL
         THEN
            p_clob := p_clob_varchar_cache;
         ELSE
            DBMS_LOB.append (p_clob, p_clob_varchar_cache);
         END IF;

         -- clear cache on final call
         p_clob_varchar_cache := NULL;
      END IF;
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         IF p_clob IS NULL
         THEN
            p_clob := p_clob_varchar_cache;
         ELSE
            DBMS_LOB.append (p_clob, p_clob_varchar_cache);
         END IF;

         p_clob_varchar_cache := p_varchar_to_append;

         IF p_final_call
         THEN
            DBMS_LOB.append (p_clob, p_clob_varchar_cache);
            -- clear cache on final call
            p_clob_varchar_cache := NULL;
         END IF;
   END util_clob_append;

   -----------------------------------------------------------------------------
   PROCEDURE util_template_replace (p_scope IN VARCHAR2 DEFAULT NULL)
   IS
      v_pattern     VARCHAR2 (30 CHAR) := '#\w+#';
      v_start_pos   PLS_INTEGER := 1;
      v_match_pos   PLS_INTEGER := 0;
      v_match_len   PLS_INTEGER := 0;
      v_match       st_substitution_key;
      v_tpl_len     PLS_INTEGER;

      PROCEDURE get_match_pos
      IS
      -- finds the first position of a substitution string like #TABLE_NAME#
      BEGIN
         v_match_pos :=
            REGEXP_INSTR (g_tapi_code_blocks.template,
                          v_pattern,
                          v_start_pos);
      END get_match_pos;

      PROCEDURE code_append (p_code_snippet VARCHAR2)
      IS
      BEGIN
         IF p_scope = 'API SPEC'
         THEN
            util_clob_append (g_tapi_code_blocks.api_spec,
                              g_tapi_code_blocks.api_spec_varchar_cache,
                              p_code_snippet);
         ELSIF p_scope = 'API BODY'
         THEN
            util_clob_append (g_tapi_code_blocks.api_body,
                              g_tapi_code_blocks.api_body_varchar_cache,
                              p_code_snippet);
         ELSIF p_scope = 'VIEW'
         THEN
            util_clob_append (g_tapi_code_blocks.dml_view,
                              g_tapi_code_blocks.dml_view_varchar_cache,
                              p_code_snippet);
         ELSIF p_scope = 'TRIGGER'
         THEN
            util_clob_append (
               g_tapi_code_blocks.dml_view_trigger,
               g_tapi_code_blocks.dml_view_trigger_varchar_cache,
               p_code_snippet);
         END IF;
      END code_append;
   BEGIN
      v_tpl_len := LENGTH (g_tapi_code_blocks.template);
      get_match_pos;

      WHILE v_start_pos < v_tpl_len
      LOOP
         get_match_pos;

         IF v_match_pos > 0
         THEN
            v_match_len :=
                 INSTR (g_tapi_code_blocks.template,
                        '#',
                        v_match_pos,
                        2)
               - v_match_pos;
            v_match :=
               SUBSTR (g_tapi_code_blocks.template,
                       v_match_pos,
                       v_match_len + 1);
            -- (1) process text before the match
            code_append (
               SUBSTR (g_tapi_code_blocks.template,
                       v_start_pos,
                       v_match_pos - v_start_pos));

            -- (2) process the match
            BEGIN
               code_append (g_tab_substitutions_array (v_match)); -- this could be a problem, if not initialized
               v_start_pos := v_match_pos + v_match_len + 1;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  raise_application_error (
                     c_generator_error_number,
                        'FIXME: Bug - Substitution '
                     || v_match
                     || ' not initialized');
            END;
         ELSE
            -- (3) process the rest of the text
            code_append (SUBSTR (g_tapi_code_blocks.template, v_start_pos));
            v_start_pos := v_tpl_len;
         END IF;
      END LOOP;
   END util_template_replace;

   -----------------------------------------------------------------------------
   -- util_execute_sql is a private helper procedure that parses and executes
   -- generated code with the help of DBMS_SQL package. Execute immediate is not
   -- used here directly, because of the missing possibility of parsing a
   -- statement in a performant way. Executing immediate and catching
   -- the error is more expensive than parsing the statement and catching the
   -- error.
   -----------------------------------------------------------------------------
   PROCEDURE util_execute_sql (p_sql IN OUT NOCOPY CLOB)
   IS
      v_cursor        NUMBER;
      v_exec_result   PLS_INTEGER;
   BEGIN
      v_cursor := DBMS_SQL.open_cursor;
      DBMS_SQL.parse (v_cursor, p_sql, DBMS_SQL.native);
      v_exec_result := DBMS_SQL.execute (v_cursor);
      DBMS_SQL.close_cursor (v_cursor);
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_SQL.close_cursor (v_cursor);
         RAISE;
   END util_execute_sql;

   -----------------------------------------------------------------------------
   -- util_get_table_key is a private helper function to find out the primary
   -- key of a table. It can also be an combined key of multiple columns.
   -- Please note, that it's possible too, to find out the columns for other
   -- constraint types e.g. unique constraints with p_key_type => 'U'.
   -----------------------------------------------------------------------------
   FUNCTION util_get_table_key (
      p_table_name   IN user_tables.table_name%TYPE,
      p_key_type     IN user_constraints.constraint_type%TYPE DEFAULT 'P',
      p_delimiter    IN VARCHAR2 DEFAULT ', ')
      RETURN VARCHAR2
   IS
      v_table_pk   VARCHAR2 (4000 CHAR);
   BEGIN
      FOR i
         IN (WITH cons
                  AS (SELECT constraint_name
                        FROM user_constraints
                       WHERE     table_name = p_table_name
                             AND constraint_type = p_key_type),
                  cols
                  AS (SELECT constraint_name, column_name, position
                        FROM user_cons_columns
                       WHERE table_name = p_table_name)
               SELECT column_name
                 FROM cons
                      JOIN cols ON cons.constraint_name = cols.constraint_name
             ORDER BY position)
      LOOP
         v_table_pk := v_table_pk || p_delimiter || i.column_name;
      END LOOP;

      RETURN LTRIM (v_table_pk, p_delimiter);
   END util_get_table_key;

   -----------------------------------------------------------------------------
   -- util_get_table_column_prefix is a private helper function to find out the
   -- column prefixes of a table. We understand everything before the first
   -- underscore "_" within the columnname as prefix. If columns have different
   -- prefixes within a table, null will be returned.
   -----------------------------------------------------------------------------
   FUNCTION util_get_table_column_prefix (p_table_name IN VARCHAR2)
      RETURN VARCHAR2
   IS
      v_count    PLS_INTEGER := 0;
      v_return   VARCHAR2 (30 CHAR);
   BEGIN
      FOR i
         IN (SELECT DISTINCT
                    SUBSTR (
                       column_name,
                       1,
                       CASE
                          WHEN INSTR (column_name, '_') = 0
                          THEN
                             LENGTH (column_name)
                          ELSE
                             INSTR (column_name, '_') - 1
                       END)
                       AS prefix
               FROM user_tab_cols
              WHERE table_name = p_table_name AND hidden_column = 'NO')
      LOOP
         v_count := v_count + 1;

         IF v_count > 1
         THEN
            v_return := NULL;
            EXIT;
         END IF;

         v_return := i.prefix;
      END LOOP;

      RETURN v_return;
   END util_get_table_column_prefix;

   -----------------------------------------------------------------------------
   -- util_get_attribute_surrogate is a private helper function to find out a
   -- datatype dependent surrogate. This is required for comparing two
   -- values of a column e.g. old value and new value. There is the special case
   -- of null comparisison in Oracle, what means null compared with null is
   -- never true. That is the reason to compare:
   --     coalesce(old value, surrogate) = coalesce(new value, surrogate)
   -- that is true, if both sides are null.
   -----------------------------------------------------------------------------
   FUNCTION util_get_attribute_surrogate (
      p_data_type   IN user_tab_cols.data_type%TYPE)
      RETURN VARCHAR2
   IS
      v_return   VARCHAR2 (100 CHAR);
   BEGIN
      v_return :=
         CASE
            WHEN p_data_type = 'NUMBER'
            THEN
               '-999999999999999.999999999999999'
            WHEN p_data_type LIKE '%CHAR%'
            THEN
               q'['@@@@@@@@@@@@@@@']'
            WHEN p_data_type = 'DATE'
            THEN
               q'[TO_DATE( '01.01.1900', 'DD.MM.YYYY' )]'
            WHEN p_data_type LIKE 'TIMESTAMP%'
            THEN
               q'[TO_TIMESTAMP( '01.01.1900', 'dd.mm.yyyy' )]'
            WHEN p_data_type = 'CLOB'
            THEN
               q'[TO_CLOB( '@@@@@@@@@@@@@@@' )]'
            WHEN p_data_type = 'BLOB'
            THEN
               q'[TO_BLOB( UTL_RAW.cast_to_raw( '@@@@@@@@@@@@@@@' ) )]'
            WHEN p_data_type = 'XMLTYPE'
            THEN
               q'[XMLTYPE( '<NULL/>' )]'
            ELSE
               q'['@@@@@@@@@@@@@@@']'
         END;
      RETURN v_return;
   END util_get_attribute_surrogate;

   -----------------------------------------------------------------------------
   -- util_get_attribute_compare is a private helper function to deliver the
   -- described (take a look at function util_get_attribute_surrogate) compare
   -- code for two attributes. In addition to that, the compare operation must
   -- be dynamically, because e.g. "=" or "<>" or other operations are required.
   -----------------------------------------------------------------------------
   FUNCTION util_get_attribute_compare (
      p_data_type           IN user_tab_cols.data_type%TYPE,
      p_first_attribute     IN VARCHAR2,
      p_second_attribute    IN VARCHAR2,
      p_compare_operation   IN VARCHAR2 DEFAULT '<>')
      RETURN VARCHAR2
   IS
      v_surrogate   VARCHAR2 (100 CHAR);
      v_return      VARCHAR2 (1000 CHAR);
   BEGIN
      v_surrogate := util_get_attribute_surrogate (p_data_type);
      v_return :=
         CASE
            WHEN p_data_type = 'XMLTYPE'
            THEN
                  'util_xml_compare( COALESCE( '
               || p_first_attribute
               || ', '
               || v_surrogate
               || ' ), COALESCE( '
               || p_second_attribute
               || ', '
               || v_surrogate
               || ' ) ) '
               || p_compare_operation
               || ' 0'
            WHEN p_data_type IN ('BLOB', 'CLOB')
            THEN
                  'DBMS_LOB.compare( COALESCE( '
               || p_first_attribute
               || ', '
               || v_surrogate
               || ' ), COALESCE( '
               || p_second_attribute
               || ', '
               || v_surrogate
               || ' ) ) '
               || p_compare_operation
               || ' 0'
            ELSE
                  'COALESCE( '
               || p_first_attribute
               || ', '
               || v_surrogate
               || ' ) '
               || p_compare_operation
               || ' COALESCE( '
               || p_second_attribute
               || ', '
               || v_surrogate
               || ' )'
         END;
      RETURN v_return;
   END util_get_attribute_compare;

   -----------------------------------------------------------------------------
   -- util_get_vc2_4000_operation is a private helper function to deliver a
   -- varchar2 representation of an attribute in dependency of its datatype.
   -----------------------------------------------------------------------------
   FUNCTION util_get_vc2_4000_operation (
      p_data_type        IN user_tab_cols.data_type%TYPE,
      p_attribute_name   IN VARCHAR2)
      RETURN VARCHAR2
   IS
      v_return   VARCHAR2 (1000 CHAR);
   BEGIN
      v_return :=
         CASE
            WHEN p_data_type IN ('NUMBER', 'FLOAT', 'INTEGER')
            THEN
               ' to_char(' || p_attribute_name || ')'
            WHEN p_data_type = 'DATE'
            THEN
                  ' to_char('
               || p_attribute_name
               || q'[, 'yyyy.mm.dd hh24:mi:ss')]'
            WHEN p_data_type LIKE 'TIMESTAMP%'
            THEN
                  ' to_char('
               || p_attribute_name
               || q'[, 'yyyy.mm.dd hh24:mi:ss.ffffff')]'
            WHEN p_data_type = 'BLOB'
            THEN
               q'['Data type "BLOB" is not supported for generic change log']'
            WHEN p_data_type = 'XMLTYPE'
            THEN
                  ' substr( CASE WHEN '
               || p_attribute_name
               || ' IS NULL THEN NULL ELSE '
               || p_attribute_name
               || '.getStringVal() END, 1, 4000)'
            ELSE
               ' substr(' || p_attribute_name || ', 1, 4000)'
         END;
      RETURN v_return;
   END util_get_vc2_4000_operation;

   -----------------------------------------------------------------------------
   -- util_string_to_bool is a private helper function to deliver a
   -- boolean representation of an string value. True is returned, if:
   --   true, yes, y, 1
   -- is given. False is returned when:
   --   false, no, n, 0
   -- is given.
   -----------------------------------------------------------------------------
   FUNCTION util_string_to_bool (p_string IN VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      RETURN CASE
                WHEN LOWER (p_string) IN ('true',
                                          'yes',
                                          'y',
                                          '1')
                THEN
                   TRUE
                WHEN LOWER (p_string) IN ('false',
                                          'no',
                                          'n',
                                          '0')
                THEN
                   FALSE
                ELSE
                   NULL
             END;
   END util_string_to_bool;

   -----------------------------------------------------------------------------
   -- util_bool_to_string is a private helper function to deliver a
   -- varchar2 representation of an boolean value. 'TRUE' is returned, if
   -- boolean value is true. 'FALSE' is returned when boolean value is false.
   -----------------------------------------------------------------------------
   FUNCTION util_bool_to_string (p_bool IN BOOLEAN)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN CASE
                WHEN p_bool THEN 'TRUE'
                WHEN NOT p_bool THEN 'FALSE'
                ELSE NULL
             END;
   END util_bool_to_string;

   -----------------------------------------------------------------------------
   -- util_get_user_name is a private helper function to deliver the current
   -- username. If a valid APEX session exists, then the APEX application user
   -- is taken, otherwise the current connected operation system user.
   -----------------------------------------------------------------------------
   FUNCTION util_get_user_name
      RETURN user_users.username%TYPE
   IS
      v_return   user_users.username%TYPE;
   BEGIN
      v_return :=
         UPPER (
            COALESCE (v ('APP_USER'),
                      SYS_CONTEXT ('USERENV', 'OS_USER'),
                      USER));
      RETURN v_return;
   END util_get_user_name;

   -----------------------------------------------------------------------------
   -- util_get_normalized_identifier is a private helper function to deliver a
   -- cleaned normalized identifier. Normalized means, it it free of special
   -- characters, only "a-z" or "A-Z" or "_" or "0-9" are allowed, so all other
   -- characters are replaced with null by this function. It is required e.g. to
   -- cleanup function- or procedure- or parameter-names generated within
   -- the table API.
   -----------------------------------------------------------------------------
   FUNCTION util_get_normalized_identifier (p_identifier VARCHAR2)
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN REGEXP_REPLACE (srcstr       => p_identifier,
                             pattern      => '[^a-zA-Z0-9_]',
                             replacestr   => NULL);
   END util_get_normalized_identifier;

   -----------------------------------------------------------------------------
   FUNCTION util_get_substituted_name (p_name_template VARCHAR2)
      RETURN VARCHAR2
   IS
      v_return           user_objects.object_name%TYPE;
      v_base_name        user_objects.object_name%TYPE;
      v_replace_string   user_objects.object_name%TYPE;
      v_position         PLS_INTEGER;
      v_length           PLS_INTEGER;
   BEGIN
      -- Get replace string
      v_replace_string :=
         REGEXP_SUBSTR (p_name_template,
                        '#[A-Za-z0-9_-]+#',
                        1,
                        1);

      -- Check, if we have to do a replacement
      IF v_replace_string IS NULL
      THEN
         -- Without replacement we return simply the input
         v_return := p_name_template;
      ELSE
         -- Replace possible placeholders in name template
         v_base_name :=
            RTRIM (REGEXP_SUBSTR (UPPER (v_replace_string),
                                  '[A-Z_]+',
                                  1,
                                  1),
                   '_');

         -- logger.log('v_base_name: ' || v_base_name);

         -- Check, if we have a valid base name
         IF v_base_name NOT IN ('TABLE_NAME', 'PK_COLUMN', 'COLUMN_PREFIX')
         THEN
            -- Without a valid base name we return simply the input
            v_return := p_name_template;
         ELSE
            -- Search for start and stop positions
            v_position :=
               REGEXP_SUBSTR (v_replace_string,
                              '-?\d+',
                              1,
                              1);
            v_length :=
               REGEXP_SUBSTR (v_replace_string,
                              '\d+',
                              1,
                              2);

            -- 1. To be backward compatible we have to support things like this #TABLE_NAME_26#.
            -- 2. If someone want to use the substr version he has always to provide position and length.
            -- 3. Negative position is supported like this #TABLE_NAME_-15_15# (the second number can not be omitted like in substr, see 1.)
            IF v_position IS NULL AND v_length IS NULL
            THEN
               v_length := 200;
               v_position := 1;
            ELSIF v_position IS NOT NULL AND v_length IS NULL
            THEN
               v_length := v_position;
               v_position := 1;
            END IF;

            v_return :=
               REPLACE (
                  p_name_template,
                  v_replace_string,
                  SUBSTR (
                     CASE v_base_name
                        WHEN 'TABLE_NAME'
                        THEN
                           g_tab_substitutions_array ('#TABLE_NAME#')
                        WHEN 'PK_COLUMN'
                        THEN
                           g_tab_substitutions_array ('#PK_COLUMN#')
                        WHEN 'COLUMN_PREFIX'
                        THEN
                           g_tab_substitutions_array ('#COLUMN_PREFIX#')
                     END,
                     v_position,
                     v_length));
         END IF;
      END IF;

      RETURN v_return;
   END util_get_substituted_name;

   -----------------------------------------------------------------------------
   FUNCTION util_serialize_xml (p_xml XMLTYPE)
      RETURN VARCHAR2
   IS
      v_return   VARCHAR2 (32767);
   BEGIN
      SELECT XMLSERIALIZE (DOCUMENT p_xml NO INDENT) INTO v_return FROM DUAL;

      RETURN v_return;
   END util_serialize_xml;

   -----------------------------------------------------------------------------
   PROCEDURE gen_header
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
CREATE OR REPLACE PACKAGE #API_NAME# IS 
  /** 
   * This is the API for the table #TABLE_NAME#. 
   *
   * GENERATION OPTIONS 
   * - must be in the lines 5-30 to be reusable by the generator
   * - DO NOT TOUCH THIS until you know what you do - read the
   *   docs under github.com/OraMUC/table-api-generator ;-)
   * <options 
   *   generator="#GENERATOR#"
   *   generator_version="#GENERATOR_VERSION#"
   *   generator_action="#GENERATOR_ACTION#"
   *   generated_at="#GENERATED_AT#"
   *   generated_by="#GENERATED_BY#"
   *   p_table_name="#TABLE_NAME#"
   *   p_reuse_existing_api_params="#REUSE_EXISTING_API_PARAMS#"
   *   p_col_prefix_in_method_names="#COL_PREFIX_IN_METHOD_NAMES#"
   *   p_enable_insertion_of_rows="#ENABLE_INSERTION_OF_ROWS#"
   *   p_enable_update_of_rows="#ENABLE_UPDATE_OF_ROWS#"
   *   p_enable_deletion_of_rows="#ENABLE_DELETION_OF_ROWS#"
   *   p_enable_generic_change_log="#ENABLE_GENERIC_CHANGE_LOG#"
   *   p_enable_dml_view="#ENABLE_DML_VIEW#"
   *   p_sequence_name="#SEQUENCE_NAME#"
   *   p_api_name="#API_NAME#"
   *   p_enable_getter_and_setter="#ENABLE_GETTER_AND_SETTER#"
   *   p_enable_parameter_prefixes="#ENABLE_PARAMETER_PREFIXES#"
   *   p_return_row_instead_of_pk="#RETURN_ROW_INSTEAD_OF_PK#"/>
   * 
   * This API provides DML functionality that can be easily called from APEX.   
   * Target of the table API is to encapsulate the table DML source code for  
   * security (UI schema needs only the execute right for the API and the 
   * read/write right for the #TABLE_NAME_24#_dml_v, tables can be hidden in 
   * extra data schema) and easy readability of the business logic (all DML is  
   * then written in the same style). For APEX automatic row processing like 
   * tabular forms you can optionally use the #TABLE_NAME_24#_dml_v, which has 
   * an instead of trigger who is also calling the #TABLE_NAME_26#_api.
   */
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
            ' 
CREATE OR REPLACE PACKAGE BODY #API_NAME# IS
  ----------------------------------------'
         || CASE
               WHEN g_xmltype_column_present
               THEN
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
            END
         || CASE
               WHEN g_enable_generic_change_log
               THEN
                  q'[
  PROCEDURE create_change_log_entry( p_table IN VARCHAR2, p_column IN VARCHAR2, p_pk_id IN NUMBER, p_old_value IN VARCHAR2, p_new_value IN VARCHAR2 )
  IS
  BEGIN
    INSERT INTO generic_change_log ( "GCL_ID"
                                   , "GCL_TABLE"
                                   , "GCL_COLUMN"
                                   , "GCL_PK_ID"
                                   , "GCL_OLD_VALUE"
                                   , "GCL_NEW_VALUE"
                                   , "GCL_USER" )
                            VALUES ( generic_change_log_seq.nextval
                                   , p_table
                                   , p_column
                                   , p_pk_id
                                   , p_old_value
                                   , p_new_value
                                   , coalesce(v('APP_USER'),sys_context('USERENV','OS_USER')) );
  END;
  ----------------------------------------]'
               ELSE
                  NULL
            END;
      util_template_replace ('API BODY');
   END gen_header;

   -----------------------------------------------------------------------------
   PROCEDURE gen_row_exists_fnc
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
  FUNCTION row_exists( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE )
  RETURN BOOLEAN;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
         ' 
  FUNCTION row_exists( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE )
  RETURN BOOLEAN 
  IS
    v_return BOOLEAN := FALSE;
  BEGIN
    FOR i IN ( SELECT 1 FROM #TABLE_NAME# WHERE "#PK_COLUMN#" = #PK_COLUMN_PARAMETER# ) LOOP
      v_return := TRUE;
    END LOOP;
    RETURN v_return;
  END;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_row_exists_fnc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_row_exists_yn_fnc
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
  FUNCTION row_exists_yn( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE )
  RETURN VARCHAR2;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
         ' 
  FUNCTION row_exists_yn( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE )
  RETURN VARCHAR2 
  IS
  BEGIN
    RETURN case when row_exists( #PK_COLUMN_PARAMETER# => #PK_COLUMN_PARAMETER# ) 
             then ''Y''
             else ''N''
           end;
  END;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_row_exists_yn_fnc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_get_pk_by_unique_cols_fnc
   IS
   BEGIN
      IF g_tab_unique_constraint_info.COUNT > 0
      THEN
         FOR i IN g_tab_unique_constraint_info.FIRST ..
                  g_tab_unique_constraint_info.LAST
         LOOP
            g_tab_substitutions_array ('#PARAM_LIST_UNIQUE#') := NULL;
            g_tab_substitutions_array ('#COLUMN_COMPARE_LIST_UNIQUE#') := NULL;

            FOR j IN g_tab_unique_cons_column_info.FIRST ..
                     g_tab_unique_cons_column_info.LAST
            LOOP
               IF g_tab_unique_cons_column_info (j).constraint_name =
                     g_tab_unique_constraint_info (i).constraint_name
               THEN
                  g_tab_unique_cons_column_info (j).parameter_name :=
                     CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                              'p_'
                           || SUBSTR (
                                 g_tab_unique_cons_column_info (j).column_name,
                                 1,
                                 28)
                        ELSE
                           g_tab_unique_cons_column_info (j).column_name
                     END;
                  g_tab_substitutions_array ('#PARAM_LIST_UNIQUE#') :=
                        g_tab_substitutions_array ('#PARAM_LIST_UNIQUE#')
                     || c_list_delimiter
                     || CASE
                           WHEN g_enable_parameter_prefixes
                           THEN
                              g_tab_unique_cons_column_info (j).parameter_name
                           ELSE
                              g_tab_unique_cons_column_info (j).parameter_name
                        END
                     || ' '
                     || g_table_name
                     || '."'
                     || g_tab_unique_cons_column_info (j).column_name
                     || '"%TYPE';
                  g_tab_substitutions_array ('#COLUMN_COMPARE_LIST_UNIQUE#') :=
                        g_tab_substitutions_array (
                           '#COLUMN_COMPARE_LIST_UNIQUE#')
                     || '         AND '
                     || util_get_attribute_compare (
                           p_data_type           => g_tab_unique_cons_column_info (j).data_type,
                           p_first_attribute     =>    '"'
                                                    || g_tab_unique_cons_column_info (
                                                          j).column_name
                                                    || '"',
                           p_second_attribute    => g_tab_unique_cons_column_info (
                                                      j).parameter_name,
                           p_compare_operation   => '=')
                     || c_crlf;
               END IF;
            END LOOP;

            g_tab_substitutions_array ('#PARAM_LIST_UNIQUE#') :=
               LTRIM (g_tab_substitutions_array ('#PARAM_LIST_UNIQUE#'),
                      c_list_delimiter);
            g_tab_substitutions_array ('#COLUMN_COMPARE_LIST_UNIQUE#') :=
               RTRIM (
                  LTRIM (
                     g_tab_substitutions_array (
                        '#COLUMN_COMPARE_LIST_UNIQUE#'),
                     '         AND '),
                  c_crlf);
            g_tapi_code_blocks.template :=
               ' 
  FUNCTION get_pk_by_unique_cols( #PARAM_LIST_UNIQUE# )
  RETURN #TABLE_NAME#."#PK_COLUMN#"%TYPE;
  ----------------------------------------';
            util_template_replace ('API SPEC');
            ----------------------------------------
            g_tapi_code_blocks.template :=
               ' 
  FUNCTION get_pk_by_unique_cols( #PARAM_LIST_UNIQUE# )
  RETURN #TABLE_NAME#."#PK_COLUMN#"%TYPE IS
    v_pk #TABLE_NAME#."#PK_COLUMN#"%TYPE;
    CURSOR cur_row IS
      SELECT "#PK_COLUMN#" from #TABLE_NAME#
       WHERE #COLUMN_COMPARE_LIST_UNIQUE#;
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_pk;
    CLOSE cur_row;
    RETURN v_pk;
  END get_pk_by_unique_cols;
  ----------------------------------------';
            util_template_replace ('API BODY');
         END LOOP;
      END IF;
   END gen_get_pk_by_unique_cols_fnc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_create_row_fnc
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
  FUNCTION create_row( #PARAM_DEFINITION_W_PK# )
  RETURN #RETURN_TYPE#;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
            ' 
  FUNCTION create_row( #PARAM_DEFINITION_W_PK# ) 
  RETURN #RETURN_TYPE# IS
    v_return #RETURN_TYPE#;
  BEGIN
    #RETURN_TYPE_PK_COLUMN# := '
         || CASE
               WHEN g_sequence_name IS NOT NULL
               THEN
                  'COALESCE( #PK_COLUMN_PARAMETER#, #SEQUENCE_NAME#.nextval );'
               ELSE
                  '#PK_COLUMN_PARAMETER#;'
            END
         || '
    INSERT INTO #TABLE_NAME# ( #COLUMN_LIST_W_PK# )
      VALUES ( #RETURN_TYPE_PK_COLUMN#, #PARAM_LIST_WO_PK# )
      RETURN #RETURN_VALUE# INTO v_return;'
         || CASE
               WHEN g_enable_generic_change_log
               THEN
                  q'[
    create_change_log_entry( p_table     => '#TABLE_NAME#'
                           , p_column    => '#PK_COLUMN#'
                           , p_pk_id     => #RETURN_TYPE_PK_COLUMN#
                           , p_old_value => 'ROW CREATED'
                           , p_new_value => 'ROW CREATED' );]'
               ELSE
                  NULL
            END
         || ' 
    RETURN v_return;
  END create_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_create_row_fnc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_create_row_prc
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         '
  PROCEDURE create_row( #PARAM_DEFINITION_W_PK# );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
         '
  PROCEDURE create_row( #PARAM_DEFINITION_W_PK# )
  IS
    v_return #RETURN_TYPE#;
  BEGIN
    v_return := create_row( #MAP_PARAM_TO_PARAM_W_PK# );
  END create_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_create_row_prc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_create_rowtype_fnc
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
  FUNCTION create_row( p_row IN #TABLE_NAME#%ROWTYPE )
  RETURN #RETURN_TYPE#;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
         ' 
  FUNCTION create_row( p_row IN #TABLE_NAME#%ROWTYPE ) 
  RETURN #RETURN_TYPE# IS
    v_return #RETURN_TYPE#;
  BEGIN
    v_return := create_row( #MAP_ROWTYPE_COL_TO_PARAM_W_PK# );
    RETURN v_return;
  END create_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_create_rowtype_fnc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_create_rowtype_prc
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
  PROCEDURE create_row( p_row IN #TABLE_NAME#%ROWTYPE );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
         ' 
  PROCEDURE create_row( p_row IN #TABLE_NAME#%ROWTYPE )
  IS
    v_return #RETURN_TYPE#;
  BEGIN
    v_return := create_row( #MAP_ROWTYPE_COL_TO_PARAM_W_PK# );
  END create_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_create_rowtype_prc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_createorupdate_row_fnc
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
  FUNCTION create_or_update_row( #PARAM_DEFINITION_W_PK# )
  RETURN #RETURN_TYPE#;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
         ' 
  FUNCTION create_or_update_row( #PARAM_DEFINITION_W_PK# )
  RETURN #RETURN_TYPE# IS
    v_return #RETURN_TYPE#;
  BEGIN
    IF #PK_COLUMN_PARAMETER# IS NULL THEN
      v_return := create_row( #MAP_PARAM_TO_PARAM_W_PK# );
    ELSE
      IF row_exists( #PK_COLUMN_PARAMETER# => #PK_COLUMN_PARAMETER# ) THEN
        #RETURN_TYPE_PK_COLUMN# := #PK_COLUMN_PARAMETER#;
        update_row( #MAP_PARAM_TO_PARAM_W_PK# );
      ELSE
        v_return := create_row( #MAP_PARAM_TO_PARAM_W_PK# );
      END IF;
    END IF;
    RETURN v_return;
  END create_or_update_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_createorupdate_row_fnc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_createorupdate_row_prc
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
  PROCEDURE create_or_update_row( #PARAM_DEFINITION_W_PK# );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
         ' 
  PROCEDURE create_or_update_row( #PARAM_DEFINITION_W_PK# )
  IS
    v_return #RETURN_TYPE#;
  BEGIN
    v_return := create_or_update_row( #MAP_PARAM_TO_PARAM_W_PK# );
  END create_or_update_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_createorupdate_row_prc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_createorupdate_rowtype_fnc
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
  FUNCTION create_or_update_row( p_row IN #TABLE_NAME#%ROWTYPE )
  RETURN #RETURN_TYPE#;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
         ' 
  FUNCTION create_or_update_row( p_row IN #TABLE_NAME#%ROWTYPE )
  RETURN #RETURN_TYPE# IS
    v_return #RETURN_TYPE#;
  BEGIN
    v_return := create_or_update_row( #MAP_ROWTYPE_COL_TO_PARAM_W_PK# );
    RETURN v_return;
  END create_or_update_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_createorupdate_rowtype_fnc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_createorupdate_rowtype_prc
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
  PROCEDURE create_or_update_row( p_row IN #TABLE_NAME#%ROWTYPE );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
         ' 
  PROCEDURE create_or_update_row( p_row IN #TABLE_NAME#%ROWTYPE )
  IS
    v_return #RETURN_TYPE#;
  BEGIN
    v_return := create_or_update_row( #MAP_ROWTYPE_COL_TO_PARAM_W_PK# );
  END create_or_update_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_createorupdate_rowtype_prc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_read_row_fnc
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
  FUNCTION read_row( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE )
  RETURN #TABLE_NAME#%ROWTYPE;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
         ' 
  FUNCTION read_row( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE )
  RETURN #TABLE_NAME#%ROWTYPE IS
    CURSOR cur_row_by_pk( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE ) IS
      SELECT * FROM #TABLE_NAME# WHERE "#PK_COLUMN#" = #PK_COLUMN_PARAMETER#;
    v_row #TABLE_NAME#%ROWTYPE;
  BEGIN
    OPEN cur_row_by_pk( #PK_COLUMN_PARAMETER# );
    FETCH cur_row_by_pk INTO v_row;
    CLOSE cur_row_by_pk;
    RETURN v_row;
  END read_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_read_row_fnc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_read_row_prc
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
  PROCEDURE read_row( #PARAM_IO_DEFINITION_W_PK# );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
         ' 
  PROCEDURE read_row( #PARAM_IO_DEFINITION_W_PK# )
  IS
    v_row #TABLE_NAME#%ROWTYPE;
  BEGIN
    v_row := read_row ( #PK_COLUMN_PARAMETER# => #PK_COLUMN_PARAMETER# );
    IF v_row."#PK_COLUMN#" IS NOT NULL THEN 
      #SET_ROWTYPE_COL_TO_PARAM_WO_PK#
    END IF;
  END read_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_read_row_prc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_read_row_by_uk_fnc
   IS
   BEGIN
      IF g_tab_unique_constraint_info.COUNT > 0
      THEN
         FOR i IN g_tab_unique_constraint_info.FIRST ..
                  g_tab_unique_constraint_info.LAST
         LOOP
            g_tab_substitutions_array ('#PARAM_LIST_UNIQUE#') := NULL;
            g_tab_substitutions_array ('#COLUMN_COMPARE_LIST_UNIQUE#') := NULL;
            g_tab_substitutions_array ('#PARAM_CALLING_LIST_UNIQUE#') := NULL;

            FOR j IN g_tab_unique_cons_column_info.FIRST ..
                     g_tab_unique_cons_column_info.LAST
            LOOP
               IF g_tab_unique_cons_column_info (j).constraint_name =
                     g_tab_unique_constraint_info (i).constraint_name
               THEN
                  g_tab_unique_cons_column_info (j).parameter_name :=
                     CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                              'p_'
                           || SUBSTR (
                                 g_tab_unique_cons_column_info (j).column_name,
                                 1,
                                 28)
                        ELSE
                           g_tab_unique_cons_column_info (j).column_name
                     END;
                  g_tab_substitutions_array ('#PARAM_LIST_UNIQUE#') :=
                        g_tab_substitutions_array ('#PARAM_LIST_UNIQUE#')
                     || c_list_delimiter
                     || g_tab_unique_cons_column_info (j).parameter_name
                     || ' '
                     || g_table_name
                     || '."'
                     || g_tab_unique_cons_column_info (j).column_name
                     || '"%TYPE';
                  g_tab_substitutions_array ('#PARAM_CALLING_LIST_UNIQUE#') :=
                        g_tab_substitutions_array (
                           '#PARAM_CALLING_LIST_UNIQUE#')
                     || c_list_delimiter
                     || g_tab_unique_cons_column_info (j).parameter_name
                     || ' => '
                     || g_tab_unique_cons_column_info (j).parameter_name;
                  g_tab_substitutions_array ('#COLUMN_COMPARE_LIST_UNIQUE#') :=
                        g_tab_substitutions_array (
                           '#COLUMN_COMPARE_LIST_UNIQUE#')
                     || '         AND '
                     || util_get_attribute_compare (
                           p_data_type           => g_tab_unique_cons_column_info (j).data_type,
                           p_first_attribute     =>    '"'
                                                    || g_tab_unique_cons_column_info (
                                                          j).column_name
                                                    || '"',
                           p_second_attribute    => g_tab_unique_cons_column_info (
                                                      j).parameter_name,
                           p_compare_operation   => '=')
                     || c_crlf;
               END IF;
            END LOOP;

            g_tab_substitutions_array ('#PARAM_LIST_UNIQUE#') :=
               LTRIM (g_tab_substitutions_array ('#PARAM_LIST_UNIQUE#'),
                      c_list_delimiter);

            g_tab_substitutions_array ('#PARAM_CALLING_LIST_UNIQUE#') :=
               LTRIM (
                  g_tab_substitutions_array ('#PARAM_CALLING_LIST_UNIQUE#'),
                  c_list_delimiter);

            g_tab_substitutions_array ('#COLUMN_COMPARE_LIST_UNIQUE#') :=
               RTRIM (
                  LTRIM (
                     g_tab_substitutions_array (
                        '#COLUMN_COMPARE_LIST_UNIQUE#'),
                     '         AND '),
                  c_crlf);
            g_tapi_code_blocks.template :=
               ' 
  FUNCTION read_row( #PARAM_LIST_UNIQUE# )
  RETURN #TABLE_NAME#%ROWTYPE;
  ----------------------------------------';
            util_template_replace ('API SPEC');
            ----------------------------------------
            g_tapi_code_blocks.template :=
               ' 
  FUNCTION read_row( #PARAM_LIST_UNIQUE# )
  RETURN #TABLE_NAME#%ROWTYPE IS
    v_pk #TABLE_NAME#."#PK_COLUMN#"%TYPE;
  BEGIN
    v_pk := get_pk_by_unique_cols( #PARAM_CALLING_LIST_UNIQUE# );
    RETURN read_row ( #PK_COLUMN_PARAMETER# => v_pk );
  END read_row;
  ----------------------------------------';
            util_template_replace ('API BODY');
         END LOOP;
      END IF;
   END gen_read_row_by_uk_fnc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_read_a_row_fnc
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
  FUNCTION read_a_row
  RETURN #TABLE_NAME#%ROWTYPE;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
         ' 
  FUNCTION read_a_row
  RETURN #TABLE_NAME#%ROWTYPE IS
    CURSOR cur_row IS
      SELECT * FROM #TABLE_NAME#;
    v_row #TABLE_NAME#%ROWTYPE;
  BEGIN
    OPEN cur_row;
    FETCH cur_row INTO v_row;
    CLOSE cur_row;
    RETURN v_row;
  END read_a_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_read_a_row_fnc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_update_row_prc
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
  PROCEDURE update_row( #PARAM_DEFINITION_W_PK# );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
            ' 
  PROCEDURE update_row( #PARAM_DEFINITION_W_PK# )
  IS
    v_row   #TABLE_NAME#%ROWTYPE;'
         || CASE
               WHEN g_enable_generic_change_log
               THEN
                  '
    v_count PLS_INTEGER := 0;'
               ELSE
                  NULL
            END
         || '
  BEGIN
    v_row := read_row( #PK_COLUMN_PARAMETER# => #PK_COLUMN_PARAMETER# );
    IF v_row."#PK_COLUMN#" IS NOT NULL THEN
      -- update only, if the column values really differ
      IF #COLUMN_COMPARE_LIST_WO_PK#
      THEN
        UPDATE #TABLE_NAME#
           SET #SET_PARAM_TO_COLUMN_WO_PK#
         WHERE "#PK_COLUMN#" = v_row."#PK_COLUMN#";
      END IF;
    END IF;
  END update_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_update_row_prc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_update_rowtype_prc
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
  PROCEDURE update_row( p_row IN #TABLE_NAME#%ROWTYPE );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
         ' 
  PROCEDURE update_row( p_row IN #TABLE_NAME#%ROWTYPE )
  IS
  BEGIN
    update_row( #MAP_ROWTYPE_COL_TO_PARAM_W_PK# );
  END update_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_update_rowtype_prc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_delete_row_prc
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
  PROCEDURE delete_row( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template :=
            ' 
  PROCEDURE delete_row( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE )
  IS
  BEGIN
    DELETE FROM #TABLE_NAME# WHERE "#PK_COLUMN#" = #PK_COLUMN_PARAMETER#;'
         || CASE
               WHEN g_enable_generic_change_log
               THEN
                  q'[
    create_change_log_entry( p_table     => '#TABLE_NAME#'
                           , p_column    => '#PK_COLUMN#'
                           , p_pk_id     => #PK_COLUMN_PARAMETER#
                           , p_old_value => 'ROW DELETED'
                           , p_new_value => 'ROW DELETED' );]'
               ELSE
                  NULL
            END
         || '
  END delete_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_delete_row_prc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_getter_functions
   IS
   BEGIN
      FOR i IN g_tab_column_info.FIRST .. g_tab_column_info.LAST
      LOOP
         IF (g_tab_column_info (i).column_name <>
                g_tab_substitutions_array ('#PK_COLUMN#'))
         THEN
            g_tab_substitutions_array ('#I_COLUMN_NAME#') :=
               g_tab_column_info (i).column_name;
            g_tab_substitutions_array ('#I_COLUMN_NAME_26#') :=
               g_tab_column_info (i).column_name_26;
            g_tapi_code_blocks.template :=
               ' 
  FUNCTION get_#I_COLUMN_NAME_26#( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE )
  RETURN #TABLE_NAME#."#I_COLUMN_NAME#"%TYPE;
  ----------------------------------------';
            util_template_replace ('API SPEC');
            ----------------------------------------
            g_tapi_code_blocks.template :=
               ' 
  FUNCTION get_#I_COLUMN_NAME_26#( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE )
  RETURN #TABLE_NAME#."#I_COLUMN_NAME#"%TYPE IS
    v_row    #TABLE_NAME#%ROWTYPE;
  BEGIN
    v_row := read_row ( #PK_COLUMN_PARAMETER# => #PK_COLUMN_PARAMETER# );
    RETURN v_row."#I_COLUMN_NAME#";
  END get_#I_COLUMN_NAME_26#;
  ----------------------------------------';
            util_template_replace ('API BODY');
         END IF;
      END LOOP;
   END gen_getter_functions;

   -----------------------------------------------------------------------------
   PROCEDURE gen_setter_procedures
   IS
   BEGIN
      FOR i IN g_tab_column_info.FIRST .. g_tab_column_info.LAST
      LOOP
         IF (g_tab_column_info (i).column_name <>
                g_tab_substitutions_array ('#PK_COLUMN#'))
         THEN
            g_tab_substitutions_array ('#I_COLUMN_NAME#') :=
               g_tab_column_info (i).column_name;
            g_tab_substitutions_array ('#I_COLUMN_NAME_26#') :=
               g_tab_column_info (i).column_name_26;
            g_tab_substitutions_array ('#I_PARAMETER_NAME#') :=
               CASE
                  WHEN g_enable_parameter_prefixes
                  THEN
                     'p_' || g_tab_column_info (i).column_name_28
                  ELSE
                     g_tab_column_info (i).column_name
               END;
            g_tab_substitutions_array ('#I_COLUMN_COMPARE#') :=
               util_get_attribute_compare (
                  p_data_type           => g_tab_column_info (i).data_type,
                  p_first_attribute     =>    'v_row."'
                                           || g_tab_column_info (i).column_name
                                           || '"',
                  p_second_attribute    => g_tab_substitutions_array (
                                             '#I_PARAMETER_NAME#'),
                  p_compare_operation   => '<>');
            g_tab_substitutions_array ('#I_OLD_VALUE#') :=
               util_get_vc2_4000_operation (
                  p_data_type        => g_tab_column_info (i).data_type,
                  p_attribute_name   =>    'v_row."'
                                        || g_tab_column_info (i).column_name
                                        || '"');
            g_tab_substitutions_array ('#I_NEW_VALUE#') :=
               util_get_vc2_4000_operation (
                  p_data_type        => g_tab_column_info (i).data_type,
                  p_attribute_name   => g_tab_substitutions_array (
                                          '#I_PARAMETER_NAME#'));
            g_tapi_code_blocks.template :=
               ' 
  PROCEDURE set_#I_COLUMN_NAME_26#( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE, #I_PARAMETER_NAME# IN #TABLE_NAME#."#I_COLUMN_NAME#"%TYPE );
  ----------------------------------------';
            util_template_replace ('API SPEC');
            ----------------------------------------
            g_tapi_code_blocks.template :=
                  ' 
  PROCEDURE set_#I_COLUMN_NAME_26#( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE, #I_PARAMETER_NAME# IN #TABLE_NAME#."#I_COLUMN_NAME#"%TYPE )
  IS
    v_row #TABLE_NAME#%ROWTYPE;
  BEGIN
    v_row := read_row ( #PK_COLUMN_PARAMETER# => #PK_COLUMN_PARAMETER# );
    IF v_row."#PK_COLUMN#" IS NOT NULL THEN
      -- update only, if the column value really differs
      IF #I_COLUMN_COMPARE# THEN
        UPDATE #TABLE_NAME#
           SET "#I_COLUMN_NAME#" = #I_PARAMETER_NAME#
         WHERE "#PK_COLUMN#" = #PK_COLUMN_PARAMETER#;'
               || CASE
                     WHEN g_enable_generic_change_log
                     THEN
                        q'[
        create_change_log_entry( p_table     => '#TABLE_NAME#'
                               , p_column    => '#I_COLUMN_NAME#'
                               , p_pk_id     => #PK_COLUMN_PARAMETER#
                               , p_old_value => #I_OLD_VALUE#
                               , p_new_value => #I_NEW_VALUE# );]'
                     ELSE
                        NULL
                  END
               || '
      END IF;
    END IF;
  END set_#I_COLUMN_NAME_26#;
  ----------------------------------------';
            util_template_replace ('API BODY');
         END IF;
      END LOOP;
   END gen_setter_procedures;

   -----------------------------------------------------------------------------
   PROCEDURE gen_footer
   IS
   BEGIN
      g_tapi_code_blocks.template := ' 
END #API_NAME#; ';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_tapi_code_blocks.template := ' 
END #API_NAME#; ';
      util_template_replace ('API BODY');
   END gen_footer;

   -----------------------------------------------------------------------------
   PROCEDURE gen_dml_view
   IS
   BEGIN
      g_tapi_code_blocks.template :=
         ' 
CREATE OR REPLACE VIEW #TABLE_NAME_24#_dml_v AS
SELECT #COLUMN_LIST_W_PK#
FROM #TABLE_NAME#';
      util_template_replace ('VIEW');
   END gen_dml_view;

   -----------------------------------------------------------------------------
   PROCEDURE gen_dml_view_trigger
   IS
   BEGIN
      g_tapi_code_blocks.template :=
            ' 
CREATE OR REPLACE TRIGGER #TABLE_NAME_24#_ioiud
  INSTEAD OF INSERT OR UPDATE OR DELETE
  ON #TABLE_NAME_24#_dml_v
  FOR EACH ROW
BEGIN
  IF INSERTING THEN 
    '
         || CASE
               WHEN g_enable_insertion_of_rows
               THEN
                  '#TABLE_NAME_26#_api.create_row( #MAP_NEW_TO_PARAM_W_PK# );'
               ELSE
                  'raise_application_error (-20000, ''Insertion of a row is not allowed.'');'
            END
         || '    
  ELSIF UPDATING THEN 
    '
         || CASE
               WHEN g_enable_update_of_rows
               THEN
                  '#TABLE_NAME_26#_api.update_row( #MAP_NEW_TO_PARAM_W_PK# );'
               ELSE
                  'raise_application_error (-20000, ''Update of a row is not allowed.'');'
            END
         || '    
  ELSIF DELETING THEN
    '
         || CASE
               WHEN g_enable_deletion_of_rows
               THEN
                  '#TABLE_NAME_26#_api.delete_row( #PK_COLUMN_PARAMETER# => :old."#PK_COLUMN#");'
               ELSE
                  'raise_application_error (-20000, ''Deletion of a row is not allowed.'');'
            END
         || '    
  END IF;
END #TABLE_NAME_24#_ioiud;';
      util_template_replace ('TRIGGER');
   END gen_dml_view_trigger;

   -----------------------------------------------------------------------------
   PROCEDURE main_generate (
      p_generator_action             IN VARCHAR2,
      p_table_name                   IN user_tables.table_name%TYPE,
      p_reuse_existing_api_params    IN BOOLEAN,
      p_col_prefix_in_method_names   IN BOOLEAN,
      p_enable_insertion_of_rows     IN BOOLEAN,
      p_enable_update_of_rows        IN BOOLEAN,
      p_enable_deletion_of_rows      IN BOOLEAN,
      p_enable_generic_change_log    IN BOOLEAN,
      p_enable_dml_view              IN BOOLEAN,
      p_sequence_name                IN user_sequences.sequence_name%TYPE,
      p_api_name                     IN user_objects.object_name%TYPE DEFAULT om_tapigen.c_api_name,
      p_enable_getter_and_setter     IN BOOLEAN DEFAULT om_tapigen.c_enable_getter_and_setter,
      p_enable_parameter_prefixes    IN BOOLEAN DEFAULT om_tapigen.c_enable_parameter_prefixes,
      p_return_row_instead_of_pk     IN BOOLEAN DEFAULT om_tapigen.c_return_row_instead_of_pk,
      p_column_defaults              IN XMLTYPE DEFAULT om_tapigen.c_column_defaults)
   IS
      PROCEDURE initialize
      IS
         v_object_exists   user_objects.object_name%TYPE;

         --
         PROCEDURE reset_globals
         IS
         BEGIN
            --------------------------------------------------------------------
            -- globl collections and records
            --------------------------------------------------------------------
            g_tab_column_info.delete;
            g_tab_substitutions_array.delete;
            g_tab_unique_constraint_info.delete;
            g_tab_unique_cons_column_info.delete;
            g_tapi_code_blocks := NULL;
            g_params_existing_api := NULL;

            --------------------------------------------------------------------
            -- global variables
            --------------------------------------------------------------------
            g_table_name := NULL;
            g_reuse_existing_api_params := NULL;
            g_col_prefix_in_method_names := NULL;
            g_enable_insertion_of_rows := NULL;
            g_enable_update_of_rows := NULL;
            g_enable_deletion_of_rows := NULL;
            g_enable_generic_change_log := NULL;
            g_enable_dml_view := NULL;
            g_sequence_name := NULL;
            g_api_name := NULL;
            g_enable_getter_and_setter := NULL;
            g_enable_parameter_prefixes := NULL;
            g_return_row_instead_of_pk := NULL;
            g_column_defaults := NULL;
            g_xmltype_column_present := NULL;
         END reset_globals;

         --
         PROCEDURE process_parameters
         IS
            v_api_found   BOOLEAN;
         BEGIN
            -- save params as global package vars for later use
            g_table_name := p_table_name;
            g_reuse_existing_api_params := p_reuse_existing_api_params;
            --
            v_api_found := FALSE;

            IF g_reuse_existing_api_params
            THEN
               OPEN g_cur_existing_apis (g_table_name);

               FETCH g_cur_existing_apis INTO g_params_existing_api;

               IF g_cur_existing_apis%FOUND
               THEN
                  v_api_found := TRUE;
               END IF;

               CLOSE g_cur_existing_apis;
            END IF;

            g_col_prefix_in_method_names :=
               CASE
                  WHEN     g_reuse_existing_api_params
                       AND v_api_found
                       AND g_params_existing_api.p_col_prefix_in_method_names
                              IS NOT NULL
                  THEN
                     util_string_to_bool (
                        g_params_existing_api.p_col_prefix_in_method_names)
                  ELSE
                     p_col_prefix_in_method_names
               END;

            g_enable_insertion_of_rows :=
               CASE
                  WHEN     g_reuse_existing_api_params
                       AND v_api_found
                       AND g_params_existing_api.p_enable_insertion_of_rows
                              IS NOT NULL
                  THEN
                     util_string_to_bool (
                        g_params_existing_api.p_enable_insertion_of_rows)
                  ELSE
                     p_enable_insertion_of_rows
               END;

            g_enable_update_of_rows :=
               CASE
                  WHEN     g_reuse_existing_api_params
                       AND v_api_found
                       AND g_params_existing_api.p_enable_update_of_rows
                              IS NOT NULL
                  THEN
                     util_string_to_bool (
                        g_params_existing_api.p_enable_update_of_rows)
                  ELSE
                     p_enable_update_of_rows
               END;

            g_enable_deletion_of_rows :=
               CASE
                  WHEN     g_reuse_existing_api_params
                       AND v_api_found
                       AND g_params_existing_api.p_enable_deletion_of_rows
                              IS NOT NULL
                  THEN
                     util_string_to_bool (
                        g_params_existing_api.p_enable_deletion_of_rows)
                  ELSE
                     p_enable_deletion_of_rows
               END;

            g_enable_generic_change_log :=
               CASE
                  WHEN     g_reuse_existing_api_params
                       AND v_api_found
                       AND g_params_existing_api.p_enable_generic_change_log
                              IS NOT NULL
                  THEN
                     util_string_to_bool (
                        g_params_existing_api.p_enable_generic_change_log)
                  ELSE
                     p_enable_generic_change_log
               END;

            g_enable_dml_view :=
               CASE
                  WHEN     g_reuse_existing_api_params
                       AND v_api_found
                       AND g_params_existing_api.p_enable_dml_view
                              IS NOT NULL
                  THEN
                     util_string_to_bool (
                        g_params_existing_api.p_enable_dml_view)
                  ELSE
                     p_enable_dml_view
               END;

            g_sequence_name :=
               CASE
                  WHEN g_reuse_existing_api_params AND v_api_found
                  THEN
                     g_params_existing_api.p_sequence_name
                  ELSE
                     p_sequence_name
               END;

            g_api_name :=
               CASE
                  WHEN     g_reuse_existing_api_params
                       AND v_api_found
                       AND g_params_existing_api.p_api_name IS NOT NULL
                  THEN
                     g_params_existing_api.p_api_name
                  ELSE
                     NVL (p_api_name, '#TABLE_NAME_26#_API')
               END;

            g_enable_getter_and_setter :=
               CASE
                  WHEN     g_reuse_existing_api_params
                       AND v_api_found
                       AND g_params_existing_api.p_enable_getter_and_setter
                              IS NOT NULL
                  THEN
                     util_string_to_bool (
                        g_params_existing_api.p_enable_getter_and_setter)
                  ELSE
                     p_enable_getter_and_setter
               END;
            g_enable_parameter_prefixes :=
               CASE
                  WHEN     g_reuse_existing_api_params
                       AND v_api_found
                       AND g_params_existing_api.p_enable_parameter_prefixes
                              IS NOT NULL
                  THEN
                     util_string_to_bool (
                        g_params_existing_api.p_enable_parameter_prefixes)
                  ELSE
                     p_enable_parameter_prefixes
               END;
            g_return_row_instead_of_pk :=
               CASE
                  WHEN     g_reuse_existing_api_params
                       AND v_api_found
                       AND g_params_existing_api.p_return_row_instead_of_pk
                              IS NOT NULL
                  THEN
                     util_string_to_bool (
                        g_params_existing_api.p_return_row_instead_of_pk)
                  ELSE
                     p_return_row_instead_of_pk
               END;

            -- We do not support saving column defaults in package spec, because this could break our
            -- pipelined service function "om_tapigen.view_existing_apis":
            -- SELECT * FROM TABLE(om_tapigen.view_existing_apis);
            g_column_defaults := p_column_defaults;
         END process_parameters;

         --
         PROCEDURE set_substitutions_literal_base
         IS
         BEGIN
            -- meta data
            g_tab_substitutions_array ('#GENERATOR#') := c_generator;
            g_tab_substitutions_array ('#GENERATOR_VERSION#') :=
               c_generator_version;
            g_tab_substitutions_array ('#GENERATOR_ACTION#') :=
               p_generator_action;
            g_tab_substitutions_array ('#GENERATED_AT#') :=
               TO_CHAR (SYSDATE, 'yyyy-mm-dd hh24:mi:ss');
            g_tab_substitutions_array ('#GENERATED_BY#') := util_get_user_name;

            -- table data
            g_tab_substitutions_array ('#TABLE_NAME#') := g_table_name;
            g_tab_substitutions_array ('#TABLE_NAME_24#') :=
               SUBSTR (g_table_name, 1, 24);
            g_tab_substitutions_array ('#TABLE_NAME_26#') :=
               SUBSTR (g_table_name, 1, 26);
            g_tab_substitutions_array ('#TABLE_NAME_28#') :=
               SUBSTR (g_table_name, 1, 28);
            g_tab_substitutions_array ('#PK_COLUMN#') :=
               util_get_table_key (p_table_name => g_table_name);
            g_tab_substitutions_array ('#PK_COLUMN_26#') :=
               SUBSTR (g_tab_substitutions_array ('#PK_COLUMN#'), 1, 26);
            g_tab_substitutions_array ('#PK_COLUMN_28#') :=
               SUBSTR (g_tab_substitutions_array ('#PK_COLUMN#'), 1, 28);
            -- check, if option "col_prefix_in_method_names" is set and check then if table's column prefix is unique
            g_tab_substitutions_array ('#COLUMN_PREFIX#') :=
               util_get_table_column_prefix (g_table_name);

            IF     g_col_prefix_in_method_names = FALSE
               AND g_tab_substitutions_array ('#COLUMN_PREFIX#') IS NULL
            THEN
               raise_application_error (
                  c_generator_error_number,
                  'The prefix of your column names (example: prefix_rest_of_column_name) is not unique and you requested to cut off the prefix for method names. Please ensure either your column names have a unique prefix or switch the parameter p_col_prefix_in_method_names to true (SQL Developer oddgen integration: check option "Keep column prefix in method names").');
            END IF;

            -- dependend on table data
            g_tab_substitutions_array ('#REUSE_EXISTING_API_PARAMS#') :=
               util_bool_to_string (g_reuse_existing_api_params);
            g_tab_substitutions_array ('#COL_PREFIX_IN_METHOD_NAMES#') :=
               util_bool_to_string (g_col_prefix_in_method_names);
            g_tab_substitutions_array ('#ENABLE_INSERTION_OF_ROWS#') :=
               util_bool_to_string (g_enable_insertion_of_rows);
            g_tab_substitutions_array ('#ENABLE_UPDATE_OF_ROWS#') :=
               util_bool_to_string (g_enable_update_of_rows);
            g_tab_substitutions_array ('#ENABLE_DELETION_OF_ROWS#') :=
               util_bool_to_string (g_enable_deletion_of_rows);
            g_tab_substitutions_array ('#ENABLE_GENERIC_CHANGE_LOG#') :=
               util_bool_to_string (g_enable_generic_change_log);
            g_tab_substitutions_array ('#ENABLE_DML_VIEW#') :=
               util_bool_to_string (g_enable_dml_view);
            g_tab_substitutions_array ('#ENABLE_GETTER_AND_SETTER#') :=
               util_bool_to_string (g_enable_getter_and_setter);
            g_tab_substitutions_array ('#ENABLE_PARAMETER_PREFIXES#') :=
               util_bool_to_string (g_enable_parameter_prefixes);
            g_tab_substitutions_array ('#RETURN_ROW_INSTEAD_OF_PK#') :=
               util_bool_to_string (g_return_row_instead_of_pk);


            IF g_sequence_name IS NOT NULL
            THEN
               g_sequence_name := util_get_substituted_name (g_sequence_name);
            END IF;

            g_tab_substitutions_array ('#SEQUENCE_NAME#') := g_sequence_name;

            --
            IF g_api_name IS NOT NULL
            THEN
               g_api_name := util_get_substituted_name (g_api_name);
            END IF;

            g_tab_substitutions_array ('#API_NAME#') := g_api_name;

            g_tab_substitutions_array ('#PK_COLUMN_PARAMETER#') :=
               CASE
                  WHEN g_enable_parameter_prefixes
                  THEN
                     'p_' || g_tab_substitutions_array ('#PK_COLUMN_28#')
                  ELSE
                     g_tab_substitutions_array ('#PK_COLUMN#')
               END;

            g_tab_substitutions_array ('#RETURN_TYPE#') :=
               CASE
                  WHEN g_return_row_instead_of_pk
                  THEN
                     g_table_name || '%ROWTYPE'
                  ELSE
                        g_table_name
                     || '."'
                     || g_tab_substitutions_array ('#PK_COLUMN#')
                     || '"%TYPE'
               END;

            g_tab_substitutions_array ('#RETURN_TYPE_PK_COLUMN#') :=
                  'v_return'
               || CASE
                     WHEN g_return_row_instead_of_pk
                     THEN
                           '."'
                        || g_tab_substitutions_array ('#PK_COLUMN#')
                        || '"'
                     ELSE
                        NULL
                  END;
         -- For g_tab_substitutions_array ('#RETURN_VALUE#') see procedure
         -- set_substitutions_literal_base, as it is dependend on #COLUMN_LIST_W_PK#

         END set_substitutions_literal_base;

         --
         PROCEDURE check_if_table_exists
         IS
         BEGIN
            v_object_exists := NULL;

            OPEN g_cur_table_exists;

            FETCH g_cur_table_exists INTO v_object_exists;

            CLOSE g_cur_table_exists;

            IF (v_object_exists IS NULL)
            THEN
               raise_application_error (
                  c_generator_error_number,
                  'Table ' || g_table_name || ' does not exist.');
            END IF;
         END check_if_table_exists;

         --
         PROCEDURE check_if_sequence_exists
         IS
         BEGIN
            IF g_sequence_name IS NOT NULL
            THEN
               v_object_exists := NULL;

               OPEN g_cur_sequence_exists;

               FETCH g_cur_sequence_exists INTO v_object_exists;

               CLOSE g_cur_sequence_exists;

               IF (v_object_exists IS NULL)
               THEN
                  raise_application_error (
                     c_generator_error_number,
                        'Sequence '
                     || g_sequence_name
                     || ' does not exist. Please provide correct sequence name or create missing sequence.');
               END IF;
            END IF;
         END check_if_sequence_exists;

         --
         PROCEDURE check_if_log_table_exists
         IS
            v_count   PLS_INTEGER;
         BEGIN
            IF g_enable_generic_change_log
            THEN
               FOR i IN (SELECT 'GENERIC_CHANGE_LOG' FROM DUAL
                         MINUS
                         SELECT table_name
                           FROM user_tables
                          WHERE table_name = 'GENERIC_CHANGE_LOG')
               LOOP
                  -- check constraint
                  SELECT COUNT (*)
                    INTO v_count
                    FROM user_objects
                   WHERE object_name = 'GENERIC_CHANGE_LOG_PK';

                  IF v_count > 0
                  THEN
                     raise_application_error (
                        c_generator_error_number,
                        'Stop trying to create generic change log table: Object with the name GENERIC_CHANGE_LOG_PK already exists.');
                  END IF;

                  -- check sequence
                  SELECT COUNT (*)
                    INTO v_count
                    FROM user_objects
                   WHERE object_name = 'GENERIC_CHANGE_LOG_SEQ';

                  IF v_count > 0
                  THEN
                     raise_application_error (
                        c_generator_error_number,
                        'Stop trying to create generic change log table: Object with the name GENERIC_CHANGE_LOG_SEQ already exists.');
                  END IF;

                  -- check index
                  SELECT COUNT (*)
                    INTO v_count
                    FROM user_objects
                   WHERE object_name = 'GENERIC_CHANGE_LOG_IDX';

                  IF v_count > 0
                  THEN
                     raise_application_error (
                        c_generator_error_number,
                        'Stop trying to create generic change log table: Object with the name GENERIC_CHANGE_LOG_IDX already exists.');
                  END IF;

                  EXECUTE IMMEDIATE
                     q'[
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

                  EXECUTE IMMEDIATE
                     q'[
create sequence generic_change_log_seq nocache noorder nocycle
]';

                  EXECUTE IMMEDIATE
                     q'[
create index generic_change_log_idx on generic_change_log (gcl_table, gcl_column, gcl_pk_id)
]';

                  EXECUTE IMMEDIATE
                     q'[
comment on column generic_change_log.gcl_id is 'Primary key of the table']';

                  EXECUTE IMMEDIATE
                     q'[
comment on column generic_change_log.gcl_table is 'Table on which the change occured']';

                  EXECUTE IMMEDIATE
                     q'[
comment on column generic_change_log.gcl_column is 'Column on which the change occured']';

                  EXECUTE IMMEDIATE
                     q'[
comment on column generic_change_log.gcl_pk_id is 'We assume that the pk column of the changed table has a number type']';

                  EXECUTE IMMEDIATE
                     q'[
comment on column generic_change_log.gcl_old_value is 'The old value before the change']';

                  EXECUTE IMMEDIATE
                     q'[
comment on column generic_change_log.gcl_new_value is 'The new value after the change']';

                  EXECUTE IMMEDIATE
                     q'[
comment on column generic_change_log.gcl_user is 'The user, who changed the data']';

                  EXECUTE IMMEDIATE
                     q'[
comment on column generic_change_log.gcl_timestamp is 'The time when the change occured']';
               END LOOP;
            END IF;
         END check_if_log_table_exists;

         --
         PROCEDURE create_temporary_lobs
         IS
         BEGIN
            DBMS_LOB.createtemporary (
               lob_loc   => g_tapi_code_blocks.api_spec,
               cache     => FALSE);
            DBMS_LOB.createtemporary (
               lob_loc   => g_tapi_code_blocks.api_body,
               cache     => FALSE);
            DBMS_LOB.createtemporary (
               lob_loc   => g_tapi_code_blocks.dml_view,
               cache     => FALSE);
            DBMS_LOB.createtemporary (
               lob_loc   => g_tapi_code_blocks.dml_view_trigger,
               cache     => FALSE);
         END create_temporary_lobs;

         --
         PROCEDURE set_substitutions_collect_base
         IS
            PROCEDURE init_substitutions
            IS
            BEGIN
               -- initialize some array key before concatenating in loop
               -- first action in loop is read and this fails, if array key is not existing
               g_tab_substitutions_array ('#COLUMN_LIST_W_PK#') := NULL;
               g_tab_substitutions_array ('#MAP_NEW_TO_PARAM_W_PK#') := NULL;
               g_tab_substitutions_array ('#MAP_PARAM_TO_PARAM_W_PK#') := NULL;
               g_tab_substitutions_array ('#MAP_ROWTYPE_COL_TO_PARAM_W_PK#') :=
                  NULL;
               g_tab_substitutions_array ('#PARAM_DEFINITION_W_PK#') := NULL;
               g_tab_substitutions_array ('#PARAM_DEFINITION_W_PK#') := NULL;
               g_tab_substitutions_array ('#PARAM_IO_DEFINITION_W_PK#') :=
                  NULL;
               g_tab_substitutions_array ('#PARAM_LIST_WO_PK#') := NULL;
               g_tab_substitutions_array ('#SET_PARAM_TO_COLUMN_WO_PK#') :=
                  NULL;
               g_tab_substitutions_array ('#SET_ROWTYPE_COL_TO_PARAM_WO_PK#') :=
                  NULL;
               g_tab_substitutions_array ('#COLUMN_COMPARE_LIST_WO_PK#') :=
                  NULL;
               g_tab_substitutions_array ('#PARAM_CALLING_LIST_UNIQUE#') :=
                  NULL;
            END init_substitutions;

            --
            PROCEDURE fetch_table_columns
            IS
            BEGIN
               OPEN g_cur_columns;

               FETCH g_cur_columns
                  BULK COLLECT INTO g_tab_column_info
                  LIMIT c_bulk_collect_limit;

               CLOSE g_cur_columns;
            END fetch_table_columns;

            --
            PROCEDURE fetch_unique_constraints
            IS
            BEGIN
               OPEN g_cur_unique_constraints;

               FETCH g_cur_unique_constraints
                  BULK COLLECT INTO g_tab_unique_constraint_info
                  LIMIT c_bulk_collect_limit;

               CLOSE g_cur_unique_constraints;
            END fetch_unique_constraints;

            --
            PROCEDURE fetch_unique_cons_columns
            IS
            BEGIN
               OPEN g_cur_unique_cons_columns;

               FETCH g_cur_unique_cons_columns
                  BULK COLLECT INTO g_tab_unique_cons_column_info
                  LIMIT c_bulk_collect_limit;

               CLOSE g_cur_unique_cons_columns;
            END fetch_unique_cons_columns;

            --
            PROCEDURE check_if_column_is_xml_type (i PLS_INTEGER)
            IS
            BEGIN
               -- check, if we have a xmltype column present in our list
               -- if so, we have to provide a XML compare function
               IF g_tab_column_info (i).data_type = 'XMLTYPE'
               THEN
                  g_xmltype_column_present := TRUE;
               END IF;
            END check_if_column_is_xml_type;

            --
            PROCEDURE calc_column_short_names (i PLS_INTEGER)
            IS
            BEGIN
               g_tab_column_info (i).column_name_26 :=
                  CASE
                     WHEN g_col_prefix_in_method_names
                     THEN
                        SUBSTR (g_tab_column_info (i).column_name, 1, 26)
                     ELSE
                        SUBSTR (
                           g_tab_column_info (i).column_name,
                             LENGTH (
                                g_tab_substitutions_array ('#COLUMN_PREFIX#'))
                           + 2,
                           26)
                  END;

               g_tab_column_info (i).column_name_28 :=
                  SUBSTR (g_tab_column_info (i).column_name, 1, 28);

               -- normalize column names by replacing
               -- all special characters with "_"
               g_tab_column_info (i).column_name_26 :=
                  util_get_normalized_identifier (
                     p_identifier   => g_tab_column_info (i).column_name_26);

               g_tab_column_info (i).column_name_28 :=
                  util_get_normalized_identifier (
                     p_identifier   => g_tab_column_info (i).column_name_28);
            END calc_column_short_names;

            --
            PROCEDURE column_list_w_pk (i PLS_INTEGER)
            IS
            BEGIN
               /* columns as flat list:
               #COLUMN_LIST_W_PK#
               e.g.
               col1
               , col2
               , col3
               , ... */
               g_tab_substitutions_array ('#COLUMN_LIST_W_PK#') :=
                     g_tab_substitutions_array ('#COLUMN_LIST_W_PK#')
                  || c_list_delimiter
                  || '"'
                  || g_tab_column_info (i).column_name
                  || '"';
            END column_list_w_pk;

            --
            PROCEDURE map_new_to_param_w_pk (i PLS_INTEGER)
            IS
            BEGIN
               /* map :new values to parameter for IOIUD-Trigger with PK:
               #MAP_NEW_TO_PARAM_W_PK#
               e.g. p_col1 => :new.col1
               , p_col2 => :new.col2
               , p_col3 => :new.col3
               , ... */
               g_tab_substitutions_array ('#MAP_NEW_TO_PARAM_W_PK#') :=
                     g_tab_substitutions_array ('#MAP_NEW_TO_PARAM_W_PK#')
                  || c_list_delimiter
                  || CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                           'p_' || g_tab_column_info (i).column_name_28
                        ELSE
                           g_tab_column_info (i).column_name
                     END
                  || ' => :new."'
                  || g_tab_column_info (i).column_name
                  || '"';
            END map_new_to_param_w_pk;

            --
            PROCEDURE map_param_to_param_w_pk (i PLS_INTEGER)
            IS
            BEGIN
               /* map parameter to parameter as pass-through parameter with PK:
               #MAP_PARAM_TO_PARAM_W_PK#
               e.g. p_col1 => p_col1
               , p_col2 => p_col2
               , p_col3 => p_col3
               , ... */
               g_tab_substitutions_array ('#MAP_PARAM_TO_PARAM_W_PK#') :=
                     g_tab_substitutions_array ('#MAP_PARAM_TO_PARAM_W_PK#')
                  || c_list_delimiter
                  || CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                           'p_' || g_tab_column_info (i).column_name_28
                        ELSE
                           g_tab_column_info (i).column_name
                     END
                  || ' => '
                  || CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                           'p_' || g_tab_column_info (i).column_name_28
                        ELSE
                           g_tab_column_info (i).column_name
                     END;
            END map_param_to_param_w_pk;

            --
            PROCEDURE map_rowtype_col_to_param_w_pk (i PLS_INTEGER)
            IS
            BEGIN
               /* map rowtype columns to parameter for rowtype handling with PK:
               #MAP_ROWTYPE_COL_TO_PARAM_W_PK#
               e.g. p_col1 => p_row.col1
               , p_col2 => p_row.col2
               , p_col3 => p_row.col3
               , ... */
               g_tab_substitutions_array ('#MAP_ROWTYPE_COL_TO_PARAM_W_PK#') :=
                     g_tab_substitutions_array (
                        '#MAP_ROWTYPE_COL_TO_PARAM_W_PK#')
                  || c_list_delimiter
                  || CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                           'p_' || g_tab_column_info (i).column_name_28
                        ELSE
                           g_tab_column_info (i).column_name
                     END
                  || ' => p_row."'
                  || g_tab_column_info (i).column_name
                  || '"';
            END map_rowtype_col_to_param_w_pk;

            --
            PROCEDURE param_definition_w_pk (i PLS_INTEGER)
            IS
            BEGIN
               /* columns as parameter definition for create_row, update_row with PK:
               #PARAM_DEFINITION_W_PK#
               e.g. p_col1 IN table.col1%TYPE
               , p_col2 IN table.col2%TYPE
               , p_col3 IN table.col3%TYPE
               , ... */
               g_tab_substitutions_array ('#PARAM_DEFINITION_W_PK#') :=
                     g_tab_substitutions_array ('#PARAM_DEFINITION_W_PK#')
                  || c_list_delimiter
                  || CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                           'p_' || g_tab_column_info (i).column_name_28
                        ELSE
                           g_tab_column_info (i).column_name
                     END
                  || ' IN '
                  || g_table_name
                  || '."'
                  || g_tab_column_info (i).column_name
                  || '"%TYPE'
                  || CASE
                        WHEN (g_tab_column_info (i).column_name =
                                 g_tab_substitutions_array ('#PK_COLUMN#'))
                        THEN
                           ' DEFAULT NULL'
                        ELSE
                           NULL
                     END;
            END param_definition_w_pk;

            --
            PROCEDURE param_io_definition_w_pk (i PLS_INTEGER)
            IS
            BEGIN
               /* columns as parameter IN OUT definition for get_row_by_pk_and_fill with PK:
               #PARAM_IO_DEFINITION_W_PK#
               e.g. p_col1 IN            table.col1%TYPE
               , p_col2 IN OUT NOCOPY table.col2%TYPE
               , p_col3 IN OUT NOCOPY table.col3%TYPE
               , ... */
               g_tab_substitutions_array ('#PARAM_IO_DEFINITION_W_PK#') :=
                     g_tab_substitutions_array ('#PARAM_IO_DEFINITION_W_PK#')
                  || c_list_delimiter
                  || CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                           'p_' || g_tab_column_info (i).column_name_28
                        ELSE
                           g_tab_column_info (i).column_name
                     END
                  || CASE
                        WHEN g_tab_column_info (i).column_name =
                                g_tab_substitutions_array ('#PK_COLUMN#')
                        THEN
                           ' IN '
                        ELSE
                           ' OUT NOCOPY '
                     END
                  || g_table_name
                  || '."'
                  || g_tab_column_info (i).column_name
                  || '"%TYPE';
            END param_io_definition_w_pk;

            --
            PROCEDURE param_list_wo_pk (i PLS_INTEGER)
            IS
            BEGIN
               /* columns as flat parameter list without PK e.g. col1 is PK:
               #PARAM_LIST_WO_PK#
               e.g. p_col2
               , p_col3
               , p_col4
               , ... */
               IF (g_tab_column_info (i).column_name <>
                      g_tab_substitutions_array ('#PK_COLUMN#'))
               THEN
                  g_tab_substitutions_array ('#PARAM_LIST_WO_PK#') :=
                        g_tab_substitutions_array ('#PARAM_LIST_WO_PK#')
                     || c_list_delimiter
                     || CASE
                           WHEN g_enable_parameter_prefixes
                           THEN
                              'p_' || g_tab_column_info (i).column_name_28
                           ELSE
                              g_tab_column_info (i).column_name
                        END;
               END IF;
            END param_list_wo_pk;

            --
            PROCEDURE set_param_to_column_wo_pk (i PLS_INTEGER)
            IS
            BEGIN
               /* a column list for updating a row without PK:
               #SET_PARAM_TO_COLUMN_WO_PK#
               e.g. test_number   = p_test_number
               , test_varchar2 = p_test_varchar2
               , ... */
               IF (g_tab_column_info (i).column_name <>
                      g_tab_substitutions_array ('#PK_COLUMN#'))
               THEN
                  g_tab_substitutions_array ('#SET_PARAM_TO_COLUMN_WO_PK#') :=
                        g_tab_substitutions_array (
                           '#SET_PARAM_TO_COLUMN_WO_PK#')
                     || c_list_delimiter
                     || '"'
                     || g_tab_column_info (i).column_name
                     || '"'
                     || ' = '
                     || CASE
                           WHEN g_enable_parameter_prefixes
                           THEN
                              'p_' || g_tab_column_info (i).column_name_28
                           ELSE
                              g_tab_column_info (i).column_name
                        END;
               END IF;
            END set_param_to_column_wo_pk;

            --
            PROCEDURE set_rowtype_col_to_param_wo_pk (i PLS_INTEGER)
            IS
            BEGIN
               /* a column list without pk for setting parameter to row columns:
               #SET_ROWTYPE_COL_TO_PARAM_WO_PK#
               e.g.
               p_test_number   := v_row.test_number;
               p_test_varchar2 := v_row.test_varchar2;
               , ... */
               IF (g_tab_column_info (i).column_name <>
                      g_tab_substitutions_array ('#PK_COLUMN#'))
               THEN
                  g_tab_substitutions_array (
                     '#SET_ROWTYPE_COL_TO_PARAM_WO_PK#') :=
                        g_tab_substitutions_array (
                           '#SET_ROWTYPE_COL_TO_PARAM_WO_PK#')
                     || CASE
                           WHEN g_enable_parameter_prefixes
                           THEN
                              'p_' || g_tab_column_info (i).column_name_28
                           ELSE
                              g_tab_column_info (i).column_name
                        END
                     || ' := v_row."'
                     || g_tab_column_info (i).column_name
                     || '"; ';
               END IF;
            END set_rowtype_col_to_param_wo_pk;

            --
            PROCEDURE column_compare_list_wo_pk (i PLS_INTEGER)
            IS
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
               IF (g_tab_column_info (i).column_name <>
                      g_tab_substitutions_array ('#PK_COLUMN#'))
               THEN
                  g_tab_substitutions_array ('#COLUMN_COMPARE_LIST_WO_PK#') :=
                        g_tab_substitutions_array (
                           '#COLUMN_COMPARE_LIST_WO_PK#')
                     || CASE
                           WHEN g_enable_generic_change_log THEN '      IF '
                           ELSE '      OR '
                        END
                     || util_get_attribute_compare (
                           p_data_type           => g_tab_column_info (i).data_type,
                           p_first_attribute     =>    'v_row."'
                                                    || g_tab_column_info (i).column_name
                                                    || '"',
                           p_second_attribute    => CASE
                                                      WHEN g_enable_parameter_prefixes
                                                      THEN
                                                            'p_'
                                                         || g_tab_column_info (
                                                               i).column_name_28
                                                      ELSE
                                                         g_tab_column_info (i).column_name
                                                   END,
                           p_compare_operation   => '<>')
                     || CASE
                           WHEN g_enable_generic_change_log
                           THEN
                                 ' THEN 
      v_count := v_count + 1;
      create_change_log_entry( p_table     => '''
                              || g_table_name
                              || '''
                             , p_column    => '''
                              || g_tab_column_info (i).column_name
                              || '''
                             , p_pk_id     => v_row."'
                              || g_tab_substitutions_array ('#PK_COLUMN#')
                              || '"
                             , p_old_value => '
                              || util_get_vc2_4000_operation (
                                    p_data_type        => g_tab_column_info (i).data_type,
                                    p_attribute_name   =>    'v_row."'
                                                          || g_tab_column_info (
                                                                i).column_name
                                                          || '"')
                              || '
                             , p_new_value => '
                              || util_get_vc2_4000_operation (
                                    p_data_type        => g_tab_column_info (i).data_type,
                                    p_attribute_name   => CASE
                                                            WHEN g_enable_parameter_prefixes
                                                            THEN
                                                                  'p_'
                                                               || g_tab_column_info (
                                                                     i).column_name_28
                                                            ELSE
                                                               g_tab_column_info (
                                                                  i).column_name
                                                         END)
                              || ' );
      END IF;'
                              || c_crlf
                           ELSE
                              c_crlf
                        END;
               END IF;
            END column_compare_list_wo_pk;

            --
            PROCEDURE cut_off_first_last_delimiter
            IS
            BEGIN
               -- cut off the first and/or last delimiter
               g_tab_substitutions_array ('#SET_PARAM_TO_COLUMN_WO_PK#') :=
                  LTRIM (
                     g_tab_substitutions_array (
                        '#SET_PARAM_TO_COLUMN_WO_PK#'),
                     c_list_delimiter);
               g_tab_substitutions_array ('#COLUMN_LIST_W_PK#') :=
                  LTRIM (g_tab_substitutions_array ('#COLUMN_LIST_W_PK#'),
                         c_list_delimiter);
               g_tab_substitutions_array ('#MAP_NEW_TO_PARAM_W_PK#') :=
                  LTRIM (
                     g_tab_substitutions_array ('#MAP_NEW_TO_PARAM_W_PK#'),
                     c_list_delimiter);
               g_tab_substitutions_array ('#MAP_PARAM_TO_PARAM_W_PK#') :=
                  LTRIM (
                     g_tab_substitutions_array ('#MAP_PARAM_TO_PARAM_W_PK#'),
                     c_list_delimiter);
               g_tab_substitutions_array ('#MAP_ROWTYPE_COL_TO_PARAM_W_PK#') :=
                  LTRIM (
                     g_tab_substitutions_array (
                        '#MAP_ROWTYPE_COL_TO_PARAM_W_PK#'),
                     c_list_delimiter);
               g_tab_substitutions_array ('#PARAM_DEFINITION_W_PK#') :=
                  LTRIM (
                     g_tab_substitutions_array ('#PARAM_DEFINITION_W_PK#'),
                     c_list_delimiter);
               g_tab_substitutions_array ('#PARAM_IO_DEFINITION_W_PK#') :=
                  LTRIM (
                     g_tab_substitutions_array ('#PARAM_IO_DEFINITION_W_PK#'),
                     c_list_delimiter);
               g_tab_substitutions_array ('#PARAM_LIST_WO_PK#') :=
                  LTRIM (g_tab_substitutions_array ('#PARAM_LIST_WO_PK#'),
                         c_list_delimiter);
               -- this has to be enhanced
               g_tab_substitutions_array ('#COLUMN_COMPARE_LIST_WO_PK#') :=
                     LTRIM (
                        LTRIM (
                           RTRIM (
                              g_tab_substitutions_array (
                                 '#COLUMN_COMPARE_LIST_WO_PK#'),
                              c_crlf),
                           '      IF '),
                        '      OR ')
                  || CASE
                        WHEN g_enable_generic_change_log
                        THEN
                           c_crlf || '      IF v_count > 0'
                        ELSE
                           NULL
                     END;
            END cut_off_first_last_delimiter;
         BEGIN
            init_substitutions;
            fetch_table_columns;
            fetch_unique_constraints;
            fetch_unique_cons_columns;

            FOR i IN g_tab_column_info.FIRST .. g_tab_column_info.LAST
            LOOP
               check_if_column_is_xml_type (i);
               calc_column_short_names (i);
               column_list_w_pk (i);
               map_new_to_param_w_pk (i);
               map_param_to_param_w_pk (i);
               map_rowtype_col_to_param_w_pk (i);
               param_definition_w_pk (i);
               param_io_definition_w_pk (i);
               param_list_wo_pk (i);
               set_param_to_column_wo_pk (i);
               set_rowtype_col_to_param_wo_pk (i);
               column_compare_list_wo_pk (i);
            END LOOP;

            cut_off_first_last_delimiter;

            -- this substitution depends on column list with pk and should
            -- normally located in set_substitutions_literal_base
            g_tab_substitutions_array ('#RETURN_VALUE#') :=
               CASE
                  WHEN g_return_row_instead_of_pk
                  THEN
                     g_tab_substitutions_array ('#COLUMN_LIST_W_PK#')
                  ELSE
                     '"' || g_tab_substitutions_array ('#PK_COLUMN#') || '"'
               END;
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
      PROCEDURE finalize
      IS
      BEGIN
         -- finalize CLOB varchar caches
         util_clob_append (
            p_clob                 => g_tapi_code_blocks.api_spec,
            p_clob_varchar_cache   => g_tapi_code_blocks.api_spec_varchar_cache,
            p_varchar_to_append    => NULL,
            p_final_call           => TRUE);
         util_clob_append (
            p_clob                 => g_tapi_code_blocks.api_body,
            p_clob_varchar_cache   => g_tapi_code_blocks.api_body_varchar_cache,
            p_varchar_to_append    => NULL,
            p_final_call           => TRUE);

         IF (g_enable_dml_view)
         THEN
            util_clob_append (
               p_clob                 => g_tapi_code_blocks.dml_view,
               p_clob_varchar_cache   => g_tapi_code_blocks.dml_view_varchar_cache,
               p_varchar_to_append    => NULL,
               p_final_call           => TRUE);
            util_clob_append (
               p_clob                 => g_tapi_code_blocks.dml_view_trigger,
               p_clob_varchar_cache   => g_tapi_code_blocks.dml_view_trigger_varchar_cache,
               p_varchar_to_append    => NULL,
               p_final_call           => TRUE);
         END IF;
      END finalize;
   --
   BEGIN
      initialize;
      gen_header;
      gen_row_exists_fnc;
      gen_row_exists_yn_fnc;
      gen_get_pk_by_unique_cols_fnc;

      --------------------------------------------------------------------------
      -- CREATE procedures / functions only if allowed
      --------------------------------------------------------------------------
      IF (g_enable_insertion_of_rows)
      THEN
         gen_create_row_fnc;
         gen_create_row_prc;
         gen_create_rowtype_fnc;
         gen_create_rowtype_prc;
      END IF;

      --------------------------------------------------------------------------
      -- READ procedures always
      --------------------------------------------------------------------------
      gen_read_row_fnc;
      gen_read_row_prc;
      gen_read_row_by_uk_fnc;
      gen_read_a_row_fnc;

      --------------------------------------------------------------------------
      -- UPDATE procedures / functions only if allowed
      --------------------------------------------------------------------------
      IF (g_enable_update_of_rows)
      THEN
         gen_update_row_prc;
         gen_update_rowtype_prc;
      END IF;

      --------------------------------------------------------------------------
      -- DELETE procedures only if allowed
      --------------------------------------------------------------------------
      IF (g_enable_deletion_of_rows)
      THEN
         gen_delete_row_prc;
      END IF;

      --------------------------------------------------------------------------
      -- CREATE or UPDATE procedures / functions only if both is allowed
      --------------------------------------------------------------------------
      IF (g_enable_insertion_of_rows AND g_enable_update_of_rows)
      THEN
         gen_createorupdate_row_fnc;
         gen_createorupdate_row_prc;
         gen_createorupdate_rowtype_fnc;
         gen_createorupdate_rowtype_prc;
      END IF;

      --------------------------------------------------------------------------
      -- GETTER procedures / functions always
      --------------------------------------------------------------------------
      IF g_enable_getter_and_setter
      THEN
         gen_getter_functions;
      END IF;

      --------------------------------------------------------------------------
      -- SETTER procedures / functions only if allowed
      --------------------------------------------------------------------------
      IF (g_enable_update_of_rows AND g_enable_getter_and_setter)
      THEN
         gen_setter_procedures;
      END IF;

      gen_footer;

      --------------------------------------------------------------------------
      -- DML View and Trigger only if allowed
      --------------------------------------------------------------------------
      IF (g_enable_dml_view)
      THEN
         gen_dml_view;
         gen_dml_view_trigger;
      END IF;

      finalize;
   END main_generate;

   -----------------------------------------------------------------------------
   PROCEDURE main_compile
   IS
   BEGIN
      -- compile package spec
      BEGIN
         util_execute_sql (g_tapi_code_blocks.api_spec);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      -- compile package body
      BEGIN
         util_execute_sql (g_tapi_code_blocks.api_body);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      -- compile DML view
      BEGIN
         util_execute_sql (g_tapi_code_blocks.dml_view);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      -- compile DML view trigger
      BEGIN
         util_execute_sql (g_tapi_code_blocks.dml_view_trigger);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END main_compile;

   -----------------------------------------------------------------------------
   FUNCTION main_return
      RETURN CLOB
   IS
      terminator   VARCHAR2 (10 CHAR) := c_crlf || '/' || c_crlflf;
   BEGIN
      RETURN    g_tapi_code_blocks.api_spec
             || terminator
             || g_tapi_code_blocks.api_body
             || terminator
             || CASE
                   WHEN g_enable_dml_view
                   THEN
                         g_tapi_code_blocks.dml_view
                      || terminator
                      || g_tapi_code_blocks.dml_view_trigger
                      || terminator
                   ELSE
                      NULL
                END;
   END main_return;

   -----------------------------------------------------------------------------
   PROCEDURE compile_api (
      p_table_name                   IN user_tables.table_name%TYPE,
      p_reuse_existing_api_params    IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params, -- if true, the following params are ignored, if API package are already
      -- existing and params are extractable from spec source line 1
      p_col_prefix_in_method_names   IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names,
      p_enable_insertion_of_rows     IN BOOLEAN DEFAULT om_tapigen.c_enable_insertion_of_rows,
      p_enable_update_of_rows        IN BOOLEAN DEFAULT om_tapigen.c_enable_update_of_rows,
      p_enable_deletion_of_rows      IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows,
      p_enable_generic_change_log    IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log,
      p_enable_dml_view              IN BOOLEAN DEFAULT om_tapigen.c_enable_dml_view,
      p_sequence_name                IN user_sequences.sequence_name%TYPE DEFAULT om_tapigen.c_sequence_name,
      p_api_name                     IN user_objects.object_name%TYPE DEFAULT om_tapigen.c_api_name,
      p_enable_getter_and_setter     IN BOOLEAN DEFAULT om_tapigen.c_enable_getter_and_setter,
      p_enable_parameter_prefixes    IN BOOLEAN DEFAULT om_tapigen.c_enable_parameter_prefixes,
      p_return_row_instead_of_pk     IN BOOLEAN DEFAULT om_tapigen.c_return_row_instead_of_pk,
      p_column_defaults              IN XMLTYPE DEFAULT om_tapigen.c_column_defaults)
   IS
   BEGIN
      main_generate (
         p_generator_action             => 'COMPILE_API',
         p_table_name                   => p_table_name,
         p_reuse_existing_api_params    => p_reuse_existing_api_params,
         p_col_prefix_in_method_names   => p_col_prefix_in_method_names,
         p_enable_insertion_of_rows     => p_enable_insertion_of_rows,
         p_enable_update_of_rows        => p_enable_update_of_rows,
         p_enable_deletion_of_rows      => p_enable_deletion_of_rows,
         p_enable_generic_change_log    => p_enable_generic_change_log,
         p_enable_dml_view              => p_enable_dml_view,
         p_sequence_name                => p_sequence_name,
         p_api_name                     => p_api_name,
         p_enable_getter_and_setter     => p_enable_getter_and_setter,
         p_enable_parameter_prefixes    => p_enable_parameter_prefixes,
         p_return_row_instead_of_pk     => p_return_row_instead_of_pk,
         p_column_defaults              => p_column_defaults);
      main_compile;
   END compile_api;

   -----------------------------------------------------------------------------
   FUNCTION compile_api_and_get_code (
      p_table_name                   IN user_tables.table_name%TYPE,
      p_reuse_existing_api_params    IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params, -- if true, the following params are ignored, if API package are already existing and params are extractable from spec
      p_col_prefix_in_method_names   IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names,
      p_enable_insertion_of_rows     IN BOOLEAN DEFAULT om_tapigen.c_enable_insertion_of_rows,
      p_enable_update_of_rows        IN BOOLEAN DEFAULT om_tapigen.c_enable_update_of_rows,
      p_enable_deletion_of_rows      IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows,
      p_enable_generic_change_log    IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log,
      p_enable_dml_view              IN BOOLEAN DEFAULT om_tapigen.c_enable_dml_view,
      p_sequence_name                IN user_sequences.sequence_name%TYPE DEFAULT om_tapigen.c_sequence_name,
      p_api_name                     IN user_objects.object_name%TYPE DEFAULT om_tapigen.c_api_name,
      p_enable_getter_and_setter     IN BOOLEAN DEFAULT om_tapigen.c_enable_getter_and_setter,
      p_enable_parameter_prefixes    IN BOOLEAN DEFAULT om_tapigen.c_enable_parameter_prefixes,
      p_return_row_instead_of_pk     IN BOOLEAN DEFAULT om_tapigen.c_return_row_instead_of_pk,
      p_column_defaults              IN XMLTYPE DEFAULT om_tapigen.c_column_defaults)
      RETURN CLOB
   IS
   BEGIN
      main_generate (
         p_generator_action             => 'COMPILE_API_AND_GET_CODE',
         p_table_name                   => p_table_name,
         p_reuse_existing_api_params    => p_reuse_existing_api_params,
         p_col_prefix_in_method_names   => p_col_prefix_in_method_names,
         p_enable_insertion_of_rows     => p_enable_insertion_of_rows,
         p_enable_update_of_rows        => p_enable_update_of_rows,
         p_enable_deletion_of_rows      => p_enable_deletion_of_rows,
         p_enable_generic_change_log    => p_enable_generic_change_log,
         p_enable_dml_view              => p_enable_dml_view,
         p_sequence_name                => p_sequence_name,
         p_api_name                     => p_api_name,
         p_enable_getter_and_setter     => p_enable_getter_and_setter,
         p_enable_parameter_prefixes    => p_enable_parameter_prefixes,
         p_return_row_instead_of_pk     => p_return_row_instead_of_pk,
         p_column_defaults              => p_column_defaults);
      main_compile;
      RETURN main_return;
   END compile_api_and_get_code;

   -----------------------------------------------------------------------------
   FUNCTION get_code (
      p_table_name                   IN user_tables.table_name%TYPE,
      p_reuse_existing_api_params    IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params, -- if true, the following params are ignored, if API package are already
      -- existing and params are extractable from spec source line 1
      p_col_prefix_in_method_names   IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names,
      p_enable_insertion_of_rows     IN BOOLEAN DEFAULT om_tapigen.c_enable_insertion_of_rows,
      p_enable_update_of_rows        IN BOOLEAN DEFAULT om_tapigen.c_enable_update_of_rows,
      p_enable_deletion_of_rows      IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows,
      p_enable_generic_change_log    IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log,
      p_enable_dml_view              IN BOOLEAN DEFAULT om_tapigen.c_enable_dml_view,
      p_sequence_name                IN user_sequences.sequence_name%TYPE DEFAULT om_tapigen.c_sequence_name,
      p_api_name                     IN user_objects.object_name%TYPE DEFAULT om_tapigen.c_api_name,
      p_enable_getter_and_setter     IN BOOLEAN DEFAULT om_tapigen.c_enable_getter_and_setter,
      p_enable_parameter_prefixes    IN BOOLEAN DEFAULT om_tapigen.c_enable_parameter_prefixes,
      p_return_row_instead_of_pk     IN BOOLEAN DEFAULT om_tapigen.c_return_row_instead_of_pk,
      p_column_defaults              IN XMLTYPE DEFAULT om_tapigen.c_column_defaults)
      RETURN CLOB
   IS
   BEGIN
      main_generate (
         p_generator_action             => 'GET_CODE',
         p_table_name                   => p_table_name,
         p_reuse_existing_api_params    => p_reuse_existing_api_params,
         p_col_prefix_in_method_names   => p_col_prefix_in_method_names,
         p_enable_insertion_of_rows     => p_enable_insertion_of_rows,
         p_enable_update_of_rows        => p_enable_update_of_rows,
         p_enable_deletion_of_rows      => p_enable_deletion_of_rows,
         p_enable_generic_change_log    => p_enable_generic_change_log,
         p_enable_dml_view              => p_enable_dml_view,
         p_sequence_name                => p_sequence_name,
         p_api_name                     => p_api_name,
         p_enable_getter_and_setter     => p_enable_getter_and_setter,
         p_enable_parameter_prefixes    => p_enable_parameter_prefixes,
         p_return_row_instead_of_pk     => p_return_row_instead_of_pk,
         p_column_defaults              => p_column_defaults);
      RETURN main_return;
   END get_code;

   -----------------------------------------------------------------------------
   PROCEDURE recreate_existing_apis
   IS
      v_apis   t_tab_existing_apis;
   BEGIN
      OPEN g_cur_existing_apis (NULL);

      FETCH g_cur_existing_apis
         BULK COLLECT INTO v_apis
         LIMIT c_bulk_collect_limit;

      CLOSE g_cur_existing_apis;

      IF v_apis.COUNT > 0
      THEN
         FOR i IN v_apis.FIRST .. v_apis.LAST
         LOOP
            compile_api (v_apis (i).p_table_name);
         END LOOP;
      END IF;
   END;

   -----------------------------------------------------------------------------
   FUNCTION view_existing_apis (
      p_table_name    user_tables.table_name%TYPE DEFAULT NULL)
      RETURN t_tab_existing_apis
      PIPELINED
   IS
      v_row   g_cur_existing_apis%ROWTYPE;
   BEGIN
      OPEN g_cur_existing_apis (p_table_name);

      LOOP
         FETCH g_cur_existing_apis INTO v_row;

         EXIT WHEN g_cur_existing_apis%NOTFOUND;

         -----------------------------------------------------------------------
         -- parameters could be null, if older om_tapigen versions where used
         -- for creating table APIs, so coalesce ensures parameter validity.
         -- If existing parameter is null, then default is taken.
         -----------------------------------------------------------------------
         v_row.p_reuse_existing_api_params :=
            COALESCE (v_row.p_reuse_existing_api_params,
                      util_bool_to_string (c_reuse_existing_api_params));

         v_row.p_col_prefix_in_method_names :=
            COALESCE (v_row.p_col_prefix_in_method_names,
                      util_bool_to_string (c_col_prefix_in_method_names));

         v_row.p_enable_insertion_of_rows :=
            COALESCE (v_row.p_enable_insertion_of_rows,
                      util_bool_to_string (c_enable_insertion_of_rows));

         v_row.p_enable_update_of_rows :=
            COALESCE (v_row.p_enable_update_of_rows,
                      util_bool_to_string (c_enable_update_of_rows));

         v_row.p_enable_deletion_of_rows :=
            COALESCE (v_row.p_enable_deletion_of_rows,
                      util_bool_to_string (c_enable_deletion_of_rows));

         v_row.p_enable_generic_change_log :=
            COALESCE (v_row.p_enable_generic_change_log,
                      util_bool_to_string (c_enable_generic_change_log));

         v_row.p_enable_dml_view :=
            COALESCE (v_row.p_enable_dml_view,
                      util_bool_to_string (c_enable_dml_view));

         v_row.p_enable_getter_and_setter :=
            COALESCE (v_row.p_enable_getter_and_setter,
                      util_bool_to_string (c_enable_getter_and_setter));

         v_row.p_enable_parameter_prefixes :=
            COALESCE (v_row.p_enable_parameter_prefixes,
                      util_bool_to_string (c_enable_parameter_prefixes));

         v_row.p_return_row_instead_of_pk :=
            COALESCE (v_row.p_return_row_instead_of_pk,
                      util_bool_to_string (c_return_row_instead_of_pk));

         IF p_table_name IS NOT NULL
         THEN
            IF v_row.table_name = p_table_name
            THEN
               PIPE ROW (v_row);
            END IF;
         ELSE
            PIPE ROW (v_row);
         END IF;
      END LOOP;

      CLOSE g_cur_existing_apis;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_row.errors :=
               'Incomplete resultset! This is the last correct proccessed row from the pipelined function. Did you change the params XML in one of the API packages? Original error message: '
            || c_crlflf
            || SQLERRM
            || c_crlflf
            || DBMS_UTILITY.format_error_backtrace;
         PIPE ROW (v_row);

         CLOSE g_cur_existing_apis;
   END view_existing_apis;

   -----------------------------------------------------------------------------
   FUNCTION view_naming_conflicts
      RETURN t_tab_naming_conflicts
      PIPELINED
   IS
   BEGIN
      FOR i IN g_cur_naming_conflicts
      LOOP
         PIPE ROW (i);
      END LOOP;
   END view_naming_conflicts;
-----------------------------------------------------------------------------
END om_tapigen;
/