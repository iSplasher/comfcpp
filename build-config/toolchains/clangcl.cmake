include_guard( DIRECTORY )

include( FetchContent )


if (EXISTS "$ENV{GITHUB_TRIPLETS_DIR}")
    set( _vcpkg_triplets_SOURCE_DIR "$ENV{GITHUB_TRIPLETS_DIR}" )
else ()
    fetchcontent_declare( _vcpkg_triplets
        GIT_REPOSITORY https://github.com/Neumann-A/my-vcpkg-triplets
        GIT_TAG master
        SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/github_vcpkg_triplets"
        )


    fetchcontent_makeavailable( _vcpkg_triplets )
    set( ENV{GITHUB_TRIPLETS_DIR} "${_vcpkg_triplets_SOURCE_DIR}" )
endif ()

message( STATUS "Looking for possible LLVM installation" )
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
    message( "...found at ${LLVMInstallDir}" )
else ()
    message( "...LLVM not found" )
endif ()

function( gnu_to_clangcl INPUT_FLAGS OUTPUT_VAR )
    # Start with the input string
    set( _result "${INPUT_FLAGS}" )

    macro( map_flag input_flags out )
        set( new_flags "" )
        foreach (flag IN LISTS ${input_flags})
            # Map every prefix every gnu flag with /clang
            if (flag MATCHES "^-")
                list( APPEND new_flags "/clang:${flag}" )
            else ()
                list( APPEND new_flags "${flag}" )
            endif ()
        endforeach ()

        set( ${out} "${new_flags}" )
    endmacro()

    # split on whitespace
    string( REGEX MATCHALL "[^ ]+" _flags "${_result}" )
    map_flag( _flags _mapped_flags )

    # Join the mapped flags back together
    string( REPLACE ";" " " _result "${_mapped_flags}" )

    # Remove any extra whitespace from the result
    string( STRIP "${_result}" _result )
    set( ${OUTPUT_VAR} "${_result}" PARENT_SCOPE )
endfunction()

set( _triplet "" )

function( get_vcpkg_triplet_variables )
    include( "${CMAKE_CURRENT_LIST_DIR}/../triplets/${VCPKG_TARGET_TRIPLET}.cmake" )
    # Be carefull here you don't want to pull in all variables from the triplet!
    # Port is not defined!
    set( VCPKG_CRT_LINKAGE "${VCPKG_CRT_LINKAGE}" PARENT_SCOPE ) # This is also forwarded by vcpkg itself
    set( VCPKG_TARGET_ARCHITECTURE "${VCPKG_TARGET_ARCHITECTURE}" PARENT_SCOPE )
endfunction()

get_vcpkg_triplet_variables()

if (VCPKG_TARGET_ARCHITECTURE STREQUAL x64)
    set( _triplet "x64-win-llvm" )
elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL x86)
    set( _triplet "x86-win-llvm" )
endif ()


set( _triplet "${_triplet}-lto" )

# if dynamic
if (VCPKG_LIBRARY_LINKAGE MATCHES "static")
    set( _triplet "${_triplet}-static" )
endif ()

if (VCPKG_CRT_LINKAGE MATCHES "dynamic" AND VCPKG_LIBRARY_LINKAGE MATCHES "static")
    set( _triplet "${_triplet}-md" )
endif ()

if (VCPKG_BUILD_TYPE MATCHES "release" OR CMAKE_BUILD_TYPE MATCHES "Release")
    set( _triplet "${_triplet}-rel" )
endif ()

# copy all files matching the triplet
file( GLOB _triplet_files_1 "${_vcpkg_triplets_SOURCE_DIR}/x64-win-llvm/x64-win-llvm*.cmake" )
file( GLOB _triplet_files_2 "${_vcpkg_triplets_SOURCE_DIR}/x64-win-llvm*.cmake" )
foreach (_file IN LISTS _triplet_files_1 _triplet_files_2)
    # get directory of the file
    get_filename_component( _dir "${_file}" DIRECTORY )
    # get the file name without the directory
    get_filename_component( _file_name "${_file}" NAME )
    # replace file name with the current triplet
    string( REPLACE "x64-win-llvm" "${VCPKG_TARGET_TRIPLET}" _file_name_out "${_file_name}" )
    if (NOT EXISTS "${_dir}/${_file_name_out}")
        file( COPY_FILE "${_file}" "${_dir}/${_file_name_out}" )
    endif ()
endforeach ()

message( STATUS "Using 3rdparty triplet: ${_triplet}" )
include( "${_vcpkg_triplets_SOURCE_DIR}/${_triplet}.cmake" )

if (NOT INSIDE_TRIPLET)
    include( "${_vcpkg_triplets_SOURCE_DIR}/x64-win-llvm/${VCPKG_TARGET_TRIPLET}.toolchain.cmake" )
endif ()

unset( _triplet )


list( APPEND _transform_vars
    VCPKG_CRT_LINK_FLAG_PREFIX
    VCPKG_SET_CHARSET_FLAG
    VCPKG_C_FLAGS VCPKG_CXX_FLAGS
    VCPKG_C_FLAGS_DEBUG VCPKG_CXX_FLAGS_DEBUG
    VCPKG_C_FLAGS_RELEASE VCPKG_CXX_FLAGS_RELEASE
    VCPKG_LINKER_FLAGS VCPKG_LINKER_FLAGS_RELEASE VCPKG_LINKER_FLAGS_DEBUG
    CMAKE_C_FLAGS_DEBUG CMAKE_CXX_FLAGS_DEBUG
    CMAKE_C_FLAGS_RELEASE CMAKE_CXX_FLAGS_RELEASE
    CMAKE_C_FLAGS CMAKE_CXX_FLAGS
    CMAKE_C_FLAGS_INIT CMAKE_CXX_FLAGS_INIT
    CMAKE_C_FLAGS_DEBUG_INIT CMAKE_CXX_FLAGS_DEBUG_INIT
    CMAKE_C_FLAGS_RELEASE_INIT CMAKE_CXX_FLAGS_RELEASE_INIT
    CMAKE_C_FLAGS_MINSIZEREL_INIT CMAKE_CXX_FLAGS_MINSIZEREL_INIT
    CMAKE_C_FLAGS_RELWITHDEBINFO_INIT CMAKE_CXX_FLAGS_RELWITHDEBINFO_INIT
    CMAKE_EXE_LINKER_FLAGS CMAKE_EXE_LINKER_FLAGS_DEBUG CMAKE_EXE_LINKER_FLAGS_RELEASE
    CMAKE_EXE_LINKER_FLAGS_MINSIZEREL CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO
    CMAKE_SHARED_LINKER_FLAGS CMAKE_SHARED_LINKER_FLAGS_DEBUG CMAKE_SHARED_LINKER_FLAGS_RELEASE
    CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO
    CMAKE_MODULE_LINKER_FLAGS CMAKE_MODULE_LINKER_FLAGS_DEBUG CMAKE_MODULE_LINKER_FLAGS_RELEASE
    CMAKE_MODULE_LINKER_FLAGS_MINSIZEREL CMAKE_MODULE_LINKER_FLAGS_RELWITHDEBINFO
    )

foreach (var IN LISTS _transform_vars)
    if (NOT DEFINED ${var} OR ${var} STREQUAL "")
        continue()
    endif ()
    gnu_to_clangcl( "${${var}}" "${var}" )
    message( STATUS "Transformed gnu-style flags to clang-cl ${var}: ${${var}}" )
endforeach ()


if (LLVMInstallDir)
    message( "...compiler found (C++): ${CMAKE_CXX_COMPILER}" )
    message( "...compiler found (C): ${CMAKE_C_COMPILER}" )
endif ()
