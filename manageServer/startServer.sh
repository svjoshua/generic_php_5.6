#!/bin/bash
if [ `whoami` != "root" ]; then
	echo "Script must be executed as root"
	exit 1
fi
TITLE='[35m'
INPUT='[32m'
RESET='[0m'

echo -e "\e${TITLE} -=Start Barberstock=- \e${RESET}"
systemctl restart apache2
#mongo local for future use
service mongod start
echo -e "\e${TITLE} -=End Startup=- \e${RESET}"
echo -e "\e${TITLE} Access Barberstock via the browser at barberstock.local/[client name] \e${RESET}"