#!/bin/bash
function subnet_names_and_ips() {
    local subnet=$1
    python -c 'import netaddr; print("\n".join([str(i) for i in netaddr.IPNetwork("'$subnet'")]))' |
    sed -e 's/\./ /g' | while read a b c d ; do
        echo "ip-$a-$b-$c-$d $a.$b.$c.$d"
    done
}

function populate_paddles() {
    local subnets="$1"
    local labdomain=$2


    local url='postgresql://paddles:paddles@localhost/paddles'

    pkill -f 'pecan serve'

    sudo -u postgres dropdb paddles
    sudo -u postgres createdb -O paddles paddles

    (
        source virtualenv/bin/activate
        pecan populate config.py

        (
            echo "begin transaction;"
            for subnet in $subnets ; do
                subnet_names_and_ips $subnet | while read name ip ; do
                    echo "insert into nodes (name,machine_type,is_vm,locked,up) values ('${name}.${labdomain}', 'openstack', TRUE, FALSE, TRUE);"
                done
            done
            echo "commit transaction;"
        ) | psql --quiet $url

        setsid pecan serve config.py < /dev/null > /dev/null 2>&1 &
        for i in $(seq 1 20) ; do
            if curl --silent http://localhost:8080/ > /dev/null 2>&1 ; then
                break
            else
                echo -n .
                sleep 5
            fi
        done
        echo -n ' '
    )

    echo "RESET the paddles server"
}
populate_paddles <subnet> <labdomain> || return 1
