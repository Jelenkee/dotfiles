if niri msg -j focused-window | grep -Fq '"is_floating":true'; then
    notify-send "Floating not supported"
    exit
fi

windowCount() {
    niri msg -j windows  | grep -Fo '"app_id":' | wc -l
}

winCount=$(windowCount)
activePid=$(niri msg -j focused-window | grep -Eo '"pid":[0-9]+' | grep -Eo '[0-9]+')
activeColumn=$(niri msg -j focused-window | grep -Eo 'pos_in_scrolling_layout":\[[0-9]+' | grep -Eo '[0-9]+')
cmd="$(ps -p "$activePid" -o args | tail -1)"

if [ "$cmd" == "" ]; then
    notify-send "Could not find command for current window"
    exit
fi

sh -c "$cmd" &
sleep 0.2

for i in {1..10}; do
    if [ "$winCount" -ne "$(windowCount)" ]; then
        niri msg action move-column-to-index $((activeColumn + 1))
        niri msg action focus-window-previous
        niri msg action consume-window-into-column
        niri msg action focus-window-previous
        niri msg action focus-column-left
        niri msg action focus-column-right
        exit
    fi
    sleep 0.3;
done

notify-send "Could not duplicate window"
