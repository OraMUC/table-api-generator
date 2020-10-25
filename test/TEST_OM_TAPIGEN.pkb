prompt Compile package test_om_tapigen (body)
create or replace package body test_om_tapigen is

--------------------------------------------------------------------------------

procedure test_all_tables_with_defaults is
  ----------
  function compile_apis_return_invalid_object_names return varchar2 is
  begin
    for i in cur_all_test_tables loop
      test_om_tapigen_log_api.create_row (
        p_test_name      => util_get_test_name,
        p_table_name     => i.table_name,
        p_generated_code => om_tapigen.compile_api_and_get_code(
          p_table_name => i.table_name
        )
      );
    end loop;
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_apis_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_apis_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(11);
end test_all_tables_with_defaults;

--------------------------------------------------------------------------------

procedure test_all_tables_enable_dml_and_1_to_1_view is
  ----------
  function compile_apis_return_invalid_object_names return varchar2 is
  begin
    for i in cur_all_test_tables loop
      test_om_tapigen_log_api.create_row (
        p_test_name      => util_get_test_name,
        p_table_name     => i.table_name,
        p_generated_code => om_tapigen.compile_api_and_get_code(
          p_table_name               => i.table_name,
          p_return_row_instead_of_pk => true,
          p_enable_dml_view          => true,
          p_enable_one_to_one_view   => true
        )
      );
    end loop;
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_apis_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_apis_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(44);
end test_all_tables_enable_dml_and_1_to_1_view;

--------------------------------------------------------------------------------

procedure test_all_tables_return_row_instead_of_pk_true is
  ----------
  function compile_apis_return_invalid_object_names return varchar2 is
  begin
    for i in cur_all_test_tables loop
      test_om_tapigen_log_api.create_row (
        p_test_name      => util_get_test_name,
        p_table_name     => i.table_name,
        p_generated_code => om_tapigen.compile_api_and_get_code(
          p_table_name               => i.table_name,
          p_return_row_instead_of_pk => true
        )
      );
    end loop;
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_apis_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_apis_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(11);
end test_all_tables_return_row_instead_of_pk_true;

--------------------------------------------------------------------------------

procedure test_all_tables_double_quote_names_false is
  ----------
  function compile_apis_return_invalid_object_names return varchar2 is
  begin
    for i in cur_all_test_tables loop
      test_om_tapigen_log_api.create_row (
        p_test_name      => util_get_test_name,
        p_table_name     => i.table_name,
        p_generated_code => om_tapigen.compile_api_and_get_code(
          p_table_name         => i.table_name,
          p_double_quote_names => false
        )
      );
    end loop;
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_apis_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_apis_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(11);
end test_all_tables_double_quote_names_false;

--------------------------------------------------------------------------------

procedure test_all_tables_enable_column_defaults_true is
  ----------
  function compile_apis_return_invalid_object_names return varchar2 is
  begin
    for i in cur_all_test_tables loop
      test_om_tapigen_log_api.create_row (
        p_test_name      => util_get_test_name,
        p_table_name     => i.table_name,
        p_generated_code => om_tapigen.compile_api_and_get_code(
          p_table_name             => i.table_name,
          p_enable_column_defaults => true
        )
      );
    end loop;
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_apis_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_apis_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(11);
end test_all_tables_enable_column_defaults_true;

--------------------------------------------------------------------------------

procedure test_all_tables_enable_custom_defaults_true is
  ----------
  function compile_apis_return_invalid_object_names return varchar2 is
  begin
    for i in cur_all_test_tables loop
      test_om_tapigen_log_api.create_row (
        p_test_name      => util_get_test_name,
        p_table_name     => i.table_name,
        p_generated_code => om_tapigen.compile_api_and_get_code(
          p_table_name             => i.table_name,
          p_enable_custom_defaults => true
        )
      );
    end loop;
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_apis_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_apis_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(11);
end test_all_tables_enable_custom_defaults_true;

--------------------------------------------------------------------------------

procedure test_users_roles_rights_audit_column_mappings_configured is
  ----------
  function compile_apis_return_invalid_object_names return varchar2 is
  begin
    for i in cur_user_roles_rights loop
      test_om_tapigen_log_api.create_row (
        p_test_name      => util_get_test_name,
        p_table_name     => i.table_name,
        p_generated_code => om_tapigen.compile_api_and_get_code(
          p_table_name                 => i.table_name,
          p_row_version_column_mapping => '#PREFIX#_VERSION_ID=tag_global_version_sequence.nextval',
          p_audit_column_mappings      => 'created=#PREFIX#_CREATED, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED, updated_by=#PREFIX#_UPDATED_BY'
        )
      );
    end loop;
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_apis_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_apis_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(5);
end test_users_roles_rights_audit_column_mappings_configured;

--------------------------------------------------------------------------------

procedure test_table_users_create_methods_only is
  l_table_name t_name := 'TAG_USERS';
  l_code clob;
  ----------
  function compile_api_return_invalid_object_names return varchar2 is
  begin
    l_code := om_tapigen.compile_api_and_get_code(
      p_table_name                 => l_table_name,
      p_enable_insertion_of_rows   => true,
      p_enable_update_of_rows      => false,
      p_enable_deletion_of_rows    => false,
      p_row_version_column_mapping => '#PREFIX#_VERSION_ID=tag_global_version_sequence.nextval',
      p_audit_column_mappings      => 'created=#PREFIX#_CREATED_ON, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED_AT, updated_by=#PREFIX#_UPDATED_BY'
    );
    test_om_tapigen_log_api.create_row (
      p_test_name      => util_get_test_name,
      p_table_name     => l_table_name,
      p_generated_code => l_code
    );
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_api_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_api_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(1);
  ut.expect(util_get_spec_regex_count(l_code,' get_pk_by_unique_cols')).to_equal(1);
  ut.expect(util_get_spec_regex_count(l_code,' create_row')).to_equal(6);
  ut.expect(util_get_spec_regex_count(l_code,' read_row')).to_equal(4);
  ut.expect(util_get_spec_regex_count(l_code,' update_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' delete_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' create_or_update_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' get_u_')).to_equal(9);
  ut.expect(util_get_spec_regex_count(l_code,' set_u_')).to_equal(0);
end test_table_users_create_methods_only;

--------------------------------------------------------------------------------

procedure test_table_users_update_methods_only is
  l_table_name t_name := 'TAG_USERS';
  l_code clob;
  ----------
  function compile_api_return_invalid_object_names return varchar2 is
  begin
    l_code := om_tapigen.compile_api_and_get_code(
      p_table_name                 => l_table_name,
      p_enable_insertion_of_rows   => false,
      p_enable_update_of_rows      => true,
      p_enable_deletion_of_rows    => false,
      p_row_version_column_mapping => '#PREFIX#_VERSION_ID=tag_global_version_sequence.nextval',
      p_audit_column_mappings      => 'created=#PREFIX#_CREATED_ON, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED_AT, updated_by=#PREFIX#_UPDATED_BY'
    );
    test_om_tapigen_log_api.create_row (
      p_test_name      => util_get_test_name,
      p_table_name     => l_table_name,
      p_generated_code => l_code
    );
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_api_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_api_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(1);
  ut.expect(util_get_spec_regex_count(l_code,' get_pk_by_unique_cols')).to_equal(1);
  ut.expect(util_get_spec_regex_count(l_code,' create_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' read_row')).to_equal(4);
  ut.expect(util_get_spec_regex_count(l_code,' update_row')).to_equal(5);
  ut.expect(util_get_spec_regex_count(l_code,' delete_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' create_or_update_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' get_u_')).to_equal(9);
  ut.expect(util_get_spec_regex_count(l_code,' set_u_')).to_equal(4);
end test_table_users_update_methods_only;

--------------------------------------------------------------------------------

procedure test_table_users_delete_methods_only is
  l_table_name t_name := 'TAG_USERS';
  l_code clob;
  ----------
  function compile_api_return_invalid_object_names return varchar2 is
  begin
    l_code := om_tapigen.compile_api_and_get_code(
      p_table_name                 => l_table_name,
      p_enable_insertion_of_rows   => false,
      p_enable_update_of_rows      => false,
      p_enable_deletion_of_rows    => true,
      p_row_version_column_mapping => '#PREFIX#_VERSION_ID=tag_global_version_sequence.nextval',
      p_audit_column_mappings      => 'created=#PREFIX#_CREATED_ON, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED_AT, updated_by=#PREFIX#_UPDATED_BY'
    );
    test_om_tapigen_log_api.create_row (
      p_test_name      => util_get_test_name,
      p_table_name     => l_table_name,
      p_generated_code => l_code
    );
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_api_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_api_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(1);
  ut.expect(util_get_spec_regex_count(l_code,' get_pk_by_unique_cols')).to_equal(1);
  ut.expect(util_get_spec_regex_count(l_code,' create_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' read_row')).to_equal(4);
  ut.expect(util_get_spec_regex_count(l_code,' update_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' delete_row')).to_equal(2);
  ut.expect(util_get_spec_regex_count(l_code,' create_or_update_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' get_u_')).to_equal(9);
  ut.expect(util_get_spec_regex_count(l_code,' set_u_')).to_equal(0);
end test_table_users_delete_methods_only;

--------------------------------------------------------------------------------

procedure test_table_users_create_and_update_methods is
  l_table_name t_name := 'TAG_USERS';
  l_code clob;
  ----------
  function compile_api_return_invalid_object_names return varchar2 is
  begin
    l_code := om_tapigen.compile_api_and_get_code(
      p_table_name                 => l_table_name,
      p_enable_insertion_of_rows   => true,
      p_enable_update_of_rows      => true,
      p_enable_deletion_of_rows    => false,
      p_enable_dml_view            => true,
      p_enable_one_to_one_view     => true,
      p_enable_custom_defaults     => true,
      p_double_quote_names         => false,
      p_row_version_column_mapping => '#PREFIX#_VERSION_ID=tag_global_version_sequence.nextval',
      p_audit_column_mappings      => 'created=#PREFIX#_CREATED_ON, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED_AT, updated_by=#PREFIX#_UPDATED_BY'
    );
    test_om_tapigen_log_api.create_row (
      p_test_name      => util_get_test_name,
      p_table_name     => l_table_name,
      p_generated_code => l_code
    );
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_api_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_api_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(4);
  ut.expect(util_get_spec_regex_count(l_code,' get_pk_by_unique_cols')).to_equal(1);
  ut.expect(util_get_spec_regex_count(l_code,' create_row')).to_equal(6);
  ut.expect(util_get_spec_regex_count(l_code,' read_row')).to_equal(4);
  ut.expect(util_get_spec_regex_count(l_code,' update_row')).to_equal(5);
  ut.expect(util_get_spec_regex_count(l_code,' delete_row')).to_equal(0);
  ut.expect(util_get_spec_regex_count(l_code,' create_or_update_row')).to_equal(4);
  ut.expect(util_get_spec_regex_count(l_code,' get_u_')).to_equal(9);
  ut.expect(util_get_spec_regex_count(l_code,' set_u_')).to_equal(4);
  ut.expect(util_get_regex_substr_count(l_code,'create_row \(.*?\)', 'p_u_')).to_equal(4);
  ut.expect(util_get_regex_substr_count(l_code,'update_row \(.*?\)', 'p_u_')).to_equal(5);
end test_table_users_create_and_update_methods;

--------------------------------------------------------------------------------

procedure test_table_users_default_api_object_names is
  l_table_name t_name := 'TAG_USERS';
  l_code clob;
  ----------
  function compile_api_return_invalid_object_names return varchar2 is
  begin
    l_code := om_tapigen.compile_api_and_get_code(
      p_table_name                 => l_table_name,
      p_enable_dml_view            => true,
      p_enable_one_to_one_view     => true,
      p_double_quote_names         => false,
      p_row_version_column_mapping => '#PREFIX#_VERSION_ID=tag_global_version_sequence.nextval',
      p_audit_column_mappings      => 'created=#PREFIX#_CREATED_ON, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED_AT, updated_by=#PREFIX#_UPDATED_BY'
    );
    test_om_tapigen_log_api.create_row (
      p_test_name      => util_get_test_name,
      p_table_name     => l_table_name,
      p_generated_code => l_code
    );
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_api_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_api_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(4);
  ut.expect(util_check_if_package_exists('TAG_USERS_API')).to_be_true;
  ut.expect(util_check_if_view_exists('TAG_USERS_DML_V')).to_be_true;
  ut.expect(util_check_if_trigger_exists('TAG_USERS_IOIUD')).to_be_true;
  ut.expect(util_check_if_view_exists('TAG_USERS_V')).to_be_true;
end test_table_users_default_api_object_names;

--------------------------------------------------------------------------------

procedure test_table_users_different_api_object_names is
  l_table_name t_name := 'TAG_USERS';
  l_code clob;
  ----------
  function compile_api_return_invalid_object_names return varchar2 is
  begin
    l_code := om_tapigen.compile_api_and_get_code(
      p_table_name                 => l_table_name,
      p_enable_dml_view            => true,
      p_dml_view_name              => '#TABLE_NAME#_DMLV',
      p_dml_view_trigger_name      => '#TABLE_NAME#_DMLT',
      p_enable_one_to_one_view     => true,
      p_one_to_one_view_name       => '#TABLE_NAME#_121V',
      p_api_name                   => '#TABLE_NAME#_TAPI',
      p_double_quote_names         => false,
      p_row_version_column_mapping => '#PREFIX#_VERSION_ID=tag_global_version_sequence.nextval',
      p_audit_column_mappings      => 'created=#PREFIX#_CREATED_ON, created_by=#PREFIX#_CREATED_BY, updated=#PREFIX#_UPDATED_AT, updated_by=#PREFIX#_UPDATED_BY'
    );
    test_om_tapigen_log_api.create_row (
      p_test_name      => util_get_test_name,
      p_table_name     => l_table_name,
      p_generated_code => l_code
    );
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_api_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_api_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(4);
  ut.expect(util_check_if_package_exists('TAG_USERS_TAPI')).to_be_true;
  ut.expect(util_check_if_view_exists('TAG_USERS_DMLV')).to_be_true;
  ut.expect(util_check_if_trigger_exists('TAG_USERS_DMLT')).to_be_true;
  ut.expect(util_check_if_view_exists('TAG_USERS_121V')).to_be_true;
end test_table_users_different_api_object_names;

--------------------------------------------------------------------------------

procedure test_table_with_very_short_column_names is
  l_table_name t_name := 'TAG_SHORT_COLUMN_NAMES';
  l_code clob;
  ----------
  function compile_api_return_invalid_object_names return varchar2 is
  begin
    l_code := om_tapigen.compile_api_and_get_code(
      p_table_name => l_table_name
    );
    test_om_tapigen_log_api.create_row (
      p_test_name      => util_get_test_name,
      p_table_name     => l_table_name,
      p_generated_code => l_code
    );
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_api_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_api_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(1);
end test_table_with_very_short_column_names;

--------------------------------------------------------------------------------

procedure test_table_with_very_long_column_names is
  l_table_name t_name := 'TAG_LONG_COLUMN_NAMES';
  l_code clob;
  ----------
  function compile_api_return_invalid_object_names return varchar2 is
  begin
    l_code := om_tapigen.compile_api_and_get_code(
      p_table_name => l_table_name
    );
    test_om_tapigen_log_api.create_row (
      p_test_name      => util_get_test_name,
      p_table_name     => l_table_name,
      p_generated_code => l_code
    );
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_api_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_api_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(1);
end test_table_with_very_long_column_names;

--------------------------------------------------------------------------------

procedure test_table_with_tenant_id_visible is
  l_table_name t_name := 'TAG_TENANT_VISIBLE';
  l_code clob;
  ----------
  function compile_api_return_invalid_object_names return varchar2 is
  begin
    l_code := om_tapigen.compile_api_and_get_code(
      p_table_name             => l_table_name,
      p_enable_dml_view        => true,
      p_enable_one_to_one_view => true,
      p_double_quote_names     => false,
      p_tenant_column_mapping  => '#PREFIX#_TENANT_ID=100'
    );
    test_om_tapigen_log_api.create_row (
      p_test_name      => util_get_test_name,
      p_table_name     => l_table_name,
      p_generated_code => l_code
    );
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_api_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_api_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(4);
  ut.expect(util_get_regex_substr_count(l_code,'create_row \(.*?\)', 'p_tv_')).to_equal(3);
  ut.expect(util_get_regex_substr_count(l_code,'update_row \(.*?\)', 'p_tv_')).to_equal(3);
  ut.expect(util_get_regex_substr_count(l_code,'insert into tag_tenant_visible \(.*?\)', 'tv_')).to_equal(4);
  ut.expect(util_get_regex_substr_count(l_code,'insert into tag_tenant_visible \(.*?\)', 'tv_tenant_id')).to_equal(1);
  ut.expect(util_get_regex_substr_count(l_code,'update\s+tag_tenant_visible\s+set.*?where', 'tv_')).to_equal(4);
  ut.expect(regexp_count(l_code, 'where\s+tv_.*? =.*?and tv_tenant_id = .*?(;|return)', 1, 'in')).to_equal(8);
end test_table_with_tenant_id_visible;

--------------------------------------------------------------------------------

procedure test_table_with_tenant_id_invisible is
  l_table_name t_name := 'TAG_TENANT_INVISIBLE';
  l_code clob;
  ----------
  function compile_api_return_invalid_object_names return varchar2 is
  begin
    l_code := om_tapigen.compile_api_and_get_code(
      p_table_name             => l_table_name,
      p_enable_dml_view        => true,
      p_enable_one_to_one_view => true,
      p_double_quote_names     => false,
      p_tenant_column_mapping  => '#PREFIX#_TENANT_ID=100'
    );
    test_om_tapigen_log_api.create_row (
      p_test_name      => util_get_test_name,
      p_table_name     => l_table_name,
      p_generated_code => l_code
    );
    commit;
    return util_get_list_of_invalid_generated_objects;
  end compile_api_return_invalid_object_names;
  ----------
begin
  ut.expect(util_count_generated_objects).to_equal(0);
  ut.expect(compile_api_return_invalid_object_names).to_be_null;
  ut.expect(util_count_generated_objects).to_equal(4);
  ut.expect(util_get_regex_substr_count(l_code,'create_row \(.*?\)', 'p_ti_')).to_equal(3);
  ut.expect(util_get_regex_substr_count(l_code,'update_row \(.*?\)', 'p_ti_')).to_equal(3);
  ut.expect(util_get_regex_substr_count(l_code,'insert into tag_tenant_invisible \(.*?\)', 'ti_')).to_equal(4);
  ut.expect(util_get_regex_substr_count(l_code,'insert into tag_tenant_invisible \(.*?\)', 'ti_tenant_id')).to_equal(1);
  ut.expect(util_get_regex_substr_count(l_code,'update\s+tag_tenant_invisible\s+set.*?where', 'ti_')).to_equal(4);
  ut.expect(util_get_regex_substr_count(l_code,'update\s+tag_tenant_invisible\s+set.*?where', 'ti_')).to_equal(4);
  ut.expect(regexp_count(l_code, 'where\s+ti_.*? =.*?and ti_tenant_id = .*?(;|return)', 1, 'in')).to_equal(8);
end test_table_with_tenant_id_invisible;

--------------------------------------------------------------------------------

procedure util_drop_and_create_test_table_objects is
begin
  util_drop_test_table_objects;
  util_create_test_table_objects;
end util_drop_and_create_test_table_objects;

--------------------------------------------------------------------------------

procedure util_create_test_table_objects is
  ----------
  procedure tag_global_version_sequence is
  begin
    execute immediate 'create sequence tag_global_version_sequence';
  end tag_global_version_sequence;
  ----------
  procedure tag_users is
  begin
    execute immediate q'[
      create table tag_users (
        u_id          integer                         generated always as identity,
        u_first_name  varchar2(15 char)                         ,
        u_last_name   varchar2(15 char)                         ,
        u_email       varchar2(30 char)               not null  ,
        u_active_yn   varchar2(1 char)   default 'Y'  not null  ,
        u_version_id  integer                         not null  ,
        u_created_on  date                            not null  , -- This is only for demo purposes.
        u_created_by  char(15 char)                   not null  , -- In reality we expect more
        u_updated_at  timestamp                       not null  , -- unified names and types
        u_updated_by  varchar2(15 char)               not null  , -- for audit columns.
        --
        primary key (u_id),
        unique (u_email),
        check (u_active_yn in ('Y', 'N'))
      )
    ]';
  end tag_users;
  ----------
  procedure tag_roles is
  begin
    execute immediate q'[
      create table tag_roles (
        ro_id          integer                         generated by default on null as identity,
        ro_name        varchar2(15 char)               not null  ,
        ro_description varchar2(30 char)               not null  ,
        ro_active_yn   varchar2(1 char)   default 'Y'  not null  ,
        ro_version_id  integer                         not null  ,
        ro_created_on  date                            not null  , -- This is only for demo purposes.
        ro_created_by  char(15 char)                   not null  , -- In reality we expect more
        ro_updated_at  timestamp                       not null  , -- unified names and types
        ro_updated_by  varchar2(15 char)               not null  , -- for audit columns.
        --
        primary key (ro_id),
        unique (ro_name),
        check (ro_active_yn in ('Y', 'N'))
      )
    ]';
  end tag_roles;
  ----------
  procedure tag_rights is
  begin
    execute immediate q'[
      create table tag_rights (
        ri_id          integer                         generated by default on null as identity,
        ri_name        varchar2(15 char)               not null  ,
        ri_description varchar2(30 char)               not null  ,
        ri_active_yn   varchar2(1 char)   default 'Y'  not null  ,
        ri_version_id  integer                         not null  ,
        ri_created_on  date                            not null  , -- This is only for demo purposes.
        ri_created_by  char(15 char)                   not null  , -- In reality we expect more
        ri_updated_at  timestamp                       not null  , -- unified names and types
        ri_updated_by  varchar2(15 char)               not null  , -- for audit columns.
        --
        primary key (ri_id),
        unique (ri_name),
        check (ri_active_yn in ('Y', 'N'))
      )
    ]';
  end tag_rights;
  ----------
  procedure tag_map_users_roles is
  begin
    execute immediate q'[
      create table tag_map_users_roles (
        mur_id          integer        generated always as identity,
        mur_u_id        integer        not null  ,
        mur_ro_id       integer        not null  ,
        mur_created_on  timestamp      not null  ,
        mur_created_by  char(15 char)  not null  ,
        --
        primary key (mur_id),
        unique (mur_u_id, mur_ro_id),
        foreign key (mur_u_id) references tag_users,
        foreign key (mur_ro_id) references tag_roles
      )
    ]';
  end tag_map_users_roles;
  ----------
  procedure tag_map_roles_rights is
  begin
    execute immediate q'[
      create table tag_map_roles_rights (
        mrr_ro_id       integer        not null  ,
        mrr_ri_id       integer        not null  ,
        mrr_created_on  timestamp      not null  ,
        mrr_created_by  char(15 char)  not null  ,
        --
        primary key (mrr_ro_id, mrr_ri_id),
        foreign key (mrr_ro_id) references tag_roles,
        foreign key (mrr_ri_id) references tag_rights
      )
    ]';
  end tag_map_roles_rights;
  ----------
  procedure tag_all_data_types_single_pk is
  begin
    execute immediate q'[
      create table tag_all_data_types_single_pk (
        adt1_id             integer                         generated always as identity,
        adt1_varchar        varchar2(15 char)                         ,
        adt1_char           char(1 char)                    not null  ,
        adt1_integer        integer                                   ,
        adt1_number         number                                    ,
        adt1_number_x_5     number(*,5)                               ,
        adt1_number_20_5    number(20,5)                              ,
        adt1_float          float                                     ,
        adt1_float_size_30  float(30)                                 ,
        adt1_xmltype        xmltype                                   ,
        adt1_clob           clob                                      ,
        adt1_blob           blob                                      ,
        adt1_date           date                                      ,
        adt1_timestamp      timestamp                                 ,
        adt1_timestamp_tz   timestamp with time zone                  ,
        adt1_timestamp_ltz  timestamp with local time zone            ,
        --
        primary key (adt1_id),
        unique (adt1_varchar)
      )
    ]';
  end tag_all_data_types_single_pk;
  ----------
  procedure tag_all_data_types_multi_pk is
  begin
    execute immediate q'[
      create table tag_all_data_types_multi_pk (
        adt2_id             integer                         generated always as identity,
        adt2_varchar        varchar2(15 char)                         ,
        adt2_char           char(1 char)                    not null  ,
        adt2_integer        integer                                   ,
        adt2_number         number                                    ,
        adt2_number_x_5     number(*,5)                               ,
        adt2_number_20_5    number(20,5)                              ,
        adt2_float          float                                     ,
        adt2_float_size_30  float(30)                                 ,
        adt2_xmltype        xmltype                                   ,
        adt2_clob           clob                                      ,
        adt2_blob           blob                                      ,
        adt2_date           date                                      ,
        adt2_timestamp      timestamp                                 ,
        adt2_timestamp_tz   timestamp with time zone                  ,
        adt2_timestamp_ltz  timestamp with local time zone            ,
        --
        primary key (adt2_id, adt2_varchar)
      )
    ]';
  end tag_all_data_types_multi_pk;
  ----------
  procedure tag_short_column_names is
  begin
    execute immediate q'[
      create table tag_short_column_names (
        scn_id  integer            generated always as identity,
        scn_a   varchar2(15 char)  ,
        scn_b   integer            ,
        scn_c   number             ,
        --
        primary key (scn_id)
      )
    ]';
  end tag_short_column_names;
  ----------
  procedure tag_long_column_names is
  begin
    execute immediate q'[
      create table tag_long_column_names (
        lcn_id                                                                                                     integer                              generated always as identity,
        lcn_a_very_very_very_very_very_long_column_name_to_test_how_far_we_can_go_with_a_descend_database_version  varchar2(15 char)  default 'testus'            ,
        lcn_another_long_column_name_although_not_as_long_as_the_first_one_but_long_enough_for_our_tests           integer            default 1         not null  ,
        lcn_a_short_one_just_for_fun                                                                               number                               not null  ,
        --
        primary key (lcn_id)
      )
    ]';
  end tag_long_column_names;
  ----------
  procedure tag_tenant_visible is
  begin
    execute immediate q'[
      create table tag_tenant_visible (
        tv_id           integer            generated by default on null as identity,
        tv_name         varchar2(15 char)  not null  ,
        tv_description  varchar2(60 char)            ,
        tv_tenant_id    integer            not null  ,
        --
        primary key (tv_id),
        unique (tv_name, tv_tenant_id)
      )
    ]';
  end tag_tenant_visible;
  ----------
  procedure tag_tenant_invisible is
  begin
    execute immediate q'[
      create table tag_tenant_invisible (
        ti_id           integer                       generated by default on null as identity,
        ti_name         varchar2(15 char)             not null  ,
        ti_description  varchar2(60 char)                       ,
        ti_tenant_id    integer            invisible  not null  ,
        --
        primary key (ti_id),
        unique (ti_name, ti_tenant_id)
      )
    ]';
  end tag_tenant_invisible;
  ----------
begin
  tag_global_version_sequence;
  tag_users;
  tag_roles;
  tag_rights;
  tag_map_users_roles;
  tag_map_roles_rights;
  tag_all_data_types_single_pk;
  tag_all_data_types_multi_pk;
  tag_short_column_names;
  tag_long_column_names;
  tag_tenant_visible;
  tag_tenant_invisible;
end util_create_test_table_objects;

--------------------------------------------------------------------------------

procedure util_drop_test_table_objects is
  ----------
  procedure drop_fk_constraints is
  begin
    for i in (
        select
          constraint_name,
          table_name
        from
          user_constraints
        where
          constraint_type = 'R'
          and table_name like 'TAG_%' escape '\'
    ) loop
      execute immediate 'alter table ' || i.table_name || ' drop constraint ' || i.constraint_name;
    end loop;
  end drop_fk_constraints;
  ----------
  procedure drop_tables_and_sequences is
  begin
    for i in cur_all_test_table_objects loop
      execute immediate 'drop ' || i.object_type || ' ' || i.object_name;
    end loop;
  end drop_tables_and_sequences;
  ----------
begin
  drop_fk_constraints;
  drop_tables_and_sequences;
  execute immediate 'purge recyclebin';
end util_drop_test_table_objects;

--------------------------------------------------------------------------------

procedure util_drop_generated_objects is
begin
  for i in cur_all_generated_objects loop
    execute immediate 'drop ' || i.object_type || ' ' || i.object_name;
  end loop;
  execute immediate 'purge recyclebin';
end util_drop_generated_objects;

--------------------------------------------------------------------------------

function  util_count_generated_objects return integer is
  l_return integer;
begin
  select
    count(*)
  into
    l_return
  from
    user_objects
  where
    object_type in ('PACKAGE', 'VIEW', 'TRIGGER')
    and object_name like 'TAG\_%' escape '\';
  return l_return;
end util_count_generated_objects;

--------------------------------------------------------------------------------

function  util_check_if_package_exists (p_name varchar2) return boolean is
  l_return boolean := false;
begin
  for i in (select object_name
              from user_objects
             where object_name = p_name
               and object_type = 'PACKAGE')
  loop
    l_return := true;
  end loop;
return l_return;
end util_check_if_package_exists;

--------------------------------------------------------------------------------

function  util_check_if_view_exists (p_name varchar2) return boolean is
  l_return boolean := false;
begin
  for i in (select view_name from user_views where view_name = p_name)
  loop
    l_return := true;
  end loop;
return l_return;
end util_check_if_view_exists;

--------------------------------------------------------------------------------

function  util_check_if_trigger_exists (p_name varchar2) return boolean is
  l_return boolean := false;
begin
  for i in (select trigger_name from user_triggers where trigger_name = p_name)
  loop
    l_return := true;
  end loop;
return l_return;
end util_check_if_trigger_exists;

--------------------------------------------------------------------------------

function util_get_list_of_invalid_generated_objects return varchar2 is
  l_return varchar2(4000);
begin
  select
    listagg(object_name || to_char(LAST_DDL_TIME,' yyyy-mm-dd hh24:mi:ss'), ', ')
      within group(order by object_name) as invalid_objects
  into
    l_return
  from
    user_objects
  where
    object_name like 'TAG\_%' escape '\'
    and status = 'INVALID';
  return l_return;
end util_get_list_of_invalid_generated_objects;

--------------------------------------------------------------------------------

function util_get_test_name return varchar2 is
begin
  -- https://stackoverflow.com/questions/50536323/currently-executing-procedure-name-within-the-package-in-oracle
  return utl_call_stack.subprogram(2)(2);
end util_get_test_name;

--------------------------------------------------------------------------------

function  util_get_spec_regex_count (
  p_code        clob,
  p_regex_count varchar2
) return integer is
  l_spec clob;
begin
  l_spec := regexp_substr(p_code, '(CREATE OR REPLACE PACKAGE.*)CREATE OR REPLACE PACKAGE BODY', 1, 1, 'in', 1);
  return regexp_count(l_spec, p_regex_count, 1, 'in');
end util_get_spec_regex_count;

--------------------------------------------------------------------------------

function util_get_regex_substr_count (
  p_code         clob,
  p_regex_substr varchar2,
  p_regex_count  varchar2
) return integer is
  l_substr clob;
begin
  l_substr := regexp_substr(p_code, p_regex_substr, 1, 1, 'in');
  --logger.log('l_substr: '|| l_substr);
  return regexp_count(l_substr, p_regex_count, 1, 'in');
end util_get_regex_substr_count;

--------------------------------------------------------------------------------

end test_om_tapigen;
/
show errors
