# ## SecurityGroup Module
module alb-sg {
  source = "terraform-aws-modules/security-group/aws"
  name   = "alb-sg"
  vpc_id = module.main-vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp", "http-80-tcp"]
  egress_rules        = ["all-all"]
}

module nginx-sg {
  source = "terraform-aws-modules/security-group/aws"
  name   = "nginx-sg"
  vpc_id = module.main-vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "http-80-tcp"
      cidr_blocks = module.main-vpc.vpc_cidr_block
    },
    {
      rule        = "ssh-tcp"
      cidr_blocks = "192.168.0.0/16"
      description = ""
    }
  ]

  ingress_with_source_security_group_id = [
    {
      # from_port                = -1
      # to_port                  = -1
      # protocol                 = "-1"
      rule                     = "all-all"
      description              = "alb"
      source_security_group_id = module.alb-sg.this_security_group_id
    }
  ]

  egress_rules = ["all-all"]
}
