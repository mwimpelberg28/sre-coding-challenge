# Create a security group
resource "aws_security_group" "jenkins" {
  name        = "ejenkins-sg"
  description = "Security group for jenkins"
  vpc_id = module.vpc.vpc_id

 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH traffic only from a specific IP range
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH traffic only from a specific IP range
  }

  # Outbound rules (egress rules)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic to anywhere (0.0.0.0/0)
  }
}