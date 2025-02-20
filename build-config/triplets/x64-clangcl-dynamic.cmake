# from https://github.com/microsoft/vcpkg/pull/31028

set( VCPKG_TARGET_ARCHITECTURE x64 )
set( VCPKG_CRT_LINKAGE dynamic )
set( VCPKG_LIBRARY_LINKAGE dynamic )

if (NOT PORT MATCHES "python3")
    set( VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/../toolchains/clang.cmake" )
    set( VCPKG_LOAD_VCVARS_ENV ON )
    if (DEFINED VCPKG_PLATFORM_TOOLSET)
        set( VCPKG_PLATFORM_TOOLSET ClangCL )
    endif ()
    set( VCPKG_QT_TARGET_MKSPEC win32-clang-msvc )
endif ()

set( VCPKG_ENV_PASSTHROUGH_UNTRACKED "VCPKG_ROOT;LLVMInstallDir;LLVMToolsVersion" )

include( "${CMAKE_CURRENT_LIST_DIR}/../port-specializations.cmake" )
