# Inspo:
# https://github.com/Neumann-A/my-vcpkg-triplets/blob/master/x64-win-llvm/x64-win-llvm.toolchain.cmake
#  https://github.com/microsoft/vcpkg/pull/31028


message( CHECK_START "Looking for possible LLVM installation" )
if (DEFINED ENV{LLVMInstallDir})
    file( TO_CMAKE_PATH "$ENV{LLVMInstallDir}/bin" POSSIBLE_LLVM_BIN_DIR )
else ()

    if (WIN32)
        # Get Program Files root to lookup possible LLVM installation
        if (DEFINED ENV{ProgramW6432})
            file( TO_CMAKE_PATH "$ENV{ProgramW6432}" PROG_ROOT )
        else ()
            file( TO_CMAKE_PATH "$ENV{PROGRAMFILES}" PROG_ROOT )
        endif ()
        file( TO_CMAKE_PATH "${PROG_ROOT}/LLVM/bin" POSSIBLE_LLVM_BIN_DIR )
    else ()
        file( TO_CMAKE_PATH "" POSSIBLE_LLVM_BIN_DIR )
    endif ()

endif ()

if (EXISTS "${POSSIBLE_LLVM_BIN_DIR}" AND NOT POSSIBLE_LLVM_BIN_DIR STREQUAL "")
    set( LLVMInstallDir "${POSSIBLE_LLVM_BIN_DIR}/../" )
    cmake_path( SET LLVMInstallDir "${LLVMInstallDir}" NORMALIZE )

    set( ENV{LLVMInstallDir} "${LLVMInstallDir}" )
    message( CHECK_PASS "Found at ${LLVMInstallDir}" )

    cmake_path( SET llvmbin "$ENV{LLVMInstallDir}/bin" NORMALIZE )
    string( REPLACE "\"" "" llvmbin "${llvmbin}" )
    find_program( CMAKE_C_COMPILER "clang.exe" PATHS "${llvmbin}" REQUIRED NO_DEFAULT_PATH )
    find_program( CMAKE_CXX_COMPILER "clang++.exe" PATHS "${llvmbin}" REQUIRED NO_DEFAULT_PATH )
    find_program( CMAKE_AR "llvm-ar.exe" PATHS "${llvmbin}" REQUIRED NO_DEFAULT_PATH )

    cmake_path( ABSOLUTE_PATH CMAKE_CXX_COMPILER NORMALIZE )
    cmake_path( ABSOLUTE_PATH CMAKE_C_COMPILER NORMALIZE )
    cmake_path( ABSOLUTE_PATH CMAKE_AR NORMALIZE )

    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libstdc++")
else ()
    message( CHECK_FAIL "Not found" )
endif ()

