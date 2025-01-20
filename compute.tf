resource "aws_lb" "app_lb" {

  # ... other configurations ...

  security_groups = [aws_security_group.alb_sg.id]

}

resource "aws_instance" "app_instance" {

  # ... other configurations ...

  security_groups = [aws_security_group.ec2_sg.id]

}
