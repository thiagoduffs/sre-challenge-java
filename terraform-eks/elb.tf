resource "aws_elb" "eks_elb" {
  name               = "eks-elb"
  internal           = false
  security_groups    = [aws_security_group.eks_sg.id]
  subnets            = aws_subnet.eks_subnets[*].id
  instances          = data.aws_instances.eks_nodes.ids

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port          = 80
    lb_protocol      = "HTTP"
  }

  health_check {
    target              = "HTTP:8080/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "eks-elb"
  }

  depends_on = [aws_eks_node_group.eks_nodes]
}
