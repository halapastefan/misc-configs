CACHE_DIR="$HOME/.cache/functions/aws/$(get_active_profile)"
CLOUDFORMATION_CACHE_FILE="$CACHE_DIR/stack_list.txt"

cf() {
  local profile selected_stack
  profile="$(get_active_profile)"

  if [ -z "$1" ]; then
    selected_stack=$(cat "$CLOUDFORMATION_CACHE_FILE" |
      fzf --preview "
        aws cloudformation describe-stacks --profile \"$profile\" --stack-name {} | jq \".Stacks[0]\" | jq \".\" | bat --language json --style=plain --paging=never --color=always
      " --preview-window=right:60% --height 100%)
  else
    selected_stack="$1"
  fi

  if [ -n "$selected_stack" ]; then
    aws cloudformation describe-stacks --profile "$profile" --stack-name "$selected_stack" | jq "."
  fi
}

_stack_list_completion() {
  if [[ -f "$CLOUDFORMATION_CACHE_FILE" ]]; then
    compadd -- $(cat "$CLOUDFORMATION_CACHE_FILE")
  fi
}
compdef _stack_list_completion cf
