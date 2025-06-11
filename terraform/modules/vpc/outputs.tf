output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
  description = "A list of IDs of the created public subnets."
  value       = aws_subnet.public.*.id # Use splat expression to get all IDs
}

# If you needed to output specific public subnet IDs by index, you could do:
output "public_subnet_1_id" {
  description = "The ID of the first public subnet."
  value       = element(aws_subnet.public.*.id, 0) # Gets the ID of the first subnet (index 0)
  # Or simply: value = aws_subnet.public[0].id
}

output "public_subnet_2_id" {
  description = "The ID of the second public subnet."
  value       = element(aws_subnet.public.*.id, 1) # Gets the ID of the second subnet (index 1)
  # Or simply: value = aws_subnet.public[1].id
}


output "internet_gateway_id" {
  description = "The ID of the Internet Gateway."
  value       = aws_internet_gateway.main_igw.id
}

output "public_route_table_id" {
  description = "The ID of the public route table."
  value       = aws_route_table.public_rt.id
}

output "private_subnet_ids" {
  description = "A list of IDs of the created private subnets."
  value       = aws_subnet.private.*.id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway."
  value       = aws_nat_gateway.main_nat_gateway.id
}

output "private_route_table_id" {
  description = "The ID of the private route table."
  value       = aws_route_table.private_rt.id
}