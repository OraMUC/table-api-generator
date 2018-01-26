CREATE OR REPLACE PACKAGE om_tapigen AUTHID CURRENT_USER IS
  /*
  THIS IS A TABLE API GENERATOR
  Source and documentation: github.com/OraMUC/table-api-generator
  
  The MIT License (MIT)
  
  Copyright (c) 2015-2018 André Borngräber, Ottmar Gobrecht
  
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
  c_generator_version CONSTANT VARCHAR2(10 CHAR) := '0.5.0_b2';
  c_ora_max_name_len  CONSTANT INTEGER :=$IF dbms_db_version.ver_le_12_1 $THEN
   30
                                         $ELSE
                                          ora_max_name_len
  $END
  ;

  -- parameter defaults
  c_reuse_existing_api_params CONSTANT BOOLEAN := TRUE;
  --^ if true, all other parameters except p_owner and p_table_name are ignored when API package is already existing and params are extractable from spec source
  c_enable_insertion_of_rows    CONSTANT BOOLEAN := TRUE;
  c_enable_column_defaults      CONSTANT BOOLEAN := FALSE;
  c_enable_update_of_rows       CONSTANT BOOLEAN := TRUE;
  c_enable_deletion_of_rows     CONSTANT BOOLEAN := FALSE;
  c_enable_parameter_prefixes   CONSTANT BOOLEAN := TRUE;
  c_enable_proc_with_out_params CONSTANT BOOLEAN := TRUE;
  c_enable_getter_and_setter    CONSTANT BOOLEAN := TRUE;
  c_col_prefix_in_method_names  CONSTANT BOOLEAN := TRUE; -- only relevant, when p_enable_getter_and_setter is true
  c_return_row_instead_of_pk    CONSTANT BOOLEAN := FALSE;
  c_enable_dml_view             CONSTANT BOOLEAN := FALSE;
  c_enable_generic_change_log   CONSTANT BOOLEAN := FALSE;
  c_api_name                    CONSTANT VARCHAR2(1 CHAR) := NULL;
  c_sequence_name               CONSTANT VARCHAR2(1 CHAR) := NULL;
  c_exclude_column_list         CONSTANT VARCHAR2(4000 CHAR) := NULL;
  c_enable_custom_defaults      CONSTANT BOOLEAN := FALSE;
  c_custom_default_values       CONSTANT xmltype := NULL;

  -----------------------------------------------------------------------------
  -- Subtypes
  -----------------------------------------------------------------------------
  SUBTYPE session_module IS VARCHAR2(48); --MODULE is limited to 48 bytes - see also: https://mwidlake.wordpress.com/2012/09/03/dbms_application_info-for-instrumentation/
  SUBTYPE session_action IS VARCHAR2(32); --ACTION is limited to 32 bytes

  -----------------------------------------------------------------------------
  -- public record (t_rec_*) and collection (tab_*) types
  -----------------------------------------------------------------------------
  TYPE t_tab_vc2 IS TABLE OF VARCHAR2(4000);

  TYPE t_rec_existing_apis IS RECORD(
    errors                        VARCHAR2(4000 CHAR),
    owner                         all_users.username%TYPE,
    table_name                    all_objects.object_name%TYPE,
    package_name                  all_objects.object_name%TYPE,
    spec_status                   all_objects.status%TYPE,
    spec_last_ddl_time            all_objects.last_ddl_time%TYPE,
    body_status                   all_objects.status%TYPE,
    body_last_ddl_time            all_objects.last_ddl_time%TYPE,
    generator                     VARCHAR2(10 CHAR),
    generator_version             VARCHAR2(10 CHAR),
    generator_action              VARCHAR2(24 CHAR),
    generated_at                  DATE,
    generated_by                  all_users.username%TYPE,
    p_owner                       all_users.username%TYPE,
    p_table_name                  all_objects.object_name%TYPE,
    p_reuse_existing_api_params   VARCHAR2(5 CHAR),
    p_enable_insertion_of_rows    VARCHAR2(5 CHAR),
    p_enable_column_defaults      VARCHAR2(5 CHAR),
    p_enable_update_of_rows       VARCHAR2(5 CHAR),
    p_enable_deletion_of_rows     VARCHAR2(5 CHAR),
    p_enable_parameter_prefixes   VARCHAR2(5 CHAR),
    p_enable_proc_with_out_params VARCHAR2(5 CHAR),
    p_enable_getter_and_setter    VARCHAR2(5 CHAR),
    p_col_prefix_in_method_names  VARCHAR2(5 CHAR),
    p_return_row_instead_of_pk    VARCHAR2(5 CHAR),
    p_enable_dml_view             VARCHAR2(5 CHAR),
    p_enable_generic_change_log   VARCHAR2(5 CHAR),
    p_api_name                    all_objects.object_name%TYPE,
    p_sequence_name               all_objects.object_name%TYPE,
    p_exclude_column_list         VARCHAR2(4000 CHAR),
    p_enable_custom_defaults      VARCHAR2(5 CHAR),
    p_custom_default_values       VARCHAR2(30 CHAR));

  TYPE t_tab_existing_apis IS TABLE OF t_rec_existing_apis;

  TYPE t_rec_naming_conflicts IS RECORD(
    object_name   all_objects.object_name%TYPE,
    object_type   all_objects.object_type%TYPE,
    status        all_objects.status%TYPE,
    last_ddl_time all_objects.last_ddl_time%TYPE);

  TYPE t_tab_naming_conflicts IS TABLE OF t_rec_naming_conflicts;

  TYPE t_rec_debug_data IS RECORD(
    run        INTEGER,
    run_time   NUMBER,
    owner      all_users.username%TYPE,
    table_name all_objects.object_name%TYPE,
    step       INTEGER,
    elapsed    NUMBER,
    execution  NUMBER,
    action     session_action,
    start_time TIMESTAMP(6));

  TYPE t_tab_debug_data IS TABLE OF t_rec_debug_data;

  --------------------------------------------------------------------------------
  PROCEDURE compile_api(p_table_name                IN all_objects.object_name%TYPE,
                        p_owner                     IN all_users.username%TYPE DEFAULT USER,
                        p_reuse_existing_api_params IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params,
                        --^ if true, the following params are ignored when API package is already existing and params are extractable from spec source
                        p_enable_insertion_of_rows    IN BOOLEAN DEFAULT om_tapigen.c_enable_insertion_of_rows,
                        p_enable_column_defaults      IN BOOLEAN DEFAULT om_tapigen.c_enable_column_defaults,
                        p_enable_update_of_rows       IN BOOLEAN DEFAULT om_tapigen.c_enable_update_of_rows,
                        p_enable_deletion_of_rows     IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows,
                        p_enable_parameter_prefixes   IN BOOLEAN DEFAULT om_tapigen.c_enable_parameter_prefixes,
                        p_enable_proc_with_out_params IN BOOLEAN DEFAULT om_tapigen.c_enable_proc_with_out_params,
                        p_enable_getter_and_setter    IN BOOLEAN DEFAULT om_tapigen.c_enable_getter_and_setter,
                        p_col_prefix_in_method_names  IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names,
                        p_return_row_instead_of_pk    IN BOOLEAN DEFAULT om_tapigen.c_return_row_instead_of_pk,
                        p_enable_dml_view             IN BOOLEAN DEFAULT om_tapigen.c_enable_dml_view,
                        p_enable_generic_change_log   IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log,
                        p_api_name                    IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_api_name,
                        p_sequence_name               IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_sequence_name,
                        p_exclude_column_list         IN VARCHAR2 DEFAULT om_tapigen.c_exclude_column_list,
                        p_enable_custom_defaults      IN BOOLEAN DEFAULT om_tapigen.c_enable_custom_defaults,
                        p_custom_default_values       IN xmltype DEFAULT om_tapigen.c_custom_default_values);

  --------------------------------------------------------------------------------

  FUNCTION compile_api_and_get_code(p_table_name                IN all_objects.object_name%TYPE,
                                    p_owner                     IN all_users.username%TYPE DEFAULT USER,
                                    p_reuse_existing_api_params IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params,
                                    --^ if true, the following params are ignored when API package is already existing and params are extractable from spec source
                                    p_enable_insertion_of_rows    IN BOOLEAN DEFAULT om_tapigen.c_enable_insertion_of_rows,
                                    p_enable_column_defaults      IN BOOLEAN DEFAULT om_tapigen.c_enable_column_defaults,
                                    p_enable_update_of_rows       IN BOOLEAN DEFAULT om_tapigen.c_enable_update_of_rows,
                                    p_enable_deletion_of_rows     IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows,
                                    p_enable_parameter_prefixes   IN BOOLEAN DEFAULT om_tapigen.c_enable_parameter_prefixes,
                                    p_enable_proc_with_out_params IN BOOLEAN DEFAULT om_tapigen.c_enable_proc_with_out_params,
                                    p_enable_getter_and_setter    IN BOOLEAN DEFAULT om_tapigen.c_enable_getter_and_setter,
                                    p_col_prefix_in_method_names  IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names,
                                    p_return_row_instead_of_pk    IN BOOLEAN DEFAULT om_tapigen.c_return_row_instead_of_pk,
                                    p_enable_dml_view             IN BOOLEAN DEFAULT om_tapigen.c_enable_dml_view,
                                    p_enable_generic_change_log   IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log,
                                    p_api_name                    IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_api_name,
                                    p_sequence_name               IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_sequence_name,
                                    p_exclude_column_list         IN VARCHAR2 DEFAULT om_tapigen.c_exclude_column_list,
                                    p_enable_custom_defaults      IN BOOLEAN DEFAULT om_tapigen.c_enable_custom_defaults,
                                    p_custom_default_values       IN xmltype DEFAULT om_tapigen.c_custom_default_values)
    RETURN CLOB;

  --------------------------------------------------------------------------------

  FUNCTION get_code(p_table_name                IN all_objects.object_name%TYPE,
                    p_owner                     IN all_users.username%TYPE DEFAULT USER,
                    p_reuse_existing_api_params IN BOOLEAN DEFAULT om_tapigen.c_reuse_existing_api_params,
                    --^ if true, the following params are ignored when API package is already existing and params are extractable from spec source
                    p_enable_insertion_of_rows    IN BOOLEAN DEFAULT om_tapigen.c_enable_insertion_of_rows,
                    p_enable_column_defaults      IN BOOLEAN DEFAULT om_tapigen.c_enable_column_defaults,
                    p_enable_update_of_rows       IN BOOLEAN DEFAULT om_tapigen.c_enable_update_of_rows,
                    p_enable_deletion_of_rows     IN BOOLEAN DEFAULT om_tapigen.c_enable_deletion_of_rows,
                    p_enable_parameter_prefixes   IN BOOLEAN DEFAULT om_tapigen.c_enable_parameter_prefixes,
                    p_enable_proc_with_out_params IN BOOLEAN DEFAULT om_tapigen.c_enable_proc_with_out_params,
                    p_enable_getter_and_setter    IN BOOLEAN DEFAULT om_tapigen.c_enable_getter_and_setter,
                    p_col_prefix_in_method_names  IN BOOLEAN DEFAULT om_tapigen.c_col_prefix_in_method_names,
                    p_return_row_instead_of_pk    IN BOOLEAN DEFAULT om_tapigen.c_return_row_instead_of_pk,
                    p_enable_dml_view             IN BOOLEAN DEFAULT om_tapigen.c_enable_dml_view,
                    p_enable_generic_change_log   IN BOOLEAN DEFAULT om_tapigen.c_enable_generic_change_log,
                    p_api_name                    IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_api_name,
                    p_sequence_name               IN all_objects.object_name%TYPE DEFAULT om_tapigen.c_sequence_name,
                    p_exclude_column_list         IN VARCHAR2 DEFAULT om_tapigen.c_exclude_column_list,
                    p_enable_custom_defaults      IN BOOLEAN DEFAULT om_tapigen.c_enable_custom_defaults,
                    p_custom_default_values       IN xmltype DEFAULT om_tapigen.c_custom_default_values) RETURN CLOB;

  --------------------------------------------------------------------------------
  -- A one liner to recreate all APIs in the current (or another) schema with
  -- the original call parameters (read from the package specs):
  -- EXEC om_tapigen.recreate_existing_apis;

  PROCEDURE recreate_existing_apis(p_owner IN all_users.username%TYPE DEFAULT USER);

  --------------------------------------------------------------------------------
  -- A helper function (pipelined) to list all APIs generated by om_tapigen:
  -- SELECT * FROM TABLE (om_tapigen.view_existing_apis);

  FUNCTION view_existing_apis(p_table_name all_tables.table_name%TYPE DEFAULT NULL,
                              p_owner      all_users.username%TYPE DEFAULT USER) RETURN t_tab_existing_apis
    PIPELINED;

  --------------------------------------------------------------------------------
  -- A helper to ckeck possible naming conflicts before the first usage of the API generator:
  -- SELECT * FROM TABLE (om_tapigen.view_naming_conflicts);
  -- No rows expected. After you generated some APIs there will be results ;-)

  FUNCTION view_naming_conflicts(p_owner all_users.username%TYPE DEFAULT USER) RETURN t_tab_naming_conflicts
    PIPELINED;

  --------------------------------------------------------------------------------
  -- Working with long columns: http://www.oracle-developer.net/display.php?id=430
  -- The following helper function is needed to read a column data default from the dictionary:

  FUNCTION util_get_column_data_default(p_table_name  IN VARCHAR2,
                                        p_column_name IN VARCHAR2,
                                        p_owner       VARCHAR2 DEFAULT USER) RETURN VARCHAR2;

  --------------------------------------------------------------------------------
  -- Working with long columns: http://www.oracle-developer.net/display.php?id=430
  -- The following helper function is needed to read a constraint search condition from the dictionary:
  -- (not needed in 12cR1 and above, there we have a column search_condition_vc in user_constraints)

  FUNCTION util_get_cons_search_condition(p_constraint_name IN VARCHAR2,
                                          p_owner           IN VARCHAR2 DEFAULT USER) RETURN VARCHAR2;

  --------------------------------------------------------------------------------
  -- A table function to split a string to a selectable table
  -- Usage: SELECT COLUMN_VALUE FROM TABLE (om_tapigen.util_split_to_table('1,2,3,test'));

  FUNCTION util_split_to_table(p_string    IN VARCHAR2,
                               p_delimiter IN VARCHAR2 DEFAULT ',') RETURN t_tab_vc2
    PIPELINED;

  --------------------------------------------------------------------------------
  -- A function to determine the maximum length for an identifier name (e.g. column name) 

  FUNCTION util_get_ora_max_name_len RETURN INTEGER;

  --------------------------------------------------------------------------------
  -- A procedure to enable (and reset) the debugging (previous debug data will be lost)
  PROCEDURE util_set_debug_on;

  --------------------------------------------------------------------------------
  -- A procedure to disable debugging
  PROCEDURE util_set_debug_off;

  --------------------------------------------------------------------------------
  -- A procedure to view the debug details. Maximum 999 API creations are captured
  -- for memory reasons. You can reset the debugging by calling om_tapigen.util_set_debug_on.
  -- Example: SELECT * FROM TABLE(om_tapigen.util_view_debug);
  FUNCTION util_view_debug_log RETURN t_tab_debug_data
    PIPELINED;

END om_tapigen;
/
