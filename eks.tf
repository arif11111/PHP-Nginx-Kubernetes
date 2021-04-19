// Configure AWS EKS Cluster

locals {
  cluster_name = "my-cluster"
}

module "cluster" {
  version      = "12.2.0"
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = "${local.cluster_name}"
  cluster_version = "1.17"
  subnets      = "${module.vpc.private_subnets}"

  tags = "${var.tags}"

  vpc_id                 = "${module.vpc.vpc_id}"
  worker_groups          = "${var.worker_groups}"
  manage_aws_auth        = "true"
  write_kubeconfig       = "true"
  config_output_path     = "./"
  workers_additional_policies = [aws_iam_policy.worker_policy.arn]
}

resource "aws_iam_policy" "worker_policy" {
  name        = "worker-policy"
  description = "Worker policy for the ALB Ingress"

  policy = file("iam-policy.json")
}

data "aws_eks_cluster" "cluster" {
  name = "${module.cluster.cluster_id}"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "${module.cluster.cluster_id}"
}