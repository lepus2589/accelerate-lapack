<!---
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
--->

# Accelerate LAPACK #

Since MacOS 13.3 Ventura, Apple's Accelerate framework comes with a new
[BLAS/LAPACK interface][accelerate-docs] compatible with [Reference LAPACK
v3.9.1][lapack-v3.9.1] in addition to the quite outdated [Reference LAPACK
v3.2.1][lapack-v3.2.1]. It also provides an ILP64 interface. On Apple Silicon
M-processors, it utilises the [proprietary AMX co-processor][apple-amx], which
makes it especially interesting.

**Update**: With the release of MacOS 15.0 Sequoia, Apple updated the Accelerate
framework to be compatible with [Reference LAPACK v3.11.0][lapack-v3.11.0].
Unfortunately, there is no mention of it in the [MacOS 15.0 Sequoia Release
Notes][macos15-release-notes], but the note in the [Accelerate BLAS
docs][accelerate-docs] has been updated accordingly.

**Update2**: With the release of MacOS 15.5 Sequoia, Apple updated the
Accelerate framework to be compatible with [Reference LAPACK
v3.12.0][lapack-v3.12.0]. Unfortunately, there is no mention of it in the [MacOS
15.5 Sequoia Release Notes][macos15.5-release-notes], but the note in the
[Accelerate BLAS docs][accelerate-docs] has been updated accordingly, even
though it erroneously says, v3.12.0 will be supported with MacOS 26.

These new interfaces are hidden behind the preprocessor defines
`ACCELERATE_NEW_LAPACK` and `ACCELERATE_LAPACK_ILP64` and they only work, if you
include the Accelerate C/C++ headers.

[accelerate-docs]: https://developer.apple.com/documentation/accelerate/blas-library
[apple-amx]: https://github.com/corsix/amx
[lapack-v3.2.1]: https://netlib.org/lapack/#_lapack_version_3_2_1
[lapack-v3.9.1]: https://github.com/Reference-LAPACK/lapack/releases/tag/v3.9.1
[lapack-v3.11.0]: https://github.com/Reference-LAPACK/lapack/releases/tag/v3.11.0
[lapack-v3.12.0]: https://github.com/Reference-LAPACK/lapack/releases/tag/v3.12.0
[macos15-release-notes]: https://developer.apple.com/documentation/macos-release-notes/macos-15-release-notes
[macos15.5-release-notes]: https://developer.apple.com/documentation/macos-release-notes/macos-15_5-release-notes

- [The Problem](#the-problem)
- [The Solution](#the-solution)
  - [The alias files (to use in other projects)](#the-alias-files-to-use-in-other-projects)
- [How to compile](#how-to-compile)
  - [Prerequisites](#prerequisites)
  - [MaxOS SDK Selection](#maxos-sdk-selection)
  - [Workflow with CMake](#workflow-with-cmake)
  - [Using Accelerate LAPACK in another CMake project](#using-accelerate-lapack-in-another-cmake-project)
    - [Input variables](#input-variables)
    - [Output variables and targets](#output-variables-and-targets)

## The Problem ##

But what if you have to or just want to link against the Accelerate framework
without including the C/C++ headers, e.&nbsp;g. when compiling Fortran code or a
third-party project, that uses the standard BLAS/LAPACK API? Well, you're out of
luck. The binary symbols for the new LAPACK version exported by the Accelerate
framework do not adhere to the BLAS/LAPACK API. Thus, they cannot be resolved by
the linker, when linking any program or library that uses the standard
BLAS/LAPACK API.

Take, for example, the `dgeqrt` LAPACK routine, that is used by the [Reference
LAPACK CMake script][dgeqrt-ref] to determine, if the user provided LAPACK
version is recent enough. When the Fortran test executable is compiled, the
`gfortran` compiler creates a function call with the binary symbol `_dgeqrt_`,
which results in the following error when linking to Accelerate (`ld` is the
Apple system linker, here):

```plaintext
ld: Undefined symbols:
  _dgeqrt_, referenced from:
      _MAIN__ in testFortranCompiler.f.o
```

The reason for this is, that the binary symbol provided by the Accelerate
framework is called `_dgeqrt$NEWLAPACK`, literally. This is a symbol, that no
Fortran compiler will probably ever emit voluntarily. So, what to do?

[dgeqrt-ref]: https://github.com/Reference-LAPACK/lapack/blob/v3.12.0/CMakeLists.txt#L295-L296

## The Solution ##

According to its `man` page, the Apple system linker `ld` provides the options
`-alias` and `-alias_list`, which let you create alias names for existing binary
symbols. Calling the linker with `-alias '_dgeqrt$NEWLAPACK' _dgeqrt_` makes the
linking of the above Fortran test executable finish successfully.

Because BLAS and LAPACK contain quite a number of subroutines and functions,
this CMake scipt uses the `-alias_list` option, which loads a plaintext file
listing all the aliases.

To generate the full alias list for the Accelerate NEWLAPACK interface, it
parses the symbols listed in the BLAS and LAPACK text-based `.dylib` stubs. For
every symbol that ends in `$NEWLAPACK` (or `$NEWLAPACK$ILP64` for the ILP64
interface), an alias is added to the alias file.

The additional linker options get attached to new interface library targets,
which are in turn attached to the BLAS::BLAS and LAPACK::LAPACK targets.

### The alias files (to use in other projects) ###

After building and installing, the alias files can be found in
`<install prefix>/share/cmake/AccelerateLAPACK-<version>`:

```plaintext
share/cmake/AccelerateLAPACK-<version>
├── new-blas-ilp64.alias
├── new-blas.alias
├── new-lapack-ilp64.alias
└── new-lapack.alias
```

These files can be used to link any project against Accelerate! For CMake
projects, you can just [import this
project](#using-accelerate-lapack-in-another-cmake-project).

## How to compile ##

It is recommended to use the Apple System C Compiler `/usr/bin/cc`. You can also
use a more recent Clang compiler provided by Homebrew or MacPorts. If you have
other compilers installed on your system, make sure CMake finds the correct one.
Otherwise, help CMake by setting the environment variable `$ export
CC=/usr/bin/cc` in your terminal window.

It is also recommended to use at least CMake v3.25 with presets, but the CMake
script also works down to CMake v3.12, if you set the required variables on the
command line.

### Prerequisites ###

Obviously, your operating system must be Mac OS X >=v13.3 Ventura with XCode
installed. Additionally, you'll need the following software (easily obtainable
via Homebrew or MacPorts):

- CMake

### MaxOS SDK Selection ###

To build the project you must provide the [`CMAKE_OSX_SYSROOT`][macos_sdk]
variable. Prior to CMake v4, this was computed automatically, if empty. Since
CMake v4, this is empty by default and won't be populated automatically.

In any case, it is **strongly recommended** to explicitly select a matching SDK
for your MacOS system. Matching in this case means, that the Accelerate
framework's API in the SDK must match the Accelerate framework's binary in the
MacOS system. The API in the SDK could either be too old (if you upgraded your
system but didn't update your XCode/Command Line Tools yet) or too recent (if
you're on an older system but installed the latest XCode/Command Line Tools). In
both cases, you risk errors, so the build script checks and prevents this.

It's recommended to provide the `CMAKE_OSX_SYSROOT` via the `SDKROOT`
environment variable, which in turn can be provided by MacOS tooling (`xcrun`).
If you start `cmake` via `xcrun`, `xcrun` will provide the currently selected
SDK in the `SDKROOT` environment variable to `cmake` (`macosx` selects the
latest `macosx` SDK in the active developer directory):

```shell
$ xcrun --sdk macosx cmake ...
```

To check, which SDK this is, use:

```shell
$ xcrun --sdk macosx --show-sdk-path
```

If the build fails due to a mismatch between SDK and MacOS system, check your
available SDKs in the active developer directory with

```shell
$ xcodebuild -showsdks
```

and use a different SDK version `macosx<XX.X>`. If the SDK version you're
looking for can't be found in the active developer directory, change it using

```shell
$ xcode-select --switch <path>
```

This way, you can switch between `/Applications/Xcode.app/Contents/Developer`
and `/Library/Developer/CommandLineTools`, for example, or between different
XCode versions.

Alternatively, you can directly provide the `CMAKE_OSX_SYSROOT` cache variable
in your `CMakeUserPresets.json`. Both the `user-accelerate-lapack32` and
`user-accelerate-lapack64` presets should additionally have the cache variable
`"CMAKE_OSX_SYSROOT": "macosx"` or `"CMAKE_OSX_SYSROOT": "<path>"`.

[macos_sdk]: https://cmake.org/cmake/help/latest/variable/CMAKE_OSX_SYSROOT.html

### Workflow with CMake ###

Use the `accelerate-lapack32-install` preset (or the
`accelerate-lapack64-install` preset for the ILP64 interface) with CMake (prefix
all of the following commands with `xcrun`, see above):

```shell
$ cmake --workflow --preset accelerate-lapack32-install
```

This will configure and install Accelerate LAPACK in your `~/.local`
directory by default. If you prefer a different install location (e.&nbsp;g.
`/opt/custom`), you can change it using a `CMakeUserPresets.json` file, for
which a template file is provided:

```shell
$ cmake --workflow --preset user-accelerate-lapack32-install
```

I wouldn't recommend installing to `/usr/local` (used by Homebrew on Intel Macs)
or `/opt/local` (used by MacPorts).

If your install location is write protected, use the `accelerate-lapack32` and
`accelerate-lapack64` workflow presets to configure and build the project only
and then install with:

```shell
$ sudo cmake --build --preset user-accelerate-lapack32-install
```

and

```shell
$ sudo cmake --build --preset user-accelerate-lapack64-install
```

### Using Accelerate LAPACK in another CMake project ###

You can use Accelerate LAPACK in other CMake projects as a drop-in replacement
for `FindLAPACK` like this:

```cmake
if (CMAKE_HOST_SYSTEM_NAME MATCHES "Darwin" AND BLA_VENDOR STREQUAL "Apple")
    include(FetchContent)

    FetchContent_Declare(
        AccelerateLAPACK
        GIT_REPOSITORY "https://github.com/lepus2589/accelerate-lapack.git"
        GIT_TAG v2.0.0
        SYSTEM
        FIND_PACKAGE_ARGS 2.0.0 CONFIG NAMES AccelerateLAPACK
    )
    set(AccelerateLAPACK_INCLUDE_PACKAGING TRUE)
    FetchContent_MakeAvailable(AccelerateLAPACK)
else ()
    find_package(LAPACK MODULE)
endif ()
```

and optionally providing the above install location via the `CMAKE_PREFIX_PATH`
variable from the command line:

```shell
$ cmake -S . -B ./build -D "CMAKE_PREFIX_PATH=~/.local"
```

This makes the modified BLAS::BLAS and LAPACK::LAPACK targets available in the
other project's `CMakeLists.txt`.

#### Input variables ####

- `BLA_SIZEOF_INTEGER`: This is the same variable name that is used in the
  `FindBLAS` and `FindLAPACK` modules and selects the 32 bit or 64 bit
  interface, respectively.

#### Output variables and targets ####

- `BLAS::NEW_BLAS` target: This target links against the 32 bit interface of
  Accelerate's NewBLAS interface.
- `BLAS::NEW_BLAS64` target: This target links against the 64 bit interface of
  Accelerate's NewBLAS interface.
- `LAPACK::NEW_LAPACK` target: This target links against the 32 bit interface of
  Accelerate's NewLAPACK interface.
- `LAPACK::NEW_LAPACK64` target: This target links against the 64 bit interface of
  Accelerate's NewLAPACK interface.
- `BLAS::BLAS` target, interface depends on `BLA_SIZEOF_INTEGER`
- `LAPACK::LAPACK` target, interface depends on `BLA_SIZEOF_INTEGER`

- `ACCELERATE_LAPACK_ILAVER_VERSION`: Accelerate's LAPACK version
- `BLAS32_LIBRARIES`: link libraries for Accelerate's NewBLAS 32 bit interface
- `BLAS32_LINKER_FLAGS`: link flags for Accelerate's NewBLAS 32 bit interface
- `BLAS64_LIBRARIES`: link libraries for Accelerate's NewBLAS 64 bit interface
- `BLAS64_LINKER_FLAGS`: link flags for Accelerate's NewBLAS 64 bit interface
- `BLAS_LIBRARIES`: patched link libraries for Accelerate's NewBLAS interface
  depending on `BLA_SIZEOF_INTEGER`
- `BLAS_LINKER_FLAGS`: patched link flags for Accelerate's NewBLAS interface
  depending on `BLA_SIZEOF_INTEGER`
- `LAPACK32_LIBRARIES`: link libraries for Accelerate's NewLAPACK 32 bit
  interface
- `LAPACK32_LINKER_FLAGS`: link flags for Accelerate's NewLAPACK 32 bit
  interface
- `LAPACK64_LIBRARIES`: link libraries for Accelerate's NewLAPACK 64 bit
  interface
- `LAPACK64_LINKER_FLAGS`: link flags for Accelerate's NewLAPACK 64 bit
  interface
- `LAPACK_LIBRARIES`: patched link libraries for Accelerate's NewLAPACK
  interface depending on `BLA_SIZEOF_INTEGER`
- `LAPACK_LINKER_FLAGS`: patched link flags for Accelerate's NewLAPACK interface
  depending on `BLA_SIZEOF_INTEGER`
