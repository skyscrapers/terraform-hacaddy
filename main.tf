module "hacaddy_instance" {
  source         = "github.com/skyscrapers/terraform-instances//instance?ref=2.3.6"
  project        = "${var.project}"
  environment    = "${var.environment}"
  name           = "${var.proxyname}"
  subnets        = "${var.subnet_ids}"
  ami            = "${var.ami}"
  key_name       = "${var.key_name}"
  instance_type  = "${var.instance_type}"
  instance_count = 2
  sgs            = ["${var.sg_all_id}", "${aws_security_group.sg_hacaddy.id}"]
  public_ip      = true
  user_data      = ["${module.userdata.user_datas[0]}", "${module.userdata.user_datas[1]}"]
  cpu_credits    = "${var.cpu_credits}"
}

module "userdata" {
  source              = "github.com/skyscrapers/terraform-instances//puppet-userdata?ref=2.3.2"
  customer            = "${var.project}"
  environment         = "${var.environment}"
  function            = "${var.proxyname}"
  amount_of_instances = 2
}

resource "aws_efs_file_system" "hacaddy_efs" {
  creation_token = "efs-${var.proxyname}-${var.project}-${var.environment}"

  tags {
    Name        = "efs-${var.proxyname}-${var.project}-${var.environment}"
    Environment = "${var.environment}"
    Project     = "${var.project}"
  }
}

resource "aws_efs_mount_target" "hacaddy_efs_target" {
  count           = "${var.subnet_count}"
  file_system_id  = "${aws_efs_file_system.hacaddy_efs.id}"
  subnet_id       = "${var.subnet_ids[count.index]}"
  security_groups = ["${aws_security_group.sg_hacaddy.id}"]
}

resource "aws_eip" "hacaddy_eip" {
  count    = 2
  instance = "${module.hacaddy_instance.instance_ids[count.index]}"
  vpc      = true

  lifecycle {
    ignore_changes = ["instance"]
  }
}

resource "aws_iam_role_policy" "hacaddy_policy" {
  name = "policy_${var.proxyname}_${var.project}_${var.environment}"
  role = "${module.hacaddy_instance.role_id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress"
      ],
      "Sid": "Stmt1375723773000",
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_security_group" "sg_hacaddy" {
  name        = "sg_${var.proxyname}_${var.project}_${var.environment}"
  description = "Security group for hacaddy"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name        = "${var.project}-${var.environment}-sg_${var.proxyname}"
    Environment = "${var.environment}"
    Project     = "${var.project}"
  }
}

## INGRESS

resource "aws_security_group_rule" "hacaddy_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.sg_hacaddy.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "hacaddy_https_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.sg_hacaddy.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "hacaddy_icmp_ingress" {
  type                     = "ingress"
  from_port                = "-1"
  to_port                  = "-1"
  protocol                 = "icmp"
  security_group_id        = "${aws_security_group.sg_hacaddy.id}"
  source_security_group_id = "${aws_security_group.sg_hacaddy.id}"
}

resource "aws_security_group_rule" "hacaddy_vrrp_ingress" {
  type                     = "ingress"
  from_port                = "-1"
  to_port                  = "-1"
  protocol                 = "112"
  security_group_id        = "${aws_security_group.sg_hacaddy.id}"
  source_security_group_id = "${aws_security_group.sg_hacaddy.id}"
}

resource "aws_security_group_rule" "hacaddy_efs_ingress" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.sg_hacaddy.id}"
  source_security_group_id = "${aws_security_group.sg_hacaddy.id}"
}

## EGRESS

resource "aws_security_group_rule" "hacaddy_icmp_egress" {
  type                     = "egress"
  from_port                = "-1"
  to_port                  = "-1"
  protocol                 = "icmp"
  security_group_id        = "${aws_security_group.sg_hacaddy.id}"
  source_security_group_id = "${aws_security_group.sg_hacaddy.id}"
}

resource "aws_security_group_rule" "hacaddy_puppet_egress" {
  type              = "egress"
  from_port         = 8140
  to_port           = 8140
  protocol          = "tcp"
  security_group_id = "${aws_security_group.sg_hacaddy.id}"
  cidr_blocks       = ["176.58.117.244/32"]
}

resource "aws_security_group_rule" "hacaddy_vrrp_egress" {
  type                     = "egress"
  from_port                = "-1"
  to_port                  = "-1"
  protocol                 = "112"
  security_group_id        = "${aws_security_group.sg_hacaddy.id}"
  source_security_group_id = "${aws_security_group.sg_hacaddy.id}"
}

resource "aws_security_group_rule" "hacaddy_efs_egress" {
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.sg_hacaddy.id}"
  source_security_group_id = "${aws_security_group.sg_hacaddy.id}"
}
