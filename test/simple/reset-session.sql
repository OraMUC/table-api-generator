set termout off
whenever sqlerror continue

-- To reset the session we simply select two times
SELECT * FROM TABLE(om_tapigen.util_view_columns_array);
SELECT * FROM TABLE(om_tapigen.util_view_columns_array);

whenever sqlerror exit sql.sqlcode rollback
set termout on
