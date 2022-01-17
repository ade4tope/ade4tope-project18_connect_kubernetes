module "networking" {
  source   = "./modules/networking"
}

module "dns" {
  source                = "./modules/route53"
  external_alb_dns_name = aws_lb.external-alb.dns_name
  external_alb_zone_id  = aws_lb.external-alb.zone_id
}

module "security_group" {
  source = "./modules/security_groups"
  vpc_id = module.networking.vpc_id
 }

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                    = "my-cluster"
  cluster_version                 = "1.21"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  cluster_encryption_config = [{
    provider_key_arn = "ac01234b-00d9-40f6-ac95-e42345f78b00"
    resources        = ["secrets"]
  }]

  vpc_id     = module.networking.vpc_id
  subnet_ids = [aws_subnet.PrivateSubnet-1.id, aws_subnet.PrivateSubnet-2.id]

 self_managed_node_group_defaults = {
    instance_type                          = "m6i.large"
    update_launch_template_default_version = true
    iam_role_additional_policies           = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  }
}