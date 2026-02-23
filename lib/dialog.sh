#!/usr/bin/env bash
# Dialog TUI wrapper helpers

DIALOG_OK=0
DIALOG_CANCEL=1
DIALOG_ESC=255

_dialog_result=""

dialog_msg() {
    local title="$1"
    local text="$2"
    dialog --title "${title}" --msgbox "${text}" 12 60
}

dialog_yesno() {
    local title="$1"
    local text="$2"
    dialog --title "${title}" --yesno "${text}" 10 60
    return $?
}

dialog_input() {
    local title="$1"
    local text="$2"
    local default="$3"
    local result
    result=$(dialog --title "${title}" --inputbox "${text}" 10 60 "${default}" 3>&1 1>&2 2>&3)
    local rc=$?
    _dialog_result="${result}"
    return ${rc}
}

dialog_password() {
    local title="$1"
    local text="$2"
    local result
    result=$(dialog --title "${title}" --insecure --passwordbox "${text}" 10 60 3>&1 1>&2 2>&3)
    local rc=$?
    _dialog_result="${result}"
    return ${rc}
}

dialog_password_confirm() {
    local title="$1"
    local text="$2"
    local pass1 pass2

    while true; do
        dialog_password "${title}" "${text}" || return 1
        pass1="${_dialog_result}"

        dialog_password "${title}" "Confirm password:" || return 1
        pass2="${_dialog_result}"

        if [[ "${pass1}" == "${pass2}" ]]; then
            _dialog_result="${pass1}"
            return 0
        fi
        dialog_msg "Error" "Passwords do not match. Try again."
    done
}

dialog_menu() {
    local title="$1"
    local text="$2"
    shift 2
    local items=("$@")
    local result
    result=$(dialog --title "${title}" --menu "${text}" 20 70 12 "${items[@]}" 3>&1 1>&2 2>&3)
    local rc=$?
    _dialog_result="${result}"
    return ${rc}
}

dialog_checklist() {
    local title="$1"
    local text="$2"
    shift 2
    local items=("$@")
    local result
    result=$(dialog --title "${title}" --checklist "${text}" 20 70 12 "${items[@]}" 3>&1 1>&2 2>&3)
    local rc=$?
    _dialog_result="${result}"
    return ${rc}
}

dialog_form() {
    local title="$1"
    local text="$2"
    shift 2
    local result
    result=$(dialog --title "${title}" --form "${text}" 20 70 8 "$@" 3>&1 1>&2 2>&3)
    local rc=$?
    _dialog_result="${result}"
    return ${rc}
}

dialog_gauge() {
    local title="$1"
    local text="$2"
    local percent="$3"
    echo "${percent}" | dialog --title "${title}" --gauge "${text}" 8 60 0
}

dialog_summary() {
    local title="$1"
    shift
    local lines=("$@")
    local text=""
    for line in "${lines[@]}"; do
        text+="${line}\n"
    done
    dialog --title "${title}" --yesno "${text}\n\nProceed with installation?" 20 70
    return $?
}
