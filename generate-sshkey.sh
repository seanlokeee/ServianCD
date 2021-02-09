#make the shell search for first match of bash in $PATH
#!/usr/bin/env bash
#-t algorithm -b keysize -f filetostorekey -q dontshowoutput -P passphrase
ssh-keygen -t rsa -b 2048 -f ~/.ssh/ServianSSHKeyPair -q -P ''
#sets permissions so that only owner & users that are set up can read 
chmod 440 ~/.ssh/ServianSSHKeyPair
#-y read private OpenSSH format file and print an OpenSSH  to stdout
#ssh-keygen -y -f ~/.ssh/ServianSSHKeyPair > ~/.ssh/ServianSSHKeyPair.pem
