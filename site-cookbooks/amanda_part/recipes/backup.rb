bash 'amdump' do
  user 'root'
  code <<-EOH
  amdump default > /tmp/a 2>&1
  EOH
end
