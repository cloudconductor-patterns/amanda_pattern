variable "vpc_id" {
  description = "VPC ID which is created by common network pattern."
}
variable "subnet_ids" {
  description = "Subnet ID which is created by common network pattern."
}
variable "shared_security_group" {
  description = "SecurityGroup ID which is created by common network pattern."
}
variable "key_name" {
  description = "Name of an existing EC2/OpenStack KeyPair to enable SSH access to the instances."
}
variable "backup_restore_image" {
  description = "[computed] BackupRestoreServer Image Id. This parameter is automatically filled by CloudConductor."
}
variable "backup_restore_instance_type" {
  description = "BackupRestoreServer instance type"
  default = "t2.small"
}
