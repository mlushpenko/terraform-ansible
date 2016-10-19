resource "null_resource" "ansible_copy" {
	triggers = {
		instance_count_changed = "${var.aws_instances_count}" 
		elb_was_updated = "${length(aws_elb.web.instances)}"
	}

	provisioner "file" {
    source = "ansible/"
    destination = "/home/ubuntu"
  }
  connection {
  	user        = "ubuntu"
    private_key = "demo.pem"
    host				= "${aws_instance.ansible.public_ip}"
  }

  #depends_on = ["null_resource.ansible_inventory_hosts"]
  depends_on = ["null_resource.ansible_dynamic_inventory"]
} 

resource "null_resource" "ssh_copy" {
	provisioner "file" {
    source = "demo.pem"
    destination = "/home/ubuntu/demo.pem"
  }
  connection {
  	user        = "ubuntu"
    private_key = "demo.pem"
    host				= "${aws_instance.ansible.public_ip}"
  }
} 

resource "null_resource" "ansible_exec" {
	triggers = {
		instance_count_changed = "${var.aws_instances_count}" 
		elb_was_updated = "${length(aws_elb.web.instances)}"
	}

	provisioner "remote-exec" {
    inline = [
      "chmod 400 demo.pem",
	    "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook apache.yml -i inventory --key-file=demo.pem",
    ]
  }
	connection {
  	user        = "ubuntu"
    private_key = "demo.pem"
    host				= "${aws_instance.ansible.public_ip}"
  }

  depends_on = ["null_resource.ansible_copy", "null_resource.ssh_copy"]
}
