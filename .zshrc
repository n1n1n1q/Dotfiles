PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "
(cat ~/.cache/wal/sequences &)
eval "$(sheldon source)"
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias neofetch='neofetch --size 400'
alias la='ls --all'
alias v='nvim'
alias conf='cd ~/.config'
alias cc='cd ..'
neofetch
