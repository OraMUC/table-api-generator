prompt VIEW COLUMNS ARRAY

column column_name            format A20
column data_type              format A20
column char_length            format A20
column data_length            format A20
column data_precision         format A20
column data_scale             format A20
column data_default           format A20
column data_custom_default    format A20
column custom_default_source  format A20
column identity_type          format A20
column default_on_null_yn     format A20
column is_pk_yn               format A20
column is_uk_yn               format A20
column is_fk_yn               format A20
column is_nullable_yn         format A20
column is_hidden_yn           format A20
column is_virtual_yn          format A20
column is_excluded_yn         format A20
column audit_type             format A20
column row_version_expression format A20
column tenant_expression      format A20
column r_owner                format A20
column r_table_name           format A20
column r_column_name          format A20

SELECT column_name,
       data_type,
       char_length,
       data_length,
       data_precision,
       data_scale,
       data_default,
       data_custom_default,
       custom_default_source,
       identity_type,
       default_on_null_yn,
       is_pk_yn,
       is_uk_yn,
       is_fk_yn,
       is_nullable_yn,
       is_hidden_yn,
       is_virtual_yn,
       is_excluded_yn,
       audit_type,
       row_version_expression,
       tenant_expression,
       r_owner,
       r_table_name,
       r_column_name
  FROM TABLE ( om_tapigen.util_view_columns_array );
