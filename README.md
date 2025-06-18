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
though it erroneously says, v3.12.0 will be supported with MacOS 16.

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
  - [Workflow with CMake](#workflow-with-cmake)
    - [CMake v4 compatibility](#cmake-v4-compatibility)
  - [Using Accelerate LAPACK in another project](#using-accelerate-lapack-in-another-project)

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

After the CMake configuration, the alias files can be found in `./build/<32|64>/src`:

```plaintext
./build/<32|64>/src
├── new-blas-ilp64.alias
├── new-blas.alias
├── new-lapack-ilp64.alias
└── new-lapack.alias
```

These files can be used to link any project against Accelerate!

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

### Workflow with CMake ###

Use the `accelerate-lapack32` preset (or the `accelerate-lapack64` preset for
the ILP64 interface) with CMake:

```shell
$ cmake --workflow --preset accelerate-lapack32
```

This will configure Accelerate LAPACK to be installed in your `~/.local`
directory by default. If you prefer a different install location (e.&nbsp;g.
`/opt/custom`), you can change it using a `CMakeUserPresets.json` file, for
which a template file is provided:

```shell
$ cmake --workflow --preset user-accelerate-lapack32
```

I wouldn't recommend installing to `/usr/local` (used by Homebrew on Intel Macs)
or `/opt/local` (used by MacPorts).

#### CMake v4 compatibility ####

To build the project with CMake v4 or higher, you must explicitly provide the
`CMAKE_OSX_SYSROOT` variable in your `CMakeUserPresets.json`. Both the
`user-accelerate-lapack32` and `user-accelerate-lapack64` presets should
additionally have the cache variable `"CMAKE_OSX_SYSROOT": "macosx"`. This is
not included by default.

### Using Accelerate LAPACK in another project ###

You can use Accelerate LAPACK in other projects like this:

```cmake
include(FetchContent)

FetchContent_Declare(
    AccelerateLAPACK
    GIT_REPOSITORY "https://github.com/lepus2589/accelerate-lapack.git"
    GIT_TAG v1.5.0
    SYSTEM
    FIND_PACKAGE_ARGS 1.5.0 CONFIG NAMES AccelerateLAPACK
)
set(AccelerateLAPACK_INCLUDE_PACKAGING TRUE)
FetchContent_MakeAvailable(AccelerateLAPACK)
```

and providing the above install location via the `CMAKE_PREFIX_PATH` variable
from the command line:

```shell
$ cmake -S . -B ./build -D "CMAKE_PREFIX_PATH=~/.local"
```

This makes the modified BLAS::BLAS and LAPACK::LAPACK targets available in the
other project's `CMakeLists.txt`.
