set( TARGET_NAME comf )

add_library( ${TARGET_NAME} STATIC "" )

target_include_directories( ${TARGET_NAME} BEFORE PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/detail>
    $<INSTALL_INTERFACE:include/${TARGET_NAME}/detail>
    )
target_include_directories( ${TARGET_NAME} PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include/${TARGET_NAME}>
    )

file( GLOB_RECURSE SOURCES CONFIGURE_DEPENDS src/*.cpp )
file( GLOB_RECURSE PRIVATE_SOURCES CONFIGURE_DEPENDS detail/*.cpp )
target_sources( ${TARGET_NAME}
    PRIVATE
    ${SOURCES}
    ${PRIVATE_SOURCES}
    )

add_cppfront_target( ${TARGET_NAME} SOURCES detail include src )

find_package( spdlog CONFIG REQUIRED )
target_link_libraries( ${TARGET_NAME} PRIVATE spdlog::spdlog )

find_package( fmt CONFIG REQUIRED )
target_link_libraries( ${TARGET_NAME} PUBLIC fmt::fmt )


find_package( ztd.text CONFIG REQUIRED )
find_package( ztd.cuneicode CONFIG REQUIRED )
target_link_libraries( ${TARGET_NAME} PRIVATE ztd::text ztd::cuneicode )

find_package( function2 CONFIG REQUIRED )
target_link_libraries( ${TARGET_NAME} PRIVATE function2::function2 )

find_package( Hana CONFIG REQUIRED )
target_link_libraries( ${TARGET_NAME} PRIVATE hana )

find_package( xyz_value_types CONFIG REQUIRED )
target_link_libraries( ${TARGET_NAME} PRIVATE xyz_value_types::xyz_value_types )

add_test_target( TARGETS ${TARGET_NAME} )

#------------------------------------------------------------
set( LIB_NAME "${TARGET_NAME}" )
include( GNUInstallDirs )

install( TARGETS "${TARGET_NAME}"
    EXPORT comfTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${LIB_NAME}
    )
