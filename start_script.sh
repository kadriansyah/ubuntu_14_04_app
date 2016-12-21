#!/bin/bash
sudo service nginx start && sudo service elasticsearch start && sudo service redis_6379 start && tail -f /var/log/nginx/access.log
