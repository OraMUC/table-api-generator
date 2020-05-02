CREATE OR REPLACE PACKAGE test_om_tapigen IS
/*

README
======

Run The Test As SQL Statement

    select * from table(ut.run('test_om_tapigen'));

Prerequisits
------------

The following system priviliges are needed to run successfully the tests:

- CREATE PROCEDURE
- CREATE SEQUENCE
- CREATE TABLE
- CREATE TRIGGER
- CREATE VIEW

*/

--%suite(OraMUC Table API Generator)
--%rollback(manual)

--%beforeall
procedure drop_objects_and_create_tables;

--%afterall
procedure drop_objects(p_only_if_all_valid boolean default true);

--%test
procedure compile_apis_with_defaults;

function get_list_of_invalid_objects return varchar2;

END test_om_tapigen;
/
