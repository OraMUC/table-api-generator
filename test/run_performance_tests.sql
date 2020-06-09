prompt RUN PERFORMANCE TESTS
   SET SERVEROUTPUT ON
DECLARE
  v_table  VARCHAR2(128 CHAR) := '&1';
  v_cycle  INTEGER := &2;
  v_start  TIMESTAMP;
  v_fmt    VARCHAR2(10 CHAR) := '990D000';
  v_act    NUMBER;
  v_min    NUMBER := 1000;
  v_max    NUMBER := 0;
  v_sum    NUMBER := 0;
  v_avg    NUMBER;
BEGIN
  dbms_output.put_line('- compile ' || v_cycle || ' times the API for table ' || v_table);
  FOR i IN 1..v_cycle LOOP
    v_start  := systimestamp;
    om_tapigen.compile_api(
      p_table_name                 => v_table,
      p_enable_insertion_of_rows   => true,
      p_enable_update_of_rows      => true,
      p_enable_deletion_of_rows    => true,
      p_enable_dml_view            => true,
      p_enable_one_to_one_view     => true,
      p_enable_custom_defaults     => true,
      p_double_quote_names         => true,
      p_row_version_column_mapping => '#PREFIX#_VERSION_ID=tag_global_version_sequence.nextval',
      p_audit_column_mappings      => 'created=#PREFIX#_CREATED_ON, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED_AT, updated_by=#PREFIX#_UPDATED_BY'
    );
    v_act    := extract(SECOND FROM systimestamp - v_start);
    v_sum    := v_sum + v_act;
    dbms_output.put_line('- '
                         || lpad(i, 3)
                         || ':'
                         || to_char(v_act, v_fmt)
                         || ' seconds');
    IF v_act < v_min THEN
      v_min := v_act;
    END IF;
    IF v_act > v_max THEN
      v_max := v_act;
    END IF;
  END LOOP;
  v_avg := v_sum / v_cycle;
  dbms_output.put_line('----------------------');
  dbms_output.put_line('- min:' || to_char(v_min, v_fmt) || ' seconds');
  dbms_output.put_line('- max:' || to_char(v_max, v_fmt) || ' seconds');
  dbms_output.put_line('- avg:' || to_char(v_avg, v_fmt) || ' seconds');
  dbms_output.put_line('- sum:' || to_char(v_sum, v_fmt) || ' seconds');
END;
/
-- SELECT * FROM TABLE ( om_tapigen.utiv_view_columns_array );