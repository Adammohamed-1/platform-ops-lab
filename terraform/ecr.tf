resource "aws_ecr_repository" "platform_api" {
  name         = "platform-ops-lab"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "platform-ops-lab"
  }
}
