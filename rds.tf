##############################################################
# Data sources to get VPC, subnets and security group details
##############################################################

resource "aws_db_subnet_group" "postgresql-subnets" {
  name        = "postgresql-subnets"
  description = "Amazon RDS subnet group"
  subnet_ids  = "${module.vpc.database_subnets}"
}

resource "aws_security_group" "sec_grp_rds" {
  name_prefix = "${module.cluster.cluster_id}-"
  vpc_id      = "${module.vpc.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${var.tags}"
}

resource "aws_security_group_rule" "allow-workers-nodes-communications" {
  description              = "Allow worker nodes to communicate with database"
  from_port                = 5432
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.sec_grp_rds.id}"
  source_security_group_id = "${module.cluster.worker_security_group_id}" # to allow webserver communication to RDS instance
  to_port                  = 5432
  type                     = "ingress"
}

#RDS Parameters
resource "aws_db_parameter_group" "levelup-postgresql-parameters" {
  name        = "levelup-postgresql-parameters"
  family      = "${var.rds_parameter_group_family}"
  description = "MariaDB parameter group"

  parameter {
    name = "client_encoding",
    value = "utf8"
  }
}

#RDS Instance properties
resource "aws_db_instance" "postgresql" {
  identifier          = "${module.cluster.cluster_id}"
  engine              = "${var.rds_engine}"
  allocated_storage   = "${var.rds_allocated_storage}"             
  engine_version      = "${var.rds_engine_version}"
  instance_class      = "${var.rds_instance_class}"  
  name                = "${var.rds_name}"
  username            = "${var.rds_username}"           
  password            = "${var.rds_password}"
  port                = "${var.rds_port}"
  db_subnet_group_name    = "${aws_db_subnet_group.postgresql-subnets.name}"
  parameter_group_name    = "${aws_db_parameter_group.levelup-postgresql-parameters.name}"
  multi_az                = "false"            # set to true to have high availability: 2 instances synchronized with each other
  vpc_security_group_ids  = ["${aws_security_group.sec_grp_rds.id}"]
  storage_type            = "gp2"
  backup_retention_period = 30  
  skip_final_snapshot     = true 
}