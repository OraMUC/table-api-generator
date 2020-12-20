CREATE OR REPLACE PACKAGE om_tapigen_oddgen_wrapper AUTHID CURRENT_USER IS
  SUBTYPE string_type IS VARCHAR2(4000 CHAR);
  SUBTYPE param_type IS VARCHAR2(100 CHAR);
  TYPE t_string IS TABLE OF string_type;
  TYPE t_param IS TABLE OF string_type INDEX BY param_type;
  TYPE t_lov IS TABLE OF t_string INDEX BY param_type;
  FUNCTION get_name RETURN VARCHAR2;

  FUNCTION get_description RETURN VARCHAR2;

  FUNCTION get_object_types RETURN t_string;

  FUNCTION get_params RETURN t_param;

  FUNCTION get_ordered_params RETURN t_string;

  FUNCTION get_lov RETURN t_lov;

  FUNCTION generate
  (
    in_object_type IN VARCHAR2,
    in_object_name IN VARCHAR2,
    in_params      IN t_param
  ) RETURN CLOB;

END om_tapigen_oddgen_wrapper;
/
