set termout off heading off pagesize 0

SPOOL "employees.pks" replace

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

SPOOL "employees.pkb" replace

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

set termout on heading on pagesize 20