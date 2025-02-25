set( SRC_PATH "X:/dev/comfstudio/comfcpp" )

set( headers_only OFF )

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL "${SRC_PATH}"
    REF "8f5558b39da751c86890a6a85f691e3d6c49a573"
    )

#vcpkg_replace_string( ${SOURCE_PATH}/ <match> <replace> [REGEX] [IGNORE_UNCHANGED])
file( REMOVE "${SOURCE_PATH}/vcpkg.json" "${SOURCE_PATH}/CMakePresets.json" )

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
    -DBUILD_TESTING=OFF
    )

vcpkg_cmake_install()
vcpkg_cmake_config_fixup( CONFIG_PATH lib/cmake/${PORT} )

vcpkg_copy_pdbs()

vcpkg_install_copyright( FILE_LIST "${SOURCE_PATH}/LICENSE" )

if (headers_only)
    file( REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib" "${CURRENT_PACKAGES_DIR}/debug/lib" )
endif ()

file( REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include" "${CURRENT_PACKAGES_DIR}/debug/share" )

