# Script

Use the following script to retrieve and convert XML permissions from your docker container database

For the script to work all apps must be published and have their own XML permissions and external apps XML permissions on different XML files

The script should take almost 1 minute to complete, if some errors are triggered in the bash the script will work as usual

The expected output are AL permission set files named like the XML permission files

## EXAMPLE

DatabaseServer:     <BC Container>      (ex: bcserverdemo)
DatabaseName:       <Company Name>      (ex: CRONUS)
DatabaseUsername:   <Username>          (ex: myusername)
DatabasePassword:   <Password>          (ex: mypassword)
Destination:        <Path to folder>    (ex: 'C:\Users\myuser\Desktop\Permissions')


