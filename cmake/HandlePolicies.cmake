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

if (NOT DEFINED CMAKE_MAXIMUM_SUPPORTED_VERSION)
    set(CMAKE_MAXIMUM_SUPPORTED_VERSION ${CMAKE_MINIMUM_REQUIRED_VERSION})
endif ()

# If CMAKE_VERSION <= CMAKE_MAXIMUM_SUPPORTED_VERSION is used, set policies up
# to CMAKE_VERSION to NEW
if (${CMAKE_VERSION} VERSION_LESS_EQUAL ${CMAKE_MAXIMUM_SUPPORTED_VERSION})
    cmake_policy(VERSION ${CMAKE_VERSION})
# If CMAKE_VERSION > CMAKE_MAXIMUM_SUPPORTED_VERSION is used, set policies up to
# CMAKE_MAXIMUM_SUPPORTED_VERSION to NEW
else ()
    cmake_policy(VERSION ${CMAKE_MAXIMUM_SUPPORTED_VERSION})
endif()
