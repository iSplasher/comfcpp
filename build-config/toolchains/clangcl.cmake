# from https://github.com/microsoft/vcpkg/pull/31028

if (NOT _VCPKG_CLANGCL_TOOLCHAIN)
    set( _VCPKG_CLANGCL_TOOLCHAIN 1 )

    if (DEFINED ENV{LLVMInstallDir})
        cmake_path( SET _vcpkg_llvmbin "$ENV{LLVMInstallDir}/bin" NORMALIZE )
        string( REPLACE "\"" "" _vcpkg_llvmbin "${_vcpkg_llvmbin}" )
        find_program( CMAKE_C_COMPILER "clang-cl.exe" PATHS "${_vcpkg_llvmbin}" REQUIRED NO_DEFAULT_PATH )
        find_program( CMAKE_CXX_COMPILER "clang-cl.exe" PATHS "${_vcpkg_llvmbin}" REQUIRED NO_DEFAULT_PATH )
        find_program( CMAKE_AR "llvm-lib.exe" PATHS "${_vcpkg_llvmbin}" REQUIRED NO_DEFAULT_PATH )
    else ()
        set( CMAKE_C_COMPILER "clang-cl.exe" )
        set( CMAKE_CXX_COMPILER "clang-cl.exe" )
    endif ()

    if (VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
        set( _vcpkg_clangcl_arch "-m32" )
    elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
        set( _vcpkg_clangcl_arch "-m64" )
    elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "arm")
        set( _vcpkg_clangcl_arch "--target=arm-pc-windows-msvc" )
    elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        set( _vcpkg_clangcl_arch "--target=arm64-pc-windows-msvc" )
    endif ()

    string( APPEND VCPKG_C_FLAGS " ${_vcpkg_clangcl_arch} -Wno-error " )
    string( APPEND VCPKG_CXX_FLAGS " ${_vcpkg_clangcl_arch} -Wno-error " )

    set( VCPKG_MSVC_CXX_WINRT_EXTENSIONS OFF )

    list( APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES ${_vcpkg_clangcl_arch} VCPKG_MSVC_CXX_WINRT_EXTENSIONS )

    if ((VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore") OR (CMAKE_SYSTEM_NAME STREQUAL "WindowsStore"))
        include( "$ENV{VCPKG_ROOT}/scripts/toolchains//uwp.cmake" )
    elseif (DEFINED XBOX_CONSOLE_TARGET)
        include( "$ENV{VCPKG_ROOT}/scripts/toolchains//xbox.cmake" )
    else ()
        include( "$ENV{VCPKG_ROOT}/scripts/toolchains/windows.cmake" )
    endif ()

    string( APPEND CMAKE_C_FLAGS_INIT "${VCPKG_C_FLAGS} " )
    string( APPEND CMAKE_CXX_FLAGS_INIT " ${VCPKG_CXX_FLAGS} " )
    string( APPEND CMAKE_C_FLAGS_DEBUG_INIT " ${VCPKG_C_FLAGS_DEBUG} " )
    string( APPEND CMAKE_CXX_FLAGS_DEBUG_INIT " ${VCPKG_CXX_FLAGS_DEBUG} " )
    string( APPEND CMAKE_C_FLAGS_RELEASE_INIT " ${VCPKG_C_FLAGS_RELEASE} " )
    string( APPEND CMAKE_CXX_FLAGS_RELEASE_INIT " ${VCPKG_CXX_FLAGS_RELEASE} " )
endif ()
