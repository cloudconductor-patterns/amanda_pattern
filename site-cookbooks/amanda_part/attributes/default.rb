default['amanda_part']['config_name'] = 'default'
default['amanda_part']['server']['amanda_dir'] = '/amanda'
default['amanda_part']['server']['amanda_config_dir'] = '/etc/amanda'
default['amanda_part']['server']['var_amanda_dir'] = '/var/lib/amanda'
default['amanda_part']['server']['slot'] = 8
default['amanda_part']['server']['vtapes_dir'] = '/amanda/vtapes'
default['amanda_part']['server']['holding_dir'] = '/amanda/holding'
default['amanda_part']['server']['info_file'] = '/amanda/state/curinfo'
default['amanda_part']['server']['log_dir'] = '/amanda/state/log'
default['amanda_part']['server']['index_dir'] = '/amanda/state/index'
default['amanda_part']['server']['dumpuser'] = 'amandabackup'
default['amanda_part']['server']['dumpusergroup'] = 'disk'
default['amanda_part']['server']['config_dir'] = File.join(
  node['amanda_part']['server']['amanda_config_dir'],
  node['amanda_part']['config_name']
)
default['amanda_part']['server']['storage'] = 's3'

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
default['amanda_part']['server']['s3']['autolabel'] = 'S3-%%%%'
default['amanda_part']['server']['s3']['labelstr'] = '^S3-[0-9][0-9]*$'
s3_slots = (1..node['amanda_part']['server']['slot']).to_a.map do |slot|
  format('%02d', slot)
end.join(',')
default['amanda_part']['server']['s3']['definition'] = <<S3_DEFINITION
define tapetype #{node['amanda_part']['server']['s3']['tapetype']['name']} {
    length #{node['amanda_part']['server']['s3']['tapetype']['length']}
}

define changer #{node['amanda_part']['server']['s3']['tpchanger']['name']} {
    tpchanger "chg-multi:s3:#{node['amanda_part']['server']['s3']['tpchanger']['bucket_name']}/slot-{#{s3_slots}}"
    device-property "S3_ACCESS_KEY" "#{node['amanda_part']['server']['s3']['tpchanger']['s3_access_key']}"
    device-property "S3_SECRET_KEY" "#{node['amanda_part']['server']['s3']['tpchanger']['s3_secret_key']}"
    device-property "S3_BUCKET_LOCATION" "#{node['amanda_part']['server']['s3']['tpchanger']['s3_bucket_location']}"
    device-property "NB_THREADS_BACKUP" "#{node['amanda_part']['server']['s3']['tpchanger']['threads']}"
    device-property "S3_SSL" "#{node['amanda_part']['server']['s3']['tpchanger']['s3_ssl']}"
    changerfile  "#{node['amanda_part']['server']['s3']['tpchanger']['changerfile']}"
}
S3_DEFINITION

storage = node['amanda_part']['server']['storage']
default['amanda_part']['server']['tapetype'] = node['amanda_part']['server'][storage]['tapetype']['name']
default['amanda_part']['server']['tpchanger'] = node['amanda_part']['server'][storage]['tpchanger']['name']
default['amanda_part']['server']['definition'] = node['amanda_part']['server'][storage]['definition']
default['amanda_part']['server']['autolabel'] = node['amanda_part']['server'][storage]['autolabel']
default['amanda_part']['server']['labelstr'] = node['amanda_part']['server'][storage]['labelstr']
default['amanda_part']['server']['tapecycle'] = 4
default['amanda_part']['server']['dumpcycle'] = '3 days'
default['amanda_part']['server']['dumptype'] = 'tar'
default['amanda_part']['server']['holdingdisk']['name'] = 'hd1'
default['amanda_part']['server']['holdingdisk']['directory'] = '/amanda/holding'
default['amanda_part']['server']['holdingdisk']['use'] = '2 mbytes'
default['amanda_part']['server']['holdingdisk']['chunksize'] = '1 mbyte'

default['amanda_part']['client']['amanda_config_dir'] = node['amanda_part']['server']['amanda_config_dir']
default['amanda_part']['client']['config_dir'] = File.join(
  node['amanda_part']['client']['amanda_config_dir'],
  node['amanda_part']['config_name']
)
default['amanda_part']['client']['var_amanda_dir'] = node['amanda_part']['server']['var_amanda_dir']
default['amanda_part']['client']['dumpuser'] = node['amanda_part']['server']['dumpuser']
default['amanda_part']['client']['dumpusergroup'] = node['amanda_part']['server']['dumpusergroup']
default['amanda_part']['client']['tpchanger'] = node['amanda_part']['server'][storage]['tpchanger']['name']
default['amanda_part']['client']['script_dir'] = '/usr/libexec/amanda/application'
