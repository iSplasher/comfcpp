cmake_minimum_required( VERSION 3.30 )


find_program( CCACHE_FOUND ccache )
if (CCACHE_FOUND)
    set_property( GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache )
endif ()

include( CMakePrintHelpers )
include( CMakeParseArguments )

message( STATUS "Using triplet: ${VCPKG_TARGET_TRIPLET}" )
message( STATUS "Using build type: ${VCPKG_BUILD_TYPE}" )


set( CMAKE_CXX_STANDARD 23 )
set( CMAKE_CXX_STANDARD_REQUIRED ON )
set( CMAKE_CXX_EXTENSIONS OFF )

option( ENABLE_MODULES "Enable modules" OFF )

if (ENABLE_MODULES)
    # Tell CMake that we explicitly want `import std`. This will initialize the
    # property on all targets declared after this to 1
    set( CMAKE_CXX_MODULE_STD ON )

    # Set experimental flag to enable `import std` support from CMake.
    # This must be enabled before C++ language support.
    set( CMAKE_EXPERIMENTAL_CXX_IMPORT_STD
        # This specific value changes as experimental support evolves. See
        # `Help/dev/experimental.rst` in the CMake source corresponding to
        # your CMake build for the exact value to use.
        "0e5b6991-d74f-4b3d-a41c-cf096e0b2508" )
endif ()

set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${ADD_CMAKE_C_FLAGS}" )
set( CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} ${ADD_CMAKE_C_FLAGS_RELEASE}" )
set( CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${ADD_CMAKE_C_FLAGS_DEBUG}" )
set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ADD_CMAKE_CXX_FLAGS}" )
set( CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${ADD_CMAKE_CXX_FLAGS_DEBUG}" )
set( CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${ADD_CMAKE_CXX_FLAGS_RELEASE}" )

set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${ADD_PLAT_CMAKE_C_FLAGS}" )
set( CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} ${ADD_PLAT_CMAKE_C_FLAGS_RELEASE}" )
set( CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${ADD_PLAT_CMAKE_C_FLAGS_DEBUG}" )
set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ADD_PLAT_CMAKE_CXX_FLAGS}" )
set( CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${ADD_PLAT_CMAKE_CXX_FLAGS_DEBUG}" )
set( CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${ADD_PLAT_CMAKE_CXX_FLAGS_RELEASE}" )


include( ${CMAKE_CURRENT_SOURCE_DIR}/build-config/cmake/tools.cmake )


# -------------------------------------------------------

project( comf VERSION 1.0 LANGUAGES C CXX )

option( BUILD_TESTING "Enable testing" ON )


if (VCPKG_TARGET_TRIPLET MATCHES "clang" AND NOT CMAKE_CXX_COMPILER MATCHES "clang")
    if ($ENV{LLVMInstallDir})
        set( CMAKE_CXX_COMPILER $ENV{LLVMInstallDir}/bin/clang++ )
        set( CMAKE_C_COMPILER $ENV{LLVMInstallDir}/bin/clang )
    elseif (LLVMInstallDir)
        set( CMAKE_CXX_COMPILER ${LLVMInstallDir}/bin/clang++ )
        set( CMAKE_C_COMPILER ${LLVMInstallDir}/bin/clang )
    endif ()
endif ()

# Suppress generation of ZERO_CHECK project
set( CMAKE_SUPPRESS_REGENERATION ON )
# Suppress generation of additional targets
set_property( GLOBAL PROPERTY CTEST_TARGETS_ADDED 1 )

cmake_print_variables( CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES )

cmake_print_variables( LINUX )
cmake_print_variables( WINDOWS )
cmake_print_variables( MACOS )

cmake_print_variables( CMAKE_CXX_COMPILER )
cmake_print_variables( CMAKE_C_COMPILER )
cmake_print_variables( CMAKE_CXX_COMPILER_ID )
cmake_print_variables( CMAKE_C_COMPILER_ID )
cmake_print_variables( CMAKE_CXX_COMPILER_FLAGS )
cmake_print_variables( CMAKE_CXX_COMPILER_FLAGS_DEBUG )
cmake_print_variables( CMAKE_CXX_COMPILER_FLAGS_RELEASE )
cmake_print_variables( CMAKE_C_COMPILER_FLAGS )
cmake_print_variables( CMAKE_C_COMPILER_FLAGS_DEBUG )
cmake_print_variables( CMAKE_C_COMPILER_FLAGS_RELEASE )

# -------------------------------------------------------

set( LIBS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libs )

set( DEBUG OFF )
if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    set( DEBUG ON )
    add_compile_definitions( DEBUG )
endif ()

# -------------------------------------------------------

if (LINUX)
    add_compile_definitions( APP_LINUX )
endif ()

if (WINDOWS)
    add_compile_definitions( APP_WINDOWS )
endif ()

if (MACOS)
    add_compile_definitions( APP_MACOS )
endif ()


if (DEBUG)
    set( CMAKE_EXECUTABLE_ENABLE_EXPORTS ON )
endif ()

# -------------------------------------------------------

add_compile_definitions(
    # This macro is used to enable -Wthread-safety annotations on libc++’s std::mutex and std::lock_guard.
    # By default, these annotations are disabled and must be manually enabled by the user
    _LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS
    )

# if compiler is clang
if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "ClangCL")
    add_compile_options(
        -Wthread-safety # Enable -Wthread-safety annotations on libc++’s std::mutex and std::lock_guard
        -Werror=return-type # Treat return type mismatch as errors
        -frelaxed-template-template-args # https://github.com/llvm/llvm-project/issues/42224
        )
endif ()

if (ENABLE_MODULES)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "ClangCL")

        add_compile_options(
            -fmodules-ts
            )
    endif ()
endif ()

if (WINDOWS)
    cmake_print_variables( MSVC )
    cmake_print_variables( MSVC_VERSION )
    # /Zc:__cplusplus is required to make __cplusplus accurate
    # /Zc:__cplusplus is available starting with Visual Studio 2017 version 15.7
    # (according to https://docs.microsoft.com/en-us/cpp/build/reference/zc-cplusplus)
    # That version is equivalent to _MSC_VER==1914
    # (according to https://docs.microsoft.com/en-us/cpp/preprocessor/predefined-macros?view=vs-2019)
    # CMake's ${MSVC_VERSION} is equivalent to _MSC_VER
    # (according to https://cmake.org/cmake/help/latest/variable/MSVC_VERSION.html#variable:MSVC_VERSION)
    if ((MSVC) AND (MSVC_VERSION GREATER_EQUAL 1914))
        add_compile_options(
            "/Zc:__cplusplus"
            "/permissive-"
            )
    endif ()

    if (MSVC)
        add_compile_options(
            #  utf-8 src files
            /source-charset:utf-8
            )
    endif ()
endif ()

# -------------------------------------------------------

if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    add_compile_options(
        -fdiagnostics-show-category=name # Show the category name for each diagnostic
        -fcolor-diagnostics # Use colors in diagnostics
        )
endif ()

# -------------------------------------------------------

macro( print_all_variables )
    message( STATUS "------------------------------------------ all_variables ------------------------------------------ {" )
    get_cmake_property( _variableNames VARIABLES )
    foreach (_variableName ${_variableNames})
        cmake_print_variables( ${_variableName} )
        message( STATUS "${_variableName}=${${_variableName}}" )
    endforeach ()
    message( STATUS "} ------------------------------------------ all_variables ------------------------------------------" )
endmacro()


function( print_all_variables_debug )
    if (CMAKE_BUILD_TYPE STREQUAL "Debug")
        print_all_variables()
    endif ()
endfunction()

macro( disable_target )
    set( _TARGET_NAME ${ARGV0} )
    message( STATUS "Disabling target: ${_TARGET_NAME}" )
    get_target_property( ${_TARGET_NAME}_EXISTING_LABELS ${_TARGET_NAME} LABELS )
    set_target_properties( ${_TARGET_NAME}
        PROPERTIES
        EXCLUDE_FROM_ALL TRUE
        EXCLUDE_FROM_DEFAULT_BUILD TRUE
        LABELS "${_TARGET_NAME}_EXISTING_LABELS;DISABLED"
        )
endmacro()

include( ${CMAKE_CURRENT_LIST_DIR}/build-config/cmake/tests.cmake )
setup_tests( TARGET tests )

# -------------------------------------------------------

add_subdirectory( src/comf )

# -------------------------------------------------------
include( ${CMAKE_CURRENT_SOURCE_DIR}/build-config/cmake/install-config.cmake )

set(COMF_CMAKE_DIR "$\{CMAKE_CURRENT_LIST_DIR\}/util")
configure_package_install( comf
    EXPORT_TARGET_NAMES
        comf
    )

install( DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/build-config/cmake/ DESTINATION "${LibraryInstallCmakeDir}/util" )

