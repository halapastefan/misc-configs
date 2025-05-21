alias downloads='open ~/Downloads'

# 
alias reddit='open -a "Brave Browser" https://reddit.com'
alias yt='open -a "Brave Browser" https://youtube.com'

alias work="timer 45m && terminal-notifier -message 'Pomodoro'\
        -title 'Work Timer is up! Take a Break 😊'\
        -appIcon '~/Pictures/pumpkin.png'\
        -sound Crystal"
        
alias rest="timer 5m && terminal-notifier -message 'Pomodoro'\
        -title 'Break is over! Get back to work 😬'\
        -appIcon '~/Pictures/pumpkin.png'\
        -sound Crystal"

alias gs='git status'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gpl='git pull'


alias h='history | fzf --tac | awk "{\$1=\"\"; sub(/^ /, \"\"); print}"'
alias he='eval $(h)'

##### browser using bat and fzf ####
# browse
alias b='fzf --reverse --inline-info --preview "bat --style=numbers --color=always {} | head -n 50"'
#browse+edit
alias be='code $(b)'
#browse+open
alias bo='open "$(b)"'
#browse+folder
alias bf='fd --type=d --hidden --strip-cwd-prefix --exclude .git | fzf'
#browse+folder+edit
alias bfe='code $(bf)'

alias ft='fd --type=d --hidden --strip-cwd-prefix --exclude .git | fzf --preview "eza --icons=always --tree --color=always {} | head -200"'

# Standard
alias cd='z'
alias ls='eza --long --color=always --icons=always --no-user'