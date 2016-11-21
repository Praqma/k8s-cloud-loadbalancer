#!/usr/bin/env bash
source lb-nodeport.f

echo " - Running createLoadBalancer"
createLoadBalancer haproxy default

# echo " - Cleaning up old files"
# rm -f /etc/httpd/conf.d/*.bl

# echo " - Copying files"
# mv -f kubernetes.services.conf /etc/httpd/conf.d/
# mv -f *.service.bl /etc/httpd/conf.d/

# echo " - Restarting httpd"
# sudo service httpd reload

echo "Restarting haproxy"
sudo systemctl restart haproxy 

# cp -f haproxy.cfg /etc/haproxy/

sleep 2

sudo systemctl status haproxy
