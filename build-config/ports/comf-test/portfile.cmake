set(SRC_PATH "X:/dev/comfstudio/comfcpp")

set( headers_only OFF )

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL "${SRC_PATH}"
    REF "a4ac8d3475c502c56435b53b9147acc7ebd62cdb"
    )

#vcpkg_replace_string( ${SOURCE_PATH}/ <match> <replace> [REGEX] [IGNORE_UNCHANGED])

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
    )

vcpkg_cmake_install()
vcpkg_cmake_config_fixup()
vcpkg_fixup_pkgconfig()

vcpkg_copy_pdbs()


if (headers_only)
    file( REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib" "${CURRENT_PACKAGES_DIR}/debug/lib" )
endif ()

file( REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share"
    "${CURRENT_PACKAGES_DIR}/debug/include"
    )
