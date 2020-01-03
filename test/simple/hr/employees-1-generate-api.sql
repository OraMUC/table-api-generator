DECLARE
  v_count   PLS_INTEGER;
  PRAGMA autonomous_transaction; -- we need this to ensure om_tapigen is initialized
BEGIN
  om_tapigen.util_set_debug_on;
  om_tapigen.compile_api(
    p_table_name                    => 'EMPLOYEES',
    p_reuse_existing_api_params     => false,
    p_enable_column_defaults        => true,
    p_enable_proc_with_out_params   => false,
    p_enable_getter_and_setter      => false,
    p_return_row_instead_of_pk      => true,
    p_enable_dml_view               => true,
    p_enable_generic_change_log     => true,
    p_api_name                      => 'EMPLOYEES_API',
    p_sequence_name                 => 'EMPLOYEES_SEQ',
    --> Generate additional methods (mainly for testing and dummy data generation):
    --> get_a_row, create_a_row, read_a_row
    p_enable_custom_defaults        => true, 
    p_custom_default_values         => xmltype(q'[
      <custom_defaults>
        <column name="SALARY"><![CDATA[round(dbms_random.value(1000,10000),2)]]></column>
      </custom_defaults>
    ]'),
    p_enable_bulk_methods           => TRUE);

  SELECT
    COUNT(*)
  INTO
    v_count
  FROM
    TABLE ( om_tapigen.view_existing_apis )
  WHERE table_name = 'EMPLOYEES'
    AND spec_status = 'VALID'
    AND body_status = 'VALID';

  IF
    v_count = 0
  THEN
    raise_application_error(
      -20000,
      'Package is invalid'
    );
  END IF;
END;
/