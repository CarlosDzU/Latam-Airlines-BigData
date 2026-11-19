# Catálogo (Glue) y motor de consulta SQL (Athena) sobre los datos del bucket.

resource "aws_glue_catalog_database" "lake" {
  name = replace(var.proyecto, "-", "_")
}

# Rol que usa el crawler para leer el bucket y registrar las tablas.
data "aws_iam_policy_document" "glue_confianza" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "crawler" {
  name               = "${var.proyecto}-crawler"
  assume_role_policy = data.aws_iam_policy_document.glue_confianza.json
}

resource "aws_iam_role_policy_attachment" "crawler_servicio" {
  role       = aws_iam_role.crawler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

data "aws_iam_policy_document" "crawler_lectura" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.lake.arn]
  }
  statement {
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.lake.arn}/silver/*",
      "${aws_s3_bucket.lake.arn}/gold/*",
    ]
  }
}

resource "aws_iam_role_policy" "crawler_lectura" {
  name   = "lectura-silver-gold"
  role   = aws_iam_role.crawler.id
  policy = data.aws_iam_policy_document.crawler_lectura.json
}

# Se ejecuta a mano cuando hay tablas nuevas; no tiene horario para no generar costo.
resource "aws_glue_crawler" "lake" {
  name          = "${var.proyecto}-catalogo"
  database_name = aws_glue_catalog_database.lake.name
  role          = aws_iam_role.crawler.arn

  s3_target {
    path = "s3://${aws_s3_bucket.lake.bucket}/silver/"
  }

  s3_target {
    path = "s3://${aws_s3_bucket.lake.bucket}/gold/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }
}

resource "aws_athena_workgroup" "lake" {
  name          = var.proyecto
  force_destroy = var.force_destroy

  configuration {
    enforce_workgroup_configuration = true
    bytes_scanned_cutoff_per_query  = 10737418240 # 10 GB por consulta como tope de gasto

    result_configuration {
      output_location = "s3://${aws_s3_bucket.lake.bucket}/athena-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}
