# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH
export PATH="$HOME/.cargo/bin:$PATH"
#export ILLOGICAL_IMPULSE_VIRTUAL_ENV="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv"
QS_IMPORT_PATHS=/home/goutam/quickshell
export GOOGLE_API_KEY="Input the key"
export GOOGLE_CX="Input the key"

eval "$(starship init bash)"
#eval "$(oh-my-posh init bash)"
#eval "$(oh-my-posh init bash --config ~/.emodipt-extend.omp.json)"
# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
