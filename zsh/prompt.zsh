setopt PROMPT_SUBST

if (( $+functions[toggle_oneline_prompt] )); then
    bindkey '^P' up-line-or-search
fi

NEWLINE_BEFORE_PROMPT=no

PROMPT='%F{244}%D{%d/%m} %D{%H:%M}%f %F{215}[%n]%f %F{110}%m%f %F{250}%~%f %B%F{39}>>%f%b '
RPROMPT=''
