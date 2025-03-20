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

include("../cmake/ParseTBDMacros.cmake")

# Paths to text-based .dylib stubs
set(BLAS_TBD_PATH "${LAPACK_Accelerate_LIBRARY}/Versions/A/Frameworks/vecLib.framework/Versions/A/libBLAS.tbd")
set(LAPACK_TBD_PATH "${LAPACK_Accelerate_LIBRARY}/Versions/A/Frameworks/vecLib.framework/Versions/A/libLAPACK.tbd")

parse_tbd_symbols(BLAS "${BLAS_TBD_PATH}")
filter_new_lapack_symbols(BLAS)
filter_new_lapack_ilp64_symbols(BLAS)

parse_tbd_symbols(LAPACK "${LAPACK_TBD_PATH}")
filter_new_lapack_symbols(LAPACK)
filter_new_lapack_ilp64_symbols(LAPACK)

build_aliases(BLAS_NEWLAPACK_SYMBOLS)
build_aliases(BLAS_NEWLAPACK_ILP64_SYMBOLS)
build_aliases(LAPACK_NEWLAPACK_SYMBOLS)
build_aliases(LAPACK_NEWLAPACK_ILP64_SYMBOLS)

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/new-lapack.alias"
"\
# BLAS

${BLAS_NEWLAPACK_ALIASES}

# LAPACK

${LAPACK_NEWLAPACK_ALIASES}
"
)

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/new-lapack-ilp64.alias"
"\
# BLAS

${BLAS_NEWLAPACK_ILP64_ALIASES}

# LAPACK

${LAPACK_NEWLAPACK_ILP64_ALIASES}
"
)

set(BLAS32_LINKER_FLAGS "-Wl,-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-lapack.alias")
set(LAPACK32_LINKER_FLAGS "-Wl,-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-lapack.alias")

if (BUILD_INDEX64)
    # Add the $NEWLAPACK$ILP64 symbols to the linker flags used for shared libraries
    list(APPEND BLAS_LINKER_FLAGS "-Wl,-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-lapack-ilp64.alias")
    list(APPEND LAPACK_LINKER_FLAGS "-Wl,-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-lapack-ilp64.alias")
else ()
    # Add the $NEWLAPACK symbols to the linker flags used for shared libraries
    list(APPEND BLAS_LINKER_FLAGS "-Wl,-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-lapack.alias")
    list(APPEND LAPACK_LINKER_FLAGS "-Wl,-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-lapack.alias")
endif ()

set(BLAS32_LINKER_FLAGS "${BLAS32_LINKER_FLAGS}" PARENT_SCOPE)
set(LAPACK32_LINKER_FLAGS "${LAPACK32_LINKER_FLAGS}" PARENT_SCOPE)
set(BLAS_LINKER_FLAGS "${BLAS_LINKER_FLAGS}" PARENT_SCOPE)
set(LAPACK_LINKER_FLAGS "${LAPACK_LINKER_FLAGS}" PARENT_SCOPE)

set_target_properties(BLAS::BLAS PROPERTIES INTERFACE_LINK_OPTIONS "$<BUILD_INTERFACE:${BLAS_LINKER_FLAGS}>")
set_target_properties(LAPACK::LAPACK PROPERTIES INTERFACE_LINK_OPTIONS "$<BUILD_INTERFACE:${LAPACK_LINKER_FLAGS}>")
