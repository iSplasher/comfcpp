vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO jbcoe/value_types
    REF aadd31849b0673395806a209830d12bbd9a0b0b3
    SHA512 22c3f2d139df726b3d7cbfc99195e597133850d24b63decc06d70099424b5cc445a1010dcb5b10efa67affd554ea8eba0d154453d39267bd422a86b3e34aac0b
    HEAD_REF main
    )

set( headers_only ON )
if (headers_only)
    set( VCPKG_BUILD_TYPE release )
endif ()


vcpkg_replace_string( ${SOURCE_PATH}/CMakeLists.txt "add_subdirectory\(benchmarks\)" "" )
vcpkg_replace_string( ${SOURCE_PATH}/xyz_value_types-config.cmake.in "xyz_value_types-target\.cmake" "xyz_value_types-export-set.cmake" )

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
    -DBUILD_TESTING=OFF
    -DENABLE_CODE_COVERAGE=OFF
    -DENABLE_SANITIZERS=ON
    -DXYZ_VALUE_TYPES_IS_NOT_SUBPROJECT=ON
    )

vcpkg_cmake_install()

vcpkg_cmake_config_fixup( PACKAGE_NAME xyz_value_types CONFIG_PATH lib/cmake/xyz_value_types )

file( REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug" )
file( REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib" )

file( INSTALL "${SOURCE_PATH}/LICENSE.txt" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright )

