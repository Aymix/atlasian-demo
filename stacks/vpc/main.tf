################################################################################
# VPC Stack — SIMULATED (no AWS required)
# Uses null_resource + random to simulate VPC infrastructure
################################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

module "tags" {
  source       = "../../modules/tags"
  project_name = var.project_name
  environment  = var.environment
}

# Simulated VPC
resource "null_resource" "vpc" {
  triggers = {
    cidr_block  = var.vpc_cidr
    environment = var.environment
    name        = "${var.project_name}-${var.environment}-vpc"
  }
}

resource "random_id" "vpc" {
  byte_length = 8
  keepers = {
    cidr = var.vpc_cidr
  }
}

# Simulated Subnets
resource "null_resource" "public_subnets" {
  count = length(var.availability_zones)

  triggers = {
    cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
    availability_zone = var.availability_zones[count.index]
    tier              = "public"
    name              = "${var.project_name}-${var.environment}-public-${var.availability_zones[count.index]}"
  }
}

resource "null_resource" "private_subnets" {
  count = length(var.availability_zones)

  triggers = {
    cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.availability_zones))
    availability_zone = var.availability_zones[count.index]
    tier              = "private"
    name              = "${var.project_name}-${var.environment}-private-${var.availability_zones[count.index]}"
  }
}

# Simulated NAT Gateway
resource "null_resource" "nat_gateway" {
  triggers = {
    name = "${var.project_name}-${var.environment}-nat"
  }
}

# Simulated Internet Gateway
resource "null_resource" "internet_gateway" {
  triggers = {
    name = "${var.project_name}-${var.environment}-igw"
  }
}

resource "aws_vpc" "main" {
  # ... existing config ...
  tags = {
    Name       = "${var.project_name}-${var.environment}-vpc"
    CostCenter = "engineering"
  }
}
