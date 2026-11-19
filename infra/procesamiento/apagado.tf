# Si un nodo pasa idle_stop_minutes con CPU promedio menor a 5 %, CloudWatch lo apaga.
# Es la red de seguridad por si alguien olvida hacer terraform destroy.

locals {
  nodos = merge(
    { master = aws_instance.master.id },
    { for i, w in aws_instance.worker : "worker-${i + 1}" => w.id },
  )
}

resource "aws_cloudwatch_metric_alarm" "ocioso" {
  for_each            = local.nodos
  alarm_name          = "${var.proyecto}-${each.key}-ocioso"
  alarm_description   = "Apaga ${each.key} tras ${var.idle_stop_minutes} min con CPU menor a 5 %."
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions          = { InstanceId = each.value }
  statistic           = "Average"
  period              = 900
  evaluation_periods  = var.idle_stop_minutes / 15
  threshold           = 5
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "missing"
  alarm_actions       = ["arn:aws:automate:${var.region}:ec2:stop"]
}
