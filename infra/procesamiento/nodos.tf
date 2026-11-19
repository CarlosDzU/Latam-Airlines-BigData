# Clúster Spark: un master (que también procesa) y de 0 a 2 workers.

locals {
  nodo_comun = {
    bucket         = local.bucket
    region         = var.region
    repo_url       = var.repo_url
    repo_rama      = var.repo_rama
    spark_version  = var.spark_version
    spark_sha512   = var.spark_sha512
    spark_defaults = local.spark_defaults
    executor_cores = var.memoria.executor_cores
  }
}

resource "aws_instance" "master" {
  ami                         = data.aws_ssm_parameter.ami_al2023.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.publica.id
  vpc_security_group_ids      = [aws_security_group.cluster.id]
  iam_instance_profile        = aws_iam_instance_profile.nodo.name
  user_data_replace_on_change = true

  user_data = templatefile("${path.module}/user_data.sh.tftpl", merge(local.nodo_comun, {
    es_master      = true
    master_ip      = ""
    memoria_worker = var.memoria.worker_en_master
  }))

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.ebs_gb
    encrypted             = true
    delete_on_termination = true
  }

  tags = { Name = "${var.proyecto}-master", Rol = "master" }

  depends_on = [aws_route_table_association.publica, aws_vpc_endpoint.s3]
}

resource "aws_instance" "worker" {
  count                       = var.worker_count
  ami                         = data.aws_ssm_parameter.ami_al2023.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.publica.id
  vpc_security_group_ids      = [aws_security_group.cluster.id]
  iam_instance_profile        = aws_iam_instance_profile.nodo.name
  user_data_replace_on_change = true

  user_data = templatefile("${path.module}/user_data.sh.tftpl", merge(local.nodo_comun, {
    es_master      = false
    master_ip      = aws_instance.master.private_ip
    memoria_worker = var.memoria.worker
  }))

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.ebs_gb
    encrypted             = true
    delete_on_termination = true
  }

  tags = { Name = "${var.proyecto}-worker-${count.index + 1}", Rol = "worker" }
}
