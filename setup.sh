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
export CACHE="${ROOTDIR}/cache"

export RUSTDIR="${CACHE}/rust_toolchain"
export CARGO_HOME="${RUSTDIR}"
export RUSTUP_HOME="${RUSTDIR}"

export IREE_COMPILER_DIR="${OUT}/host/iree_compiler"

export PATH="${HOME}/.local/bin:${PATH}"
export PATH="${CACHE}/toolchain/bin:${PATH}"
export PATH="${RUSTDIR}/bin:${PATH}"
export PATH="${ROOTDIR}/scripts:${PATH}"
export PATH="${OUT}/host/renode:${PATH}"
export PATH="${OUT}/host/qemu/riscv32-softmmu:${PATH}"

export KATA_RUST_VERSION="nightly-2021-08-05"
export RENODE_PORT=1234

function renode
{
    "${OUT}/host/renode/renode.sh" "$@"
}

function iss
{
    (cd "${ROOTDIR}" && python3 "${ROOTDIR}/scripts/quick_sim.py" "$@")
}

function qemu_sim_springbok
{
    local file="${1}"; shift
    (cd "${ROOTDIR}" && qemu-system-riscv32 -M springbok -nographic -d springbok -device loader,file="${file}" "$@")
}

function sim_springbok
{
    local command="start;"
    if [[ "$2" == "debug" ]]; then
        command=""
    fi
    (cd "${ROOTDIR}" && renode -e "\$bin=@$1; i @sim/config/springbok.resc; \
    ${command} sysbus.vec_controlblock WriteDoubleWord 0xc 0" \
        --disable-xwt --console)

}

function get-groups
{
    git --git-dir="${ROOTDIR}/.repo/manifests.git" config \
        --get manifest.groups
}

function m
{
    (cd "${ROOTDIR}" && make -f "${ROOTDIR}/build/Makefile" "$@")
    return $?
}

function hmm
{
    local targetname="${1}"; shift

    targetname="${targetname}" awk -f "${ROOTDIR}/build/helpmemake.awk" \
              "${ROOTDIR}/build/Makefile" "${ROOTDIR}"/build/*.mk
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
echo "========================================"
echo ROOTDIR="${ROOTDIR}"
echo OUT="${OUT}"
echo "========================================"
echo
echo Type \'m \[target\]\' to build.
hmm

if [[ ! -d "${RUSTDIR}" ]] ||
   [[ ! -d "${ROOTDIR}/cache/toolchain" ]] ||
   [[ ! -d "${ROOTDIR}/cache/toolchain_iree_rv32imf" ]] ||
   [[ ! -d "${ROOTDIR}/out/host/renode" ]]; then
    echo
    echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    echo You have missing tools. Please run \'m prereqs\' followed
    echo by \'m tools\' to install them.
    echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    echo
fi
