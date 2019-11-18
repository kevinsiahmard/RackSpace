# RackSpace
First edit and enter required info in terraform.tfvars file<br/>
then run: 1- terraform init<br/>
          2- terraform plan -var-file="terraform.tfvars"<br/>
          3- terraform apply -var-file="terraform.tfvars"<br/>
after provisioning of objects in AWS, you have to use Ansible for configuring servers.<br/>
First, edit vars.yml, and hosts files and enter required info<br/>
then run: ansible-plasybook -i host wordpress.yml <br/>
after configuring servers, connect to one of web servers and complete wordpress configuration<br/>
finally, you have to be able to get access through ELB.<br/>
