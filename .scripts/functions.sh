mkd() {
    mkdir -p "$@" && cd -- "${@: -1}"
}

_df_is_sudo="false";
if groups | grep -qE "sudo|wheel|root"; then
    _df_is_sudo="true"
fi

if [ "$_df_is_sudo" == "false" ]; then
    sudo() {
        echo "no sudo permissions";
        return 1;
    }
fi

eecho() {
    echo "$@" >&2
}

up() {
    if [ ! "$(type -t dockar)" == "" ]; then
        for ii in $(dockar ps -q); do
            local script=$(dockar inspect --format '{{ index .Config.Labels "com.docker.compose.project.config_files" }}' $ii)
            if [ ! "$script" == "" ]; then
                dockar compose -f "$script" pull
                dockar compose -f "$script" up -d --remove-orphans
            fi
        done
    fi
    if [ ! "$(type -t yay)" == "" ]; then
        yay --noconfirm
    elif [ ! "$(type -t pacman)" == "" ]; then
        sudo pacman -Syu --noconfirm
    elif [ ! "$(type -t apt)" == "" ]; then
        sudo apt update && sudo apt upgrade -y
        sudo apt autoremove -y
    else
        echo "System not supported"
    fi

    if [ ! "$(type -t rustup)" == "" ]; then
        rustup self update
        until rustup update stable; do sleep 5; done
    fi

    if [ ! "$(type -t deno)" == "" ]; then
        if [[ "$(type -p deno)" == /home* ]]; then
            deno upgrade
        else
            sudo deno upgrade
        fi
    fi

    if [ ! "$(type -t snap)" == "" ]; then
        sudo snap refresh
    fi
    if [ ! "$(type -t npm)" == "" ]; then
        sudo npm -g upgrade || npm -g upgrade
    fi
    if [ ! "$(type -t mise)" == "" ]; then
        mise self-update -y
        mise bootstrap -y
        mise up --inactive -y
    fi
    if [ ! "$(type -t pi)" == "" ]; then
        eval pi update --extensions
    fi
}

ebrc() {
    "$EDITOR" ~/.bashrc;
}

sbrc() {
    source ~/.bashrc
}

serve() {
    local port="${1:-9000}"
    if [ ! "$(type -t python3)" == "" ]; then
        python3 -m http.server $port
    elif [ ! "$(type -t php)" == "" ]; then
        php -S localhost:$port
    elif [ ! "$(type -t npx)" == "" ]; then
        npx --yes serve --listen $port
    fi
    
}

pwgen() {
    local len="${1:-16}"
    local number="${2:-1}"
    for (( i=0; i<$number; i++ ))
    do
        base64 -w 0 < /dev/urandom | tr -d "=+/" | head -c "$len"
        echo ""
    done
}

..() {
    cd ..
    _TMPPWD="$OLDPWD"
    if [ "$#" -ne 0 ]; then
        cd "$@"
        OLDPWD="$_TMPPWD"
    fi
}

...() {
    cd ../..
    _TMPPWD="$OLDPWD"
    if [ "$#" -ne 0 ]; then
        cd "$@"
        OLDPWD="$_TMPPWD"
    fi
}

search() {
    find $PWD -iname "*${1}*" -type f
}

searchd() {
    find $PWD -iname "*${1}*" -type d
}

erase() {
    rm -rf ~/.local/share/Trash/*
    rm -rf ~/.cargo/registry/src
    rm -rf ~/.cargo/registry/cache
    if [ ! "$(type -t cargo)" == "" ]; then
        find ~ -path ~/.rustup -prune -o -path ~/.cargo -prune -o -name 'Cargo.toml' -exec cargo clean --manifest-path {} \; -exec cargo clean -r --manifest-path {} \;
    fi
    if [ ! "$(type -t pacman)" == "" ]; then
        sudo pacman -Rcs $(pacman -Qdtq)
        sudo pacman -Sc
    elif [ ! "$(type -t apt)" == "" ]; then
        sudo apt autoremove
        sudo apt clean
    fi
    if [ ! "$(type -t yay)" == "" ]; then
        echo Y | yay -Sc
    fi
    if [ ! "$(type -t docker)" == "" ]; then
        sudo docker image prune -f
        sudo docker buildx prune -f
        sudo docker volume prune -f
    fi
    if [ ! "$(type -t npm)" == "" ]; then
        npm cache verify
    fi
}

upload() {
    local title=""
    if [ ! "$1" == "" ]; then
        local text="$(cat $1)"
        local title="$(basename $1)"
    else
        local text=$(cat)
    fi
    if [ "$text" == "" ]; then
        echo "no text"
        return
    fi
    local url=$(curl -v 'https://paste.centos.org/' -X POST -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode "name=$USER" --data-urlencode "title=$title" --data-urlencode "lang=text" --data-urlencode "code=$text" --data-urlencode "expire=1440" --data-urlencode "submit=submit" 2>&1 | grep -iF "location: " | grep -o "https.*")
    echo $url
    echo $url | sed 's#/view#/view/raw#'
}

gsw() {
    if [ "$1" == "" ]; then
        echo "Missing argument"
        return 1
    fi

    if [ "$1" == "-" ]; then
        git switch -
        return $?
    fi

    local branch=$(git branch -l --format "%(refname:short)" | grep -F -i "$1")

    if [ "$branch" == "" ]; then
        echo "No branch found"
        return 1
    fi

    git switch $branch
}

killport() {
    if [ "$1" == "" ]; then
        echo "Missing argument"
        return 1
    fi

    local pid=$(_get_pid $1)
    
    if [ "$pid" == "" ]; then
        echo "No PID found"
        return 1
    fi

    local pid2
    kill $pid
    for i in {1..5}; do
        sleep 2;
        pid2=$(_get_pid $1)
        if [ "$pid2" == "" ]; then
            return
        fi  
    done

    kill -9 $pid2
}

_get_pid() {
    if [ ! "$(type -t lsof)" == "" ]; then
        lsof -i :$1 | grep -w -i -F tcp | awk '{print $2}'
    elif [ ! "$(type -t ss)" == "" ]; then
        ss -tlpn | grep -F :$1 | grep -i -o -P "pid=\d+" | awk -F= '{print $2}'
    fi
}

paths() {
    echo $PATH | tr ':' '\n'
}

loadenv() {
    local file=${1:-.env}        
    export $(cat $file | xargs)
}

_parse_version() {
    grep --color=never -o -P "\d+\.\d+(.\d+)?"
}

if [ ! "$(type -t docker)" == "" ]; then
    dockar() {
        if [ "$(id -u)" == "0" ]; then
            docker "$@"
            return
        fi
        if groups $USER | grep -Fqw docker; then
            docker "$@"
        else
            sudo docker "$@"
        fi
    }
    
    if [ ! "$(type -t __start_docker)" == "" ]; then
        complete -o default -F __start_docker dockar
    elif [ ! "$(type -t _docker)" == "" ]; then
        complete -o default -F _docker dockar
    fi

    dokk_exec() {
        if [ "$1" == "" ]; then
            echo "Missing argument"
            return 1
        fi
        docker ps > /dev/null
        docker exec -it $1 /bin/bash || docker exec -it $1 /bin/sh
    }

    _df_comp_dokk_exec() {
        local cur prev;
        cur="${COMP_WORDS[COMP_CWORD]}";
        prev="${COMP_WORDS[COMP_CWORD-1]}";
        COMPREPLY=()
        if [ "$prev" == "dokk_exec" ]; then
            COMPREPLY=( $(compgen -W "$(docker ps --format '{{.Names}}')" -- ${cur}) )
        fi
    }
    
    complete -F _df_comp_dokk_exec dokk_exec

    _docom_commands=("build" "down" "exec" "kill" "pause" "port" "ps" "pull" "restart" "rm" "start" "stop" "unpause" "up")
    docom() {
        if [ "$1" == "" ]; then
            echo "Missing argument"
            return 1
        fi
        if [ "$1" == "upgrade" ]; then
            docom pull
            docom up -d --remove-orphans
            return 0
        fi
        if [[ ! ${_docom_commands[@]} =~ $1 ]]; then
            echo "Invalid command"
            return 1
        fi
        find -L . -type f -iname "docker-compose.y*ml" -exec sh -c "docker compose -f {} $1 $2 $3" \;
    }

    _df_comp_docom() {
        local cur prev;
        cur="${COMP_WORDS[COMP_CWORD]}";
        prev="${COMP_WORDS[COMP_CWORD-1]}";
        COMPREPLY=()
        if [ "$prev" == "docom" ]; then
            COMPREPLY=( $(compgen -W "$(echo ${_docom_commands[@]})" -- ${cur}) )
        fi
    }

    complete -F _df_comp_docom docom
fi

if [ "$(type -t npx)" == "" ] && [ ! "$(type -t deno)" == "" ]; then
    npx() {
        deno run -A npm:${@}
    }
fi

harden_vps() {
    if [ "$USER" == "root" ]; then
        local username=""
        read -p "enter new user (leave empty to skip) " username
        if [ ! "$username" == "" ]; then
            useradd -m $username
            passwd $username
            usermod -aG sudo $username
            usermod --shell $(which bash) $username
        fi
        return
    fi

    sudo groupadd docker
    sudo usermod -aG docker $USER

    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    local new_ssh_port=""
    read -p "enter new ssh port (default 22) " new_ssh_port
    if [ ! "$new_ssh_port" == "" ]; then
        if [ "$(grep ^Port /etc/ssh/sshd_config)" == "" ]; then
            echo "Port $new_ssh_port" | sudo tee -a /etc/ssh/sshd_config > /dev/null
        else
            sudo sed -i "s/^Port .*/Port $new_ssh_port/g" /etc/ssh/sshd_config
        fi
        echo "changed port to $new_ssh_port"
    fi
    if [ "$(grep ^PasswordAuthentication /etc/ssh/sshd_config)" == "" ]; then
        echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config > /dev/null
    else
        sudo sed -i "s/^PasswordAuthentication .*/PasswordAuthentication no/g" /etc/ssh/sshd_config
    fi
    echo "disbaled password ssh: $(grep ^PasswordAuth /etc/ssh/sshd_config)" 
    sudo systemctl restart sshd
    sudo systemctl restart ssh

    if [ ! "$(type -t ufw)" == "" ]; then
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw allow ssh
        sudo ufw allow 22/tcp
        local ssh_port=$(grep ^Port /etc/ssh/sshd_config | awk '{print $2}')
        if [ ! "$ssh_port" == "" ]; then
            sudo ufw allow $ssh_port/tcp
        fi
        sudo ufw allow http
        sudo ufw allow https
        echo "configured ufw (ssh port ${ssh_port:-22})"

        sudo ufw enable
        echo "enabled ufw"
        sudo ufw status verbose
    else
        echo "please install ufw!!"
    fi
    up

}

repo_dump() {
    if ! git rev-parse --is-inside-work-tree 2>/dev/null 1>/dev/null; then
        echo "no git repo"
        return 1
    fi
    local output="repo_out.txt"
    echo "##### START #####" > $output
    echo >> $output
    while IFS= read -r -d '' file; do
        if [[ "$file" == *".git/"* ]]; then
            continue
        fi
        if git check-ignore "$file"; then
            continue
        fi
        if [[ "$file" == *"$output" ]]; then
            continue
        fi
        echo "### $file ###" >> $output
        echo >> $output
        cat "$file" >> $output
        echo >> $output
    done < <(find . -type f -print0)

    echo >> $output
    echo "##### END #####" >> $output
}