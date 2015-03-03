case amanda_server?
when true
  include_recipe 'amanda_part::all_configure_server'
when false
  include_recipe 'amanda_part::all_configure_client'
end
