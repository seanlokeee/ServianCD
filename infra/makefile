#Terraform Command Line Tool to execute changes in environments

init: #validate backend config and create statefile if doesn't exist
#scan terraform files to see what sort of modules and providers
#to download and make environment ready accordingly
	terraform init

#access value directly - clean string (remove " start & end)
albendpoint: #prints string with no extra escaping or whitespace & copy value
	terraform output -raw alb_endpoint | pbcopy

up: #validate code, format indentations & styling correctly and deploy
	terraform validate
	terraform fmt
	sh deployinfra.sh
 
down:
	sh destroyinfra.sh
