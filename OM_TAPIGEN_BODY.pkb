CREATE OR REPLACE PACKAGE BODY om_tapigen
IS
   -----------------------------------------------------------------------------
   -- private global constants c_*
   -----------------------------------------------------------------------------
   c_generator_error_number        CONSTANT PLS_INTEGER := -20000;
   c_bulk_collect_limit            CONSTANT NUMBER := 10000;
   c_list_delimiter                CONSTANT VARCHAR2 (2 CHAR) := ', ';
   c_crlf                          CONSTANT VARCHAR2 (2 CHAR)
                                               := CHR (13) || CHR (10) ;
   c_crlflf                        CONSTANT VARCHAR2 (3 CHAR)
                                               := CHR (13) || CHR (10) || CHR (10) ;
   c_column_defaults_present_msg   CONSTANT VARCHAR2 (30)
      := 'SEE_END_OF_API_PACKAGE_SPEC' ;
   c_spec_options_min_line         CONSTANT NUMBER := 5;
   c_spec_options_max_line         CONSTANT NUMBER := 35;

   -----------------------------------------------------------------------------
   -- private global variables g_*
   -----------------------------------------------------------------------------
   g_table_name                             user_tables.table_name%TYPE;
   g_multi_column_pk_present                BOOLEAN;
   g_pk_column                              USER_TAB_COLUMNS.COLUMN_NAME%TYPE;
   g_column_prefix                          USER_TAB_COLUMNS.COLUMN_NAME%TYPE;
   g_reuse_existing_api_params              BOOLEAN;
   g_col_prefix_in_method_names             BOOLEAN;
   g_enable_insertion_of_rows               BOOLEAN;
   g_enable_update_of_rows                  BOOLEAN;
   g_enable_deletion_of_rows                BOOLEAN;
   g_enable_generic_change_log              BOOLEAN;
   g_enable_dml_view                        BOOLEAN;
   g_sequence_name                          user_sequences.sequence_name%TYPE;
   g_api_name                               user_objects.object_name%TYPE;
   g_enable_getter_and_setter               BOOLEAN;
   g_enable_proc_with_out_params            BOOLEAN;
   g_enable_parameter_prefixes              BOOLEAN;
   g_return_row_instead_of_pk               BOOLEAN;
   g_column_defaults                        XMLTYPE;
   g_column_defaults_serialized             VARCHAR2 (32767 CHAR);
   g_owner                                  ALL_USERS.username%TYPE;

   g_xmltype_column_present                 BOOLEAN;

   -----------------------------------------------------------------------------
   -- private types t_*, subtypes st_* and collections tab_*
   -----------------------------------------------------------------------------
   TYPE t_column_info IS RECORD
   (
      column_name      user_tab_columns.column_name%TYPE,
      column_name_26   user_tab_columns.column_name%TYPE,
      column_name_28   user_tab_columns.column_name%TYPE,
      data_type        user_tab_cols.data_type%TYPE,
      data_default     VARCHAR2 (4000)
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

   g_columns                                t_tab_column_info;
   g_unique_constraints                     t_tab_unique_constraint_info;
   g_unique_cons_columns                    t_tab_unique_cons_column_info;
   g_substitutions                          t_tab_substitutions_array;
   g_code_blocks                            t_tapi_code_blocks;
   g_params_existing_api                    g_row_existing_apis;

   -----------------------------------------------------------------------------
   -- private global cursors g_cur_*
   -----------------------------------------------------------------------------

   CURSOR g_cur_columns
   IS
        SELECT column_name AS column_name,
               NULL AS column_name_26,
               NULL AS column_name_28,
               data_type,
               CASE
                  WHEN data_default IS NOT NULL
                  THEN
                     (SELECT util_get_column_data_default (
                                p_owner         => g_owner,
                                P_TABLE_NAME    => table_name,
                                P_COLUMN_NAME   => column_name)
                        FROM DUAL)
                  ELSE
                     NULL
               END
                  AS data_default
          FROM all_tab_cols
         WHERE     owner = g_owner
               AND table_name = g_table_name
               AND hidden_column = 'NO'
      ORDER BY column_id;

   CURSOR g_cur_unique_constraints
   IS
        SELECT constraint_name
          FROM all_constraints
         WHERE     owner = g_owner
               AND table_name = g_table_name
               AND constraint_type = 'U'
      ORDER BY constraint_name;

   CURSOR g_cur_unique_cons_columns
   IS
        SELECT acc.constraint_name,
               acc.column_name AS column_name,
               NULL AS column_name_28,
               atc.data_type
          FROM all_constraints ac
               JOIN all_cons_columns acc
                  ON     ac.owner = acc.owner
                     AND ac.constraint_name = acc.constraint_name
               JOIN all_tab_columns atc
                  ON     acc.owner = atc.owner
                     AND acc.table_name = atc.table_name
                     AND acc.column_name = atc.column_name
         WHERE     ac.owner = g_owner
               AND ac.table_name = g_table_name
               AND ac.constraint_type = 'U'
      ORDER BY ac.constraint_name, acc.position;

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
            REGEXP_INSTR (g_code_blocks.template, v_pattern, v_start_pos);
      END get_match_pos;

      PROCEDURE code_append (p_code_snippet VARCHAR2)
      IS
      BEGIN
         IF p_scope = 'API SPEC'
         THEN
            util_clob_append (g_code_blocks.api_spec,
                              g_code_blocks.api_spec_varchar_cache,
                              p_code_snippet);
         ELSIF p_scope = 'API BODY'
         THEN
            util_clob_append (g_code_blocks.api_body,
                              g_code_blocks.api_body_varchar_cache,
                              p_code_snippet);
         ELSIF p_scope = 'VIEW'
         THEN
            util_clob_append (g_code_blocks.dml_view,
                              g_code_blocks.dml_view_varchar_cache,
                              p_code_snippet);
         ELSIF p_scope = 'TRIGGER'
         THEN
            util_clob_append (g_code_blocks.dml_view_trigger,
                              g_code_blocks.dml_view_trigger_varchar_cache,
                              p_code_snippet);
         END IF;
      END code_append;
   BEGIN
      v_tpl_len := LENGTH (g_code_blocks.template);
      get_match_pos;

      WHILE v_start_pos < v_tpl_len
      LOOP
         get_match_pos;

         IF v_match_pos > 0
         THEN
            v_match_len :=
                 INSTR (g_code_blocks.template,
                        '#',
                        v_match_pos,
                        2)
               - v_match_pos;
            v_match :=
               SUBSTR (g_code_blocks.template, v_match_pos, v_match_len + 1);
            -- (1) process text before the match
            code_append (
               SUBSTR (g_code_blocks.template,
                       v_start_pos,
                       v_match_pos - v_start_pos));

            -- (2) process the match
            BEGIN
               code_append (g_substitutions (v_match)); -- this could be a problem, if not initialized
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
            code_append (SUBSTR (g_code_blocks.template, v_start_pos));
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
                        FROM all_constraints
                       WHERE     owner = g_owner
                             AND table_name = p_table_name
                             AND constraint_type = p_key_type),
                  cols
                  AS (SELECT constraint_name, column_name, position
                        FROM all_cons_columns
                       WHERE owner = g_owner AND table_name = p_table_name)
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
               FROM all_tab_cols
              WHERE     owner = g_owner
                    AND table_name = p_table_name
                    AND hidden_column = 'NO')
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
      p_data_type        IN all_tab_cols.data_type%TYPE,
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
               || q'[, 'yyyy.mm.dd hh24:mi:ss.ff')]'
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
      RETURN all_users.username%TYPE
   IS
      v_return   all_users.username%TYPE;
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
      v_return           all_objects.object_name%TYPE;
      v_base_name        all_objects.object_name%TYPE;
      v_replace_string   all_objects.object_name%TYPE;
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
                        WHEN 'TABLE_NAME' THEN g_table_name
                        WHEN 'PK_COLUMN' THEN g_PK_COLUMN
                        WHEN 'COLUMN_PREFIX' THEN g_COLUMN_PREFIX
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
   FUNCTION util_get_spec_column_defaults (p_api_name VARCHAR2)
      RETURN XMLTYPE
   IS
      v_return      VARCHAR2 (32767);
      v_xml_begin   VARCHAR2 (20) := '<defaults>';
      v_xml_end     VARCHAR2 (20) := '</defaults>';
   BEGIN
      FOR i
         IN (SELECT text
               FROM all_source
              WHERE     owner = g_owner
                    AND name = p_api_name
                    AND TYPE = 'PACKAGE'
                    AND line >=
                           (SELECT MIN (line) AS line
                              FROM all_source
                             WHERE     owner = g_owner
                                   AND name = p_api_name
                                   AND TYPE = 'PACKAGE'
                                   AND INSTR (TEXT, v_xml_begin) > 0))
      LOOP
         v_return := v_return || REGEXP_REPLACE (i.text, '^   \* ');
         EXIT WHEN INSTR (i.text, v_xml_end) > 0;
      END LOOP;

      RETURN CASE WHEN v_return IS NULL THEN NULL ELSE xmltype (v_return) END;
   END util_get_spec_column_defaults;

   -----------------------------------------------------------------------------
   FUNCTION util_get_column_data_default (
      p_table_name    IN VARCHAR2,
      p_column_name   IN VARCHAR2,
      p_owner            VARCHAR2 DEFAULT USER)
      RETURN VARCHAR2
   AS
      v_return   LONG;

      CURSOR c_utc
      IS
         SELECT data_default
           FROM all_tab_columns
          WHERE     owner = p_owner
                AND table_name = p_table_name
                AND column_name = p_column_name;
   BEGIN
      OPEN c_utc;

      FETCH c_utc INTO v_return;

      CLOSE c_utc;

      RETURN SUBSTR (v_return, 1, 4000);
   END;

   --------------------------------------------------------------------------------
   FUNCTION util_get_cons_search_condition (
      p_constraint_name   IN VARCHAR2,
      p_owner             IN VARCHAR2 DEFAULT USER)
      RETURN VARCHAR2
   AS
      v_return   LONG;

      CURSOR c_search_condition
      IS
         SELECT search_condition
           FROM all_constraints
          WHERE owner = p_owner AND constraint_name = p_constraint_name;
   BEGIN
      OPEN c_search_condition;

      FETCH c_search_condition INTO v_return;

      CLOSE c_search_condition;

      RETURN SUBSTR (v_return, 1, 4000);
   END;

   --------------------------------------------------------------------------------
   FUNCTION util_table_row_to_xml (p_table_name    VARCHAR2,
                                   p_owner         VARCHAR2 DEFAULT USER)
      RETURN XMLTYPE
   IS
      v_return   XMLTYPE;
      v_code     VARCHAR2 (32767);
   BEGIN
      v_code :=
            'DECLARE
  v_row    '
         || p_table_name
         || '%ROWTYPE;
  CURSOR v_cur IS SELECT * FROM '
         || p_table_name
         || ';
BEGIN
  OPEN v_cur;
  FETCH v_cur INTO v_row;
  CLOSE v_cur;
  WITH t AS (';

      FOR i IN (  SELECT column_name, data_type
                    FROM all_tab_columns
                   WHERE owner = p_owner AND table_name = p_table_name
                ORDER BY column_id)
      LOOP
         v_code :=
               v_code
            || CHR (10)
            || q'[SELECT ']'
            || i.column_name
            || q'[' AS c, CASE WHEN v_row."]'
            || i.column_name
            || '" IS NOT NULL THEN '
            || CASE
                  WHEN i.data_type IN ('NUMBER', 'INTEGER', 'FLOAT')
                  THEN
                     q'[ to_char(v_row."]' || i.column_name || q'[") ]'
                  WHEN i.data_type LIKE '%CHAR%'
                  THEN
                        q'[ q'{'}' || v_row."]'
                     || i.column_name
                     || q'[" || q'{'}' ]'
                  WHEN i.data_type = 'DATE'
                  THEN
                        q'[ q'{to_date('}' || to_char(v_row."]'
                     || i.column_name
                     || q'[",'yyyy-mm-dd hh24:mi:ss') || q'{','yyyy-mm-dd hh24:mi:ss')}' ]'
                  WHEN i.data_type LIKE 'TIMESTAMP%'
                  THEN
                        q'[ q'{to_timestamp('}' || to_char(v_row."]'
                     || i.column_name
                     || q'[",'yyyy-mm-dd hh24:mi:ss.ff') || q'{','yyyy.mm.dd hh24:mi:ss.ff')}' ]'
                  WHEN i.data_type = 'CLOB'
                  THEN
                     q'[ q'{to_clob('Dummy clob for API method get_a_row.')}' ]'
                  WHEN i.data_type = 'BLOB'
                  THEN
                     q'[ q'{to_blob(utl_raw.cast_to_raw('Dummy blob for API method get_a_row.'))}' ]'
                  WHEN i.data_type = 'XMLTYPE'
                  THEN
                     q'[ q'{XMLTYPE('<dummy>Dummy XML for API method get_a_row.</dummy>')}' ]'
                  ELSE
                     q'[ q'{'unsupported data type'}' ]'
               END
            || q'[ ELSE NULL END AS v FROM DUAL UNION ALL]';
      END LOOP;

      v_code :=
            REGEXP_REPLACE (v_code, 'UNION ALL$')
         || CHR (10)
         || q'[  )
  SELECT XMLELEMENT("rowset", XMLAGG(XMLELEMENT("row", XMLELEMENT("col", c), XMLELEMENT("val", v))))
    INTO :out
    FROM t;
END;]';

      --DBMS_OUTPUT.PUT_LINE (v_code);
      EXECUTE IMMEDIATE v_code USING OUT v_return;

      RETURN v_return;
   END;

   -----------------------------------------------------------------------------
   FUNCTION util_get_custom_col_defaults (
      p_table_name    VARCHAR2,
      p_owner         VARCHAR2 DEFAULT USER)
      RETURN XMLTYPE
   IS
      v_return   XMLTYPE;
   BEGIN
      -- I was not able to compile without execute immediate - got a strange ORA-03113.
      -- Direct execution of the statement in SQL tool works :-(
      EXECUTE IMMEDIATE
         q'[
WITH cons
     AS (SELECT owner,
                constraint_name,
                constraint_type,
                TABLE_NAME,
                CASE
                   WHEN search_condition IS NOT NULL
                   THEN
                      (SELECT om_tapigen.util_get_cons_search_condition (
                                 p_owner             => :owner,
                                 p_constraint_name   => constraint_name)
                         FROM DUAL)
                END
                   AS search_condition,
                r_owner,
                r_constraint_name,
                delete_rule,
                STATUS
           FROM all_constraints
          WHERE owner = :owner AND TABLE_NAME = :table_name),
     con_cols
     AS (SELECT owner,
                constraint_name,
                TABLE_NAME,
                column_name,
                POSITION
           FROM all_cons_columns
          WHERE        owner = :owner
                   AND constraint_name IN (SELECT constraint_name FROM cons)
                OR constraint_name IN (SELECT r_constraint_name
                                         FROM cons
                                        WHERE r_constraint_name IS NOT NULL)),
     con_nn
     AS ( --> because of primary keys and not null check constraints we have to select distinct here
         SELECT DISTINCT table_name, column_name, 'N' AS nullable_table_level
           FROM con_cols
          WHERE constraint_name IN (SELECT constraint_name
                                      FROM cons
                                     WHERE     status = 'ENABLED'
                                           AND (   constraint_type = 'P'
                                                OR     constraint_type = 'C'
                                                   AND REGEXP_COUNT (
                                                          TRIM (
                                                             search_condition),
                                                             '^"{0,1}'
                                                          || column_name
                                                          || '"{0,1}\s+is\s+not\s+null$',
                                                          1,
                                                          'i') = 1))),
     con_pk
     AS (SELECT table_name, column_name, 'Y' AS is_pk
           FROM con_cols
          WHERE constraint_name IN (SELECT constraint_name
                                      FROM cons
                                     WHERE     status = 'ENABLED'
                                           AND constraint_type = 'P')),
     con_uq
     AS (SELECT table_name, column_name, 'Y' AS has_to_be_unique
           FROM con_cols
          WHERE constraint_name IN (SELECT constraint_name
                                      FROM cons
                                     WHERE     status = 'ENABLED'
                                           AND constraint_type = 'U')),
     con_fk
     AS (SELECT fk_source.table_name,
                fk_source.column_name,
                cons.r_owner AS fk_owner,
                fk_target.table_name AS fk_table_name,
                fk_target.column_name AS fk_column_name
           FROM cons
                JOIN con_cols fk_source
                   ON cons.constraint_name = fk_source.constraint_name
                JOIN con_cols fk_target
                   ON cons.r_constraint_name = fk_target.constraint_name
          WHERE status = 'ENABLED' AND constraint_type = 'R'),
     tab_data
     AS (         SELECT x.column_name, x.data_random_row
                    FROM XMLTABLE (
                            '/rowset/row'
                            PASSING OM_TAPIGEN.util_table_row_to_xml (
                                       p_table_name   => :table_name,
                                       p_owner        => :owner)
                            COLUMNS column_name VARCHAR2 (128) PATH './col',
                                    data_random_row VARCHAR2 (4000) PATH './val') x),
     tab_cols
     AS (  SELECT t.table_name,
                  t.column_id,
                  t.column_name,
                  t.char_length,
                  t.data_type,
                  t.data_length,
                  t.data_precision,
                  t.data_scale,
                  CASE
                     WHEN data_default IS NOT NULL
                     THEN
                        (SELECT om_tapigen.util_get_column_data_default (
                                   p_owner         => :owner,
                                   p_table_name    => t.table_name,
                                   p_column_name   => t.column_name)
                           FROM DUAL)
                  END
                     AS data_default,
                  d.data_random_row,
                  --> Dictionary does not recognize table level not null constraints
                  t.nullable AS nullable_column_level,
                  NVL (n.nullable_table_level, 'Y') AS nullable_table_level,
                  NVL (p.is_pk, 'N') AS is_pk,
                  NVL (u.has_to_be_unique, 'N') AS has_to_be_unique,
                  f.fk_owner,
                  f.fk_table_name,
                  f.fk_column_name
             FROM all_tab_columns T
                  LEFT JOIN con_nn n
                     ON     t.table_name = n.table_name
                        AND t.column_name = n.column_name
                  LEFT JOIN con_pk p
                     ON     t.table_name = p.table_name
                        AND t.column_name = p.column_name
                  LEFT JOIN con_uq u
                     ON     t.table_name = u.table_name
                        AND t.column_name = u.column_name
                  LEFT JOIN con_fk f
                     ON     t.table_name = f.table_name
                        AND t.column_name = f.column_name
                  LEFT JOIN tab_data d ON t.column_name = d.column_name
            WHERE T.OWNER = :owner AND t.table_name = :table_name
         ORDER BY COLUMN_ID)                        -- SELECT * FROM tab_cols;
                            ,
     result
     AS (SELECT column_name,
                CASE
                   WHEN is_pk = 'Y'
                   THEN
                      NULL
                   WHEN data_random_row IS NOT NULL
                   THEN
                      CASE
                         WHEN has_to_be_unique = 'N'
                         THEN
                            data_random_row
                         ELSE
                            CASE
                               WHEN data_type IN ('NUMBER',
                                                  'INTEGER',
                                                  'FLOAT')
                               THEN
                                  q'{to_char(systimestamp,'yyyymmddhh24missff')}'
                               WHEN data_type LIKE '%CHAR%'
                               THEN
                                     'SUBSTR (SYS_GUID (), 1, '
                                  || char_length
                                  || ')'
                               WHEN data_type = 'CLOB'
                               THEN
                                  q'{to_clob('Dummy clob for API method get_a_row: ' || sys_guid())}'
                               WHEN data_type = 'BLOB'
                               THEN
                                  q'{to_blob(utl_raw.cast_to_raw('Dummy clob for API method get_a_row: ' || sys_guid()))}'
                               WHEN data_type = 'XMLTYPE'
                               THEN
                                  q'{XMLTYPE('<dummy>Dummy XML for API method get_a_row: ' || sys_guid() || '</dummy>')}'
                               ELSE
                                  NULL
                            END
                      END
                END
                   AS data_default
           FROM tab_cols)                              --select * from result;
SELECT XMLELEMENT (
          "defaults",
          XMLAGG (
             XMLELEMENT ("item",
                         XMLELEMENT ("col", column_name),
                         XMLELEMENT ("val", data_default))))
  FROM result
 WHERE data_default IS NOT NULL
        ]'
         INTO v_return
         USING p_owner,
               p_owner,
               p_table_name,
               p_owner,
               p_table_name,
               p_owner,
               p_owner,
               p_owner,
               p_table_name;

      --SELECT XMLSERIALIZE (
      --          DOCUMENT XMLELEMENT (
      --                      "defaults",
      --                      XMLAGG (
      --                         XMLELEMENT ("item",
      --                                     XMLELEMENT ("col", column_name),
      --                                     XMLELEMENT ("val", data_default))))
      --          INDENT)
      --  FROM defaults
      -- WHERE data_default IS NOT NULL;


      RETURN v_return;
   END;

   -----------------------------------------------------------------------------
   PROCEDURE gen_header
   IS
   BEGIN
      g_code_blocks.template :=
         '
CREATE OR REPLACE PACKAGE "#OWNER#"."#API_NAME#" IS
  /**
   * This is the API for the table "#TABLE_NAME#".
   *
   * GENERATION OPTIONS
   * - must be in the lines #SPEC_OPTIONS_MIN_LINE#-#SPEC_OPTIONS_MAX_LINE# to be reusable by the generator
   * - DO NOT TOUCH THIS until you know what you do - read the
   *   docs under github.com/OraMUC/table-api-generator ;-)
   * <options
   *   generator="#GENERATOR#"
   *   generator_version="#GENERATOR_VERSION#"
   *   generator_action="#GENERATOR_ACTION#"
   *   generated_at="#GENERATED_AT#"
   *   generated_by="#GENERATED_BY#"
   *   p_owner="#OWNER#"
   *   p_table_name="#TABLE_NAME#"
   *   p_reuse_existing_api_params="#REUSE_EXISTING_API_PARAMS#"
   *   p_enable_insertion_of_rows="#ENABLE_INSERTION_OF_ROWS#"
   *   p_enable_update_of_rows="#ENABLE_UPDATE_OF_ROWS#"
   *   p_enable_deletion_of_rows="#ENABLE_DELETION_OF_ROWS#"
   *   p_enable_parameter_prefixes="#ENABLE_PARAMETER_PREFIXES#"
   *   p_enable_proc_with_out_params="#ENABLE_PROC_WITH_OUT_PARAMS#"
   *   p_enable_getter_and_setter="#ENABLE_GETTER_AND_SETTER#"
   *   p_col_prefix_in_method_names="#COL_PREFIX_IN_METHOD_NAMES#"
   *   p_return_row_instead_of_pk="#RETURN_ROW_INSTEAD_OF_PK#"
   *   p_enable_dml_view="#ENABLE_DML_VIEW#"
   *   p_enable_generic_change_log="#ENABLE_GENERIC_CHANGE_LOG#"
   *   p_api_name="#API_NAME#"
   *   p_sequence_name="#SEQUENCE_NAME#"
   *   p_column_defaults="#COLUMN_DEFAULTS#"/>
   *
   * This API provides DML functionality that can be easily called from APEX.
   * Target of the table API is to encapsulate the table DML source code for
   * security (UI schema needs only the execute right for the API and the
   * read/write right for the #TABLE_NAME_24#_DML_V, tables can be hidden in
   * extra data schema) and easy readability of the business logic (all DML is
   * then written in the same style). For APEX automatic row processing like
   * tabular forms you can optionally use the #TABLE_NAME_24#_DML_V, which has
   * an instead of trigger who is also calling the #TABLE_NAME_26#_API.
   */
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
            '
CREATE OR REPLACE PACKAGE BODY "#OWNER#"."#API_NAME#" IS
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
      g_code_blocks.template :=
         '
  FUNCTION row_exists( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE )
  RETURN BOOLEAN;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
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
      g_code_blocks.template :=
         '
  FUNCTION row_exists_yn( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE )
  RETURN VARCHAR2;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
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
      IF g_unique_constraints.COUNT > 0
      THEN
         FOR i IN g_unique_constraints.FIRST .. g_unique_constraints.LAST
         LOOP
            g_substitutions ('#PARAM_LIST_UNIQUE#') := NULL;
            g_substitutions ('#COLUMN_COMPARE_LIST_UNIQUE#') := NULL;

            FOR j IN g_unique_cons_columns.FIRST ..
                     g_unique_cons_columns.LAST
            LOOP
               IF g_unique_cons_columns (j).constraint_name =
                     g_unique_constraints (i).constraint_name
               THEN
                  g_unique_cons_columns (j).parameter_name :=
                     CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                              'p_'
                           || SUBSTR (g_unique_cons_columns (j).column_name,
                                      1,
                                      28)
                        ELSE
                           g_unique_cons_columns (j).column_name
                     END;
                  g_substitutions ('#PARAM_LIST_UNIQUE#') :=
                        g_substitutions ('#PARAM_LIST_UNIQUE#')
                     || c_list_delimiter
                     || CASE
                           WHEN g_enable_parameter_prefixes
                           THEN
                              g_unique_cons_columns (j).parameter_name
                           ELSE
                              g_unique_cons_columns (j).parameter_name
                        END
                     || ' '
                     || g_table_name
                     || '."'
                     || g_unique_cons_columns (j).column_name
                     || '"%TYPE';
                  g_substitutions ('#COLUMN_COMPARE_LIST_UNIQUE#') :=
                        g_substitutions ('#COLUMN_COMPARE_LIST_UNIQUE#')
                     || '         AND '
                     || util_get_attribute_compare (
                           p_data_type           => g_unique_cons_columns (j).data_type,
                           p_first_attribute     =>    '"'
                                                    || g_unique_cons_columns (j).column_name
                                                    || '"',
                           p_second_attribute    => g_unique_cons_columns (j).parameter_name,
                           p_compare_operation   => '=')
                     || c_crlf;
               END IF;
            END LOOP;

            g_substitutions ('#PARAM_LIST_UNIQUE#') :=
               LTRIM (g_substitutions ('#PARAM_LIST_UNIQUE#'),
                      c_list_delimiter);
            g_substitutions ('#COLUMN_COMPARE_LIST_UNIQUE#') :=
               RTRIM (
                  LTRIM (g_substitutions ('#COLUMN_COMPARE_LIST_UNIQUE#'),
                         '         AND '),
                  c_crlf);
            g_code_blocks.template :=
               '
  FUNCTION get_pk_by_unique_cols( #PARAM_LIST_UNIQUE# )
  RETURN #TABLE_NAME#."#PK_COLUMN#"%TYPE;
  ----------------------------------------';
            util_template_replace ('API SPEC');
            ----------------------------------------
            g_code_blocks.template :=
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
   PROCEDURE gen_get_a_row_fnc
   IS
   BEGIN
      g_code_blocks.template := '
  FUNCTION get_a_row
  RETURN #TABLE_NAME#%ROWTYPE;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template := '
  FUNCTION get_a_row
  RETURN #TABLE_NAME#%ROWTYPE IS
    v_row #TABLE_NAME#%ROWTYPE;
  BEGIN
    #COLUMN_DEFAULTS_LIST#
    return v_row;
  END get_a_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_get_a_row_fnc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_create_row_fnc
   IS
   BEGIN
      g_code_blocks.template :=
         '
  FUNCTION create_row( #PARAM_DEFINITION_W_PK# )
  RETURN #RETURN_TYPE#;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
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
      RETURN #RETURN_VALUE#
        INTO v_return;'
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
      g_code_blocks.template :=
         '
  PROCEDURE create_row( #PARAM_DEFINITION_W_PK# );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
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
      g_code_blocks.template :=
         '
  FUNCTION create_row( p_row IN #TABLE_NAME#%ROWTYPE )
  RETURN #RETURN_TYPE#;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
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
      g_code_blocks.template :=
         '
  PROCEDURE create_row( p_row IN #TABLE_NAME#%ROWTYPE );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
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
   PROCEDURE gen_create_a_row_fnc
   IS
   BEGIN
      g_code_blocks.template :=
         '
  FUNCTION create_a_row( #PARAM_DEF_W_PK_AND_DEFAULTS# )
  RETURN #RETURN_TYPE#;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
         '
  FUNCTION create_a_row( #PARAM_DEF_W_PK_AND_DEFAULTS# )
  RETURN #RETURN_TYPE# IS
    v_return #RETURN_TYPE#;
  BEGIN
    v_return := create_row( #MAP_PARAM_TO_PARAM_W_PK# );
    RETURN v_return;
  END create_a_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_create_a_row_fnc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_create_a_row_prc
   IS
   BEGIN
      g_code_blocks.template :=
         '
  PROCEDURE create_a_row( #PARAM_DEF_W_PK_AND_DEFAULTS# );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
         '
  PROCEDURE create_a_row( #PARAM_DEF_W_PK_AND_DEFAULTS# )
  IS
    v_return #RETURN_TYPE#;
  BEGIN
    v_return := create_row( #MAP_PARAM_TO_PARAM_W_PK# );
  END create_a_row;
  ----------------------------------------';
      util_template_replace ('API BODY');
   END gen_create_a_row_prc;

   -----------------------------------------------------------------------------
   PROCEDURE gen_createorupdate_row_fnc
   IS
   BEGIN
      g_code_blocks.template :=
         '
  FUNCTION create_or_update_row( #PARAM_DEFINITION_W_PK# )
  RETURN #RETURN_TYPE#;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
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
      g_code_blocks.template :=
         '
  PROCEDURE create_or_update_row( #PARAM_DEFINITION_W_PK# );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
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
      g_code_blocks.template :=
         '
  FUNCTION create_or_update_row( p_row IN #TABLE_NAME#%ROWTYPE )
  RETURN #RETURN_TYPE#;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
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
      g_code_blocks.template :=
         '
  PROCEDURE create_or_update_row( p_row IN #TABLE_NAME#%ROWTYPE );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
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
      g_code_blocks.template :=
         '
  FUNCTION read_row( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE )
  RETURN #TABLE_NAME#%ROWTYPE;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
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
      g_code_blocks.template :=
         '
  PROCEDURE read_row( #PARAM_IO_DEFINITION_W_PK# );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
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
      IF g_unique_constraints.COUNT > 0
      THEN
         FOR i IN g_unique_constraints.FIRST .. g_unique_constraints.LAST
         LOOP
            g_substitutions ('#PARAM_LIST_UNIQUE#') := NULL;
            g_substitutions ('#COLUMN_COMPARE_LIST_UNIQUE#') := NULL;
            g_substitutions ('#PARAM_CALLING_LIST_UNIQUE#') := NULL;

            FOR j IN g_unique_cons_columns.FIRST ..
                     g_unique_cons_columns.LAST
            LOOP
               IF g_unique_cons_columns (j).constraint_name =
                     g_unique_constraints (i).constraint_name
               THEN
                  g_unique_cons_columns (j).parameter_name :=
                     CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                              'p_'
                           || SUBSTR (g_unique_cons_columns (j).column_name,
                                      1,
                                      28)
                        ELSE
                           g_unique_cons_columns (j).column_name
                     END;
                  g_substitutions ('#PARAM_LIST_UNIQUE#') :=
                        g_substitutions ('#PARAM_LIST_UNIQUE#')
                     || c_list_delimiter
                     || g_unique_cons_columns (j).parameter_name
                     || ' '
                     || g_table_name
                     || '."'
                     || g_unique_cons_columns (j).column_name
                     || '"%TYPE';
                  g_substitutions ('#PARAM_CALLING_LIST_UNIQUE#') :=
                        g_substitutions ('#PARAM_CALLING_LIST_UNIQUE#')
                     || c_list_delimiter
                     || g_unique_cons_columns (j).parameter_name
                     || ' => '
                     || g_unique_cons_columns (j).parameter_name;
                  g_substitutions ('#COLUMN_COMPARE_LIST_UNIQUE#') :=
                        g_substitutions ('#COLUMN_COMPARE_LIST_UNIQUE#')
                     || '         AND '
                     || util_get_attribute_compare (
                           p_data_type           => g_unique_cons_columns (j).data_type,
                           p_first_attribute     =>    '"'
                                                    || g_unique_cons_columns (j).column_name
                                                    || '"',
                           p_second_attribute    => g_unique_cons_columns (j).parameter_name,
                           p_compare_operation   => '=')
                     || c_crlf;
               END IF;
            END LOOP;

            g_substitutions ('#PARAM_LIST_UNIQUE#') :=
               LTRIM (g_substitutions ('#PARAM_LIST_UNIQUE#'),
                      c_list_delimiter);

            g_substitutions ('#PARAM_CALLING_LIST_UNIQUE#') :=
               LTRIM (g_substitutions ('#PARAM_CALLING_LIST_UNIQUE#'),
                      c_list_delimiter);

            g_substitutions ('#COLUMN_COMPARE_LIST_UNIQUE#') :=
               RTRIM (
                  LTRIM (g_substitutions ('#COLUMN_COMPARE_LIST_UNIQUE#'),
                         '         AND '),
                  c_crlf);
            g_code_blocks.template :=
               '
  FUNCTION read_row( #PARAM_LIST_UNIQUE# )
  RETURN #TABLE_NAME#%ROWTYPE;
  ----------------------------------------';
            util_template_replace ('API SPEC');
            ----------------------------------------
            g_code_blocks.template :=
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
      g_code_blocks.template := '
  FUNCTION read_a_row
  RETURN #TABLE_NAME#%ROWTYPE;
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template := '
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
      g_code_blocks.template :=
         '
  PROCEDURE update_row( #PARAM_DEFINITION_W_PK# );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
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
      g_code_blocks.template :=
         '
  PROCEDURE update_row( p_row IN #TABLE_NAME#%ROWTYPE );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
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
      g_code_blocks.template :=
         '
  PROCEDURE delete_row( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE );
  ----------------------------------------';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template :=
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
      FOR i IN g_columns.FIRST .. g_columns.LAST
      LOOP
         IF (g_columns (i).column_name <> g_substitutions ('#PK_COLUMN#'))
         THEN
            g_substitutions ('#I_COLUMN_NAME#') := g_columns (i).column_name;
            g_substitutions ('#I_COLUMN_NAME_26#') :=
               g_columns (i).column_name_26;
            g_code_blocks.template :=
               '
  FUNCTION get_#I_COLUMN_NAME_26#( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE )
  RETURN #TABLE_NAME#."#I_COLUMN_NAME#"%TYPE;
  ----------------------------------------';
            util_template_replace ('API SPEC');
            ----------------------------------------
            g_code_blocks.template :=
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
      FOR i IN g_columns.FIRST .. g_columns.LAST
      LOOP
         IF (g_columns (i).column_name <> g_substitutions ('#PK_COLUMN#'))
         THEN
            g_substitutions ('#I_COLUMN_NAME#') := g_columns (i).column_name;
            g_substitutions ('#I_COLUMN_NAME_26#') :=
               g_columns (i).column_name_26;
            g_substitutions ('#I_PARAMETER_NAME#') :=
               CASE
                  WHEN g_enable_parameter_prefixes
                  THEN
                     'p_' || g_columns (i).column_name_28
                  ELSE
                     g_columns (i).column_name
               END;
            g_substitutions ('#I_COLUMN_COMPARE#') :=
               util_get_attribute_compare (
                  p_data_type           => g_columns (i).data_type,
                  p_first_attribute     =>    'v_row."'
                                           || g_columns (i).column_name
                                           || '"',
                  p_second_attribute    => g_substitutions (
                                             '#I_PARAMETER_NAME#'),
                  p_compare_operation   => '<>');
            g_substitutions ('#I_OLD_VALUE#') :=
               util_get_vc2_4000_operation (
                  p_data_type        => g_columns (i).data_type,
                  p_attribute_name   =>    'v_row."'
                                        || g_columns (i).column_name
                                        || '"');
            g_substitutions ('#I_NEW_VALUE#') :=
               util_get_vc2_4000_operation (
                  p_data_type        => g_columns (i).data_type,
                  p_attribute_name   => g_substitutions ('#I_PARAMETER_NAME#'));
            g_code_blocks.template :=
               '
  PROCEDURE set_#I_COLUMN_NAME_26#( #PK_COLUMN_PARAMETER# IN #TABLE_NAME#."#PK_COLUMN#"%TYPE, #I_PARAMETER_NAME# IN #TABLE_NAME#."#I_COLUMN_NAME#"%TYPE );
  ----------------------------------------';
            util_template_replace ('API SPEC');
            ----------------------------------------
            g_code_blocks.template :=
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
      g_code_blocks.template :=
            CASE
               WHEN g_column_defaults_serialized IS NOT NULL
               THEN
                     c_crlf
                  || '  /**'
                  || c_crlf
                  || q'[   * Custom column defaults (&lt; = < | &gt; = > | &quot; = " | &apos; = ' | &amp; = & ):]'
                  || c_crlf
                  || '   * '
                  || g_column_defaults_serialized
                  || c_crlf
                  || '   */'
               ELSE
                  NULL
            END
         || '
END #API_NAME#; ';
      util_template_replace ('API SPEC');
      ----------------------------------------
      g_code_blocks.template := '
END #API_NAME#; ';
      util_template_replace ('API BODY');
   END gen_footer;

   -----------------------------------------------------------------------------
   PROCEDURE gen_dml_view
   IS
   BEGIN
      g_code_blocks.template :=
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
      g_code_blocks.template :=
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
      p_generator_action              IN VARCHAR2,
      p_table_name                    IN all_objects.object_name%TYPE,
      p_owner                         IN all_users.username%TYPE,
      p_reuse_existing_api_params     IN BOOLEAN,
      p_enable_insertion_of_rows      IN BOOLEAN,
      p_enable_update_of_rows         IN BOOLEAN,
      p_enable_deletion_of_rows       IN BOOLEAN,
      p_enable_parameter_prefixes     IN BOOLEAN,
      p_enable_proc_with_out_params   IN BOOLEAN,
      p_enable_getter_and_setter      IN BOOLEAN,
      p_col_prefix_in_method_names    IN BOOLEAN,
      p_return_row_instead_of_pk      IN BOOLEAN,
      p_enable_dml_view               IN BOOLEAN,
      p_enable_generic_change_log     IN BOOLEAN,
      p_api_name                      IN all_objects.object_name%TYPE,
      p_sequence_name                 IN all_objects.object_name%TYPE,
      p_column_defaults               IN XMLTYPE)
   IS
      PROCEDURE initialize
      IS
         --
         PROCEDURE reset_globals
         IS
         BEGIN
            --------------------------------------------------------------------
            -- globl collections and records
            --------------------------------------------------------------------
            g_columns.delete;
            g_substitutions.delete;
            g_unique_constraints.delete;
            g_unique_cons_columns.delete;
            g_code_blocks := NULL;
            g_params_existing_api := NULL;

            --------------------------------------------------------------------
            -- global variables
            --------------------------------------------------------------------
            g_owner := NULL;
            g_table_name := NULL;
            g_pk_column := NULL;
            g_column_prefix := NULL;
            --
            g_reuse_existing_api_params := NULL;
            g_enable_insertion_of_rows := NULL;
            g_enable_update_of_rows := NULL;
            g_enable_deletion_of_rows := NULL;
            g_enable_parameter_prefixes := NULL;
            g_enable_proc_with_out_params := NULL;
            g_enable_getter_and_setter := NULL;
            g_col_prefix_in_method_names := NULL;
            g_return_row_instead_of_pk := NULL;
            g_enable_dml_view := NULL;
            g_enable_generic_change_log := NULL;
            g_api_name := NULL;
            g_sequence_name := NULL;
            g_column_defaults := NULL;
            g_column_defaults_serialized := NULL;
            --
            g_xmltype_column_present := NULL;
         END reset_globals;

         --
         PROCEDURE process_parameters
         IS
            v_api_found   BOOLEAN;

            --
            PROCEDURE check_if_table_exists
            IS
               v_object_name   all_objects.object_name%TYPE;

               CURSOR v_cur
               IS
                  SELECT table_name
                    FROM all_tables
                   WHERE owner = g_owner AND table_name = g_table_name;
            BEGIN
               OPEN v_cur;

               FETCH v_cur INTO v_object_name;

               CLOSE v_cur;

               IF (v_object_name IS NULL)
               THEN
                  raise_application_error (
                     c_generator_error_number,
                     'Table ' || g_table_name || ' does not exist.');
               END IF;
            END check_if_table_exists;

            --
            PROCEDURE check_if_sequence_exists
            IS
               v_object_name   all_objects.object_name%TYPE;

               CURSOR v_cur
               IS
                  SELECT sequence_name
                    FROM all_sequences
                   WHERE     sequence_owner = g_owner
                         AND sequence_name = g_sequence_name;
            BEGIN
               IF g_sequence_name IS NOT NULL
               THEN
                  OPEN v_cur;

                  FETCH v_cur INTO v_object_name;

                  CLOSE v_cur;

                  IF (v_object_name IS NULL)
                  THEN
                     raise_application_error (
                        c_generator_error_number,
                           'Sequence '
                        || g_sequence_name
                        || ' does not exist. Please provide correct sequence name or create missing sequence.');
                  END IF;
               END IF;
            END check_if_sequence_exists;

            PROCEDURE check_if_api_name_exists
            IS
               v_object_type   all_objects.object_type%TYPE;

               CURSOR v_cur
               IS
                  SELECT object_type
                    FROM ALL_OBJECTS
                   WHERE     owner = g_owner
                         AND object_name = g_api_name
                         AND object_type NOT IN ('PACKAGE', 'PACKAGE BODY');
            BEGIN
               IF g_api_name IS NOT NULL
               THEN
                  OPEN v_cur;

                  FETCH v_cur INTO v_object_type;

                  CLOSE v_cur;

                  IF (v_object_type IS NOT NULL)
                  THEN
                     raise_application_error (
                        c_generator_error_number,
                           'API name "'
                        || g_api_name
                        || '" does already exist as an object type "'
                        || v_object_type
                        || '". Please provide a different API name.');
                  END IF;
               END IF;
            END check_if_api_name_exists;



            PROCEDURE fetch_existing_api_params
            IS
               CURSOR v_cur
               IS
                  SELECT *
                    FROM TABLE (
                            view_existing_apis (
                               P_TABLE_NAME   => g_table_name,
                               P_OWNER        => g_owner));
            BEGIN
               v_api_found := FALSE;

               IF g_reuse_existing_api_params
               THEN
                  OPEN v_cur;

                  FETCH v_cur INTO g_params_existing_api;

                  IF v_cur%FOUND
                  THEN
                     v_api_found := TRUE;
                  END IF;

                  CLOSE v_cur;
               END IF;
            END fetch_existing_api_params;

            --
            PROCEDURE check_column_prefix_validity
            IS
            BEGIN
               -- check, if option "col_prefix_in_method_names" is set and check then
               -- if table's column prefix is unique
               IF     g_col_prefix_in_method_names = FALSE
                  AND g_column_prefix IS NULL
               THEN
                  raise_application_error (
                     c_generator_error_number,
                     'The prefix of your column names (example: prefix_rest_of_column_name) is not unique and you requested to cut off the prefix for method names. Please ensure either your column names have a unique prefix or switch the parameter p_col_prefix_in_method_names to true (SQL Developer oddgen integration: check option "Keep column prefix in method names").');
               END IF;
            END check_column_prefix_validity;

            --
            PROCEDURE check_if_log_table_exists
            IS
               v_count   PLS_INTEGER;
            BEGIN
               IF g_enable_generic_change_log
               THEN
                  FOR i
                     IN (SELECT 'GENERIC_CHANGE_LOG' FROM DUAL
                         MINUS
                         SELECT table_name
                           FROM all_tables
                          WHERE     owner = g_owner
                                AND table_name = 'GENERIC_CHANGE_LOG')
                  LOOP
                     -- check constraint
                     SELECT COUNT (*)
                       INTO v_count
                       FROM all_objects
                      WHERE     owner = g_owner
                            AND object_name = 'GENERIC_CHANGE_LOG_PK';

                     IF v_count > 0
                     THEN
                        raise_application_error (
                           c_generator_error_number,
                           'Stop trying to create generic change log table: Object with the name GENERIC_CHANGE_LOG_PK already exists.');
                     END IF;

                     -- check sequence
                     SELECT COUNT (*)
                       INTO v_count
                       FROM all_objects
                      WHERE     owner = g_owner
                            AND object_name = 'GENERIC_CHANGE_LOG_SEQ';

                     IF v_count > 0
                     THEN
                        raise_application_error (
                           c_generator_error_number,
                           'Stop trying to create generic change log table: Object with the name GENERIC_CHANGE_LOG_SEQ already exists.');
                     END IF;

                     -- check index
                     SELECT COUNT (*)
                       INTO v_count
                       FROM all_objects
                      WHERE     owner = g_owner
                            AND object_name = 'GENERIC_CHANGE_LOG_IDX';

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
  gcl_user      VARCHAR2(30 CHAR),
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
         BEGIN
            -- process table name dependend globals
            g_owner := p_owner;
            g_table_name := p_table_name;
            check_if_table_exists;
            g_pk_column := util_get_table_key (p_table_name => g_table_name);
            g_column_prefix :=
               util_get_table_column_prefix (p_table_name => g_table_name);

            -- process existing API params
            g_reuse_existing_api_params := p_reuse_existing_api_params;
            fetch_existing_api_params;

            -- process rest of parameters
            g_sequence_name :=
               CASE
                  WHEN g_reuse_existing_api_params AND v_api_found
                  THEN
                     g_params_existing_api.p_sequence_name
                  ELSE
                     CASE
                        WHEN p_sequence_name IS NOT NULL
                        THEN
                           util_get_substituted_name (p_sequence_name)
                        ELSE
                           NULL
                     END
               END;
            check_if_sequence_exists;

            g_api_name :=
               CASE
                  WHEN     g_reuse_existing_api_params
                       AND v_api_found
                       AND g_params_existing_api.p_api_name IS NOT NULL
                  THEN
                     g_params_existing_api.p_api_name
                  ELSE
                     util_get_substituted_name (
                        NVL (p_api_name, '#TABLE_NAME_26#_API'))
               END;
            check_if_api_name_exists;

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
            check_column_prefix_validity;

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
            check_if_log_table_exists;

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

            g_enable_proc_with_out_params :=
               CASE
                  WHEN     g_reuse_existing_api_params
                       AND v_api_found
                       AND g_params_existing_api.p_enable_proc_with_out_params
                              IS NOT NULL
                  THEN
                     util_string_to_bool (
                        g_params_existing_api.p_enable_proc_with_out_params)
                  ELSE
                     p_enable_proc_with_out_params
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


            g_column_defaults :=
               CASE
                  WHEN     g_reuse_existing_api_params
                       AND v_api_found
                       -- contains only placeholder to signal that defaults exists
                       AND g_params_existing_api.p_column_defaults
                              IS NOT NULL
                  THEN
                     -- get the xml defaults from the end of the package spec
                     util_get_spec_column_defaults (g_api_name)
                  ELSE
                     p_column_defaults
               END;
            g_column_defaults_serialized :=
               util_serialize_xml (g_column_defaults);

            -- check for empty XML element
            IF g_column_defaults_serialized = '<defaults/>'
            THEN
               g_column_defaults := NULL;
               g_column_defaults_serialized := NULL;
            END IF;
         END process_parameters;

         --
         PROCEDURE set_substitutions_literal_base
         IS
         BEGIN
            -- meta data
            g_substitutions ('#GENERATOR#') := c_generator;
            g_substitutions ('#GENERATOR_VERSION#') := c_generator_version;
            g_substitutions ('#GENERATOR_ACTION#') := p_generator_action;
            g_substitutions ('#GENERATED_AT#') :=
               TO_CHAR (SYSDATE, 'yyyy-mm-dd hh24:mi:ss');
            g_substitutions ('#GENERATED_BY#') := util_get_user_name;
            g_substitutions ('#SPEC_OPTIONS_MIN_LINE#') :=
               c_SPEC_OPTIONS_MIN_LINE;
            g_substitutions ('#SPEC_OPTIONS_MAX_LINE#') :=
               c_SPEC_OPTIONS_MAX_LINE;


            -- table data
            g_substitutions ('#OWNER#') := g_owner;
            g_substitutions ('#TABLE_NAME#') := g_table_name;
            g_substitutions ('#TABLE_NAME_24#') :=
               SUBSTR (g_table_name, 1, 24);
            g_substitutions ('#TABLE_NAME_26#') :=
               SUBSTR (g_table_name, 1, 26);
            g_substitutions ('#TABLE_NAME_28#') :=
               SUBSTR (g_table_name, 1, 28);
            g_substitutions ('#PK_COLUMN#') := g_pk_column;
            g_substitutions ('#PK_COLUMN_26#') := SUBSTR (g_pk_column, 1, 26);
            g_substitutions ('#PK_COLUMN_28#') := SUBSTR (g_pk_column, 1, 28);
            g_substitutions ('#COLUMN_PREFIX#') := g_column_prefix;

            -- dependend on table data
            g_substitutions ('#REUSE_EXISTING_API_PARAMS#') :=
               util_bool_to_string (g_reuse_existing_api_params);
            g_substitutions ('#COL_PREFIX_IN_METHOD_NAMES#') :=
               util_bool_to_string (g_col_prefix_in_method_names);
            g_substitutions ('#ENABLE_INSERTION_OF_ROWS#') :=
               util_bool_to_string (g_enable_insertion_of_rows);
            g_substitutions ('#ENABLE_UPDATE_OF_ROWS#') :=
               util_bool_to_string (g_enable_update_of_rows);
            g_substitutions ('#ENABLE_DELETION_OF_ROWS#') :=
               util_bool_to_string (g_enable_deletion_of_rows);
            g_substitutions ('#ENABLE_GENERIC_CHANGE_LOG#') :=
               util_bool_to_string (g_enable_generic_change_log);
            g_substitutions ('#ENABLE_DML_VIEW#') :=
               util_bool_to_string (g_enable_dml_view);
            g_substitutions ('#ENABLE_GETTER_AND_SETTER#') :=
               util_bool_to_string (g_enable_getter_and_setter);
            g_substitutions ('#ENABLE_PROC_WITH_OUT_PARAMS#') :=
               util_bool_to_string (g_enable_proc_with_out_params);
            g_substitutions ('#ENABLE_PARAMETER_PREFIXES#') :=
               util_bool_to_string (g_enable_parameter_prefixes);
            g_substitutions ('#RETURN_ROW_INSTEAD_OF_PK#') :=
               util_bool_to_string (g_return_row_instead_of_pk);
            g_substitutions ('#COLUMN_DEFAULTS#') :=
               CASE
                  WHEN g_column_defaults IS NOT NULL
                  THEN
                     -- We set only a placeholder to signal that column defaults are given.
                     -- Column defaults itself could be very large XML and are saved at
                     -- the end of the package spec.
                     c_column_defaults_present_msg
                  ELSE
                     NULL
               END;

            g_substitutions ('#SEQUENCE_NAME#') := g_sequence_name;

            g_substitutions ('#API_NAME#') := g_api_name;

            g_substitutions ('#PK_COLUMN_PARAMETER#') :=
               CASE
                  WHEN g_enable_parameter_prefixes
                  THEN
                     'p_' || g_substitutions ('#PK_COLUMN_28#')
                  ELSE
                     g_substitutions ('#PK_COLUMN#')
               END;

            g_substitutions ('#RETURN_TYPE#') :=
               CASE
                  WHEN g_return_row_instead_of_pk
                  THEN
                     g_table_name || '%ROWTYPE'
                  ELSE
                        g_table_name
                     || '."'
                     || g_substitutions ('#PK_COLUMN#')
                     || '"%TYPE'
               END;

            g_substitutions ('#RETURN_TYPE_PK_COLUMN#') :=
                  'v_return'
               || CASE
                     WHEN g_return_row_instead_of_pk
                     THEN
                        '."' || g_substitutions ('#PK_COLUMN#') || '"'
                     ELSE
                        NULL
                  END;
         -- For g_substitutions ('#RETURN_VALUE#') see procedure
         -- set_substitutions_literal_base, as it is dependend on #COLUMN_LIST_W_PK#

         END set_substitutions_literal_base;



         --
         PROCEDURE create_temporary_lobs
         IS
         BEGIN
            DBMS_LOB.createtemporary (lob_loc   => g_code_blocks.api_spec,
                                      cache     => FALSE);
            DBMS_LOB.createtemporary (lob_loc   => g_code_blocks.api_body,
                                      cache     => FALSE);
            DBMS_LOB.createtemporary (lob_loc   => g_code_blocks.dml_view,
                                      cache     => FALSE);
            DBMS_LOB.createtemporary (
               lob_loc   => g_code_blocks.dml_view_trigger,
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
               g_substitutions ('#COLUMN_LIST_W_PK#') := NULL;
               g_substitutions ('#MAP_NEW_TO_PARAM_W_PK#') := NULL;
               g_substitutions ('#MAP_PARAM_TO_PARAM_W_PK#') := NULL;
               g_substitutions ('#MAP_ROWTYPE_COL_TO_PARAM_W_PK#') := NULL;
               g_substitutions ('#PARAM_DEFINITION_W_PK#') := NULL;
               g_substitutions ('#PARAM_DEFINITION_W_PK#') := NULL;
               g_substitutions ('#PARAM_IO_DEFINITION_W_PK#') := NULL;
               g_substitutions ('#PARAM_LIST_WO_PK#') := NULL;
               g_substitutions ('#SET_PARAM_TO_COLUMN_WO_PK#') := NULL;
               g_substitutions ('#SET_ROWTYPE_COL_TO_PARAM_WO_PK#') := NULL;
               g_substitutions ('#COLUMN_COMPARE_LIST_WO_PK#') := NULL;
               g_substitutions ('#PARAM_CALLING_LIST_UNIQUE#') := NULL;
               g_substitutions ('#COLUMN_DEFAULTS_LIST#') := NULL;
               g_substitutions ('#PARAM_DEF_W_PK_AND_DEFAULTS#') := NULL;
            END init_substitutions;

            --
            PROCEDURE fetch_table_columns
            IS
            BEGIN
               OPEN g_cur_columns;

               FETCH g_cur_columns
                  BULK COLLECT INTO g_columns
                  LIMIT c_bulk_collect_limit;

               CLOSE g_cur_columns;
            END fetch_table_columns;

            --
            PROCEDURE fetch_unique_constraints
            IS
            BEGIN
               OPEN g_cur_unique_constraints;

               FETCH g_cur_unique_constraints
                  BULK COLLECT INTO g_unique_constraints
                  LIMIT c_bulk_collect_limit;

               CLOSE g_cur_unique_constraints;
            END fetch_unique_constraints;

            --
            PROCEDURE fetch_unique_cons_columns
            IS
            BEGIN
               OPEN g_cur_unique_cons_columns;

               FETCH g_cur_unique_cons_columns
                  BULK COLLECT INTO g_unique_cons_columns
                  LIMIT c_bulk_collect_limit;

               CLOSE g_cur_unique_cons_columns;
            END fetch_unique_cons_columns;

            --
            PROCEDURE check_if_column_is_xml_type (i PLS_INTEGER)
            IS
            BEGIN
               -- check, if we have a xmltype column present in our list
               -- if so, we have to provide a XML compare function
               IF g_columns (i).data_type = 'XMLTYPE'
               THEN
                  g_xmltype_column_present := TRUE;
               END IF;
            END check_if_column_is_xml_type;

            --
            PROCEDURE calc_column_short_names (i PLS_INTEGER)
            IS
            BEGIN
               g_columns (i).column_name_26 :=
                  CASE
                     WHEN g_col_prefix_in_method_names
                     THEN
                        SUBSTR (g_columns (i).column_name, 1, 26)
                     ELSE
                        SUBSTR (
                           g_columns (i).column_name,
                           LENGTH (g_substitutions ('#COLUMN_PREFIX#')) + 2,
                           26)
                  END;

               g_columns (i).column_name_28 :=
                  SUBSTR (g_columns (i).column_name, 1, 28);

               -- normalize column names by replacing
               -- all special characters with "_"
               g_columns (i).column_name_26 :=
                  util_get_normalized_identifier (
                     p_identifier   => g_columns (i).column_name_26);

               g_columns (i).column_name_28 :=
                  util_get_normalized_identifier (
                     p_identifier   => g_columns (i).column_name_28);
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
               g_substitutions ('#COLUMN_LIST_W_PK#') :=
                     g_substitutions ('#COLUMN_LIST_W_PK#')
                  || c_list_delimiter
                  || '"'
                  || g_columns (i).column_name
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
               g_substitutions ('#MAP_NEW_TO_PARAM_W_PK#') :=
                     g_substitutions ('#MAP_NEW_TO_PARAM_W_PK#')
                  || c_list_delimiter
                  || CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                           'p_' || g_columns (i).column_name_28
                        ELSE
                           g_columns (i).column_name
                     END
                  || ' => :new."'
                  || g_columns (i).column_name
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
               g_substitutions ('#MAP_PARAM_TO_PARAM_W_PK#') :=
                     g_substitutions ('#MAP_PARAM_TO_PARAM_W_PK#')
                  || c_list_delimiter
                  || CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                           'p_' || g_columns (i).column_name_28
                        ELSE
                           g_columns (i).column_name
                     END
                  || ' => '
                  || CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                           'p_' || g_columns (i).column_name_28
                        ELSE
                           g_columns (i).column_name
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
               g_substitutions ('#MAP_ROWTYPE_COL_TO_PARAM_W_PK#') :=
                     g_substitutions ('#MAP_ROWTYPE_COL_TO_PARAM_W_PK#')
                  || c_list_delimiter
                  || CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                           'p_' || g_columns (i).column_name_28
                        ELSE
                           g_columns (i).column_name
                     END
                  || ' => p_row."'
                  || g_columns (i).column_name
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
               g_substitutions ('#PARAM_DEFINITION_W_PK#') :=
                     g_substitutions ('#PARAM_DEFINITION_W_PK#')
                  || c_list_delimiter
                  || CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                           'p_' || g_columns (i).column_name_28
                        ELSE
                           g_columns (i).column_name
                     END
                  || ' IN '
                  || g_table_name
                  || '."'
                  || g_columns (i).column_name
                  || '"%TYPE'
                  || CASE
                        WHEN (g_columns (i).column_name =
                                 g_substitutions ('#PK_COLUMN#'))
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
               g_substitutions ('#PARAM_IO_DEFINITION_W_PK#') :=
                     g_substitutions ('#PARAM_IO_DEFINITION_W_PK#')
                  || c_list_delimiter
                  || CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                           'p_' || g_columns (i).column_name_28
                        ELSE
                           g_columns (i).column_name
                     END
                  || CASE
                        WHEN g_columns (i).column_name =
                                g_substitutions ('#PK_COLUMN#')
                        THEN
                           ' IN '
                        ELSE
                           ' OUT NOCOPY '
                     END
                  || g_table_name
                  || '."'
                  || g_columns (i).column_name
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
               IF (g_columns (i).column_name <>
                      g_substitutions ('#PK_COLUMN#'))
               THEN
                  g_substitutions ('#PARAM_LIST_WO_PK#') :=
                        g_substitutions ('#PARAM_LIST_WO_PK#')
                     || c_list_delimiter
                     || CASE
                           WHEN g_enable_parameter_prefixes
                           THEN
                              'p_' || g_columns (i).column_name_28
                           ELSE
                              g_columns (i).column_name
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
               IF (g_columns (i).column_name <>
                      g_substitutions ('#PK_COLUMN#'))
               THEN
                  g_substitutions ('#SET_PARAM_TO_COLUMN_WO_PK#') :=
                        g_substitutions ('#SET_PARAM_TO_COLUMN_WO_PK#')
                     || c_list_delimiter
                     || '"'
                     || g_columns (i).column_name
                     || '"'
                     || ' = '
                     || CASE
                           WHEN g_enable_parameter_prefixes
                           THEN
                              'p_' || g_columns (i).column_name_28
                           ELSE
                              g_columns (i).column_name
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
               IF (g_columns (i).column_name <>
                      g_substitutions ('#PK_COLUMN#'))
               THEN
                  g_substitutions ('#SET_ROWTYPE_COL_TO_PARAM_WO_PK#') :=
                        g_substitutions ('#SET_ROWTYPE_COL_TO_PARAM_WO_PK#')
                     || CASE
                           WHEN g_enable_parameter_prefixes
                           THEN
                              'p_' || g_columns (i).column_name_28
                           ELSE
                              g_columns (i).column_name
                        END
                     || ' := v_row."'
                     || g_columns (i).column_name
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
               IF (g_columns (i).column_name <>
                      g_substitutions ('#PK_COLUMN#'))
               THEN
                  g_substitutions ('#COLUMN_COMPARE_LIST_WO_PK#') :=
                        g_substitutions ('#COLUMN_COMPARE_LIST_WO_PK#')
                     || CASE
                           WHEN g_enable_generic_change_log THEN '      IF '
                           ELSE '      OR '
                        END
                     || util_get_attribute_compare (
                           p_data_type           => g_columns (i).data_type,
                           p_first_attribute     =>    'v_row."'
                                                    || g_columns (i).column_name
                                                    || '"',
                           p_second_attribute    => CASE
                                                      WHEN g_enable_parameter_prefixes
                                                      THEN
                                                            'p_'
                                                         || g_columns (i).column_name_28
                                                      ELSE
                                                         g_columns (i).column_name
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
                              || g_columns (i).column_name
                              || '''
                             , p_pk_id     => v_row."'
                              || g_substitutions ('#PK_COLUMN#')
                              || '"
                             , p_old_value => '
                              || util_get_vc2_4000_operation (
                                    p_data_type        => g_columns (i).data_type,
                                    p_attribute_name   =>    'v_row."'
                                                          || g_columns (i).column_name
                                                          || '"')
                              || '
                             , p_new_value => '
                              || util_get_vc2_4000_operation (
                                    p_data_type        => g_columns (i).data_type,
                                    p_attribute_name   => CASE
                                                            WHEN g_enable_parameter_prefixes
                                                            THEN
                                                                  'p_'
                                                               || g_columns (
                                                                     i).column_name_28
                                                            ELSE
                                                               g_columns (i).column_name
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


            --
            PROCEDURE param_def_w_pk_and_defaults (i PLS_INTEGER)
            IS
            BEGIN
               /* column defaults:
               #PARAM_DEF_W_PK_AND_DEFAULTS#
               e.g.
               p_employee_id IN employees.employee_id%TYPE DEFAULT get_a_row()."EMPLOYEE_ID",
               p_first_name IN employees.first_name%TYPE DEFAULT get_a_row()."FIRST_NAME",
               p_last_name IN employees.last_name%TYPE DEFAULT get_a_row()."LAST_NAME",
               ... */
               g_substitutions ('#PARAM_DEF_W_PK_AND_DEFAULTS#') :=
                     g_substitutions ('#PARAM_DEF_W_PK_AND_DEFAULTS#')
                  || c_list_delimiter
                  || CASE
                        WHEN g_enable_parameter_prefixes
                        THEN
                           'p_' || g_columns (i).column_name_28
                        ELSE
                           g_columns (i).column_name
                     END
                  || ' IN '
                  || g_table_name
                  || '."'
                  || g_columns (i).column_name
                  || '"%TYPE'
                  || CASE
                        WHEN (g_columns (i).column_name =
                                 g_substitutions ('#PK_COLUMN#'))
                        THEN
                           ' DEFAULT NULL'
                        ELSE
                              ' DEFAULT get_a_row()."'
                           || g_columns (i).column_name
                           || '"'
                     END;
            END param_def_w_pk_and_defaults;

            --
            PROCEDURE column_defaults_list
            IS
               v_code   VARCHAR2 (32767);
            BEGIN
               /* column defaults:
               #COLUMN_DEFAULTS_LIST#
               e.g.
               v_row.employee_id := employees_seq.nextval; --generated from SEQ
               v_row.first_name := 'Rowan';
               v_row.last_name := 'Atkinson';
               , ... */
               IF g_column_defaults IS NULL
               THEN
                  -- normal list processing
                  FOR i IN g_columns.FIRST .. g_columns.LAST
                  LOOP
                     IF g_columns (i).data_default IS NOT NULL
                     THEN
                        g_substitutions ('#COLUMN_DEFAULTS_LIST#') :=
                              g_substitutions ('#COLUMN_DEFAULTS_LIST#')
                           || '    v_row."'
                           || g_columns (i).column_name
                           || '" := '
                           || g_columns (i).data_default
                           || ';'
                           || c_crlf;
                     END IF;
                  END LOOP;
               ELSE
                  -- special handling of given XML parameter
                  FOR i
                     IN (         SELECT x.column_name, x.data_default
                                    FROM XMLTABLE (
                                            '/defaults/item'
                                            PASSING g_column_defaults
                                            COLUMNS column_name    VARCHAR2 (128)
                                                                      PATH './col',
                                                    data_default   VARCHAR2 (4000)
                                                                      PATH './val') x)
                  LOOP
                     IF i.data_default IS NOT NULL
                     THEN
                        g_substitutions ('#COLUMN_DEFAULTS_LIST#') :=
                              g_substitutions ('#COLUMN_DEFAULTS_LIST#')
                           || '    v_row."'
                           || i.column_name
                           || '" := '
                           || i.data_default
                           || ';'
                           || c_crlf;
                     END IF;
                  END LOOP;
               END IF;
            END column_defaults_list;

            --
            PROCEDURE cut_off_first_last_delimiter
            IS
            BEGIN
               -- cut off the first and/or last delimiter
               g_substitutions ('#SET_PARAM_TO_COLUMN_WO_PK#') :=
                  LTRIM (g_substitutions ('#SET_PARAM_TO_COLUMN_WO_PK#'),
                         c_list_delimiter);
               g_substitutions ('#COLUMN_LIST_W_PK#') :=
                  LTRIM (g_substitutions ('#COLUMN_LIST_W_PK#'),
                         c_list_delimiter);
               g_substitutions ('#MAP_NEW_TO_PARAM_W_PK#') :=
                  LTRIM (g_substitutions ('#MAP_NEW_TO_PARAM_W_PK#'),
                         c_list_delimiter);
               g_substitutions ('#MAP_PARAM_TO_PARAM_W_PK#') :=
                  LTRIM (g_substitutions ('#MAP_PARAM_TO_PARAM_W_PK#'),
                         c_list_delimiter);
               g_substitutions ('#MAP_ROWTYPE_COL_TO_PARAM_W_PK#') :=
                  LTRIM (g_substitutions ('#MAP_ROWTYPE_COL_TO_PARAM_W_PK#'),
                         c_list_delimiter);
               g_substitutions ('#PARAM_DEFINITION_W_PK#') :=
                  LTRIM (g_substitutions ('#PARAM_DEFINITION_W_PK#'),
                         c_list_delimiter);
               g_substitutions ('#PARAM_IO_DEFINITION_W_PK#') :=
                  LTRIM (g_substitutions ('#PARAM_IO_DEFINITION_W_PK#'),
                         c_list_delimiter);
               g_substitutions ('#PARAM_LIST_WO_PK#') :=
                  LTRIM (g_substitutions ('#PARAM_LIST_WO_PK#'),
                         c_list_delimiter);
               g_substitutions ('#PARAM_DEF_W_PK_AND_DEFAULTS#') :=
                  LTRIM (g_substitutions ('#PARAM_DEF_W_PK_AND_DEFAULTS#'),
                         c_list_delimiter);

               -- this has to be enhanced
               g_substitutions ('#COLUMN_COMPARE_LIST_WO_PK#') :=
                     LTRIM (
                        LTRIM (
                           RTRIM (
                              g_substitutions ('#COLUMN_COMPARE_LIST_WO_PK#'),
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

               g_substitutions ('#COLUMN_DEFAULTS_LIST#') :=
                  CASE
                     WHEN g_substitutions ('#COLUMN_DEFAULTS_LIST#') IS NULL
                     THEN
                        'NULL; -- no defaults defined'
                     ELSE
                        LTRIM (g_substitutions ('#COLUMN_DEFAULTS_LIST#'))
                  END;
            END cut_off_first_last_delimiter;
         BEGIN
            init_substitutions;
            fetch_table_columns;
            fetch_unique_constraints;
            fetch_unique_cons_columns;

            FOR i IN g_columns.FIRST .. g_columns.LAST
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
               param_def_w_pk_and_defaults (i);
            END LOOP;

            column_defaults_list;

            cut_off_first_last_delimiter;

            -- this substitution depends on column list with pk and should
            -- normally located in set_substitutions_literal_base
            g_substitutions ('#RETURN_VALUE#') :=
               CASE
                  WHEN g_return_row_instead_of_pk
                  THEN
                     g_substitutions ('#COLUMN_LIST_W_PK#')
                  ELSE
                     '"' || g_substitutions ('#PK_COLUMN#') || '"'
               END;
         END set_substitutions_collect_base;
      --
      BEGIN
         reset_globals;
         process_parameters;
         set_substitutions_literal_base;
         create_temporary_lobs;
         set_substitutions_collect_base;
      END initialize;

      --
      PROCEDURE finalize
      IS
      BEGIN
         -- finalize CLOB varchar caches
         util_clob_append (
            p_clob                 => g_code_blocks.api_spec,
            p_clob_varchar_cache   => g_code_blocks.api_spec_varchar_cache,
            p_varchar_to_append    => NULL,
            p_final_call           => TRUE);
         util_clob_append (
            p_clob                 => g_code_blocks.api_body,
            p_clob_varchar_cache   => g_code_blocks.api_body_varchar_cache,
            p_varchar_to_append    => NULL,
            p_final_call           => TRUE);

         IF (g_enable_dml_view)
         THEN
            util_clob_append (
               p_clob                 => g_code_blocks.dml_view,
               p_clob_varchar_cache   => g_code_blocks.dml_view_varchar_cache,
               p_varchar_to_append    => NULL,
               p_final_call           => TRUE);
            util_clob_append (
               p_clob                 => g_code_blocks.dml_view_trigger,
               p_clob_varchar_cache   => g_code_blocks.dml_view_trigger_varchar_cache,
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
      gen_get_a_row_fnc;

      --------------------------------------------------------------------------
      -- CREATE procedures / functions only if allowed
      --------------------------------------------------------------------------
      IF (g_enable_insertion_of_rows)
      THEN
         gen_create_row_fnc;
         gen_create_row_prc;
         gen_create_rowtype_fnc;
         gen_create_rowtype_prc;
         gen_create_a_row_fnc;                         -- with column defaults
         gen_create_a_row_prc;                         -- with column defaults
      END IF;

      --------------------------------------------------------------------------
      -- READ procedures always (except the one with out params for APEX)
      --------------------------------------------------------------------------
      gen_read_row_fnc;

      IF g_enable_proc_with_out_params
      THEN
         gen_read_row_prc;
      END IF;

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
         util_execute_sql (g_code_blocks.api_spec);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      -- compile package body
      BEGIN
         util_execute_sql (g_code_blocks.api_body);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      -- compile DML view
      BEGIN
         util_execute_sql (g_code_blocks.dml_view);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      -- compile DML view trigger
      BEGIN
         util_execute_sql (g_code_blocks.dml_view_trigger);
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
      RETURN    g_code_blocks.api_spec
             || terminator
             || g_code_blocks.api_body
             || terminator
             || CASE
                   WHEN g_enable_dml_view
                   THEN
                         g_code_blocks.dml_view
                      || terminator
                      || g_code_blocks.dml_view_trigger
                      || terminator
                   ELSE
                      NULL
                END;
   END main_return;

   -----------------------------------------------------------------------------
   PROCEDURE compile_api (
      p_table_name                    IN all_objects.object_name%TYPE,
      p_owner                         IN all_users.username%TYPE DEFAULT USER,
      p_reuse_existing_api_params     IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params,
      --^ if true, the following params are ignored when API package are already existing and params are extractable from spec source
      p_enable_insertion_of_rows      IN BOOLEAN DEFAULT om_tapigen.c_enable_insertion_of_rows,
      p_enable_update_of_rows         IN BOOLEAN DEFAULT om_tapigen.c_enable_update_of_rows,
      p_enable_deletion_of_rows       IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows,
      p_enable_parameter_prefixes     IN BOOLEAN DEFAULT om_tapigen.c_enable_parameter_prefixes,
      p_enable_proc_with_out_params   IN BOOLEAN DEFAULT om_tapigen.c_enable_proc_with_out_params,
      p_enable_getter_and_setter      IN BOOLEAN DEFAULT om_tapigen.c_enable_getter_and_setter,
      p_col_prefix_in_method_names    IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names,
      p_return_row_instead_of_pk      IN BOOLEAN DEFAULT om_tapigen.c_return_row_instead_of_pk,
      p_enable_dml_view               IN BOOLEAN DEFAULT om_tapigen.c_enable_dml_view,
      p_enable_generic_change_log     IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log,
      p_api_name                      IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_api_name,
      p_sequence_name                 IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_sequence_name,
      p_column_defaults               IN XMLTYPE DEFAULT om_tapigen.c_column_defaults)
   IS
   BEGIN
      main_generate (
         p_generator_action              => 'COMPILE_API',
         p_table_name                    => p_table_name,
         p_owner                         => p_owner,
         p_reuse_existing_api_params     => p_reuse_existing_api_params,
         p_enable_insertion_of_rows      => p_enable_insertion_of_rows,
         p_enable_update_of_rows         => p_enable_update_of_rows,
         p_enable_deletion_of_rows       => p_enable_deletion_of_rows,
         p_enable_parameter_prefixes     => p_enable_parameter_prefixes,
         p_enable_proc_with_out_params   => p_enable_proc_with_out_params,
         p_enable_getter_and_setter      => p_enable_getter_and_setter,
         p_col_prefix_in_method_names    => p_col_prefix_in_method_names,
         p_return_row_instead_of_pk      => p_return_row_instead_of_pk,
         p_enable_dml_view               => p_enable_dml_view,
         p_enable_generic_change_log     => p_enable_generic_change_log,
         p_api_name                      => p_api_name,
         p_sequence_name                 => p_sequence_name,
         p_column_defaults               => p_column_defaults);
      main_compile;
   END compile_api;

   -----------------------------------------------------------------------------
   FUNCTION compile_api_and_get_code (
      p_table_name                    IN all_objects.object_name%TYPE,
      p_owner                         IN all_users.username%TYPE DEFAULT USER,
      p_reuse_existing_api_params     IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params,
      --^ if true, the following params are ignored when API package are already existing and params are extractable from spec source
      p_enable_insertion_of_rows      IN BOOLEAN DEFAULT om_tapigen.c_enable_insertion_of_rows,
      p_enable_update_of_rows         IN BOOLEAN DEFAULT om_tapigen.c_enable_update_of_rows,
      p_enable_deletion_of_rows       IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows,
      p_enable_parameter_prefixes     IN BOOLEAN DEFAULT om_tapigen.c_enable_parameter_prefixes,
      p_enable_proc_with_out_params   IN BOOLEAN DEFAULT om_tapigen.c_enable_proc_with_out_params,
      p_enable_getter_and_setter      IN BOOLEAN DEFAULT om_tapigen.c_enable_getter_and_setter,
      p_col_prefix_in_method_names    IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names,
      p_return_row_instead_of_pk      IN BOOLEAN DEFAULT om_tapigen.c_return_row_instead_of_pk,
      p_enable_dml_view               IN BOOLEAN DEFAULT om_tapigen.c_enable_dml_view,
      p_enable_generic_change_log     IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log,
      p_api_name                      IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_api_name,
      p_sequence_name                 IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_sequence_name,
      p_column_defaults               IN XMLTYPE DEFAULT om_tapigen.c_column_defaults)
      RETURN CLOB
   IS
   BEGIN
      main_generate (
         p_generator_action              => 'COMPILE_API_AND_GET_CODE',
         p_table_name                    => p_table_name,
         p_owner                         => p_owner,
         p_reuse_existing_api_params     => p_reuse_existing_api_params,
         p_enable_insertion_of_rows      => p_enable_insertion_of_rows,
         p_enable_update_of_rows         => p_enable_update_of_rows,
         p_enable_deletion_of_rows       => p_enable_deletion_of_rows,
         p_enable_parameter_prefixes     => p_enable_parameter_prefixes,
         p_enable_proc_with_out_params   => p_enable_proc_with_out_params,
         p_enable_getter_and_setter      => p_enable_getter_and_setter,
         p_col_prefix_in_method_names    => p_col_prefix_in_method_names,
         p_return_row_instead_of_pk      => p_return_row_instead_of_pk,
         p_enable_dml_view               => p_enable_dml_view,
         p_enable_generic_change_log     => p_enable_generic_change_log,
         p_api_name                      => p_api_name,
         p_sequence_name                 => p_sequence_name,
         p_column_defaults               => p_column_defaults);
      main_compile;
      RETURN main_return;
   END compile_api_and_get_code;

   -----------------------------------------------------------------------------
   FUNCTION get_code (
      p_table_name                    IN all_objects.object_name%TYPE,
      p_owner                         IN all_users.username%TYPE DEFAULT USER,
      p_reuse_existing_api_params     IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params,
      --^ if true, the following params are ignored when API package are already existing and params are extractable from spec source
      p_enable_insertion_of_rows      IN BOOLEAN DEFAULT om_tapigen.c_enable_insertion_of_rows,
      p_enable_update_of_rows         IN BOOLEAN DEFAULT om_tapigen.c_enable_update_of_rows,
      p_enable_deletion_of_rows       IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows,
      p_enable_parameter_prefixes     IN BOOLEAN DEFAULT om_tapigen.c_enable_parameter_prefixes,
      p_enable_proc_with_out_params   IN BOOLEAN DEFAULT om_tapigen.c_enable_proc_with_out_params,
      p_enable_getter_and_setter      IN BOOLEAN DEFAULT om_tapigen.c_enable_getter_and_setter,
      p_col_prefix_in_method_names    IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names,
      p_return_row_instead_of_pk      IN BOOLEAN DEFAULT om_tapigen.c_return_row_instead_of_pk,
      p_enable_dml_view               IN BOOLEAN DEFAULT om_tapigen.c_enable_dml_view,
      p_enable_generic_change_log     IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log,
      p_api_name                      IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_api_name,
      p_sequence_name                 IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_sequence_name,
      p_column_defaults               IN XMLTYPE DEFAULT om_tapigen.c_column_defaults)
      RETURN CLOB
   IS
   BEGIN
      main_generate (
         p_generator_action              => 'GET_CODE',
         p_table_name                    => p_table_name,
         p_owner                         => p_owner,
         p_reuse_existing_api_params     => p_reuse_existing_api_params,
         p_enable_insertion_of_rows      => p_enable_insertion_of_rows,
         p_enable_update_of_rows         => p_enable_update_of_rows,
         p_enable_deletion_of_rows       => p_enable_deletion_of_rows,
         p_enable_parameter_prefixes     => p_enable_parameter_prefixes,
         p_enable_proc_with_out_params   => p_enable_proc_with_out_params,
         p_enable_getter_and_setter      => p_enable_getter_and_setter,
         p_col_prefix_in_method_names    => p_col_prefix_in_method_names,
         p_return_row_instead_of_pk      => p_return_row_instead_of_pk,
         p_enable_dml_view               => p_enable_dml_view,
         p_enable_generic_change_log     => p_enable_generic_change_log,
         p_api_name                      => p_api_name,
         p_sequence_name                 => p_sequence_name,
         p_column_defaults               => p_column_defaults);
      RETURN main_return;
   END get_code;

   -----------------------------------------------------------------------------
   PROCEDURE recreate_existing_apis (
      p_owner   IN all_users.username%TYPE DEFAULT USER)
   IS
      v_apis   g_tab_existing_apis;

      CURSOR v_cur
      IS
         SELECT * FROM TABLE (view_existing_apis (P_OWNER => p_owner));
   BEGIN
      OPEN v_cur;

      FETCH v_cur BULK COLLECT INTO v_apis LIMIT c_bulk_collect_limit;

      CLOSE v_cur;

      IF v_apis.COUNT > 0
      THEN
         FOR i IN v_apis.FIRST .. v_apis.LAST
         LOOP
            compile_api (p_table_name   => v_apis (i).table_name,
                         p_owner        => v_apis (i).owner);
         END LOOP;
      END IF;
   END;

   -----------------------------------------------------------------------------

   FUNCTION view_existing_apis (
      p_table_name    all_tables.table_name%TYPE DEFAULT NULL,
      p_owner         all_users.username%TYPE DEFAULT USER)
      RETURN g_tab_existing_apis
      PIPELINED
   IS
      v_tab   g_tab_existing_apis;
      v_row   g_row_existing_apis;
   BEGIN
      -- I was not able to compile without execute immediate - got a strange ORA-03113.
      -- Direct execution of the statement in SQL tool works :-(
      EXECUTE IMMEDIATE
         q'[
-- ATTENTION: query columns need to match the global row definition om_tapigen.g_row_existing_apis.
-- Creating a cursor was not possible - database throws

WITH api_names
     AS (SELECT owner, NAME AS api_name
           FROM all_source
          WHERE     owner = :p_owner
                AND TYPE = 'PACKAGE'
                AND line BETWEEN :spec_options_min_line
                             AND :spec_options_max_line
                AND INSTR (text, 'generator="OM_TAPIGEN"') > 0) -- select * from apis
                                                               ,
     sources
     AS (  SELECT owner,
                  package_name,
                  xmltype (
                     NVL (REGEXP_SUBSTR (REPLACE (source_code, '*', NULL),
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
                          AND name IN (SELECT api_name FROM api_names)
                          AND TYPE = 'PACKAGE'
                          AND line BETWEEN :spec_options_min_line
                                       AND :spec_options_max_line)
         GROUP BY owner, package_name, source_code)  -- select * from sources;
                                                   ,
     apis
     AS (                        SELECT t.owner,
                                        x.p_table_name AS table_name,
                                        t.package_name,
                                        x.generator,
                                        x.generator_version,
                                        x.generator_action,
                                        TO_DATE (x.generated_at, 'yyyy-mm-dd hh24:mi:ss')
                                           AS generated_at,
                                        x.generated_by,
                                        x.p_owner,
                                        x.p_table_name,
                                        x.p_reuse_existing_api_params,
                                        x.p_enable_insertion_of_rows,
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
                                        x.p_column_defaults
                                   FROM sources t
                                        CROSS JOIN
                                        XMLTABLE (
                                           '/options'
                                           PASSING options
                                           COLUMNS generator VARCHAR2 (30 CHAR) PATH '@generator',
                                                   generator_version VARCHAR2 (10 CHAR)
                                                      PATH '@generator_version',
                                                   generator_action VARCHAR2 (30 CHAR)
                                                      PATH '@generator_action',
                                                   generated_at VARCHAR2 (30 CHAR)
                                                      PATH '@generated_at',
                                                   generated_by VARCHAR2 (128 CHAR)
                                                      PATH '@generated_by',
                                                   p_owner VARCHAR2 (128 CHAR) PATH '@p_owner',
                                                   p_table_name VARCHAR2 (128 CHAR)
                                                      PATH '@p_table_name',
                                                   p_reuse_existing_api_params VARCHAR2 (5 CHAR)
                                                      PATH '@p_reuse_existing_api_params',
                                                   p_enable_insertion_of_rows VARCHAR2 (5 CHAR)
                                                      PATH '@p_enable_insertion_of_rows',
                                                   p_enable_update_of_rows VARCHAR2 (5 CHAR)
                                                      PATH '@p_enable_update_of_rows',
                                                   p_enable_deletion_of_rows VARCHAR2 (5 CHAR)
                                                      PATH '@p_enable_deletion_of_rows',
                                                   p_enable_parameter_prefixes VARCHAR2 (5 CHAR)
                                                      PATH '@p_enable_parameter_prefixes',
                                                   p_enable_proc_with_out_params VARCHAR2 (5 CHAR)
                                                      PATH '@p_enable_proc_with_out_params',
                                                   p_enable_getter_and_setter VARCHAR2 (5 CHAR)
                                                      PATH '@p_enable_getter_and_setter',
                                                   p_col_prefix_in_method_names VARCHAR2 (5 CHAR)
                                                      PATH '@p_col_prefix_in_method_names',
                                                   p_return_row_instead_of_pk VARCHAR2 (5 CHAR)
                                                      PATH '@p_return_row_instead_of_pk',
                                                   p_enable_dml_view VARCHAR2 (5 CHAR)
                                                      PATH '@p_enable_dml_view',
                                                   p_enable_generic_change_log VARCHAR2 (5 CHAR)
                                                      PATH '@p_enable_generic_change_log',
                                                   p_api_name VARCHAR2 (128 CHAR) PATH '@p_api_name',
                                                   p_sequence_name VARCHAR2 (128 CHAR)
                                                      PATH '@p_sequence_name',
                                                   p_column_defaults VARCHAR2 (30 CHAR)
                                                      PATH '@p_column_defaults') x) -- SELECT * FROM apis;
                                                                                   ,
     objects
     AS (SELECT specs.object_name AS package_name,
                specs.status AS spec_status,
                specs.last_ddl_time AS spec_last_ddl_time,
                bodys.status AS body_status,
                bodys.last_ddl_time AS body_last_ddl_time
           FROM (SELECT object_name,
                        object_type,
                        status,
                        last_ddl_time
                   FROM all_objects
                  WHERE     owner = :p_owner
                        AND object_type = 'PACKAGE'
                        AND object_name IN (SELECT api_name FROM api_names))
                specs
                LEFT JOIN
                (SELECT object_name,
                        object_type,
                        status,
                        last_ddl_time
                   FROM all_objects
                  WHERE     owner = :p_owner
                        AND object_type = 'PACKAGE BODY'
                        AND object_name IN (SELECT api_name FROM api_names))
                bodys
                   ON     specs.object_name = bodys.object_name
                      AND specs.object_type || ' BODY' = bodys.object_type)
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
       apis.p_column_defaults
  FROM apis JOIN objects ON apis.package_name = objects.package_name
 WHERE table_name = NVL ( :p_table_name, table_name)
            ]'
         BULK COLLECT INTO v_tab
         USING p_owner,
               c_spec_options_min_line,
               c_spec_options_max_line,
               p_owner,
               c_spec_options_min_line,
               c_spec_options_max_line,
               p_owner,
               p_owner,
               p_table_name;

      FOR i IN v_tab.FIRST .. v_tab.LAST
      LOOP
         -----------------------------------------------------------------------
         -- parameters could be null, if older om_tapigen versions where used
         -- for creating table APIs, so coalesce ensures parameter validity.
         -- If existing parameter is null, then default is taken.
         -----------------------------------------------------------------------
         v_tab (i).p_reuse_existing_api_params :=
            COALESCE (v_tab (i).p_reuse_existing_api_params,
                      util_bool_to_string (c_reuse_existing_api_params));

         v_tab (i).p_return_row_instead_of_pk :=
            COALESCE (v_tab (i).p_return_row_instead_of_pk,
                      util_bool_to_string (c_return_row_instead_of_pk));

         v_tab (i).p_enable_insertion_of_rows :=
            COALESCE (v_tab (i).p_enable_insertion_of_rows,
                      util_bool_to_string (c_enable_insertion_of_rows));

         v_tab (i).p_enable_update_of_rows :=
            COALESCE (v_tab (i).p_enable_update_of_rows,
                      util_bool_to_string (c_enable_update_of_rows));

         v_tab (i).p_enable_deletion_of_rows :=
            COALESCE (v_tab (i).p_enable_deletion_of_rows,
                      util_bool_to_string (c_enable_deletion_of_rows));

         v_tab (i).p_enable_parameter_prefixes :=
            COALESCE (v_tab (i).p_enable_parameter_prefixes,
                      util_bool_to_string (c_enable_parameter_prefixes));

         v_tab (i).p_enable_proc_with_out_params :=
            COALESCE (v_tab (i).p_enable_proc_with_out_params,
                      util_bool_to_string (c_enable_proc_with_out_params));

         v_tab (i).p_enable_generic_change_log :=
            COALESCE (v_tab (i).p_enable_generic_change_log,
                      util_bool_to_string (c_enable_generic_change_log));

         v_tab (i).p_enable_dml_view :=
            COALESCE (v_tab (i).p_enable_dml_view,
                      util_bool_to_string (c_enable_dml_view));

         v_tab (i).p_enable_getter_and_setter :=
            COALESCE (v_tab (i).p_enable_getter_and_setter,
                      util_bool_to_string (c_enable_getter_and_setter));

         v_tab (i).p_col_prefix_in_method_names :=
            COALESCE (v_tab (i).p_col_prefix_in_method_names,
                      util_bool_to_string (c_col_prefix_in_method_names));

         PIPE ROW (v_tab (i));
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_row.errors :=
            SUBSTR (
                  'Incomplete resultset! This is the last correct proccessed row from the pipelined function. Did you change the params XML in one of the API packages? Original error message: '
               || c_crlflf
               || SQLERRM
               || c_crlflf
               || DBMS_UTILITY.format_error_backtrace,
               1,
               4000);
         PIPE ROW (v_row);
   END view_existing_apis;

   -----------------------------------------------------------------------------

   FUNCTION view_naming_conflicts (
      p_owner    all_users.username%TYPE DEFAULT USER)
      RETURN g_tab_naming_conflicts
      PIPELINED
   IS
   BEGIN
      FOR i
         IN (WITH ut
                  AS (SELECT table_name
                        FROM all_tables
                       WHERE owner = p_owner),
                  temp
                  AS (SELECT SUBSTR (table_name, 1, 26) || '_API'
                                AS object_name
                        FROM ut
                      UNION ALL
                      SELECT SUBSTR (table_name, 1, 24) || '_DML_V' FROM ut
                      UNION ALL
                      SELECT SUBSTR (table_name, 1, 24) || '_IOIUD' FROM ut
                      UNION ALL
                      SELECT 'GENERIC_CHANGE_LOG' FROM DUAL
                      UNION ALL
                      SELECT 'GENERIC_CHANGE_LOG_SEQ' FROM DUAL
                      UNION ALL
                      SELECT 'GENERIC_CHANGE_LOG_PK' FROM DUAL
                      UNION ALL
                      SELECT 'GENERIC_CHANGE_LOG_IDX' FROM DUAL)
               SELECT uo.object_name,
                      uo.object_type,
                      uo.status,
                      uo.last_ddl_time
                 FROM all_objects uo
                WHERE     owner = p_owner
                      AND uo.object_name IN (SELECT object_name FROM temp)
             ORDER BY uo.object_name)
      LOOP
         PIPE ROW (i);
      END LOOP;
   END view_naming_conflicts;
-----------------------------------------------------------------------------

END om_tapigen;
/