# Datos que este stack lee de afuera.

# Nombre y ARN del bucket, desde el estado local de infra/almacenamiento (debe aplicarse antes).
data "terraform_remote_state" "almacenamiento" {
  backend = "local"
  config = {
    path = "${path.module}/../almacenamiento/terraform.tfstate"
  }
}

# Amazon Linux 2023 más reciente que publica AWS.
data "aws_ssm_parameter" "ami_al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_availability_zones" "disponibles" {
  state = "available"
}

data "aws_caller_identity" "actual" {}

locals {
  bucket     = data.terraform_remote_state.almacenamiento.outputs.bucket_name
  bucket_arn = data.terraform_remote_state.almacenamiento.outputs.bucket_arn
  crawler    = data.terraform_remote_state.almacenamiento.outputs.crawler_name
  cuenta     = data.aws_caller_identity.actual.account_id
  az         = data.aws_availability_zones.disponibles.names[0]

  spark_defaults = templatefile("${path.module}/spark-defaults.conf.tftpl", {
    bucket         = local.bucket
    region         = var.region
    driver_mem     = var.memoria.driver
    executor_mem   = var.memoria.executor
    executor_cores = var.memoria.executor_cores
  })
}
