#[[
MIT License

CMake build script for the Accelerate LAPACK project
Copyright (c) 2025 Tim Kaune

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

set(CMAKE_MAXIMUM_SUPPORTED_VERSION 4.1)

cmake_minimum_required(VERSION 3.12...${CMAKE_MAXIMUM_SUPPORTED_VERSION})

project(AccelerateLAPACK VERSION 1.6.0 LANGUAGES C)

string(COMPARE EQUAL "${CMAKE_PROJECT_NAME}" "${PROJECT_NAME}" IS_TOP_LEVEL)

option(AccelerateLAPACK_INCLUDE_PACKAGING "Include packaging rules for AccelerateLAPACK" "${IS_TOP_LEVEL}")

if (NOT IS_TOP_LEVEL)
    # Check if BLAS was already searched in the parent project
    if (BLAS_FOUND)
        if (NOT BLAS_Accelerate_LIBRARY)
            message(STATUS "BLAS is provided by a different distribution than Accelerate.")
            return()
        endif ()
    else ()
        if (DEFINED BLA_VENDOR AND NOT BLA_VENDOR STREQUAL "Apple")
            message(WARNING "BLAS by vendor \"${BLA_VENDOR}\" is requested, but will be overridden to vendor \"Apple\" to search for Accelerate.")
        endif ()
    endif ()

    # Check if LAPACK was already searched in the parent project
    if (LAPACK_FOUND)
        if (NOT LAPACK_Accelerate_LIBRARY)
            message(STATUS "LAPACK is provided by a different distribution than Accelerate.")
            return()
        endif ()
    else ()
        if (DEFINED BLA_VENDOR AND NOT BLA_VENDOR STREQUAL "Apple")
            message(WARNING "LAPACK by vendor \"${BLA_VENDOR}\" is requested, but will be overridden to vendor \"Apple\" to search for Accelerate.")
        endif ()
    endif ()
endif ()

if (BLA_SIZEOF_INTEGER EQUAL 8)
    set(BUILD_INDEX64 ON)
else ()
    set(BUILD_INDEX64 OFF)
endif ()

message(STATUS "Trying to find ILP64 interface of Accelerate's BLAS/LAPACK: ${BUILD_INDEX64}")

if (CMAKE_HOST_SYSTEM_NAME MATCHES "Darwin")
    # The available binary Accelerate version is determined by the MacOS system
    message(STATUS "The Darwin kernel version is: ${CMAKE_HOST_SYSTEM_VERSION}")

    if (CMAKE_HOST_SYSTEM_VERSION VERSION_GREATER_EQUAL 24.5)
        # Mac OS X 15.5 Sequoia or later
        message(STATUS "The MacOS version is: >=15.5")
        set(MINIMUM_MACOS_SDK_VERSION 15.5)
        set(ACCELERATE_NEW_LAPACK_VERSION 3.12.0)
    elseif (CMAKE_HOST_SYSTEM_VERSION VERSION_GREATER_EQUAL 24.0)
        # Mac OS X 15.0 Sequoia or later
        message(STATUS "The MacOS version is: >=15.0,<15.5")
        set(MINIMUM_MACOS_SDK_VERSION 15.0)
        set(MAXIMUM_MACOS_SDK_VERSION 15.4)
        set(ACCELERATE_NEW_LAPACK_VERSION 3.11.0)
    elseif (CMAKE_HOST_SYSTEM_VERSION VERSION_GREATER_EQUAL 22.4)
        # Mac OS X 13.3 Ventura or later
        message(STATUS "The MacOS version is: >=13.3,<15.0")
        set(MINIMUM_MACOS_SDK_VERSION 13.3)
        set(MAXIMUM_MACOS_SDK_VERSION 14.5)
        set(ACCELERATE_NEW_LAPACK_VERSION 3.9.1)
    else ()
        # Before Mac OS X 13.3 Ventura
        message(FATAL_ERROR "You need at least MacOS 13.3 Ventura for Accelerate with BLAS/LAPACK v3.9.1!")
    endif ()

    message(STATUS "The BLAS/LAPACK version provided by the Accelerate framework should be: ${ACCELERATE_NEW_LAPACK_VERSION}")
else ()
    message(FATAL_ERROR "Accelerate is only available on MacOS!")
endif ()

if (NOT DEFINED CMAKE_OSX_SYSROOT OR CMAKE_OSX_SYSROOT STREQUAL "")
    message(FATAL_ERROR "Please select a MacOS SDK by providing the CMAKE_OSX_SYSROOT path! See <https://cmake.org/cmake/help/latest/variable/CMAKE_OSX_SYSROOT.html>")
endif ()

find_program(XCRUN_EXECUTABLE xcrun REQUIRED)

set(ENV{SDKROOT} "${CMAKE_OSX_SYSROOT}")
execute_process(
    COMMAND "${XCRUN_EXECUTABLE}" --show-sdk-version
    OUTPUT_VARIABLE SELECTED_MACOS_SDK_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

message(STATUS "The selected MacOS SDK path is: ${CMAKE_OSX_SYSROOT}")
message(STATUS "The selected MacOS SDK version is: ${SELECTED_MACOS_SDK_VERSION}")

# The text-based .dylib stubs describing the Accelerate framework are provided
# by the MacOS SDK, which has to match the MacOS system. It could be too old for
# the system, in which case it might be missing symbols that could actually be
# provided by the Accelerate binary, or it could be too recent, in which case
# there might be newer symbols in the text-based .dylib stubs that are not
# provided by the Accelerate binary, leading to linking errors.
if (SELECTED_MACOS_SDK_VERSION VERSION_LESS MINIMUM_MACOS_SDK_VERSION)
    # SDK is too old!
    message(STATUS "The minimum compatible MacOS SDK version is: ${MINIMUM_MACOS_SDK_VERSION}")
    message(FATAL_ERROR "Please install and select a more recent XCode/Command Line Tools for a compatible MacOS SDK.")
else ()
    # SDK is not too old, but...
    if (DEFINED MAXIMUM_MACOS_SDK_VERSION AND SELECTED_MACOS_SDK_VERSION VERSION_GREATER MAXIMUM_MACOS_SDK_VERSION)
        # ...there is a maximum compatible MacOS SDK version, because the MacOS
        # system is older and only supports one of the past iterations of the
        # new Accelerate BLAS/LAPACK, and the selected SDK is too recent!
        message(STATUS "The minimum compatible MacOS SDK version is: ${MINIMUM_MACOS_SDK_VERSION}")
        message(STATUS "The maximum compatible MacOS SDK version is: ${MAXIMUM_MACOS_SDK_VERSION}")
        message(FATAL_ERROR "Please install and select a compatible MacOS SDK via XCode/Command Line Tools.")    
    endif ()
endif ()

# The selected MacOS SDK's new Accelerate BLAS/LAPACK matches the MacOS system's
# Accelerate binary.

set(ENV{CMAKE_FRAMEWORK_PATH} "${CMAKE_OSX_SYSROOT}/System/Library/Frameworks")

set(BLA_VENDOR "Apple")
set(BLA_SIZEOF_INTEGER_BACKUP "${BLA_SIZEOF_INTEGER}")
set(BLA_SIZEOF_INTEGER "ANY")

# BLAS::BLAS and LAPACK::LAPACK targets need to be global to be available in the
# parent project
if (NOT BLAS_FOUND)
    find_package(BLAS MODULE GLOBAL)
endif ()
if (NOT LAPACK_FOUND)
    find_package(LAPACK MODULE GLOBAL)
endif ()

set(BLA_SIZEOF_INTEGER "${BLA_SIZEOF_INTEGER_BACKUP}")
unset(ENV{CMAKE_FRAMEWORK_PATH})

if (NOT BLAS_FOUND OR NOT BLAS_Accelerate_LIBRARY OR NOT LAPACK_FOUND OR NOT LAPACK_Accelerate_LIBRARY)
    message(FATAL_ERROR "Couldn't find Accelerate framework in MacOS SDK!")
endif ()

add_subdirectory(src)

if (AccelerateLAPACK_INCLUDE_PACKAGING)
    add_subdirectory(packaging)
endif ()

if (NOT IS_TOP_LEVEL)
    # Export the API variables into the parent project
    set(ACCELERATE_LAPACK_ILAVER_VERSION "${ACCELERATE_LAPACK_ILAVER_VERSION}" PARENT_SCOPE)

    set(BLAS_FOUND "${BLAS_FOUND}" PARENT_SCOPE)
    set(BLAS_LIBRARIES "${BLAS_LIBRARIES}" PARENT_SCOPE)
    set(BLAS_LINKER_FLAGS "${BLAS_LINKER_FLAGS}" PARENT_SCOPE)

    set(BLAS32_LIBRARIES "${BLAS32_LIBRARIES}" PARENT_SCOPE)
    set(BLAS32_LINKER_FLAGS "${BLAS32_LINKER_FLAGS}" PARENT_SCOPE)
    set(BLAS64_LIBRARIES "${BLAS64_LIBRARIES}" PARENT_SCOPE)
    set(BLAS64_LINKER_FLAGS "${BLAS64_LINKER_FLAGS}" PARENT_SCOPE)

    set(LAPACK_FOUND "${LAPACK_FOUND}" PARENT_SCOPE)
    set(LAPACK_LIBRARIES "${LAPACK_LIBRARIES}" PARENT_SCOPE)
    set(LAPACK_LINKER_FLAGS "${LAPACK_LINKER_FLAGS}" PARENT_SCOPE)

    set(LAPACK32_LIBRARIES "${LAPACK32_LIBRARIES}" PARENT_SCOPE)
    set(LAPACK32_LINKER_FLAGS "${LAPACK32_LINKER_FLAGS}" PARENT_SCOPE)
    set(LAPACK64_LIBRARIES "${LAPACK64_LIBRARIES}" PARENT_SCOPE)
    set(LAPACK64_LINKER_FLAGS "${LAPACK64_LINKER_FLAGS}" PARENT_SCOPE)
endif ()
