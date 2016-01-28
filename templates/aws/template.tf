resource "aws_security_group" "backup_restore_security_group" {
  name = "BackupRestoreSecurityGroup"
  description = "Enable amanda access"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = 10080
    to_port = 10083
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 571
    to_port = 571
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_security_group_rule" "shared_security_group_inbound_rule_amanda" {
    type = "ingress"
    from_port = 10080
    to_port = 10083
    protocol = "tcp"
    security_group_id = "${var.shared_security_group}"
    source_security_group_id = "${aws_security_group.backup_restore_security_group.id}"
}

resource "aws_security_group_rule" "shared_security_group_inbound_rule_meter" {
    type = "ingress"
    from_port = 571
    to_port = 571
    protocol = "tcp"
    security_group_id = "${var.shared_security_group}"
    source_security_group_id = "${aws_security_group.backup_restore_security_group.id}"
}

resource "aws_instance" "backup_restore_server" {
  ami = "${var.backup_restore_image}"
  instance_type = "${var.backup_restore_instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.backup_restore_security_group.id}", "${var.shared_security_group}"]
  subnet_id = "${element(split(", ", var.subnet_ids), 0)}"
  associate_public_ip_address = true
  tags {
    Name = "BackupRestoreServer"
  }
}

output "cluster_addresses" {
  value = "${aws_instance.backup_restore_server.private_ip}"
}
