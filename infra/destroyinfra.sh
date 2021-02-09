#shebang (#!) directive to the loader to use bash as interpreter for the file
#!/bin/bash
set +ex #don't print each executed command

#-z check whether terraform public key variable empty
if [[ -z ${TF_VAR_public_key} ]]; then #empty
    export TF_VAR_public_key=$(cat ~/.ssh/ServianSSHKeyPair.pub)
    #tears down all deployed resources except for remote backend setup
	terraform destroy --auto-approve
else #not empty 
    #flag used to skip yes step after plan command is entered
	terraform destroy --auto-approve
fi #CircleCI Pipeline deploy need flag because
#nobody inside to click a button (headless inside the container) 
