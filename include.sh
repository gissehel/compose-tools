#!/usr/bin/env bash

running_dir=~/.config/compose-tools
yaml_dir_pattern="*/*yaml.d/*.yml"
env_files_pattern="*/env.d/*"

recreate_env() {
    pushd . >/dev/null
    cd "${running_dir}"
    if [ "$(echo ${env_files_pattern})" != "${env_files_pattern}" ]
    then
        cat ${env_files_pattern} > .env
    fi
    popd >/dev/null
}

get_include() {
    pushd . >/dev/null
    cd "${running_dir}"
    if [ "$(echo ${yaml_dir_pattern})" != "${yaml_dir_pattern}" ]
    then
        grep -l "^#:include" ${yaml_dir_pattern}
    fi
    popd >/dev/null
}

get_daemon() {
    pushd . >/dev/null
    cd "${running_dir}"
    if [ "$(echo ${yaml_dir_pattern})" != "${yaml_dir_pattern}" ]
    then
        grep -oh "^#:daemon:.*" ${yaml_dir_pattern} | sed -e 's/.*://'
    fi
    popd >/dev/null
}

get_interactive() {
    pushd . >/dev/null
    cd "${running_dir}"
    if [ "$(echo ${yaml_dir_pattern})" != "${yaml_dir_pattern}" ]
    then
        grep -oh "^#:interactive:.*" ${yaml_dir_pattern} | sed -e 's/.*://'
    fi
    popd >/dev/null
}

compose() {
    pushd . >/dev/null
    cd "${running_dir}"
    docker-compose -p docker ${CONFIG_FILES} "$@"
    popd >/dev/null
}

run_post_phase() {
    phase_name="$1"
    pushd . >/dev/null
    cd "${running_dir}"
    if [ "$(echo */post/"${phase_name}"/*)" != "*/post/${phase_name}/*" ]
    then
        for scriptname in */post/"${phase_name}"/*
        do
            bash "${scriptname}"
        done
    fi
    popd >/dev/null
}

install() {
    pushd . >/dev/null
    cd "${running_dir}"
    mkdir -p "${HOME}/bin"
    for scriptname in ct-compose ct-config ct-down ct-up ct-interactive
    do
        [ -f "${HOME}/bin/${scriptname}" ] || ln -s "${basedir}/${scriptname}" "${HOME}/bin/${scriptname}"
    done
    popd >/dev/null
}

mkdir -p "${running_dir}"
recreate_env
CONFIG_FILES=""

for FILE_PREFIX in $(get_include)
do
    CONFIG_FILES="${CONFIG_FILES} -f ${FILE_PREFIX}"
done

