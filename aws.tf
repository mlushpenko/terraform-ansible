provider "aws" {
  access_key = "${var.aws_keys["access"]}"
  secret_key = "${var.aws_keys["secret"]}"
  region     = "${var.aws_region}"
}

resource "aws_elb" "web" {
  name = "${var.user_prefix}-elb"

  subnets         = ["${aws_subnet.default.id}"]
  security_groups = ["${aws_security_group.elb.id}"]

  # The instances are registered automatically
  instances = ["${aws_instance.web.*.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 10
    timeout = 10
    target = "HTTP:80/index.html"
    interval = 30
  }
}

resource "aws_instance" "ansible" {
  tags = {
    Name  = "${var.user_prefix}-ansible"
    group = "ansible_master"
  }

  instance_type          = "m1.small"
  ami                    = "${lookup(var.aws_amis, var.aws_region)}"
  subnet_id              = "${aws_subnet.default.id}"
  vpc_security_group_ids = ["${aws_security_group.ansible.id}"]

  connection {
    # The default username for our AMI
    user        = "ubuntu"
    private_key = "Accenture.pem"
  }

  key_name = "Accenture"

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y install python-software-properties",
      "sudo apt-add-repository -y ppa:ansible/ansible",
      "sudo apt-get -y update",
      "sudo apt-get -y install ansible",
    ]
  }
}

resource "aws_instance" "web" {
  tags = {
    Name  = "${var.user_prefix}-web-${count.index}"
    group = "web"
  }

  instance_type = "m1.small"
  ami           = "${lookup(var.aws_amis, var.aws_region)}"
  key_name      = "Accenture"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.default.id}"]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.default.id}"

  # This will create a number of instances idicated below
  count = "${var.aws_instances_count}"
}
