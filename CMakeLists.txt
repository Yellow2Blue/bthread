# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

cmake_minimum_required(VERSION 2.8.10)
project(brpc C CXX)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(DEBUG "Print debug logs" OFF)
option(WITH_DEBUG_SYMBOLS "With debug symbols" ON)
option(BUILD_UNIT_TESTS "Whether to build unit tests" ON)
option(DOWNLOAD_GTEST "Download and build a fresh copy of googletest. Requires Internet access." ON)

# Enable MACOSX_RPATH. Run "cmake --help-policy CMP0042" for policy details.
if(POLICY CMP0042)
    cmake_policy(SET CMP0042 NEW)
endif()

set(BRPC_VERSION 1.4.0)

SET(CPACK_GENERATOR "DEB")
SET(CPACK_DEBIAN_PACKAGE_MAINTAINER "brpc authors")
INCLUDE(CPack)

if(WITH_DEBUG_SYMBOLS)
    set(DEBUG_SYMBOL "-g")
endif()

include(GNUInstallDirs)

set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

find_package(GFLAGS REQUIRED)

execute_process(
    COMMAND bash -c "grep \"namespace [_A-Za-z0-9]\\+ {\" ${GFLAGS_INCLUDE_PATH}/gflags/gflags_declare.h | head -1 | awk '{print $2}' | tr -d '\n'"
    OUTPUT_VARIABLE GFLAGS_NS
)
if(${GFLAGS_NS} STREQUAL "GFLAGS_NAMESPACE")
    execute_process(
        COMMAND bash -c "grep \"#define GFLAGS_NAMESPACE [_A-Za-z0-9]\\+\" ${GFLAGS_INCLUDE_PATH}/gflags/gflags_declare.h | head -1 | awk '{print $3}' | tr -d '\n'"
        OUTPUT_VARIABLE GFLAGS_NS
    )
endif()

include_directories(
    ${PROJECT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_BINARY_DIR}
)

set(CMAKE_CPP_FLAGS "${CMAKE_CPP_FLAGS} ${DEFINE_CLOCK_GETTIME} -DGFLAGS_NS=${GFLAGS_NS}")
set(CMAKE_CPP_FLAGS "${CMAKE_CPP_FLAGS} -DBTHREAD_USE_FAST_PTHREAD_MUTEX -D__const__=__unused__ -D_GNU_SOURCE -DUSE_SYMBOLIZE -DNO_TCMALLOC -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS -D__STDC_CONSTANT_MACROS -DBRPC_REVISION=\\\"${BRPC_REVISION}\\\" -D__STRICT_ANSI__")
set(CMAKE_CPP_FLAGS "${CMAKE_CPP_FLAGS} ${DEBUG_SYMBOL}")
set(CMAKE_CXX_FLAGS "${CMAKE_CPP_FLAGS} -O2 -pipe -Wall -W -fPIC -fstrict-aliasing -Wno-invalid-offsetof -Wno-unused-parameter -fno-omit-frame-pointer")
set(CMAKE_C_FLAGS "${CMAKE_CPP_FLAGS} -O2 -pipe -Wall -W -fPIC -fstrict-aliasing -Wno-unused-parameter -fno-omit-frame-pointer")

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    #required by butil/crc32.cc to boost performance for 10x
    if((CMAKE_SYSTEM_PROCESSOR MATCHES "(x86)|(X86)|(amd64)|(AMD64)") AND NOT (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 4.4))
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -msse4 -msse4.2")
    elseif((CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64"))
        # segmentation fault in libcontext
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-gcse")
    endif()
    if(NOT (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 7.0))
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-aligned-new")
    endif()
endif()

find_package(Threads REQUIRED)

include_directories(
        ${GFLAGS_INCLUDE_PATH}
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        )

set(DYNAMIC_LIB
    ${GFLAGS_LIBRARY}
    ${CMAKE_THREAD_LIBS_INIT}
    dl
    z)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(DYNAMIC_LIB ${DYNAMIC_LIB} rt)
    set(BRPC_PRIVATE_LIBS "${BRPC_PRIVATE_LIBS} -lrt")
endif()

# for *.so
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/output/lib)
# for *.a
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/output/lib)

# the reason why not using file(GLOB_RECURSE...) is that we want to
# include different files on different platforms.
set(BUTIL_SOURCES
    ${PROJECT_SOURCE_DIR}/src/butil/third_party/dmg_fp/g_fmt.cc
    ${PROJECT_SOURCE_DIR}/src/butil/third_party/dmg_fp/dtoa_wrapper.cc
    ${PROJECT_SOURCE_DIR}/src/butil/third_party/dynamic_annotations/dynamic_annotations.c
    ${PROJECT_SOURCE_DIR}/src/butil/third_party/icu/icu_utf.cc
    ${PROJECT_SOURCE_DIR}/src/butil/third_party/superfasthash/superfasthash.c
    ${PROJECT_SOURCE_DIR}/src/butil/third_party/modp_b64/modp_b64.cc
    ${PROJECT_SOURCE_DIR}/src/butil/third_party/symbolize/demangle.cc
    ${PROJECT_SOURCE_DIR}/src/butil/third_party/symbolize/symbolize.cc
    ${PROJECT_SOURCE_DIR}/src/butil/third_party/snappy/snappy-sinksource.cc
    ${PROJECT_SOURCE_DIR}/src/butil/third_party/snappy/snappy-stubs-internal.cc
    ${PROJECT_SOURCE_DIR}/src/butil/third_party/snappy/snappy.cc
    ${PROJECT_SOURCE_DIR}/src/butil/third_party/murmurhash3/murmurhash3.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/arena.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/at_exit.cc
    ${PROJECT_SOURCE_DIR}/src/butil/atomicops_internals_x86_gcc.cc
    ${PROJECT_SOURCE_DIR}/src/butil/base64.cc
    ${PROJECT_SOURCE_DIR}/src/butil/big_endian.cc
    ${PROJECT_SOURCE_DIR}/src/butil/cpu.cc
    ${PROJECT_SOURCE_DIR}/src/butil/debug/alias.cc
    ${PROJECT_SOURCE_DIR}/src/butil/debug/asan_invalid_access.cc
    ${PROJECT_SOURCE_DIR}/src/butil/debug/crash_logging.cc
    ${PROJECT_SOURCE_DIR}/src/butil/debug/debugger.cc
    ${PROJECT_SOURCE_DIR}/src/butil/debug/debugger_posix.cc
    ${PROJECT_SOURCE_DIR}/src/butil/debug/dump_without_crashing.cc
    ${PROJECT_SOURCE_DIR}/src/butil/debug/proc_maps_linux.cc
    ${PROJECT_SOURCE_DIR}/src/butil/debug/stack_trace.cc
    ${PROJECT_SOURCE_DIR}/src/butil/debug/stack_trace_posix.cc
    ${PROJECT_SOURCE_DIR}/src/butil/environment.cc
    ${PROJECT_SOURCE_DIR}/src/butil/files/file.cc
    ${PROJECT_SOURCE_DIR}/src/butil/files/file_posix.cc
    ${PROJECT_SOURCE_DIR}/src/butil/files/file_enumerator.cc
    ${PROJECT_SOURCE_DIR}/src/butil/files/file_enumerator_posix.cc
    ${PROJECT_SOURCE_DIR}/src/butil/files/file_path.cc
    ${PROJECT_SOURCE_DIR}/src/butil/files/file_path_constants.cc
    ${PROJECT_SOURCE_DIR}/src/butil/files/memory_mapped_file.cc
    ${PROJECT_SOURCE_DIR}/src/butil/files/memory_mapped_file_posix.cc
    ${PROJECT_SOURCE_DIR}/src/butil/files/scoped_file.cc
    ${PROJECT_SOURCE_DIR}/src/butil/files/scoped_temp_dir.cc
    ${PROJECT_SOURCE_DIR}/src/butil/file_util.cc
    ${PROJECT_SOURCE_DIR}/src/butil/file_util_posix.cc
    ${PROJECT_SOURCE_DIR}/src/butil/guid.cc
    ${PROJECT_SOURCE_DIR}/src/butil/guid_posix.cc
    ${PROJECT_SOURCE_DIR}/src/butil/hash.cc
    ${PROJECT_SOURCE_DIR}/src/butil/lazy_instance.cc
    ${PROJECT_SOURCE_DIR}/src/butil/location.cc
    ${PROJECT_SOURCE_DIR}/src/butil/memory/aligned_memory.cc
    ${PROJECT_SOURCE_DIR}/src/butil/memory/ref_counted.cc
    ${PROJECT_SOURCE_DIR}/src/butil/memory/ref_counted_memory.cc
    ${PROJECT_SOURCE_DIR}/src/butil/memory/singleton.cc
    ${PROJECT_SOURCE_DIR}/src/butil/memory/weak_ptr.cc
    ${PROJECT_SOURCE_DIR}/src/butil/posix/file_descriptor_shuffle.cc
    ${PROJECT_SOURCE_DIR}/src/butil/posix/global_descriptors.cc
    ${PROJECT_SOURCE_DIR}/src/butil/process_util.cc
    ${PROJECT_SOURCE_DIR}/src/butil/rand_util.cc
    ${PROJECT_SOURCE_DIR}/src/butil/rand_util_posix.cc
    ${PROJECT_SOURCE_DIR}/src/butil/fast_rand.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/safe_strerror_posix.cc
    ${PROJECT_SOURCE_DIR}/src/butil/sha1_portable.cc
    ${PROJECT_SOURCE_DIR}/src/butil/strings/latin1_string_conversions.cc
    ${PROJECT_SOURCE_DIR}/src/butil/strings/nullable_string16.cc
    ${PROJECT_SOURCE_DIR}/src/butil/strings/safe_sprintf.cc
    ${PROJECT_SOURCE_DIR}/src/butil/strings/string16.cc
    ${PROJECT_SOURCE_DIR}/src/butil/strings/string_number_conversions.cc
    ${PROJECT_SOURCE_DIR}/src/butil/strings/string_split.cc
    ${PROJECT_SOURCE_DIR}/src/butil/strings/string_piece.cc
    ${PROJECT_SOURCE_DIR}/src/butil/strings/string_util.cc
    ${PROJECT_SOURCE_DIR}/src/butil/strings/string_util_constants.cc
    ${PROJECT_SOURCE_DIR}/src/butil/strings/stringprintf.cc
    ${PROJECT_SOURCE_DIR}/src/butil/strings/utf_offset_string_conversions.cc
    ${PROJECT_SOURCE_DIR}/src/butil/strings/utf_string_conversion_utils.cc
    ${PROJECT_SOURCE_DIR}/src/butil/strings/utf_string_conversions.cc
    ${PROJECT_SOURCE_DIR}/src/butil/synchronization/cancellation_flag.cc
    ${PROJECT_SOURCE_DIR}/src/butil/synchronization/condition_variable_posix.cc
    ${PROJECT_SOURCE_DIR}/src/butil/synchronization/waitable_event_posix.cc
    ${PROJECT_SOURCE_DIR}/src/butil/threading/non_thread_safe_impl.cc
    ${PROJECT_SOURCE_DIR}/src/butil/threading/platform_thread_posix.cc
    ${PROJECT_SOURCE_DIR}/src/butil/threading/simple_thread.cc
    ${PROJECT_SOURCE_DIR}/src/butil/threading/thread_checker_impl.cc
    ${PROJECT_SOURCE_DIR}/src/butil/threading/thread_collision_warner.cc
    ${PROJECT_SOURCE_DIR}/src/butil/threading/thread_id_name_manager.cc
    ${PROJECT_SOURCE_DIR}/src/butil/threading/thread_local_posix.cc
    ${PROJECT_SOURCE_DIR}/src/butil/threading/thread_local_storage.cc
    ${PROJECT_SOURCE_DIR}/src/butil/threading/thread_local_storage_posix.cc
    ${PROJECT_SOURCE_DIR}/src/butil/threading/thread_restrictions.cc
    ${PROJECT_SOURCE_DIR}/src/butil/threading/watchdog.cc
    ${PROJECT_SOURCE_DIR}/src/butil/time/clock.cc
    ${PROJECT_SOURCE_DIR}/src/butil/time/default_clock.cc
    ${PROJECT_SOURCE_DIR}/src/butil/time/default_tick_clock.cc
    ${PROJECT_SOURCE_DIR}/src/butil/time/tick_clock.cc
    ${PROJECT_SOURCE_DIR}/src/butil/time/time.cc
    ${PROJECT_SOURCE_DIR}/src/butil/time/time_posix.cc
    ${PROJECT_SOURCE_DIR}/src/butil/version.cc
    ${PROJECT_SOURCE_DIR}/src/butil/logging.cc
    ${PROJECT_SOURCE_DIR}/src/butil/class_name.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/errno.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/find_cstr.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/status.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/string_printf.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/thread_local.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/unix_socket.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/endpoint.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/fd_utility.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/files/temp_file.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/files/file_watcher.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/time.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/zero_copy_stream_as_streambuf.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/crc32c.cc
    ${PROJECT_SOURCE_DIR}/src/butil/containers/case_ignored_flat_map.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/iobuf.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/binary_printer.cpp
    ${PROJECT_SOURCE_DIR}/src/butil/recordio.cc
    ${PROJECT_SOURCE_DIR}/src/butil/popen.cpp
    )

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(BUTIL_SOURCES ${BUTIL_SOURCES}
        ${PROJECT_SOURCE_DIR}/src/butil/file_util_linux.cc
        ${PROJECT_SOURCE_DIR}/src/butil/threading/platform_thread_linux.cc
        ${PROJECT_SOURCE_DIR}/src/butil/strings/sys_string_conversions_posix.cc)
endif()

file(GLOB_RECURSE BVAR_SOURCES "${PROJECT_SOURCE_DIR}/src/bvar/*.cpp")
file(GLOB_RECURSE BTHREAD_SOURCES "${PROJECT_SOURCE_DIR}/src/bthread/*.cpp")


set(SOURCES
    ${BVAR_SOURCES}
    ${BTHREAD_SOURCES}
    )

add_subdirectory(src)

file(COPY ${PROJECT_SOURCE_DIR}/src/
        DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/output/include/
        FILES_MATCHING
        PATTERN "*.h"
        PATTERN "*.hpp"
        )

