alias dssh='ssh -p 2222'
alias dscp='scp -P 2222'
alias tssh='ssh -p 3022'
alias tscp='scp -P 3022'

# paths
alias kyos='cd ~/Projects/kyos'
alias kc='cd ~/kyos/'
alias kd='cd ~/kyos/platform'
alias it='cd ~/Projects/kyos/+engineering/itsupport'
alias ct='cd ~/Projects/kyos/+engineering/clients'
alias opstf='cd ~/Projects/kyos/+engineering/ops-terraform'
alias opsan='cd ~/Projects/kyos/+engineering/ops-ansible'

# docker compose
alias kddown='kd && docker compose down && cd -'
alias kdup='kd && docker compose up -d && cd -'
alias kdps='kd && docker compose ps && cd -'

# container execs
alias dmysql='docker exec -it mysql-db mysql -u root -proot kyosonline'
alias dcron='docker exec -it cron /bin/bash'
alias dphp='docker exec -it kyos-php /bin/bash'
alias dart='docker exec -it kyos-php php artisan'
alias dide='docker exec -it kyos-php composer ide'
alias dmig='docker exec -it kyos-php bash /startup.sh'

# xdebug related
alias xdon='docker exec -it php-server /bin/bash -c "xdebug-switch 1" && docker stop php-server && docker start php-server'
alias xdoff='docker exec -it php-server /bin/bash -c "xdebug-switch 0" && docker stop php-server && docker start php-server'

# unit tests
alias cttest='cd ~/Projects/kyos/clients/tests && composer test && cd -'
