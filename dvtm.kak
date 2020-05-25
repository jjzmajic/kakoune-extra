##
## dvtm.kak by lenormf
## Support for client creation/tagging/focusing from a kakoune client
##

# http://www.brain-dump.org/projects/dvtm/
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook global KakBegin .* %{
    evaluate-commands %sh{
        if [ -n "${DVTM}" ]; then
            echo "
                alias global terminal dvtm-terminal
                alias global focus dvtm-focus
                alias global new dvtm-new
            "
        fi
    }
}

define-command -params 1.. -shell-completion -docstring "Create a new terminal
and launch any arguments as a command in it." \
    dvtm-terminal %{ nop %sh{
        if [ -p "${DVTM_CMD_FIFO}" ]; then
            printf %s\\n "create \"$@\"" > "${DVTM_CMD_FIFO}"
        else
            printf %s\\n 'echo -color Error No command socket available'
        fi
} }

define-command -params .. -command-completion -docstring "Create a new window" \
    dvtm-new %{ evaluate-commands %sh{
    params=""
    if [ $# -gt 0 ]; then
        ## `dvtm` requires those simple quotes to be escaped even within double quotes
        params="-e \\'$@\\'"
    fi

    ## The FIFO command pipe has to be created using the `-c` flag
    if [ -p "${DVTM_CMD_FIFO}" ]; then
        printf %s\\n "create \"kak -c ${kak_session} ${params}\"" > "${DVTM_CMD_FIFO}"
    else
        printf %s\\n 'echo -color Error No command socket available'
    fi
} }

define-command -params 0..1 -client-completion -docstring %{dvtm-focus [<client>] focus a client
If no client is passed, then the current client is used} \
    dvtm-focus %{ evaluate-commands %sh{
    if [ $# -eq 1 ]; then
        printf %s\\n "eval -client '$1' focus"
    elif [ -p "${DVTM_CMD_FIFO}" ]; then
        printf %s\\n "focus ${kak_client_env_DVTM_WINDOW_ID}" > "${DVTM_CMD_FIFO}"
    else
        printf %s\\n "echo -color Error No command socket available"
    fi
} }

define-command -params 1.. -docstring %{dvtm-cmd <command> <args>: interact with dvtm using the dvtm-cmd utility
The command argument is a command supported by dvtm-cmd
The tags arguments is a list of one or more tags to assign to the given client} \
    dvtm-cmd %{ evaluate-commands %sh{
    if [ -p "${DVTM_CMD_FIFO}" ]; then
        readonly command="$1"; shift
        readonly output=$(dvtm-cmd "${command}" "$@" 2>&1)

        if [ -n "${output}" ]; then
            printf %s\\n "echo -color Error %{ ${output} }"
        fi
    else
        printf %s\\n "echo -color Error No command socket available"
    fi
} }
