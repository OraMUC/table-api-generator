DECLARE
  PRAGMA autonomous_transaction; -- we need this to ensure employees_api is initialized
BEGIN
  FOR i IN 1..10 LOOP
    DEPARTMENTS_api.create_a_row;
  END LOOP;
  ROLLBACK;
END;
/