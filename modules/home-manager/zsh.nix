{pkgs, config, ...}:

{
  programs.zsh = {
    enable = true;
    enableCompletion = false;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initExtraFirst = " (cat ~/.cache/wal/sequences &)";
    initExtra = "autoload -U colors && colors && PS1=\"%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b \"";
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch --flake /home/oleh/.nixos/#default";
      up-test = "sudo nixos-rebuild test --flake /home/oleh/.nixos/#default";
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      neofetch = "neofetch --size 400";
      la = "ls --all";
      v = "nvim";
      cc = "cd ..";
    };

    history = {
      size = 1000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
  };
}