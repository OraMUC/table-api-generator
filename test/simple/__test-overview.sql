-- Standard test - runs all script files with the prefix "test-" 
-- and outputs the API to files for inspection in other editors.
@_test-run-all.sql;

-- Regenerate all APIs in the current schema
BEGIN
  om_tapigen.util_set_debug_on;
  om_tapigen.recreate_existing_apis;
END;
/

-- checks API status
SELECT * FROM TABLE(om_tapigen.view_existing_apis) order by spec_last_ddl_time desc;

-- check internal columns array
SELECT * FROM TABLE(om_tapigen.util_view_columns_array);

-- some debug checks
SELECT * FROM TABLE(om_tapigen.util_view_debug_log);
SELECT * FROM TABLE(om_tapigen.util_view_debug_log) WHERE run = 6;
SELECT * FROM TABLE(om_tapigen.util_view_debug_log) WHERE action != 'compile' ORDER BY execution DESC;
SELECT * FROM TABLE(om_tapigen.util_view_debug_log) WHERE action = 'fetch_columns';
SELECT * FROM TABLE(om_tapigen.util_view_debug_log) WHERE table_name = 'TEST_TABLE_2' ORDER BY execution DESC;

-- check overall run time (should take around 0.1 - 0.3 seconds on a warmed up system for a normal table like emp, dept, employees...)
SELECT run, 
       run_time, 
       table_name, 
       to_char(min(start_time),'hh24:mi:ss') as start_time
  FROM TABLE(om_tapigen.util_view_debug_log) 
 GROUP BY run, run_time, table_name
 ORDER BY run_time DESC;
 
-- check if we have any unmessured time (missing debug calls or overhead)
SELECT run,
       table_name,
       run_time, 
       sum(execution) as sum_execution, 
       run_time - sum(execution) as unmessured_time
  FROM TABLE(om_tapigen.util_view_debug_log) 
 GROUP BY run, table_name, run_time;