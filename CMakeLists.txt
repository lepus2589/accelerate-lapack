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

set(CMAKE_MAXIMUM_SUPPORTED_VERSION 4.0)

cmake_minimum_required(VERSION 3.12...${CMAKE_MAXIMUM_SUPPORTED_VERSION})

project(AccelerateLAPACK VERSION 1.4.0 LANGUAGES C)

string(COMPARE EQUAL "${CMAKE_PROJECT_NAME}" "${PROJECT_NAME}" IS_TOP_LEVEL)

option(AccelerateLAPACK_INCLUDE_PACKAGING "Include packaging rules for AccelerateLAPACK" "${IS_TOP_LEVEL}")

option(BUILD_INDEX64 "Link to ILP64 version of LAPACK?" OFF)

message(STATUS "Trying to link to ILP64 interface of LAPACK: ${BUILD_INDEX64}")

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
        set(VALID_MACOS_SDK_VERSIONS 15.4 15.2 15.1 ${MINIMUM_MACOS_SDK_VERSION})
        set(ACCELERATE_NEW_LAPACK_VERSION 3.11.0)
    elseif (CMAKE_HOST_SYSTEM_VERSION VERSION_GREATER_EQUAL 22.4)
        # Mac OS X 13.3 Ventura or later
        message(STATUS "The MacOS version is: >=13.3,<15.0")
        set(MINIMUM_MACOS_SDK_VERSION 13.3)
        set(VALID_MACOS_SDK_VERSIONS 14.5 14.4 14.2 14.0 ${MINIMUM_MACOS_SDK_VERSION})
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
    message(FATAL_ERROR "Please provide the CMAKE_OSX_SYSROOT location! See <https://cmake.org/cmake/help/latest/variable/CMAKE_OSX_SYSROOT.html>")
endif ()

string(REGEX MATCH [=[SDKs/MacOSX(.*)\.sdk$]=] _REGEX_DUMMY "${CMAKE_OSX_SYSROOT}")
set(MAIN_MACOS_SDK_VERSION "${CMAKE_MATCH_1}")

# The text-based .dylib stubs describing the Accelerate framework are provided
# by the MacOS SDK, which has to match the MacOS system. Otherwise, there might
# be newer symbols in the text-based .dylib stubs that are not provided by the
# Accelerate binary, leading to linking errors.
if (NOT DEFINED VALID_MACOS_SDK_VERSIONS)
    # MacOS system supports the latest iteration of the new Accelerate
    # BLAS/LAPACK. Use the default SDK, if it's recent enough.
    if (MAIN_MACOS_SDK_VERSION VERSION_LESS MINIMUM_MACOS_SDK_VERSION)
        message(STATUS "The MacOS SDK is: ${CMAKE_OSX_SYSROOT}")
        message(STATUS "The minimum compatible MacOS SDK version is: ${MINIMUM_MACOS_SDK_VERSION}")
        message(FATAL_ERROR "Please install a more recent XCode for a compatible MacOS SDK.")
    endif ()
elseif (NOT MAIN_MACOS_SDK_VERSION IN_LIST VALID_MACOS_SDK_VERSIONS)
    # MacOS system supports one of the past iterations of the new Accelerate
    # BLAS/LAPACK. If the latest possible XCode is installed on this older
    # system, there might be a mismatch between the SDK and the system binary.
    # Find a matching SDK from the Command Line Tools instead (which must be
    # manually installed).
    foreach (_MACOS_SDK_VERSION IN LISTS VALID_MACOS_SDK_VERSIONS)
        find_path(VALID_MACOS_SDK NAMES "MacOSX${_MACOS_SDK_VERSION}.sdk" HINTS "/Library/Developer/CommandLineTools/SDKs" NO_CACHE)

        if (VALID_MACOS_SDK)
            set(VALID_MACOS_SDK "${VALID_MACOS_SDK}/MacOSX${_MACOS_SDK_VERSION}.sdk")
            break ()
        endif ()
    endforeach ()

    if (VALID_MACOS_SDK)
        # Override CMAKE_OSX_SYSROOT with a local variable.
        set(CMAKE_OSX_SYSROOT "${VALID_MACOS_SDK}")
    else ()
        message(STATUS "The MacOS SDK is: ${CMAKE_OSX_SYSROOT}")
        message(STATUS "The compatible MacOS SDK versions are: ${VALID_MACOS_SDK_VERSIONS}")
        message(FATAL_ERROR "Couldn't find a compatible MacOS SDK. Please install compatible XCode Command Line Tools.")
    endif ()
endif ()

message(STATUS "The MacOS SDK is: ${CMAKE_OSX_SYSROOT}")

set(ENV{CMAKE_FRAMEWORK_PATH} "${CMAKE_OSX_SYSROOT}/System/Library/Frameworks")

set(BLA_VENDOR "Apple")
# BLAS::BLAS and LAPACK::LAPACK targets need to be global to be used in try_compile()
find_package(LAPACK MODULE GLOBAL)

unset(ENV{CMAKE_FRAMEWORK_PATH})

if (NOT LAPACK_FOUND OR NOT LAPACK_Accelerate_LIBRARY)
    message(FATAL_ERROR "Couldn't find Accelerate framework in MacOS SDK!")
endif ()

add_subdirectory(src)

if (AccelerateLAPACK_INCLUDE_PACKAGING)
    add_subdirectory(packaging)
endif ()
