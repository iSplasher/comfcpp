set( TARGET_NAME comf )

add_library( ${TARGET_NAME} STATIC "" )

#target_include_directories( ${TARGET_NAME} BEFORE PUBLIC
#    $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/detail>
#    $<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${CMAKE_INSTALL_INCLUDEDIR}/detail>
#    )
#target_include_directories( ${TARGET_NAME} PUBLIC
#    $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/include>
#    $<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${CMAKE_INSTALL_INCLUDEDIR}/${TARGET_NAME}>
#    )

file(GLOB_RECURSE PUBLIC_HEADERS CONFIGURE_DEPENDS include/*)
file(GLOB_RECURSE PRIVATE_HEADERS CONFIGURE_DEPENDS detail/*)


file( GLOB_RECURSE SOURCES CONFIGURE_DEPENDS src/*.cpp )
file( GLOB_RECURSE PRIVATE_SOURCES CONFIGURE_DEPENDS detail/*.cpp )

target_sources( ${TARGET_NAME}
    PRIVATE
    ${SOURCES}
    ${PRIVATE_SOURCES}
    PUBLIC
    FILE_SET ${TARGET_NAME}_HEADERS
    TYPE HEADERS
    BASE_DIRS ${CMAKE_CURRENT_LIST_DIR}/detail
    FILES ${PRIVATE_HEADERS}
    PUBLIC
    FILE_SET ${TARGET_NAME}_PUBLIC_HEADERS
    TYPE HEADERS
    BASE_DIRS ${CMAKE_CURRENT_LIST_DIR}/include
    FILES ${PUBLIC_HEADERS}
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
    EXPORT ${TARGET_NAME}Targets
    FILE_SET ${TARGET_NAME}_PUBLIC_HEADERS DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILE_SET ${TARGET_NAME}_HEADERS DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )

