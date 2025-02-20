# from https://github.com/microsoft/vcpkg/pull/31028

set( VCPKG_TARGET_ARCHITECTURE x64 )
set( VCPKG_CRT_LINKAGE dynamic )
set( VCPKG_LIBRARY_LINKAGE dynamic )

set( VCPKG_CMAKE_SYSTEM_NAME WindowsStore )
set( VCPKG_CMAKE_SYSTEM_VERSION 10.0 )

set( VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/../../scripts/toolchains/clangcl.cmake" )
set( VCPKG_LOAD_VCVARS_ENV ON )
if (DEFINED VCPKG_PLATFORM_TOOLSET)
    set( VCPKG_PLATFORM_TOOLSET ClangCL )
endif ()
set( VCPKG_ENV_PASSTHROUGH_UNTRACKED "LLVMInstallDir;LLVMToolsVersion" )
