#!/bin/bash
dnf install -y httpd
echo "hello from $(hostname) - w1 app tier" > /var/www/html/index.html
systemctl enable --now httpd
