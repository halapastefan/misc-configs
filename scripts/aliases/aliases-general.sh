alias downloads='open ~/Downloads'

# 
alias reddit='open -a "Brave Browser" https://reddit.com'
alias yt='open -a "Brave Browser" https://youtube.com'
alias google='open -a "Brave Browser" https://www.google.com/search?q='

alias work="timer 45m && terminal-notifier -message 'Pomodoro'\
        -title 'Work Timer is up! Take a Break 😊'\
        -appIcon '~/Pictures/pumpkin.png'\
        -sound Crystal"
        
alias rest="timer 5m && terminal-notifier -message 'Pomodoro'\
        -title 'Break is over! Get back to work 😬'\
        -appIcon '~/Pictures/pumpkin.png'\
        -sound Crystal"

# GIT 
# Aliases: git
alias ga='git add'
alias gap='ga --patch'
alias gb='git branch'
alias gba='gb --all'
alias gc='git commit'
alias gca='gc --amend --no-edit'
alias gce='gc --amend'
alias gco='git checkout'
alias gcl='git clone --recursive'
alias gd='git diff --output-indicator-new=" " --output-indicator-old=" "'
alias gds='gd --staged'
alias gi='git init'
alias gl='git log --graph --all --pretty=format:"%C(magenta)%h %C(white) %an  %ar%C(blue)  %D%n%s%n"'
alias gm='git merge'
alias gn='git checkout -b'  # new branch
alias gp='git push'
alias gr='git reset'
alias gs='git status --short'
alias gu='git pull'

# alias gs='git status'
# alias gcm='git commit -m'
# alias gca='git commit --amend'
# alias gpl='git pull'
# alias gl='git log --graph --all --pretty=format:"%C(magenta)%h %C(white) %an  %ar%C(blue)  %D%n%s%n"'


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
