#make the shell search for first match of bash in $PATH
#!/usr/bin/env bash
#-t algorithm -b keysize -f filetostorekey -q dontshowoutput -P passphrase
ssh-keygen -t rsa -b 2048 -f ~/.ssh/ServianSSHKeyPair -q -P ''
#sets permissions so that only owner can read to prevent unprotected private key file err
chmod 400 ~/.ssh/ServianSSHKeyPair
#ansible requires private key file to be NOT accessible by others