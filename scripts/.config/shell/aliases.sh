#alias gmerged='git checkout master && git fetch --prune && git pull'
gmerged() {
  local default
  default=$(git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||')

  git checkout "$default" &&
    git fetch --prune &&
    git pull &&
    git branch --merged |
    grep -v '^\*' |
      grep -v "^  $default$" |
      xargs -r git branch -d
}
alias vim='nvim'

alias tm='tmux attach || tmux'
