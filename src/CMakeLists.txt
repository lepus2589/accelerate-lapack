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

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/new-blas.alias.in"
    "${CMAKE_CURRENT_BINARY_DIR}/new-blas.alias"
    @ONLY
)

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/new-lapack.alias.in"
    "${CMAKE_CURRENT_BINARY_DIR}/new-lapack.alias"
    @ONLY
)

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/new-blas-ilp64.alias.in"
    "${CMAKE_CURRENT_BINARY_DIR}/new-blas-ilp64.alias"
    @ONLY
)

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/new-lapack-ilp64.alias.in"
    "${CMAKE_CURRENT_BINARY_DIR}/new-lapack-ilp64.alias"
    @ONLY
)

add_library(NEW_BLAS INTERFACE)
add_library(BLAS::NEW_BLAS ALIAS NEW_BLAS)
target_link_libraries(NEW_BLAS INTERFACE ${BLAS_LIBRARIES})

add_library(NEW_LAPACK INTERFACE)
add_library(LAPACK::NEW_LAPACK ALIAS NEW_LAPACK)
target_link_libraries(NEW_LAPACK INTERFACE ${LAPACK_LIBRARIES} NEW_BLAS)

add_library(BLAS::NEW_BLAS_IMPORTED INTERFACE IMPORTED GLOBAL)
target_link_libraries(BLAS::NEW_BLAS_IMPORTED INTERFACE ${BLAS_LIBRARIES})

add_library(LAPACK::NEW_LAPACK_IMPORTED INTERFACE IMPORTED GLOBAL)
target_link_libraries(LAPACK::NEW_LAPACK_IMPORTED INTERFACE ${LAPACK_LIBRARIES} BLAS::NEW_BLAS_IMPORTED)

# Add the $NEWLAPACK symbols to the linker flags of the NEW_BLAS and NEW_LAPACK
# targets
target_link_options(
    NEW_BLAS
    INTERFACE
    ${BLAS_LINKER_FLAGS}
    "$<BUILD_INTERFACE:LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-blas.alias>"
)
target_link_options(
    NEW_LAPACK
    INTERFACE
    ${LAPACK_LINKER_FLAGS}
    "$<BUILD_INTERFACE:LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-lapack.alias>"
)

target_link_options(
    BLAS::NEW_BLAS_IMPORTED
    INTERFACE
    ${BLAS_LINKER_FLAGS}
    "LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-blas.alias"
)
target_link_options(
    LAPACK::NEW_LAPACK_IMPORTED
    INTERFACE
    ${LAPACK_LINKER_FLAGS}
    "LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-lapack.alias"
)

add_library(NEW_BLAS64 INTERFACE)
add_library(BLAS::NEW_BLAS64 ALIAS NEW_BLAS64)
target_link_libraries(NEW_BLAS64 INTERFACE ${BLAS_LIBRARIES})

add_library(NEW_LAPACK64 INTERFACE)
add_library(LAPACK::NEW_LAPACK64 ALIAS NEW_LAPACK64)
target_link_libraries(NEW_LAPACK64 INTERFACE ${LAPACK_LIBRARIES} NEW_BLAS64)

add_library(BLAS::NEW_BLAS64_IMPORTED INTERFACE IMPORTED GLOBAL)
target_link_libraries(BLAS::NEW_BLAS64_IMPORTED INTERFACE ${BLAS_LIBRARIES})

add_library(LAPACK::NEW_LAPACK64_IMPORTED INTERFACE IMPORTED GLOBAL)
target_link_libraries(LAPACK::NEW_LAPACK64_IMPORTED INTERFACE ${LAPACK_LIBRARIES} BLAS::NEW_BLAS64_IMPORTED)

# Add the $NEWLAPACK$ILP64 symbols to the linker flags of the NEW_BLAS64 and
# NEW_LAPACK64 targets
target_link_options(
    NEW_BLAS64
    INTERFACE
    ${BLAS_LINKER_FLAGS}
    "$<BUILD_INTERFACE:LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-blas-ilp64.alias>"
)
target_link_options(
    NEW_LAPACK64
    INTERFACE
    ${LAPACK_LINKER_FLAGS}
    "$<BUILD_INTERFACE:LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-lapack-ilp64.alias>"
)

target_link_options(
    BLAS::NEW_BLAS64_IMPORTED
    INTERFACE
    ${BLAS_LINKER_FLAGS}
    "LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-blas-ilp64.alias"
)
target_link_options(
    LAPACK::NEW_LAPACK64_IMPORTED
    INTERFACE
    ${LAPACK_LINKER_FLAGS}
    "LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-lapack-ilp64.alias"
)

if (BUILD_INDEX64)
    # Add the $NEWLAPACK$ILP64 symbols to the BLAS and LAPACK libraries.
    set(BLAS_LIBRARIES "BLAS::NEW_BLAS64")
    set(LAPACK_LIBRARIES "LAPACK::NEW_LAPACK64")
else ()
    # Add the $NEWLAPACK symbols to the BLAS and LAPACK libraries.
    set(BLAS_LIBRARIES "BLAS::NEW_BLAS")
    set(LAPACK_LIBRARIES "LAPACK::NEW_LAPACK")
endif ()

set_target_properties(BLAS::BLAS PROPERTIES INTERFACE_LINK_LIBRARIES "${BLAS_LIBRARIES}")
set_target_properties(LAPACK::LAPACK PROPERTIES INTERFACE_LINK_LIBRARIES "${LAPACK_LIBRARIES}")

try_run(
    HAS_RUN_ILAVER HAS_ILAVER
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/lapack_version.c"
    LINK_LIBRARIES "LAPACK::NEW_LAPACK_IMPORTED"
    RUN_OUTPUT_VARIABLE ACCELERATE_LAPACK_ILAVER_VERSION
)

try_run(
    HAS_RUN_ILAVER64 HAS_ILAVER64
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/lapack64_version.c"
    LINK_LIBRARIES "LAPACK::NEW_LAPACK64_IMPORTED"
    RUN_OUTPUT_VARIABLE ACCELERATE_LAPACK_ILAVER64_VERSION
)

if (ACCELERATE_LAPACK_ILAVER_VERSION VERSION_EQUAL ACCELERATE_NEW_LAPACK_VERSION)
    message(STATUS "The BLAS/LAPACK version provided by the Accelerate framework is confirmed to be: ${ACCELERATE_LAPACK_ILAVER_VERSION}")
else ()
    message(WARNING "The BLAS/LAPACK version ${ACCELERATE_LAPACK_ILAVER_VERSION} provided by the Accelerate framework doesn't match what it should be: ${ACCELERATE_NEW_LAPACK_VERSION}")
endif ()

if (ACCELERATE_LAPACK_ILAVER64_VERSION VERSION_EQUAL ACCELERATE_NEW_LAPACK_VERSION)
    message(STATUS "The ILP64 interface is available.")
else ()
    message(WARNING "The BLAS/LAPACK ILP64 version ${ACCELERATE_LAPACK_ILAVER_VERSION} provided by the Accelerate framework doesn't match what it should be: ${ACCELERATE_NEW_LAPACK_VERSION}")
endif ()

set_target_properties(
    NEW_BLAS
    NEW_LAPACK
    PROPERTIES
    VERSION ${ACCELERATE_LAPACK_ILAVER_VERSION}
)

set_target_properties(
    NEW_BLAS64
    NEW_LAPACK64
    PROPERTIES
    VERSION ${ACCELERATE_LAPACK_ILAVER64_VERSION}
)

set(ACCELERATE_LAPACK_ILAVER_VERSION "${ACCELERATE_LAPACK_ILAVER_VERSION}" PARENT_SCOPE)
set(ACCELERATE_LAPACK_ILAVER64_VERSION "${ACCELERATE_LAPACK_ILAVER64_VERSION}" PARENT_SCOPE)
