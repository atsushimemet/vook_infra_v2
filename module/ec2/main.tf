#--------------------------------------------------------------
# Security group
#--------------------------------------------------------------

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "ec2" {
  name = "${var.app_name}-ec2-sg"

  description = "EC2 service security group for ${var.app_name}"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ec2_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group_rule" "ec2_ingress_ssh" {
  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group_rule" "ec2_ingress_http" {
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  security_group_id = aws_security_group.ec2.id
}
 
resource "aws_security_group_rule" "ec2_ingress_https" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  security_group_id = aws_security_group.ec2.id
}

#--------------------------------------------------------------
# IAM Role
#--------------------------------------------------------------

data "aws_iam_policy_document" "ec2" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "systems-manager" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "ec2" {
  name               = "${var.app_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2.json
}

resource "aws_iam_role_policy_attachment" "ec2" {
  role       = aws_iam_role.ec2.name
  policy_arn = data.aws_iam_policy.systems-manager.arn
}

resource "aws_iam_instance_profile" "systems-manager" {
  name = "${var.app_name}-ec2-instance-profile"
  role = aws_iam_role.ec2.name
}

#--------------------------------------------------------------
# EC2
#--------------------------------------------------------------
resource "aws_instance" "ec2" {
  ami                         = "ami-06fdbb60c8e83aa5e"
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet_ids[0]
  associate_public_ip_address = "false"
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.systems-manager.name

  user_data = file("${path.module}/script.sh")
}

#--------------------------------------------------------------
# KEY PAIR
#--------------------------------------------------------------
# privateキーのアルゴリズム設定
resource "tls_private_key" "keygen" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# 作成したキーペアを格納するファイルを指定。
# 存在しないディレクトリを指定した場合は新規にディレクトリを作成してくれる
locals {
  public_key_file  = "./.ssh/${var.key_name}.id_rsa.pub"
  private_key_file = "./.ssh/${var.key_name}.id_rsa"
}

#local_fileのリソースを指定するとterraformを実行するディレクトリ内でファイル作成やコマンド実行が出来る。
resource "local_file" "private_key_pem" {
  filename = local.private_key_file
  content  = tls_private_key.keygen.private_key_pem
  provisioner "local-exec" {
    command = "chmod 600 ${local.private_key_file}"
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.keygen.public_key_openssh
}