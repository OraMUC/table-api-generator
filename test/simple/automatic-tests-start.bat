echo off
rem https://stackoverflow.com/questions/12021033/how-do-i-request-and-receive-user-input-in-a-bat-and-use-it-to-run-a-certain-pr

set NLS_LANG=AMERICAN_AMERICA.AL32UTF8
rem set /p password_db_user=Please enter password for hr on localhost:
echo exit | sqlplus hr/oracle@localhost:1521/xe @automatic-tests.sql
