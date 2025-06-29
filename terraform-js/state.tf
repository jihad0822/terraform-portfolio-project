terraform {
    backend "s3" {
        bucket = "jw-terraform-state-bucket"
        key = "global/s3/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "my_db_website_table"
    }
}