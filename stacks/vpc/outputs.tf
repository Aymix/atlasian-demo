output "vpc_id" {
  description = "The simulated VPC ID"
  value       = "vpc-${random_id.vpc.hex}"
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = var.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of simulated public subnet IDs"
  value       = [for i, s in null_resource.public_subnets : "subnet-pub-${i}"]
}

output "private_subnet_ids" {
  description = "List of simulated private subnet IDs"
  value       = [for i, s in null_resource.private_subnets : "subnet-priv-${i}"]
}

output "nat_gateway_id" {
  description = "Simulated NAT Gateway ID"
  value       = "nat-${random_id.vpc.hex}"
}

output "internet_gateway_id" {
  description = "Simulated Internet Gateway ID"
  value       = "igw-${random_id.vpc.hex}"
}
