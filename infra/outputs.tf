# Copy these into the repository variables used by .github/workflows/deploy.yml.

output "aws_region" {
  value = var.region
}

output "aws_role_arn" {
  description = "Repository variable AWS_ROLE_ARN"
  value       = aws_iam_role.github_deploy.arn
}

output "ecr_repository" {
  description = "Repository variable ECR_REPOSITORY"
  value       = aws_ecr_repository.api.name
}

output "ecs_cluster" {
  description = "Repository variable ECS_CLUSTER"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service" {
  description = "Repository variable ECS_SERVICE"
  value       = aws_ecs_service.api.name
}

output "task_definition_family" {
  description = "Repository variable ECS_TASK_FAMILY"
  value       = aws_ecs_task_definition.api.family
}
