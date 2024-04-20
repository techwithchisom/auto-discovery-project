output "stage-lb-dns" {
  value = aws_lb.stage-alb.dns_name
}
output "stage-lb-arn" {
  value = aws_lb.stage-alb.arn
}
output "stage-lb-zoneid" {
  value = aws_lb.stage-alb.zone_id
}
output "stage-tg-arn" {
  value = aws_lb_target_group.stage-tg.arn
}
