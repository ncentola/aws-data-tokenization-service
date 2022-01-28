resource "aws_kms_key" "this" {
  description             = var.key_description
  deletion_window_in_days = var.key_deletion_window_in_days

  lifecycle {
    prevent_destroy = false
  }
}
