{ pkgs, config, ... }:
let
  shellInit = pkgs.pkgs.writeShellScriptBin "shin" ''
    if [ "$#" -ne 2 ]; then
        echo "Usage: sh-init <cpp|py> <destination directory>"
        exit 1
    fi
    if [ "$#" -eq 3 ] && ls "$3" 2>/dev/null | grep -q "flake.nix"; then
        echo "Flake.nix already exists in the destination directory. Move it or delete it to continue."
        exit 0
    fi
    if [ "$1" = "cpp" ]; then
        cp -r /home/oleh/.nixos/shell-templates/cpp.nix "$2"/flake.nix
        echo "C++ flake.nix created successfully!"
    elif [ "$1" = "py" ]; then
        cp -r /home/oleh/.nixos/shell-templates/python.nix "$2"/flake.nix
        echo "Python flake.nix created successfully!"
    else
        echo "Error: First argument must be 'cpp' or 'py'"
        exit 1
    fi
'';
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = false;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initExtraFirst = " (cat ~/.cache/wal/sequences &)";
    initExtra = "autoload -U colors\n
colors && PS1=\"%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b \" \n
    unset GIT_ASKPASS
    unset SSH_ASKPASS
";
    shellAliases = {
      sh-init = "${shellInit}/bin/shin";
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
