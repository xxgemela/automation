#!/bin/bash
/usr/bin/ldapmodify -h localhost -p 10389 -D "uid=admin,ou=system" -w <%= @toas_apacheds_pwd %> -a -f replication.ldif