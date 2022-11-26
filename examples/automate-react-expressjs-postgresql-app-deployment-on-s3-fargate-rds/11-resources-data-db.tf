#################
# IAM resources #
#################

resource "aws_iam_role" "rds_monitoring_role" {
  name = "rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  ]
}

######################
# Database resources #
######################

resource "aws_db_subnet_group" "data_db_subnet_grp" {
  name = "${var.sys_name}-db-subnet-grp"
  subnet_ids = [for s in aws_subnet.sys_private_subnets: "${s.id}"]

  tags = {
    Name = "${var.sys_name}-db-subnet-grp"
  }
}

resource "aws_db_instance" "data_dbi" {
  identifier            = "${var.sys_name}-data-dbi"
  db_name               = var.data_db_name
  engine                = "postgres"
  engine_version        = "12.11"
  instance_class        = "db.t3.medium"
  allocated_storage     = 29
  max_allocated_storage = 1000
  vpc_security_group_ids = [
    aws_security_group.data_db_sg.id
  ]
  parameter_group_name                = "default.postgres12"
  db_subnet_group_name                = aws_db_subnet_group.data_db_subnet_grp.name
  username                            = "postgres"
  password                            = var.data_master_db_password
  apply_immediately                   = true
  skip_final_snapshot                 = true
  copy_tags_to_snapshot               = true
  customer_owned_ip_enabled           = false
  deletion_protection                 = false  # IMPORTANT: This is just to be easy to destroy the whole stack. In your actual enviroment, it should be true.
  iam_database_authentication_enabled = false
  iops                                = 0
  performance_insights_enabled        = true
  publicly_accessible                 = false
  storage_encrypted                   = true
  monitoring_interval                 = 60
  monitoring_role_arn                 = aws_iam_role.rds_monitoring_role.arn
  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade"
  ]
  backup_retention_period = 7
  backup_window           = "18:00-18:30"
  maintenance_window      = "Sat:20:00-Sat:20:30"
}
