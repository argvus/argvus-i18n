# shellcheck shell=sh

argvus_tr() {
    if [ "$#" -lt 2 ]; then
        printf '%s\n' 'argvus_tr: expected DOMAIN KEY' >&2
        return 2
    fi
    argvus-i18n get "$@"
}

argvus_locale() {
    argvus-i18n locale
}
