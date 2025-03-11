provider "aws" {
    region = "eu-north-1"
}

resource "aws_instance" "ubuntu_instance" {
    ami           = "ami-02e2af61198e99faf"
    instance_type = "t3.micro"
    tags = {
        Name = var.instance_name
    }
    vpc_security_group_ids = [aws_security_group.ec2_security_group.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "HELLO WORLD" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
    user_data_replace_on_change = true
}

resource "aws_security_group" "ec2_security_group" {
    name = "web"
    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}