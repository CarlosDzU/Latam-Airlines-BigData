# Rol de los nodos: permisos temporales que AWS entrega a la instancia, sin claves en el código.

data "aws_iam_policy_document" "ec2_confianza" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "nodo" {
  name               = "${var.proyecto}-nodo"
  assume_role_policy = data.aws_iam_policy_document.ec2_confianza.json
}

data "aws_iam_policy_document" "nodo" {
  statement {
    sid       = "ListarBucket"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [local.bucket_arn]
  }

  statement {
    sid       = "LeerEscribirBucket"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:AbortMultipartUpload"]
    resources = ["${local.bucket_arn}/*"]
  }

  statement {
    sid       = "LanzarCrawler"
    actions   = ["glue:StartCrawler", "glue:GetCrawler"]
    resources = ["arn:aws:glue:${var.region}:${local.cuenta}:crawler/${local.crawler}"]
  }
}

resource "aws_iam_role_policy" "nodo" {
  name   = "bucket-y-catalogo"
  role   = aws_iam_role.nodo.id
  policy = data.aws_iam_policy_document.nodo.json
}

# Permite administrar la instancia por Session Manager (túnel y terminal) sin SSH.
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.nodo.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nodo" {
  name = "${var.proyecto}-nodo"
  role = aws_iam_role.nodo.name
}
