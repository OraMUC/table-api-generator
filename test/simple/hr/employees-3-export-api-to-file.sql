set termout off heading off pagesize 0 

SPOOL "hr/employees.pks" replace

SELECT
  text
FROM
  user_source
WHERE
  type = 'PACKAGE'
  AND   name = 'EMPLOYEES_API'
ORDER BY
  line;

SPOOL OFF

SPOOL "hr/employees.pkb" replace

SELECT
  text
FROM
  user_source
WHERE
  type = 'PACKAGE BODY'
  AND   name = 'EMPLOYEES_API'
ORDER BY
  line;

SPOOL OFF

set termout on heading on pagesize 100