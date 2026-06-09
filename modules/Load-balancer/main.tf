resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"

  security_groups = var.security_groups
  subnets         = var.subnets

  idle_timeout               = var.idle_timeout
  enable_deletion_protection = var.enable_deletion_protection
  client_keep_alive          = var.client_keep_alive

  drop_invalid_header_fields = var.drop_invalid_header_fields
  enable_http2               = var.enable_http2

  enable_waf_fail_open       = var.enable_waf_fail_open
  xff_header_processing_mode = var.xff_header_processing_mode

  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  ip_address_type = var.ip_address_type

  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = var.access_logs_prefix
    enabled = var.access_logs_enabled
  }

  tags = var.tags
}




resource "aws_lb_target_group" "this" {
  name        = var.tg_name
  port        = var.tg_port
  protocol    = var.tg_protocol
  target_type = var.target_type
  vpc_id      = var.vpc_id
  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = var.health_check_protocol
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 86400
  }
}



# HTTP to HTTPS Redirect

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
