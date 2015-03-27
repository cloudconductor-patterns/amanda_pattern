case node['amanda_part']['server']['storage']
when 's3'
  include_recipe('amanda_part::restore_s3')
end
