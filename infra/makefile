#Terraform Command Line Tool to execute changes in environments

init: #validate backend config and create statefile if doesn't exist
#scan terraform files to see what sort of modules and providers
#to download and make environment ready accordingly
	terraform init

#give access to value directly - clean string
albendpoint: #pbcopy copies string of the value
	terraform output alb_endpoint | pbcopy

up: #validate code, format indentations & styling correctly and deploy
	terraform validate
	terraform fmt
	sh deployinfra.sh
 
down:
	sh destroyinfra.sh
