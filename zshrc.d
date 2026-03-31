autoload -Uz compinit

zstyle ':completion:*' completer _complete _ignored _correct _approximate
zstyle ':completion:*' file-sort name
zstyle :compinstall filename /home/maks/.zshrc
zstyle ':completion:*' ignore-parents parent pwd directory
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' max-errors 3
zstyle ':completion:*' menu 'select=0'
zstyle ':completion:*' original true
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s

source completions/*
