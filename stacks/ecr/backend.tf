# Local backend — no S3 required
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
