autoload -U colors && colors
PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "
eval "$(sheldon source)"
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias neofetch='neofetch --size 400'
alias la='ls --all'
alias v='nvim'
alias conf='cd ~/.config'
alias cc='cd ..'
alias susp="swaylock && systemctl suspend"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/oleh/google-cloud-sdk/path.zsh.inc' ]; then . '/home/oleh/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/oleh/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/oleh/google-cloud-sdk/completion.zsh.inc'; fi
