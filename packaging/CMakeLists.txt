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

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

if (NOT DEFINED AccelerateLAPACK_INSTALL_CMAKEDIR)
    set(
        AccelerateLAPACK_INSTALL_CMAKEDIR
        "${CMAKE_INSTALL_DATAROOTDIR}/cmake/${PROJECT_NAME}-${PROJECT_VERSION}"
    )
    set(
        AccelerateLAPACK_FULL_INSTALL_CMAKEDIR
        "${CMAKE_INSTALL_FULL_DATAROOTDIR}/cmake/${PROJECT_NAME}-${PROJECT_VERSION}"
    )
endif ()

# Add the $NEWLAPACK symbols to the linker flags of the NEW_BLAS and NEW_LAPACK
# targets
target_link_options(
    NEW_BLAS
    INTERFACE
    ${BLAS_LINKER_FLAGS}
    "$<INSTALL_INTERFACE:LINKER:-alias_list,${AccelerateLAPACK_FULL_INSTALL_CMAKEDIR}/new-blas.alias>"
)
target_link_options(
    NEW_LAPACK
    INTERFACE
    ${LAPACK_LINKER_FLAGS}
    "$<INSTALL_INTERFACE:LINKER:-alias_list,${AccelerateLAPACK_FULL_INSTALL_CMAKEDIR}/new-lapack.alias>"
)

# Add the $NEWLAPACK$ILP64 symbols to the linker flags of the NEW_BLAS64 and
# NEW_LAPACK64 targets
target_link_options(
    NEW_BLAS64
    INTERFACE
    ${BLAS_LINKER_FLAGS}
    "$<INSTALL_INTERFACE:LINKER:-alias_list,${AccelerateLAPACK_FULL_INSTALL_CMAKEDIR}/new-blas-ilp64.alias>"
)
target_link_options(
    NEW_LAPACK64
    INTERFACE
    ${LAPACK_LINKER_FLAGS}
    "$<INSTALL_INTERFACE:LINKER:-alias_list,${AccelerateLAPACK_FULL_INSTALL_CMAKEDIR}/new-lapack-ilp64.alias>"
)

install(
    TARGETS NEW_BLAS NEW_BLAS64
    EXPORT NewBLAS_Targets
)

install(
    EXPORT NewBLAS_Targets
    DESTINATION "${AccelerateLAPACK_INSTALL_CMAKEDIR}"
    NAMESPACE BLAS::
)

install(
    TARGETS NEW_LAPACK NEW_LAPACK64
    EXPORT NewLAPACK_Targets
)

install(
    EXPORT NewLAPACK_Targets
    DESTINATION "${AccelerateLAPACK_INSTALL_CMAKEDIR}"
    NAMESPACE LAPACK::
)

install(
    FILES
    "../LICENSE"
    RENAME copyright
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/doc/${PROJECT_NAME}-${PROJECT_VERSION}"
)

write_basic_package_version_file(
    AccelerateLAPACKConfigVersion.cmake
    COMPATIBILITY SameMajorVersion
)

configure_package_config_file(
    "AccelerateLAPACKConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/AccelerateLAPACKConfig.cmake"
    INSTALL_DESTINATION "${AccelerateLAPACK_INSTALL_CMAKEDIR}"
    PATH_VARS AccelerateLAPACK_INSTALL_CMAKEDIR
)

install(
    FILES
    "${CMAKE_CURRENT_BINARY_DIR}/AccelerateLAPACKConfigVersion.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/AccelerateLAPACKConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/../src/new-blas.alias"
    "${CMAKE_CURRENT_BINARY_DIR}/../src/new-blas-ilp64.alias"
    "${CMAKE_CURRENT_BINARY_DIR}/../src/new-lapack.alias"
    "${CMAKE_CURRENT_BINARY_DIR}/../src/new-lapack-ilp64.alias"
    DESTINATION "${AccelerateLAPACK_INSTALL_CMAKEDIR}"
)
