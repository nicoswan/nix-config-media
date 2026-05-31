{ pkgs, ... }: {
  imports = [
    ./system-packages.nix
    ./users
  ];

  # Pinned to initial install version — do not bump without understanding migration implications
  system.stateVersion = "24.11";

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      interactiveShellInit = ''
        source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
        bindkey '^[OA' history-substring-search-up
        bindkey '^[[A' history-substring-search-up
        bindkey '^[OB' history-substring-search-down
        bindkey '^[[B' history-substring-search-down
      '';
    };
    fzf = {
      fuzzyCompletion = true;
      keybindings = true;
    };
  };
}
