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
  dbms_output.put_line('- for table ' || v_table);
  FOR i IN 1..v_cycle LOOP
    v_start  := systimestamp;
    om_tapigen.compile_api(p_table_name => v_table);
    v_act    := extract(SECOND FROM systimestamp - v_start);
    v_sum    := v_sum + v_act;
    dbms_output.put_line('- '
                         || lpad(i, 6)
                         || '. runtime:'
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
  dbms_output.put_line('- minimum runtime:'
                       || to_char(v_min, v_fmt)
                       || ' seconds');
  dbms_output.put_line('- maximum runtime:'
                       || to_char(v_max, v_fmt)
                       || ' seconds');
  dbms_output.put_line('- average runtime:'
                       || to_char(v_avg, v_fmt)
                       || ' seconds');
  dbms_output.put_line('- overall runtime:'
                       || to_char(v_sum, v_fmt)
                       || ' seconds');
END;
/
-- SELECT * FROM TABLE ( om_tapigen.utiv_view_columns_array );