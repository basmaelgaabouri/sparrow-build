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

export C_PREFIX="riscv32-unknown-elf-"
export IREE_PREFIX="riscv32-unknown-elf-"
export IREE_ARCH="rv32imf"
export RUST_PREFIX="riscv32-unknown-linux-gnu"

# NB: $(CANTRIP_SRC_DIR)/apps/system/rust.cmake forces riscv32imac for
#     the target when building Rust code
export CANTRIP_TARGET_ARCH="riscv32-unknown-elf"
