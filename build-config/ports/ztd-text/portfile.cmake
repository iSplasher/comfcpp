vcpkg_from_github(
    OUT_SOURCE_PATH ZTD_CMAKE_SOURCE_PATH
    REPO soasis/cmake
    REF be654188476033a960d345f61e38874f9ebf9953
    SHA512 0c66ad3d19acb8d1217b98413f24bd3675450a36922c38c9689f09a336a5921df027e681f31e85f0780f3d8a6c8e8052fa5b1ccf17c20a955693b94837a2f619
    )

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO soasis/text
    REF c06e3bf990911e09652b784ed01bc68f8f1c1105
    SHA512 957776afb6a8a943d6480abda69e53b818e95997053d0126ebfbf61c38eb49805972ba20dd1394e6f94de6416766bcd5a9113e958545d8923ed942249fc8ffeb
    HEAD_REF main
    PATCHES
    fix-cmake-install.patch
    )

set( VCPKG_BUILD_TYPE release ) # header-only
vcpkg_check_linkage( ONLY_STATIC_LIBRARY )


vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
    # See https://github.com/soasis/cmake/blob/c29df2f0b006f8b24214ccea0a7e2f8fbbe135ce/CMakeLists.txt#L43
    "-DZTD_CMAKE_PACKAGES=${ZTD_CMAKE_SOURCE_PATH}/Packages"
    "-DZTD_CMAKE_MODULES=${ZTD_CMAKE_SOURCE_PATH}/Modules"
    "-DZTD_CMAKE_PROJECT_PRELUDE=${ZTD_CMAKE_SOURCE_PATH}/Includes/Project.cmake"
    )

vcpkg_cmake_install()

vcpkg_install_copyright( FILE_LIST "${SOURCE_PATH}/LICENSE" )
