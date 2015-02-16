execute 'amdump' do
  user node['amanda_part']['execuser']
  command "amdump #{node['amanda_part']['config_name']}"
end
