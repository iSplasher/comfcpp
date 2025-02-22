include_guard( DIRECTORY )
# https://github.com/microsoft/vcpkg/discussions/38030


function( get_vcpkg_triplet_variables )
    include( "${CMAKE_CURRENT_LIST_DIR}/../triplets/${VCPKG_TARGET_TRIPLET}.cmake" )
    # Be carefull here you don't want to pull in all variables from the triplet!
    # Port is not defined!
    set( VCPKG_CRT_LINKAGE "${VCPKG_CRT_LINKAGE}" PARENT_SCOPE ) # This is also forwarded by vcpkg itself
endfunction()

if (NOT INSIDE_TRIPLET)
    set( ENV{VCPKG_KEEP_ENV_VARS} "VCPKG_ROOT;GITHUB_TRIPLETS_DIR;LLVMInstallDir;LLVMToolsVersion;$ENV{VCPKG_KEEP_ENV_VARS}" )

    get_vcpkg_triplet_variables()
    set( VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/clangcl.cmake" )
    include( "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" )
else ()
    set( VCPKG_ROOT "$ENV{VCPKG_ROOT}" )
    string( APPEND VCPKG_ENV_PASSTHROUGH_UNTRACKED "VCPKG_ROOT" )
    set( VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/bootstrap.cmake" )
endif ()



