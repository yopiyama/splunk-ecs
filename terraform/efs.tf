resource "aws_efs_file_system" "splunk-var" {}
resource "aws_efs_file_system" "splunk-etc" {}

locals {
  subnets = {
    public1 = aws_subnet.subnet-public-1a.id
    public2 = aws_subnet.subnet-public-1c.id
  }
}

resource "aws_efs_mount_target" "splunk-var-efs-public" {
  for_each = local.subnets

  file_system_id  = aws_efs_file_system.splunk-var.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs-sg.id]
}

resource "aws_efs_mount_target" "splunk-etc-efs-public" {
  for_each = local.subnets

  file_system_id  = aws_efs_file_system.splunk-etc.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs-sg.id]
}
