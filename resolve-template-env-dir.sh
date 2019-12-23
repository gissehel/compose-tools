#!/usr/bin/env bash

# This script is not used, but as it has been written, I keep it here

src="$1"
output="$2"

[ -d "${output}" ] && echo "ERROR: Directory ${output} already exists. Don't tout." >/dev/stderr && exit 1
[ -z "${src}" ] && echo "ERROR: No source directory." >/dev/stderr && exit 1
[ -z "${output}" ] && echo "ERROR: No output directory." >/dev/stderr && exit 1

export_file="${output}/__export__"

mkdir -p "${output}"
names=$(echo "${src}"/*)

varfiles=""
for fullname in $(echo "${src}"/*)
do
    varfile=$(basename "${fullname}")
    varfiles="${varfiles} ${varfile}"
done

var_names=""
for varfile in ${varfiles}
do
    . "${src}/${varfile}"
    var_names="${var_names} $(echo $(cat "${src}/${varfile}" | grep "=" | grep -v "\\$" | perl -ape 's{=.*}{}'))"
done

var_list=""
echo "" > "${export_file}"

for var_name in ${var_names}
do
    var_list="${var_list} \${${var_name}}"
    echo "export ${var_name}" >> "${export_file}"
done

. "${export_file}"

for varfile in ${varfiles}
do
    . "${src}/${varfile}"
    envsubst "${var_list}" < "${src}/${varfile}" > "${output}/${varfile}"
done

previous_export_len=0
current_export_len=$(cat "${export_file}" | wc -l)

while [ "${previous_export_len}" != "${current_export_len}" ]
do
    previous_export_len="${current_export_len}"

    var_names=""
    for varfile in ${varfiles}
    do
        . "${output}/${varfile}"
        var_names="${var_names} $(echo $(cat "${output}/${varfile}" | grep "=" | grep -v "\\$" | perl -ape 's{=.*}{}'))"
    done

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
        for varfile in ${varfiles}
        do
            . "${output}/${varfile}"
            envsubst "${var_list}" < "${output}/${varfile}" > "${output}/${varfile}-tmp-file"
            rm "${output}/${varfile}"
            mv "${output}/${varfile}-tmp-file" "${output}/${varfile}"
        done
    fi
done

rm -f "${export_file}"
