#!/bin/bash
#
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

## Shamelessly borrowed from android's envsetup.sh.
function getrootdir
{
    local TOPFILE="build/Makefile"
    if [[ -n "$ROOTDIR" && -f "$ROOTDIR/$TOPFILE" ]]; then
        # The following circumlocution ensures we remove symlinks from ROOTDIR.
        (cd "${ROOTDIR}"; PWD= /bin/pwd)
    else
        if [[ -f "${TOPFILE}" ]]; then
            # The following circumlocution (repeated below as well) ensures
            # that we record the true directory name and not one that is
            # faked up with symlink names.
            PWD= /bin/pwd
        else
            local HERE="${PWD}"
            local R=
            while [ \( ! \( -f "${TOPFILE}" \) \) -a \( "${PWD}" != "/" \) ]; do
                \cd ..
                R=`PWD= /bin/pwd -P`
            done
            \cd "${HERE}"
            if [ -f "${R}/${TOPFILE}" ]; then
                echo "${R}"
            fi
        fi
    fi
}

export ROOTDIR="$(getrootdir)"
export OUT="${ROOTDIR}/out"
export PATH="${PATH}:${ROOTDIR}/build:${ROOTDIR}/scripts"

function get-groups
{
    git --git-dir="${ROOTDIR}/.repo/manifests.git" config \
        --get manifest.groups
}

function m
{
    local target="build"

    pushd "${ROOTDIR}" >/dev/null
    make -f "${ROOTDIR}/build/Makefile" "$@"
    popd >/dev/null
}

function safe-abandon
{
    local branch="${1}"; shift

    if [[ -z "${branch}" ]]; then
        echo "Usage: safe-abandon <branchname>"
        echo
        echo "Abandons a repo branch in the current project only."
        echo "This is much safer than using the actual 'repo abandon'"
        echo "command, since it won't globally revert branches across"
        echo "the entire project space."
        echo
        return 1
    fi

    repo abandon "${branch}" .
}

if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
    unset JUMP_TARGETS
    declare -Ax JUMP_TARGETS
    JUMP_TARGETS[.]="."
    JUMP_TARGETS[top]="${ROOTDIR}"
    JUMP_TARGETS[rootdir]="${ROOTDIR}"
    JUMP_TARGETS[out]="${OUT}"
    JUMP_TARGETS[build]="${ROOTDIR}/build"
    JUMP_TARGETS[doc]="${ROOTDIR}/doc"

    function j
    {
        local target="$1"; shift
        local splitpath=(${target//\// })
        local subpath=""

        if [[ -z "${target}" ]]; then
            cd "${ROOTDIR}"
            return 0
        fi

        if [[ -z "${JUMP_TARGETS[$target]}" ]]; then
            target="${splitpath[0]}"
            subpath="${splitpath[@]:1}"
        fi

        if [[ -z "${JUMP_TARGETS[$target]}" ]]; then
            echo "Jump targets are:"
            echo "${!JUMP_TARGETS[@]}"
            return 1
        fi

        cd "${JUMP_TARGETS[$target]}"

        if [[ ! -z "${subpath}" ]]; then
            cd "${subpath}"
        fi
    }

    if builtin complete >/dev/null 2>/dev/null; then
        function _j_targets
        {
            echo "${!JUMP_TARGETS[@]}"
        }

        function _j
        {
            local cur="${COMP_WORDS[COMP_CWORD]}"
            COMPREPLY=()
            if [[ "${COMP_CWORD}" -eq 1 ]]; then
                COMPREPLY=( $(compgen -W "$(_j_targets)" $cur) )
            fi
        }

        complete -F _j j
    fi
fi

echo ========================================
echo ROOTDIR="${ROOTDIR}"
echo OUT="${OUT}"
echo ========================================
echo
echo Type m to build.
