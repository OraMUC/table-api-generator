CREATE OR REPLACE PACKAGE om_tapigen AUTHID CURRENT_USER IS
  /*
  THIS IS A TABLE API GENERATOR
  Source and documentation: github.com/OraMUC/table-api-generator
  
  The MIT License (MIT)
  
  Copyright (c) 2015-2017 André Borngräber, Ottmar Gobrecht
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  
  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.
  
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
  */

  -----------------------------------------------------------------------------
  -- public global constants c_*
  -----------------------------------------------------------------------------
  c_generator         CONSTANT VARCHAR2(10 CHAR) := 'OM_TAPIGEN';
  c_generator_version CONSTANT VARCHAR2(10 CHAR) := '0.5.0';

  c_reuse_existing_api_params  CONSTANT BOOLEAN := TRUE;
  c_col_prefix_in_method_names CONSTANT BOOLEAN := TRUE;
  c_enable_insertion_of_rows   CONSTANT BOOLEAN := TRUE;
  c_enable_update_of_rows      CONSTANT BOOLEAN := TRUE;
  c_enable_deletion_of_rows    CONSTANT BOOLEAN := FALSE;
  c_enable_generic_change_log  CONSTANT BOOLEAN := FALSE;
  c_enable_dml_view            CONSTANT BOOLEAN := FALSE;
  c_sequence_name              CONSTANT VARCHAR2(30 CHAR) := NULL;
  c_api_name                   CONSTANT VARCHAR2(30 CHAR) := NULL;
  c_enable_getter_and_setter   CONSTANT BOOLEAN := TRUE;
  c_enable_parameter_prefixes  CONSTANT BOOLEAN := TRUE;
  c_return_row_instead_of_pk   CONSTANT BOOLEAN := FALSE;
  c_column_defaults            CONSTANT xmltype := NULL;

  -----------------------------------------------------------------------------
  -- public global cursors g_cur_* and global collections g_tab_*
  -----------------------------------------------------------------------------
  CURSOR g_cur_existing_apis(pi_table_name user_tables.table_name%TYPE) IS
    WITH ut AS
     (SELECT table_name
        FROM user_tables ut
       WHERE table_name = coalesce(pi_table_name
                                  ,table_name)),
    uo AS
     (SELECT specs.object_name   AS package_name
            ,specs.status        AS spec_status
            ,specs.last_ddl_time AS spec_last_ddl_time
            ,bodys.status        AS body_status
            ,bodys.last_ddl_time AS body_last_ddl_time
        FROM (SELECT object_name
                    ,object_type
                    ,status
                    ,last_ddl_time
                FROM user_objects
               WHERE object_type = 'PACKAGE'
                 AND object_name LIKE '%\_API' ESCAPE '\') specs
        LEFT JOIN (SELECT object_name
                        ,object_type
                        ,status
                        ,last_ddl_time
                    FROM user_objects
                   WHERE object_type = 'PACKAGE BODY'
                     AND object_name LIKE '%\_API' ESCAPE '\') bodys
          ON specs.object_name = bodys.object_name
         AND specs.object_type || ' BODY' = bodys.object_type),
    us AS
     (SELECT x.generator
            ,x.generator_version
            ,x.generator_action
            ,to_date(x.generated_at
                    ,'yyyy-mm-dd hh24:mi:ss') AS generated_at
            ,x.generated_by
            ,t.package_name
            ,x.p_table_name
            ,x.p_reuse_existing_api_params
            ,x.p_col_prefix_in_method_names
            ,x.p_enable_insertion_of_rows
            ,x.p_enable_update_of_rows
            ,x.p_enable_deletion_of_rows
            ,x.p_enable_generic_change_log
            ,x.p_enable_dml_view
            ,x.p_sequence_name
            ,x.p_api_name
            ,x.p_enable_getter_and_setter
            ,x.p_enable_parameter_prefixes
            ,x.p_return_row_instead_of_pk
        FROM (SELECT package_name
                    ,xmltype(nvl(regexp_substr(REPLACE(source_code
                                                      ,'*'
                                                      ,NULL)
                                              ,'<options.*>'
                                              ,1
                                              ,1
                                              ,'ni')
                                ,'<no_data_found/>')) AS options
                FROM (SELECT NAME AS package_name
                            ,listagg(text
                                    ,' ') within GROUP(ORDER BY NAME, line) over(PARTITION BY NAME) AS source_code
                        FROM user_source
                       WHERE TYPE = 'PACKAGE'
                         AND NAME LIKE '%\_API' ESCAPE '\'
                         AND line BETWEEN 5 AND 30)
               GROUP BY package_name
                       ,source_code) t
            ,xmltable('for $i in /options return $i' passing options columns --
                      generator VARCHAR2(30 CHAR) path '/options/@generator'
                     ,generator_version VARCHAR2(10 CHAR) path '/options/@generator_version'
                     ,generator_action VARCHAR2(30 CHAR) path '/options/@generator_action'
                     ,generated_at VARCHAR2(30 CHAR) path '/options/@generated_at'
                     ,generated_by VARCHAR2(120 CHAR) path '/options/@generated_by'
                     ,p_table_name VARCHAR2(30 CHAR) path '/options/@p_table_name'
                     ,p_reuse_existing_api_params VARCHAR2(10 CHAR) path '/options/@p_reuse_existing_api_params'
                     ,p_col_prefix_in_method_names VARCHAR2(10 CHAR) path '/options/@p_col_prefix_in_method_names'
                     ,p_enable_insertion_of_rows VARCHAR2(10 CHAR) path '/options/@p_enable_insertion_of_rows'
                     ,p_enable_update_of_rows VARCHAR2(10 CHAR) path '/options/@p_enable_update_of_rows'
                     ,p_enable_deletion_of_rows VARCHAR2(10 CHAR) path '/options/@p_enable_deletion_of_rows'
                     ,p_enable_generic_change_log VARCHAR2(10 CHAR) path '/options/@p_enable_generic_change_log'
                     ,p_enable_dml_view VARCHAR2(10 CHAR) path '/options/@p_enable_dml_view'
                     ,p_sequence_name VARCHAR2(128 CHAR) path '/options/@p_sequence_name' --
                     ,p_api_name VARCHAR2(128 CHAR) path '/options/@p_api_name'
                     ,p_enable_getter_and_setter VARCHAR2(10 CHAR) path '/options/@p_enable_getter_and_setter'
                     ,p_enable_parameter_prefixes VARCHAR2(10 CHAR) path '/options/@p_enable_parameter_prefixes'
                     ,p_return_row_instead_of_pk VARCHAR2(10 CHAR) path '/options/@p_return_row_instead_of_pk' --
                      ) x)
    SELECT NULL AS errors
          ,ut.table_name
          ,uo.package_name
          ,uo.spec_status
          ,uo.spec_last_ddl_time
          ,uo.body_status
          ,uo.body_last_ddl_time
          ,us.generator
          ,us.generator_version
          ,us.generator_action
          ,us.generated_at
          ,us.generated_by
          ,us.p_table_name
          ,us.p_reuse_existing_api_params
          ,us.p_col_prefix_in_method_names
          ,us.p_enable_insertion_of_rows
          ,us.p_enable_update_of_rows
          ,us.p_enable_deletion_of_rows
          ,us.p_enable_generic_change_log
          ,us.p_enable_dml_view
          ,us.p_sequence_name
          ,us.p_api_name
          ,us.p_enable_getter_and_setter
          ,us.p_enable_parameter_prefixes
          ,us.p_return_row_instead_of_pk
      FROM uo
      LEFT JOIN us
        ON uo.package_name = us.package_name
      LEFT JOIN ut
        ON us.p_table_name = ut.table_name
     WHERE generator = 'OM_TAPIGEN'
       AND CASE
             WHEN pi_table_name IS NULL THEN
              '1'
             ELSE
              ut.table_name
           END = CASE
             WHEN pi_table_name IS NULL THEN
              '1'
             ELSE
              pi_table_name
           END;

  TYPE t_tab_existing_apis IS TABLE OF g_cur_existing_apis%ROWTYPE;

  --
  CURSOR g_cur_naming_conflicts IS
    WITH ut AS
     (SELECT table_name FROM user_tables),
    temp AS
     (SELECT substr(table_name
                   ,1
                   ,26) || '_API' AS object_name
        FROM ut
      UNION ALL
      SELECT substr(table_name
                   ,1
                   ,24) || '_DML_V'
        FROM ut
      UNION ALL
      SELECT substr(table_name
                   ,1
                   ,24) || '_IOIUD'
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
    SELECT uo.object_name
          ,uo.object_type
          ,uo.status
          ,uo.last_ddl_time
      FROM user_objects uo
     WHERE uo.object_name IN (SELECT object_name FROM temp)
     ORDER BY uo.object_name;

  TYPE t_tab_naming_conflicts IS TABLE OF g_cur_naming_conflicts%ROWTYPE;

  --------------------------------------------------------------------------------
  PROCEDURE compile_api
  (
    p_table_name                 IN user_tables.table_name%TYPE
   ,p_reuse_existing_api_params  IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params
   , --if true, the following params are ignored, if API package are already existing and params are extractable from spec source
    p_col_prefix_in_method_names IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names
   ,p_enable_insertion_of_rows   IN BOOLEAN DEFAULT om_tapigen.c_enable_insertion_of_rows
   ,p_enable_update_of_rows      IN BOOLEAN DEFAULT om_tapigen.c_enable_update_of_rows
   ,p_enable_deletion_of_rows    IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows
   ,p_enable_generic_change_log  IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log
   ,p_enable_dml_view            IN BOOLEAN DEFAULT om_tapigen.c_enable_dml_view
   ,p_sequence_name              IN user_sequences.sequence_name%TYPE DEFAULT om_tapigen.c_sequence_name
   ,p_api_name                   IN user_objects.object_name%TYPE DEFAULT om_tapigen.c_api_name
   ,p_enable_getter_and_setter   IN BOOLEAN DEFAULT om_tapigen.c_enable_getter_and_setter
   ,p_enable_parameter_prefixes  IN BOOLEAN DEFAULT om_tapigen.c_enable_parameter_prefixes
   ,p_return_row_instead_of_pk   IN BOOLEAN DEFAULT om_tapigen.c_return_row_instead_of_pk
   ,p_column_defaults            IN xmltype DEFAULT om_tapigen.c_column_defaults
  );

  --------------------------------------------------------------------------------
  FUNCTION compile_api_and_get_code
  (
    p_table_name                 IN user_tables.table_name%TYPE
   ,p_reuse_existing_api_params  IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params
   , --if true, the following params are ignored, if API package are already existing and params are extractable from spec source 
    p_col_prefix_in_method_names IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names
   ,p_enable_insertion_of_rows   IN BOOLEAN DEFAULT om_tapigen.c_enable_insertion_of_rows
   ,p_enable_update_of_rows      IN BOOLEAN DEFAULT om_tapigen.c_enable_update_of_rows
   ,p_enable_deletion_of_rows    IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows
   ,p_enable_generic_change_log  IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log
   ,p_enable_dml_view            IN BOOLEAN DEFAULT om_tapigen.c_enable_dml_view
   ,p_sequence_name              IN user_sequences.sequence_name%TYPE DEFAULT om_tapigen.c_sequence_name
   ,p_api_name                   IN user_objects.object_name%TYPE DEFAULT om_tapigen.c_api_name
   ,p_enable_getter_and_setter   IN BOOLEAN DEFAULT om_tapigen.c_enable_getter_and_setter
   ,p_enable_parameter_prefixes  IN BOOLEAN DEFAULT om_tapigen.c_enable_parameter_prefixes
   ,p_return_row_instead_of_pk   IN BOOLEAN DEFAULT om_tapigen.c_return_row_instead_of_pk
   ,p_column_defaults            IN xmltype DEFAULT om_tapigen.c_column_defaults
  ) RETURN CLOB;

  --------------------------------------------------------------------------------
  FUNCTION get_code
  (
    p_table_name                 IN user_tables.table_name%TYPE
   ,p_reuse_existing_api_params  IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params
   , --if true, the following params are ignored, if API package are already existing and params are extractable from spec source
    p_col_prefix_in_method_names IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names
   ,p_enable_insertion_of_rows   IN BOOLEAN DEFAULT om_tapigen.c_enable_insertion_of_rows
   ,p_enable_update_of_rows      IN BOOLEAN DEFAULT om_tapigen.c_enable_update_of_rows
   ,p_enable_deletion_of_rows    IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows
   ,p_enable_generic_change_log  IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log
   ,p_enable_dml_view            IN BOOLEAN DEFAULT om_tapigen.c_enable_dml_view
   ,p_sequence_name              IN user_sequences.sequence_name%TYPE DEFAULT om_tapigen.c_sequence_name
   ,p_api_name                   IN user_objects.object_name%TYPE DEFAULT om_tapigen.c_api_name
   ,p_enable_getter_and_setter   IN BOOLEAN DEFAULT om_tapigen.c_enable_getter_and_setter
   ,p_enable_parameter_prefixes  IN BOOLEAN DEFAULT om_tapigen.c_enable_parameter_prefixes
   ,p_return_row_instead_of_pk   IN BOOLEAN DEFAULT om_tapigen.c_return_row_instead_of_pk
   ,p_column_defaults            IN xmltype DEFAULT om_tapigen.c_column_defaults
  ) RETURN CLOB;

  --------------------------------------------------------------------------------
  PROCEDURE recreate_existing_apis;

  --------------------------------------------------------------------------------
  FUNCTION view_existing_apis(p_table_name user_tables.table_name%TYPE DEFAULT NULL) RETURN t_tab_existing_apis
    PIPELINED;

  --------------------------------------------------------------------------------
  FUNCTION view_naming_conflicts RETURN t_tab_naming_conflicts
    PIPELINED;
  -------------------------------------------------------------------------------- 

END om_tapigen;
/
