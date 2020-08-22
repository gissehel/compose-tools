#!/usr/bin/env bash

src="$1"
output="$2"
mode="$3"

[ -z "${src}" ] && echo "ERROR: No source file." >/dev/stderr && exit 1
[ -z "${output}" ] && echo "ERROR: No output file." >/dev/stderr && exit 1

export_file="${output}-__export__"
tmp_file="${output}-tmp"

. "${src}"
var_names="$(echo $(cat "${src}" | grep "=" | grep -v "\\$" | perl -ape 's{=.*}{}'))"

var_list=""
echo "" > "${export_file}"
[ -n "${mode}" ] && {
    chmod "${mode}" "${export_file}"
}

for var_name in ${var_names}
do
    var_list="${var_list} \${${var_name}}"
    echo "export ${var_name}" >> "${export_file}"
done

. "${export_file}"

. "${src}"
[ -n "${mode}" ] && {
    touch "${output}"
    chmod "${mode}" "${output}"
}
envsubst "${var_list}" < "${src}" > "${output}"

previous_export_len=0
current_export_len=$(cat "${export_file}" | wc -l)

while [ "${previous_export_len}" != "${current_export_len}" ]
do
    previous_export_len="${current_export_len}"

    . "${output}"
    var_names="$(echo $(cat "${output}" | grep "=" | grep -v "\\$" | perl -ape 's{=.*}{}'))"

    var_list=""
    echo "" > "${export_file}"

    for var_name in ${var_names}
    do
        var_list="${var_list} \${${var_name}}"
        echo "export ${var_name}" >> "${export_file}"
    done

    . "${export_file}"

    current_export_len=$(cat "${export_file}" | wc -l)
    if [ "${previous_export_len}" != "${current_export_len}" ]
    then
        . "${output}"
        [ -n "${mode}" ] && {
            touch "${tmp_file}"
            chmod "${mode}" "${tmp_file}"
        }
        envsubst "${var_list}" < "${output}" > "${tmp_file}"
        rm "${output}"
        mv "${tmp_file}" "${output}"
    fi
done

rm -f "${export_file}"
