/* FIXME: provide a stable set of test tables and data and start to use utplsql */

BEGIN
    om_tapigen.util_set_debug_on;

  om_tapigen.compile_api(p_table_name                => 'COUNTRIES',
                         p_reuse_existing_api_params => FALSE,
                         p_enable_dml_view           => false,
                         p_enable_generic_change_log => TRUE,
                         p_sequence_name             => 'COUNTRIES_SEQ');

  om_tapigen.compile_api(p_table_name                  => 'EMP',
                         p_reuse_existing_api_params   => FALSE,
                         p_enable_insertion_of_rows    => TRUE,
                         p_enable_update_of_rows       => TRUE,
                         p_enable_deletion_of_rows     => TRUE,
                         p_enable_generic_change_log   => TRUE,
                         p_enable_dml_view             => TRUE,
                         p_sequence_name               => NULL,
                         p_api_name                    => 'EMP_API',
                         p_enable_getter_and_setter    => TRUE,
                         p_col_prefix_in_method_names  => true,
                         p_enable_proc_with_out_params => TRUE,
                         p_enable_parameter_prefixes   => TRUE,
                         p_return_row_instead_of_pk    => FALSE,
                         p_exclude_column_list         => 'HIREDATE'
                         --,p_custom_default_values        => om_tapigen.util_get_custom_col_defaults('EMP')
                         );
                         
  om_tapigen.compile_api(p_table_name                => 'DEPT',
                         p_reuse_existing_api_params => FALSE,
                         p_enable_dml_view           => TRUE);

  om_tapigen.compile_api(p_table_name                  => 'EMPLOYEES',
                         p_reuse_existing_api_params   => FALSE,
                         p_enable_insertion_of_rows    => TRUE,
                         p_enable_column_defaults      => TRUE,
                         p_enable_update_of_rows       => TRUE,
                         p_enable_deletion_of_rows     => FALSE,
                         p_enable_generic_change_log   => TRUE,
                         p_enable_dml_view             => TRUE,
                         p_sequence_name               => 'EMPLOYEES_SEQ',
                         p_api_name                    => 'EMPLOYEES_API',
                         p_exclude_column_list         => 'SALARY,COMMISSION_PCT',
                         p_enable_parameter_prefixes   => TRUE,
                         p_enable_getter_and_setter    => TRUE,
                         p_col_prefix_in_method_names  => TRUE,
                         p_enable_proc_with_out_params => TRUE,
                         p_return_row_instead_of_pk    => TRUE,
                         p_enable_custom_defaults      => FALSE
                         --,p_custom_default_values        => om_tapigen.util_get_custom_col_defaults('EMPLOYEES')
                         );

  om_tapigen.compile_api(p_table_name                => 'TEST_2',
                         p_reuse_existing_api_params => FALSE,
                         p_enable_dml_view           => TRUE,
                         p_sequence_name             => 'TEST_2_SEQ');

  om_tapigen.compile_api(
    p_table_name                  => 'TEST_TABLE',
    p_reuse_existing_api_params   => FALSE,
    p_enable_insertion_of_rows    => TRUE,
    p_enable_column_defaults      => false,
    p_enable_update_of_rows       => TRUE,
    p_enable_deletion_of_rows     => TRUE,
    p_enable_generic_change_log   => TRUE,
    p_enable_dml_view             => TRUE,
    p_sequence_name               => 'TEST_TABLE_SEQ',
    p_api_name                    => null, --'TEST_TABLE_API',
    p_exclude_column_list         => 'HIREDATE',
    p_enable_getter_and_setter    => TRUE,
    p_col_prefix_in_method_names  => false,
    p_enable_proc_with_out_params => TRUE,
    p_enable_parameter_prefixes   => TRUE,
    p_return_row_instead_of_pk    => FALSE,
    p_enable_custom_defaults      => true,
    p_custom_default_values       => xmltype(q'{
        <custom_defaults>
          <column name="TEST_NUMBER"><![CDATA[99]]></column>
        </custom_defaults>}')
                         );

  om_tapigen.compile_api(p_table_name                  => 'TEST_TABLE_2',
                         p_reuse_existing_api_params   => FALSE,
                         p_enable_insertion_of_rows    => TRUE,
                         p_enable_column_defaults      => TRUE,
                         p_enable_update_of_rows       => TRUE,
                         p_enable_deletion_of_rows     => TRUE,
                         p_enable_generic_change_log   => FALSE,
                         p_enable_dml_view             => TRUE,
                         p_sequence_name               => 'TEST_TABLE_2_SEQ',
                         p_api_name                    => 'TEST_TABLE_2_API',
                         p_exclude_column_list         => 'HIREDATE',
                         p_enable_proc_with_out_params => TRUE,
                         p_enable_parameter_prefixes   => TRUE,
                         p_return_row_instead_of_pk    => FALSE,
                         p_enable_getter_and_setter    => TRUE,
                         p_col_prefix_in_method_names  => TRUE,
                         p_enable_custom_defaults      => TRUE,
                         p_custom_default_values       => NULL);
END;
/

