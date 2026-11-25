# Data module: restores the Day 4 database from its kept manual snapshot
# into the new data tier. Engine, storage, and credentials are inherited
# from the snapshot; only placement and class are set here.

resource "aws_db_subnet_group" "w1" {
  name       = "w1-data-subnet-group"
  subnet_ids = var.data_subnet_ids

  tags = { Name = "w1-data-subnet-group" }
}

resource "aws_db_instance" "app" {
  identifier             = "app-db"
  snapshot_identifier    = var.snapshot_id
  instance_class         = var.instance_class
  db_subnet_group_name   = aws_db_subnet_group.w1.name
  vpc_security_group_ids = [var.data_security_group_id]
  publicly_accessible    = false
  multi_az               = false

  # The restore source (app-db-manual-1) is kept separately, so a later
  # terraform destroy of this lab instance does not need a final snapshot.
  skip_final_snapshot = true

  tags = { Name = "app-db" }
}
