# https://github.com/hashicorp/terraform/issues/4084
# Create a list of groups like [web]/n[db]
# resource "null_resource" "ansible_groups" {
#   triggers = {
#     groups = "${join(",", formatlist("[%v]", distinct(concat(list(aws_instance.ansible.tags.group), aws_instance.web.*.tags.group))))}"
#   }
# }

# # Add ansible groups to inventory file
# resource "null_resource" "ansible_inventory_groups" {
#   provisioner "local-exec" {
#     command = "echo ${null_resource.ansible_groups.triggers.groups} >> ansible/inventory && sed -i 's/,/\\n/' ansible/inventory"
#   }
# }

# # Add web hosts to the web group
# resource "null_resource" "ansible_inventory_hosts" {
#   count = "${var.aws_instances_count}"

#   provisioner "local-exec" {
#     command = "sed -i '/\\[${element(aws_instance.web.*.tags.group, count.index)}\\]/ a ${element(aws_instance.web.*.private_ip, count.index)}' ansible/inventory"
#   }

#   depends_on = ["null_resource.ansible_inventory_groups"]
# }

resource "null_resource" "ansible_dynamic_inventory" {
  triggers = {
    instance_count_changed = "${var.aws_instances_count}" 
    # for cases when infrastructre malfunctions and has to be reprovisioned
    elb_was_updated = "${length(aws_elb.web.instances)}" 
  }
  provisioner "local-exec" {
    command = "grep '\"private_ip\":' terraform.tfstate | grep -P '(?:[0-9]{1,3}\\.){3}[0-9]{1,3}' -o | sed '/${aws_instance.ansible.private_ip}/d' > ansible/inventory"
  }

  depends_on = ["aws_instance.web"]
}