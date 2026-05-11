if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -g fish_greeting

starship init fish | source

set -gx COWPATH ~/.config/cowsay/cows /usr/share/cowsay/cows

abbr -a dtsc "~/dotfiles/sync.sh"
alias sysclean="~/scripts/sysclean.sh"

# 基础文本
set -g fish_color_normal normal

# 命令 (对应 Primary 主色 - 绿色)
set -g fish_color_command green

# 关键字 (对应 Secondary 次要色 - 蓝色)
set -g fish_color_keyword blue

# 引号字符串 (对应 Tertiary 强调色 - 黄色)
set -g fish_color_quote yellow

# 重定向和分隔符 (对应 Secondary Fixed - 青色)
set -g fish_color_redirection cyan
set -g fish_color_end cyan

# 错误信息 (对应 Error 错误色 - 红色)
set -g fish_color_error red

# 参数 (使用普通文本色，避免太花哨)
set -g fish_color_param normal

# 注释和自动补全 (使用终端的 Bright Black 亮黑色，作为柔和的灰色提示)
set -g fish_color_comment brblack
set -g fish_color_autosuggestion brblack

# 操作符和转义字符
set -g fish_color_operator cyan
set -g fish_color_escape cyan

# 选中与搜索高亮文本的背景
set -g fish_color_selection --background=brblack
set -g fish_color_search_match --background=brblack
export PATH="$HOME/.local/bin:$PATH"
