/* FIXME: provide a stable set of test tables and data and start to use utplsql */
BEGIN
  om_tapigen.util_set_debug_on;
  --
--  om_tapigen.compile_api(
--    p_table_name                    => 'EMPLOYEES',
--    p_owner                         => user,
--    p_reuse_existing_api_params     => false,
--    p_enable_insertion_of_rows      => true,
--    p_enable_column_defaults        => true,
--    p_enable_update_of_rows         => true,
--    p_enable_deletion_of_rows       => false,
--    p_enable_parameter_prefixes     => true,
--    p_enable_proc_with_out_params   => true,
--    p_enable_getter_and_setter      => true,
--    p_col_prefix_in_method_names    => true,
--    p_return_row_instead_of_pk      => true,
--    p_enable_dml_view               => true,
--    p_enable_generic_change_log     => true,
--    p_api_name                      => 'EMPLOYEES_API',
--    p_sequence_name                 => 'EMPLOYEES_SEQ',
--    p_exclude_column_list           => 'SALARY,COMMISSION_PCT',
--    p_enable_custom_defaults        => true,
--    p_custom_default_values         => xmltype(q'#
--      <custom_defaults>
--        <column name="JOB_ID"><![CDATA[1]]></column>
--      </custom_defaults>#'
--)
--  );
  om_tapigen.compile_api(
    p_table_name                    => 'EMPLOYEES',
    p_reuse_existing_api_params     => false,
    p_enable_proc_with_out_params   => false,
    p_enable_getter_and_setter      => false,
    p_return_row_instead_of_pk      => false,
    p_enable_dml_view               => false,
    p_enable_generic_change_log     => false,
    p_api_name                      => 'EMPLOYEES_API',
    p_sequence_name                 => 'EMPLOYEES_SEQ',
    p_exclude_column_list           => 'SALARY,COMMISSION_PCT',
    p_enable_custom_defaults        => true,
    p_custom_default_values         => xmltype(q'#
    <custom_defaults>
      <column name="JOB_ID"><![CDATA[1]]></column>
    </custom_defaults>#'
)
  );

--  om_tapigen.compile_api(
--    p_table_name                  => 'COUNTRIES',
--    p_reuse_existing_api_params   => false,
--    p_enable_dml_view             => false,
--    p_enable_generic_change_log   => true,
--    p_sequence_name               => 'COUNTRIES_SEQ'
--  );
--
--  om_tapigen.compile_api(
--    p_table_name                    => 'EMP',
--    p_reuse_existing_api_params     => false,
--    p_enable_insertion_of_rows      => true,
--    p_enable_update_of_rows         => true,
--    p_enable_deletion_of_rows       => true,
--    p_enable_generic_change_log     => true,
--    p_enable_dml_view               => true,
--    p_sequence_name                 => NULL,
--    p_api_name                      => 'EMP_API',
--    p_enable_getter_and_setter      => true,
--    p_col_prefix_in_method_names    => true,
--    p_enable_proc_with_out_params   => true,
--    p_enable_parameter_prefixes     => true,
--    p_return_row_instead_of_pk      => false,
--    p_exclude_column_list           => 'HIREDATE'
--  );
--
--  om_tapigen.compile_api(
--    p_table_name                  => 'DEPT',
--    p_reuse_existing_api_params   => false,
--    p_enable_dml_view             => true
--  );
--
--  om_tapigen.compile_api(
--    p_table_name                  => 'TEST_2',
--    p_reuse_existing_api_params   => false,
--    p_enable_dml_view             => true,
--    p_sequence_name               => 'TEST_2_SEQ'
--  );
--
--  om_tapigen.compile_api(
--    p_table_name                    => 'TEST_TABLE',
--    p_reuse_existing_api_params     => false,
--    p_enable_insertion_of_rows      => true,
--    p_enable_column_defaults        => false,
--    p_enable_update_of_rows         => true,
--    p_enable_deletion_of_rows       => true,
--    p_enable_generic_change_log     => true,
--    p_enable_dml_view               => true,
--    p_sequence_name                 => 'TEST_TABLE_SEQ',
--    p_api_name                      => NULL, --'TEST_TABLE_API',
--    p_exclude_column_list           => 'HIREDATE',
--    p_enable_getter_and_setter      => true,
--    p_col_prefix_in_method_names    => false,
--    p_enable_proc_with_out_params   => true,
--    p_enable_parameter_prefixes     => true,
--    p_return_row_instead_of_pk      => false,
--    p_enable_custom_defaults        => true,
--    p_custom_default_values         => xmltype(q'#
--      <custom_defaults>
--        <column name="TEST_NUMBER"><![CDATA[99]]></column>
--      </custom_defaults>#'
--)
--  );
--
--  om_tapigen.compile_api(
--    p_table_name                    => 'TEST_TABLE_2',
--    p_reuse_existing_api_params     => false,
--    p_enable_insertion_of_rows      => true,
--    p_enable_column_defaults        => true,
--    p_enable_update_of_rows         => true,
--    p_enable_deletion_of_rows       => true,
--    p_enable_generic_change_log     => false,
--    p_enable_dml_view               => true,
--    p_sequence_name                 => 'TEST_TABLE_2_SEQ',
--    p_api_name                      => 'TEST_TABLE_2_API',
--    p_exclude_column_list           => 'HIREDATE',
--    p_enable_proc_with_out_params   => true,
--    p_enable_parameter_prefixes     => true,
--    p_return_row_instead_of_pk      => false,
--    p_enable_getter_and_setter      => true,
--    p_col_prefix_in_method_names    => true,
--    p_enable_custom_defaults        => true,
--    p_custom_default_values         => NULL
--  );

END;
/