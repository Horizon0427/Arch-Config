set -g fish_greeting

# 普通 TTY 无 SCHED_RR 权限，关闭 Hyprland 的可选实时调度尝试。
set -gx HYPRLAND_NO_RT 1

starship init fish | source

set -gx COWPATH ~/.config/cowsay/cows /usr/share/cowsay/cows

# 语法高亮
set -g fish_color_normal normal
set -g fish_color_command green
set -g fish_color_keyword blue
set -g fish_color_quote yellow
set -g fish_color_redirection cyan
set -g fish_color_end cyan
set -g fish_color_error red
set -g fish_color_param normal
set -g fish_color_comment brblack
set -g fish_color_autosuggestion brblack
set -g fish_color_operator cyan
set -g fish_color_escape cyan

# 选择与搜索
set -g fish_color_selection --background=brblack
set -g fish_color_search_match --background=brblack

export PATH="$HOME/.local/bin:$PATH"
