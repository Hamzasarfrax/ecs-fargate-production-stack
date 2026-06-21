output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC."
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "The CIDR block of the VPC."
}

output "public_subnet_ids" {
  value       = values(aws_subnet.public_subnet)[*].id
  description = "List of public subnet IDs."
}

output "private_subnet_ids" {
  value       = values(aws_subnet.private_subnet)[*].id
  description = "List of private subnet IDs."
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.gw.id
  description = "The ID of the Internet Gateway."
}

output "public_route_table_id" {
  value       = aws_route_table.public_route_table.id
  description = "The public route table ID."
}

output "private_route_table_ids" {
  value       = values(aws_route_table.private_route_table)[*].id
  description = "List of private route table IDs."
}

output "nat_gateway_ids" {
  value       = values(aws_nat_gateway.nat_gateway)[*].id
  description = "List of NAT Gateway IDs."
}

output "public_subnet_ids_by_name" {
  value       = { for name, subnet in aws_subnet.public_subnet : name => subnet.id }
  description = "Public subnet IDs keyed by subnet name."
}

output "private_subnet_ids_by_name" {
  value       = { for name, subnet in aws_subnet.private_subnet : name => subnet.id }
  description = "Private subnet IDs keyed by subnet name."
}

output "private_route_table_ids_by_name" {
  value       = { for name, route_table in aws_route_table.private_route_table : name => route_table.id }
  description = "Private route table IDs keyed by private subnet name."
}

output "nat_gateway_ids_by_name" {
  value       = { for name, nat_gateway in aws_nat_gateway.nat_gateway : name => nat_gateway.id }
  description = "NAT Gateway IDs keyed by NAT Gateway name."
}

output "gateway_endpoint_ids" {
  value       = { for name, endpoint in aws_vpc_endpoint.gateway : name => endpoint.id }
  description = "Gateway VPC endpoint IDs keyed by AWS service name."
}

output "interface_endpoint_ids" {
  value       = { for name, endpoint in aws_vpc_endpoint.interface : name => endpoint.id }
  description = "Interface VPC endpoint IDs keyed by AWS service name."
}
