#!/usr/bin/expect -f

set timeout -1
spawn sandpiper-saas -h
match_max 100000
expect -exact "Please review our Terms of Service: https://makerchip.com/terms/.\r
Have you read and do you accept these Terms of Service? \[y/N\]: "
send -- "y\r"
expect eof
