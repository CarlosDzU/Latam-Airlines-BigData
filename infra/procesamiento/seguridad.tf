# Ningún puerto abierto a internet: las personas entran solo por Session Manager (SSM).
# Los nodos se hablan entre sí libremente y salen a internet únicamente por HTTPS.

resource "aws_security_group" "cluster" {
  name        = "${var.proyecto}-cluster"
  description = "Nodos Spark sin ingreso desde internet"
  vpc_id      = aws_vpc.cluster.id
  tags        = { Name = "${var.proyecto}-cluster" }
}

resource "aws_vpc_security_group_ingress_rule" "entre_nodos" {
  security_group_id            = aws_security_group.cluster.id
  description                  = "Trafico entre nodos del cluster"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.cluster.id
}

resource "aws_vpc_security_group_egress_rule" "entre_nodos" {
  security_group_id            = aws_security_group.cluster.id
  description                  = "Trafico hacia otros nodos del cluster"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.cluster.id
}

resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.cluster.id
  description       = "HTTPS saliente: paquetes, Spark, GitHub, fuentes de datos y APIs de AWS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}
