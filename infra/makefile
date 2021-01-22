#Terraform Command Line Tool to execute changes in environments

init:#validate backend config and create statefile if doesn't exist
#scan terraform files to see what sort of modules and providers
#to download and make environment ready accordingly
	terraform init

#give access to value directly, clean string
ipaddress:#pbcopy copies string of the value
	terraform output instance_public_ip | pbcopy

lbendpoint:
	terraform output lb_endpoint | pbcopy

#validate code and format indentations & styling correctly
check:#outline differences which will happen to environment if
#applied, comparing HCL states vs current states
	terraform validate
	terraform fmt
	terraform plan

#apply HCL against environment and make any necessary changes
up:#flag is useful for skipping steps (E.g. yes step after plan
#command is entered). Deploying to CI tool need it because
#nobody inside to click a button, headless inside the container
	terraform apply --auto-approve

down:#teardown all deployed resources
	terraform destroy --auto-approve
