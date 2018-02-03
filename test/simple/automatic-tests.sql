set define off verify off feedback off pagesize 100 linesize 5000 wrap off trimout on trimspool on
whenever sqlerror exit sql.sqlcode rollback

prompt
prompt
prompt RUN TESTS FOR HR TABLES
prompt Reset session...
@reset-session.sql
prompt ==============================
prompt COUNTRIES
prompt Generate API...
@hr/countries-1-generate-api.sql
prompt Insert 10 rows...
@hr/countries-2-insert-10-rows.sql
prompt Export API to files...
@hr/countries-3-export-api-to-file.sql
prompt ==============================
prompt DEPARTMENTS
prompt Generate API...
@hr/departments-1-generate-api.sql
prompt Insert 10 rows...
@hr/departments-2-insert-10-rows.sql
prompt Export API to files...
@hr/departments-3-export-api-to-file.sql
prompt ==============================
prompt EMPLOYEES
prompt Generate API...
@hr/employees-1-generate-api.sql
prompt Insert 10 rows...
@hr/employees-2-insert-10-rows.sql
prompt Export API to files...
@hr/employees-3-export-api-to-file.sql
prompt ==============================
prompt Done :-)
prompt
prompt

set define on verify on feedback on
