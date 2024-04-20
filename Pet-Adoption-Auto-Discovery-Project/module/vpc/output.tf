output "vpc_id" {
  value = aws_vpc.vpc.id
}
output "publicsub1" {
  value = aws_subnet.publicsub[0].id
}
output "publicsub2" {
  value = aws_subnet.publicsub[1].id
}
output "publicsub3" {
  value = aws_subnet.publicsub[2].id
}
output "privatesub1" {
  value = aws_subnet.privatesub[0].id
}
output "privatesub2" {
  value = aws_subnet.privatesub[1].id
}
output "privatesub3" {
  value = aws_subnet.privatesub[2].id
}