output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "aws_region" {
  value = "eu-west-2"
}

output "ecr_repository_url" {
  value = aws_ecr_repository.platform_api.repository_url
}
