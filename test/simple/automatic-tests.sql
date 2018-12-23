set define off verify off feedback off trimout on trimspool on pagesize 100 linesize 5000 long 1000000 longchunksize 1000000
whenever sqlerror exit sql.sqlcode rollback

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

prompt
prompt
prompt RUN TESTS FOR HR TABLES
prompt Reset session...
@reset-session.sql;
prompt ==============================
prompt COUNTRIES
prompt Generate API...
@hr/countries-1-generate-api.sql;
prompt Insert 3 rows...
@hr/countries-2-insert-3-rows.sql;
prompt Export API to files...
@hr/countries-3-export-api-to-file.sql;
prompt ==============================
prompt DEPARTMENTS
prompt Generate API...
@hr/departments-1-generate-api.sql;
prompt Insert 3 rows...
@hr/departments-2-insert-3-rows.sql;
prompt Export API to files...
@hr/departments-3-export-api-to-file.sql;
prompt ==============================
prompt LOCATIONS
prompt Generate API...
@hr/locations-1-generate-api.sql;
prompt Insert 3 rows...
@hr/locations-2-insert-3-rows.sql;
prompt Export API to files...
@hr/locations-3-export-api-to-file.sql;
prompt ==============================
prompt REGIONS
prompt Generate API...
@hr/regions-1-generate-api.sql;
prompt Insert 3 rows...
@hr/regions-2-insert-3-rows.sql;
prompt Export API to files...
@hr/regions-3-export-api-to-file.sql;
prompt ==============================
prompt JOBS
prompt Generate API...
@hr/jobs-1-generate-api.sql;
prompt Insert 3 rows...
@hr/jobs-2-insert-3-rows.sql;
prompt Export API to files...
@hr/jobs-3-export-api-to-file.sql;
prompt ==============================
prompt EMPLOYEES
prompt Generate API...
@hr/employees-1-generate-api.sql;
prompt Insert 3 rows...
@hr/employees-2-insert-3-rows.sql;
prompt Export API to files...
@hr/employees-3-export-api-to-file.sql;
prompt ==============================
prompt Done :-)
prompt
prompt

set define on verify on feedback on
