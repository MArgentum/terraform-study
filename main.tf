provider "aws" {
    region = "eu-north-1"
}

resource "aws_instance" "ec2_instance" {
    ami           = "ami-02e2af61198e99faf"
    instance_type = "t3.micro"
    tags = {
        Name = "ubuntu-server"
    }
}
