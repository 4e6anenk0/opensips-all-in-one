service rsyslog start
service apache2 start
service mysql start

iptables -t nat -A OUTPUT -o lo -p tcp --dport 8080 -j REDIRECT --to-port 3306

/usr/sbin/opensipsctl start

tail -f /var/log/opensips.log