data "archive_file" "data_mover" {
  type        = "zip"
  source_dir  = "data_mover"
  output_path = "data_mover.zip"
}