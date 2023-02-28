# Copyright 2022 Google LLC
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

# TODO(sleffler): release-built apps fail
CANTRIP_APPS_RELEASE := $(CANTRIP_OUT_RUST_APP_RELEASE)/hello/hello.app \
                        $(CANTRIP_OUT_RUST_APP_RELEASE)/keyval/keyval.app \
                        $(CANTRIP_OUT_RUST_APP_RELEASE)/logtest/logtest.app \
                        $(CANTRIP_OUT_RUST_APP_RELEASE)/panic/panic.app \
                        $(CANTRIP_OUT_RUST_APP_RELEASE)/timer/timer.app
                        
CANTRIP_APPS_DEBUG   := $(CANTRIP_OUT_RUST_APP_DEBUG)/hello/hello.app \
                        $(CANTRIP_OUT_RUST_APP_DEBUG)/keyval/keyval.app \
                        $(CANTRIP_OUT_RUST_APP_DEBUG)/logtest/logtest.app \
                        $(CANTRIP_OUT_RUST_APP_RELEASE)/panic/panic.app \
                        $(CANTRIP_OUT_RUST_APP_DEBUG)/timer/timer.app \
                        $(CANTRIP_OUT_RUST_APP_RELEASE)/test/test.app

CANTRIP_SCRIPTS      := ${CANTRIP_SRC_DIR}/apps/repl/autostart.repl
