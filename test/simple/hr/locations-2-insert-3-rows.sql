DECLARE
  PRAGMA autonomous_transaction; -- we need this to ensure LOCATIONS_api is initialized
BEGIN
  FOR i IN 1..3 LOOP
    LOCATIONS_api.create_a_row;
  END LOOP;
  ROLLBACK;
END;
/