provider "aws" {
  region = "ap-southeast-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "provisioning-key" {
  key_name   = "provisioning-key"
  public_key = file("${path.module}/provisioning-key.pub")
  
  tags = {
    Name = "provisioning-key"
  }
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  key_name      = aws_key_pair.provisioning-key.key_name
  user_data     = file("installDependencies.sh")
  tags = {
    Name = "provisioning-server"
  }

  provisioner "remote-exec" {
    inline = ["echo 'SSH is ready!'"]
    
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("provisioning-key")
      host        = self.public_ip
      timeout     = "5m"
    }
  }
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}