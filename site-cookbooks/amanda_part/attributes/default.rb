default['amanda_part']['user'] = 'amandabackup'
default['amanda_part']['group'] = 'disk'
default['amanda_part']['amanda_dir'] = '/amanda'
default['amanda_part']['amanda_config_dir'] = '/etc/amanda'
default['amanda_part']['amanda_data_dir'] = '/var/lib/amanda'
default['amanda_part']['server']['vtapes_dir'] = File.join(node['amanda_part']['amanda_dir'], 'vtapes')
default['amanda_part']['server']['holding_dir'] = File.join(node['amanda_part']['amanda_dir'], 'holding')
default['amanda_part']['server']['state_dir'] = File.join(node['amanda_part']['amanda_dir'], 'state')
default['amanda_part']['server']['info_dir'] = File.join(node['amanda_part']['server']['state_dir'], 'curinfo')
default['amanda_part']['server']['log_dir'] = File.join(node['amanda_part']['amanda_dir'], 'log')
default['amanda_part']['server']['index_dir'] = File.join(node['amanda_part']['amanda_dir'], 'index')
default['amanda_part']['server']['dumpcycle'] = '1 weeks'
default['amanda_part']['server']['runspercycle'] = '7 days'
default['amanda_part']['server']['tapecycle'] = '8 tapes'
default['amanda_part']['server']['dumptype'] = 'dumptype_tar'
default['amanda_part']['server']['holding_prefix'] = 'hd_'
default['amanda_part']['server']['holding_use'] = '2 mbytes'
default['amanda_part']['server']['holding_chunksize'] = '1 mbyte'
default['amanda_part']['server']['slot'] = 8
default['amanda_part']['server']['schedule'] = '0 0 0 * *'
default['amanda_part']['server']['storage'] = 's3'

# S3 configuration
default['amanda_part']['server']['s3']['tapetype']['name'] = 'S3'
default['amanda_part']['server']['s3']['tapetype']['length'] = '10240 gigabytes'
default['amanda_part']['server']['s3']['tpchanger']['name'] = 's3_tpchanger'
default['amanda_part']['server']['s3']['tpchanger']['bucket_name'] = ''
default['amanda_part']['server']['s3']['tpchanger']['s3_access_key'] = ''
default['amanda_part']['server']['s3']['tpchanger']['s3_secret_key'] = ''
default['amanda_part']['server']['s3']['tpchanger']['s3_bucket_location'] = ''
default['amanda_part']['server']['s3']['tpchanger']['threads'] = '3'
default['amanda_part']['server']['s3']['tpchanger']['s3_ssl'] = 'yes'
default['amanda_part']['server']['s3']['tpchanger']['changerfile'] = 's3-statefile'
s3_slots = (1..node['amanda_part']['server']['slot']).to_a.map do |slot|
  format('%02d', slot)
end.join(',')
default['amanda_part']['server']['s3']['tpchanger']['slots'] = s3_slots
default['amanda_part']['server']['s3']['autolabel'] = 'S3-%%%%'
default['amanda_part']['server']['s3']['labelstr'] = '^S3-[0-9][0-9]*$'

default['amanda_part']['client']['script_dir'] = '/usr/libexec/amanda/application'
