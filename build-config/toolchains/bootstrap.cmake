# https://github.com/microsoft/vcpkg/discussions/38030

include( "${CMAKE_CURRENT_LIST_DIR}/clang.cmake" )
include( "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" )

set(CMAKE_CXX_COMPILER_ID "Clang")
set(CMAKE_C_COMPILER_ID "Clang")
