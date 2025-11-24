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
parse_tbd_symbols(LAPACK "${LAPACK_TBD_PATH}")

filter_new_lapack_symbols(BLAS)
filter_new_lapack_symbols(LAPACK)
filter_new_lapack_ilp64_symbols(BLAS)
filter_new_lapack_ilp64_symbols(LAPACK)

build_aliases(BLAS_NEWLAPACK_SYMBOLS)
build_aliases(LAPACK_NEWLAPACK_SYMBOLS)
build_aliases(BLAS_NEWLAPACK_ILP64_SYMBOLS)
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

# Both 32 bit and 64 bit symbols are contained in Accelerate.
set(BLAS32_LIBRARIES ${BLAS_LIBRARIES})
set(BLAS64_LIBRARIES ${BLAS_LIBRARIES})
set(LAPACK32_LIBRARIES ${LAPACK_LIBRARIES})
set(LAPACK64_LIBRARIES ${LAPACK_LIBRARIES})

# Linker flags need to be expanded for 32 bit and 64 bit, respectively.
set(
    BLAS32_LINKER_FLAGS
    ${BLAS_LINKER_FLAGS}
    "$<BUILD_INTERFACE:LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-blas.alias>"
)
set(
    BLAS64_LINKER_FLAGS
    ${BLAS_LINKER_FLAGS}
    "$<BUILD_INTERFACE:LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-blas-ilp64.alias>"
)
set(
    LAPACK32_LINKER_FLAGS
    ${LAPACK_LINKER_FLAGS}
    "$<BUILD_INTERFACE:LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-blas.alias>"
    "$<BUILD_INTERFACE:LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-lapack.alias>"
)
set(
    LAPACK64_LINKER_FLAGS
    ${LAPACK_LINKER_FLAGS}
    "$<BUILD_INTERFACE:LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-blas-ilp64.alias>"
    "$<BUILD_INTERFACE:LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-lapack-ilp64.alias>"
)

add_library(NEW_BLAS INTERFACE)
add_library(BLAS::NEW_BLAS ALIAS NEW_BLAS)
target_link_libraries(NEW_BLAS INTERFACE ${BLAS32_LIBRARIES})

add_library(NEW_LAPACK INTERFACE)
add_library(LAPACK::NEW_LAPACK ALIAS NEW_LAPACK)
target_link_libraries(NEW_LAPACK INTERFACE ${LAPACK32_LIBRARIES})

# Add the $NEWLAPACK symbols to the linker flags of the NEW_BLAS and NEW_LAPACK
# targets
target_link_options(NEW_BLAS INTERFACE ${BLAS32_LINKER_FLAGS})
target_link_options(NEW_LAPACK INTERFACE ${LAPACK32_LINKER_FLAGS})

add_library(NEW_BLAS64 INTERFACE)
add_library(BLAS::NEW_BLAS64 ALIAS NEW_BLAS64)
target_link_libraries(NEW_BLAS64 INTERFACE ${BLAS64_LIBRARIES})

add_library(NEW_LAPACK64 INTERFACE)
add_library(LAPACK::NEW_LAPACK64 ALIAS NEW_LAPACK64)
target_link_libraries(NEW_LAPACK64 INTERFACE ${LAPACK64_LIBRARIES})

# Add the $NEWLAPACK$ILP64 symbols to the linker flags of the NEW_BLAS64 and
# NEW_LAPACK64 targets
target_link_options(NEW_BLAS64 INTERFACE ${BLAS64_LINKER_FLAGS})
target_link_options(NEW_LAPACK64 INTERFACE ${LAPACK64_LINKER_FLAGS})

if (BUILD_INDEX64)
    # Add the $NEWLAPACK$ILP64 symbols to the BLAS and LAPACK libraries.
    set(
        BLAS_IMPORTED_LINKER_FLAGS
        ${BLAS_LINKER_FLAGS}
        "LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-blas-ilp64.alias"
    )
    set(BLAS_LINKER_FLAGS ${BLAS64_LINKER_FLAGS})
    set(
        LAPACK_IMPORTED_LINKER_FLAGS
        ${LAPACK_LINKER_FLAGS}
        "LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-blas-ilp64.alias"
        "LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-lapack-ilp64.alias"
    )
    set(LAPACK_LINKER_FLAGS ${LAPACK64_LINKER_FLAGS})

    try_run(
        HAS_RUN_ILAVER64 HAS_ILAVER64
        SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/lapack64_version.c"
        LINK_LIBRARIES ${LAPACK64_LIBRARIES}
        LINK_OPTIONS ${LAPACK64_LINKER_FLAGS}
        RUN_OUTPUT_VARIABLE ACCELERATE_LAPACK_ILAVER_VERSION
    )

    if (ACCELERATE_LAPACK_ILAVER_VERSION VERSION_EQUAL ACCELERATE_NEW_LAPACK_VERSION)
        message(STATUS "The BLAS/LAPACK ILP64 version provided by the Accelerate framework is confirmed to be: ${ACCELERATE_LAPACK_ILAVER_VERSION}")
    else ()
        message(WARNING "The BLAS/LAPACK ILP64 version ${ACCELERATE_LAPACK_ILAVER_VERSION} provided by the Accelerate framework doesn't match what it should be: ${ACCELERATE_NEW_LAPACK_VERSION}")
    endif ()
else ()
    # Add the $NEWLAPACK symbols to the BLAS and LAPACK libraries.
    set(
        BLAS_IMPORTED_LINKER_FLAGS
        ${BLAS_LINKER_FLAGS}
        "LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-blas.alias"
    )
    set(BLAS_LINKER_FLAGS ${BLAS32_LINKER_FLAGS})
    set(
        LAPACK_IMPORTED_LINKER_FLAGS
        ${LAPACK_LINKER_FLAGS}
        "LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-blas.alias"
        "LINKER:-alias_list,${CMAKE_CURRENT_BINARY_DIR}/new-lapack.alias"
    )
    set(LAPACK_LINKER_FLAGS ${LAPACK32_LINKER_FLAGS})

    try_run(
        HAS_RUN_ILAVER HAS_ILAVER
        SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/lapack_version.c"
        LINK_LIBRARIES ${LAPACK32_LIBRARIES}
        LINK_OPTIONS ${LAPACK32_LINKER_FLAGS}
        RUN_OUTPUT_VARIABLE ACCELERATE_LAPACK_ILAVER_VERSION
    )

    if (ACCELERATE_LAPACK_ILAVER_VERSION VERSION_EQUAL ACCELERATE_NEW_LAPACK_VERSION)
        message(STATUS "The BLAS/LAPACK version provided by the Accelerate framework is confirmed to be: ${ACCELERATE_LAPACK_ILAVER_VERSION}")
    else ()
        message(WARNING "The BLAS/LAPACK version ${ACCELERATE_LAPACK_ILAVER_VERSION} provided by the Accelerate framework doesn't match what it should be: ${ACCELERATE_NEW_LAPACK_VERSION}")
    endif ()
endif ()

set_target_properties(
    NEW_BLAS
    NEW_LAPACK
    NEW_BLAS64
    NEW_LAPACK64
    PROPERTIES
    VERSION ${ACCELERATE_LAPACK_ILAVER_VERSION}
)

set_target_properties(BLAS::BLAS PROPERTIES INTERFACE_LINK_LIBRARIES "${BLAS_LIBRARIES}")
set_target_properties(BLAS::BLAS PROPERTIES INTERFACE_LINK_OPTIONS "${BLAS_IMPORTED_LINKER_FLAGS}")

set_target_properties(LAPACK::LAPACK PROPERTIES INTERFACE_LINK_LIBRARIES "${LAPACK_LIBRARIES}")
set_target_properties(LAPACK::LAPACK PROPERTIES INTERFACE_LINK_OPTIONS "${LAPACK_IMPORTED_LINKER_FLAGS}")

set(ACCELERATE_LAPACK_ILAVER_VERSION "${ACCELERATE_LAPACK_ILAVER_VERSION}" PARENT_SCOPE)

set(BLAS_LINKER_FLAGS "${BLAS_LINKER_FLAGS}" PARENT_SCOPE)
set(BLAS32_LIBRARIES "${BLAS32_LIBRARIES}" PARENT_SCOPE)
set(BLAS32_LINKER_FLAGS "${BLAS32_LINKER_FLAGS}" PARENT_SCOPE)
set(BLAS64_LIBRARIES "${BLAS64_LIBRARIES}" PARENT_SCOPE)
set(BLAS64_LINKER_FLAGS "${BLAS64_LINKER_FLAGS}" PARENT_SCOPE)

set(LAPACK_LINKER_FLAGS "${LAPACK_LINKER_FLAGS}" PARENT_SCOPE)
set(LAPACK32_LIBRARIES "${LAPACK32_LIBRARIES}" PARENT_SCOPE)
set(LAPACK32_LINKER_FLAGS "${LAPACK32_LINKER_FLAGS}" PARENT_SCOPE)
set(LAPACK64_LIBRARIES "${LAPACK64_LIBRARIES}" PARENT_SCOPE)
set(LAPACK64_LINKER_FLAGS "${LAPACK64_LINKER_FLAGS}" PARENT_SCOPE)
