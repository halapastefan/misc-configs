source "$HOME/scripts/aws/functions.sh"
source "$HOME/scripts/aws/lambda.sh"
source "$HOME/scripts/aws/cloudformation.sh"
source "$HOME/scripts/aws/pipelines.sh"
source "$HOME/scripts/aws/cloudwatch.sh"

lazyaws_help() {
    cat <<EOF
Supported operations in pipeline.sh:

pd [pipeline_name]        - Get pipeline details (select with fzf if not provided)
ple [pipeline_name]       - List pipeline executions (select with fzf if not provided)
rpl [pipeline_name]       - Read pipeline logs (select with fzf if not provided)
tpl [pipeline_name]       - Tail logs for a specific pipeline action (select with fzf if not provided)
pipeline_help             - Show this help message

You can also use TAB completion for pipeline names.
EOF
}

# List of available lazyaws sub-commands (add new functions here as needed)
lazyaws_commands=(pd ple rpl tpl pipeline_help)

# Main lazyaws dispatcher function
lazyaws() {
    local cmd="$1"
    if [[ "$cmd" == "--help" ]]; then
        shift
        lazyaws_help "$@"
        return
    fi
    shift
    if [[ -n "$cmd" && " ${lazyaws_commands[*]} " == *" $cmd "* ]]; then
        "$cmd" "$@"
    else
        echo "Usage: lazyaws {${lazyaws_commands[*]}}"
        return 1
    fi
}

# Completion for lazyaws sub-commands
_lazyaws_completions() {
    local cur_word
    cur_word="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=($(compgen -W "${lazyaws_commands[*]}" -- "$cur_word"))
}

complete -F _lazyaws_completions lazyaws

# Improved Zsh completion for lazyaws that delegates to _pipeline_name_completion for relevant sub-commands
if [[ -n $ZSH_VERSION ]]; then
    _lazyaws_zsh_completions() {
        local -a subcmds
        subcmds=(${lazyaws_commands[@]})
        if ((CURRENT == 2)); then
            compadd -a subcmds
        else
            local subcmd="$words[2]"
            # If the sub-command is one of the pipeline commands, delegate to _pipeline_name_completion
            case $subcmd in
            pd | ple | rpl | tpl)
                ((CURRENT--))
                ((COMP_CWORD--))
                words=($subcmd "${words[@]:2}")
                _pipeline_name_completion
                ;;
            *)
                _files
                ;;
            esac
        fi
    }
    compdef _lazyaws_zsh_completions lazyaws
fi
