#/usr/bin/env sh

SCHEDULER_HOST="10.20.52.49"

# 定义函数，用于读取 /etc/os-release 文件中的 Name 字段并返回对应的值
get_os_name() {
    local os_name=$(grep '^NAME=' /etc/os-release | sed 's/NAME="//;s/"//')
    echo "$os_name"
}

# 定义函数，用于判断操作系统名称并返回相应的值
check_os() {
    local os_name=$(get_os_name)
    case "$os_name" in
    "Arch Linux")
        echo 1
        ;;
    "Deepin")
        echo 2
        ;;
    *)
        echo 0
        ;;
    esac
}

check_package() {
    case $(check_os) in
    1)
        if ! command -v yay &>/dev/null; then
            echo "没有找到 yay，请先安装它！"
            return 0
        fi
        if [ -n "$(yay -Q icecream)" ]; then
            echo "软件包检查完毕"
            return 0
        fi
        echo "即将安装 icecream..."
        yes | yay -S icecream
        echo "完成安装。"
        ;;
    2)
        if [ -n "$(dpkg -l | grep icecc)" ]; then
            echo "软件包检查完毕"
            return 0
        fi
        echo "即将安装 icecc..."
        yes | sudo apt install icecc
        echo "完成安装。"
        ;;
    *) ;;
    esac
}

check_config() {
    case $(check_os) in
    1)
        profile_config='export PATH=/usr/lib/icecream/libexec/icecc/bin:$PATH'
        conf_path="/etc/icecream.conf"
        conf_key="ICECREAM_SCHEDULER_HOST"
        ;;
    2)
        profile_config='export PATH=/usr/lib/icecc/bin:$PATH'
        conf_path="/etc/icecc/icecc.conf"
        conf_key="ICECC_SCHEDULER_HOST"
        ;;
    *) ;;
    esac
    if test -e /etc/profile.d/icecc.sh; then
        echo "profile 已配置"
    else
        echo "配置 profile..."
        echo $profile_config | sudo tee /etc/profile.d/icecc.sh
        echo "配置完毕"
    fi
    local scheduler_host=$(grep '^ICECREAM_SCHEDULER_HOST=' $conf_path | sed 's/ICECREAM_SCHEDULER_HOST="//;s/"//')
    if [ "x$scheduler_host" = "x$SCHEDULER_HOST" ]; then
        echo "icecc 配置正确"
    else
        echo "配置 icecc..."
        sudo sed -i "s/$conf_key=\".*\"/$conf_key=\"$SCHEDULER_HOST\"/" $conf_path
        echo "配置完毕"
    fi
}

enable_service() {
    case $(check_os) in
    1)
        sudo systemctl enable icecream.service
        ;;
    2)
        iceccd -d
        ;;
    *) ;;
    esac
}

check_package
check_config
enable_service

echo "已全部配置完毕，请重启机器生效！"
