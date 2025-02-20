set( VCPKG_TARGET_ARCHITECTURE x64 )
set( VCPKG_CRT_LINKAGE dynamic )
set( VCPKG_LIBRARY_LINKAGE dynamic )

set( VCPKG_LOAD_VCVARS_ENV ON ) # Setting VCPKG_CHAINLOAD_TOOLCHAIN_FILE deactivates automatic vcvars setup so reenable it!

#if (DEFINED VCPKG_PLATFORM_TOOLSET) # Tricks vcpkg to load vcvars for a VCPKG_PLATFORM_TOOLSET which is not vc14[0-9]
#    set( VCPKG_PLATFORM_TOOLSET ClangCL )
#endif ()

message( STATUS "COMPILER: ${CMAKE_CXX_COMPILER}" )

set( VCPKG_ENV_PASSTHROUGH_UNTRACKED "LLVMInstallDir;LLVMToolsVersion" ) # For the ClangCL toolset


include( "${CMAKE_CURRENT_LIST_DIR}/../toolchains/clang.cmake" )

set(CMAKE_CXX_COMPILER_ID "Clang")
set(CMAKE_C_COMPILER_ID "Clang")

include( "${CMAKE_CURRENT_LIST_DIR}/../port-specializations.cmake" )
