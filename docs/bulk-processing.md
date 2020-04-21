# Bulk Processing

-- Example 1:

DECLARE
  v_ref_cursor example_api.t_all_cols_ref_cursor;
  v_rows_tab   example_api.t_rows_tab;
BEGIN
  -- selection of data
  OPEN v_ref_cursor FOR SELECT * FROM t_applied_irev;

  -- optionally set bulk size, if other chunksize than 10.000 is required
  example_api.set_bulk_limit(p_bulk_limit => 42);

  -- manipulation of data, don't forget the loop to process all data!
  LOOP
    v_rows_tab := example_api.read_rows_bulk(p_ref_cursor => v_ref_cursor);

    -- business logic based on collection comes here...
    -- e.g. update the data

    EXIT WHEN example_api.g_bulk_completed;
  END LOOP;

  CLOSE v_ref_cursor;
END;
/


Ein konkretes Beispiel für einen Bulk update, zum Beispiel auf Employees wäre:

DECLARE
  v_strong_ref_cursor employees_api.t_strong_ref_cursor;
  v_rows_tab          employees_api.t_rows_tab;
BEGIN
  OPEN v_strong_ref_cursor FOR SELECT * FROM employees;

  LOOP
    v_rows_tab := employees_api.read_rows(p_ref_cursor => v_strong_ref_cursor);

    -- do some business logic here by using collection v_rows_tab (nested table)

    FOR i IN 1 .. v_rows_tab.COUNT
    LOOP
      v_rows_tab(i).phone_number := RTRIM(v_rows_tab(i).phone_number, '6');
    END LOOP;

    employees_api.update_rows(p_rows_tab => v_rows_tab);

    EXIT WHEN employees_api.bulk_is_complete;
  END LOOP;

  CLOSE v_strong_ref_cursor;
END;
/