prompt RUN PERFORMANCE TESTS
   SET SERVEROUTPUT ON
DECLARE
  l_table  VARCHAR2(128 CHAR) := '&1';
  l_cycle  INTEGER := &2;
  l_start  NUMBER;
  l_act    NUMBER;
  l_min    NUMBER := 100000;
  l_max    NUMBER := 0;
  l_sum    NUMBER := 0;
  l_avg    NUMBER;
BEGIN
  dbms_output.put_line('- for table ' || l_table);
  FOR i IN 1..l_cycle LOOP
    l_start  := dbms_utility.get_time;
    om_tapigen.compile_api(p_table_name => 'TAG_TENANT_INVISIBLE');
    l_act    := dbms_utility.get_time - l_start;
    l_sum    := l_sum + l_act;
    dbms_output.put_line('- '
                         || lpad(i, 6)
                         || '. runtime: '
                         || trim(to_char(l_act / 100, '990D000'))
                         || ' seconds');
    IF l_act < l_min THEN
      l_min := l_act;
    END IF;
    IF l_act > l_max THEN
      l_max := l_act;
    END IF;
  END LOOP;
  l_avg := l_sum / l_cycle;
  dbms_output.put_line('- minimum runtime: '
                       || trim(to_char(l_min / 100, '990D000'))
                       || ' seconds');
  dbms_output.put_line('- maximum runtime: '
                       || trim(to_char(l_max / 100, '990D000'))
                       || ' seconds');
  dbms_output.put_line('- average runtime: '
                       || trim(to_char(l_avg / 100, '990D000'))
                       || ' seconds');
  dbms_output.put_line('- overall runtime: '
                       || trim(to_char(l_sum / 100, '990D000'))
                       || ' seconds');
END;
/
-- SELECT * FROM TABLE ( om_tapigen.util_view_columns_array );