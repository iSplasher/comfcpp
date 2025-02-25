include_guard( GLOBAL )


set(COMF_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}/@LIB_NAME@/cmake" CACHE INTERNAL "Comf CMake directory" )

macro( configure_package_install library_name )

    cmake_parse_arguments( CONFIG "" "FIND_DEPS_CONTENT" "COMPONENTS;REQUIRED_COMPONENTS;EXPORT_TARGET_NAMES" ${ARGN} )

    include( GNUInstallDirs )
    include( CMakePackageConfigHelpers )

    set( LibraryName "${library_name}" )

    if (NOT CONFIG_EXPORT_TARGET_NAMES)
        message( FATAL_ERROR "At least one export target name is required" )
    endif()

    set( LibraryComponents ${CONFIG_COMPONENTS} )
    set( LibraryRequiredComponents ${CONFIG_REQUIRED_COMPONENTS} )

    set( LibraryInstallCmakeDir "${CMAKE_INSTALL_LIBDIR}/cmake/${LibraryName}" )
    set( LibraryInstallIncludeDir "${CMAKE_INSTALL_INCLUDEDIR}/" )

    set( CONFIG_IN_CONTENT [=[
include_guard( GLOBAL )

@PACKAGE_INIT@

# ==================================================
include(CMakeFindDependencyMacro)

if (EXISTS @COMF_CMAKE_DIR@)
    include( "@COMF_CMAKE_DIR@/tests.cmake" )
    include( "@COMF_CMAKE_DIR@/tools.cmake" )
    include( "@COMF_CMAKE_DIR@/utils.cmake" )
    include( "@COMF_CMAKE_DIR@/install-config.cmake" )
    include( "@COMF_CMAKE_DIR@/python.cmake" )
endif()

@FIND_DEPS_CONTENT@
# ==================================================

    ]=] )

    set( CONFIG_IN_CONTENT_COMP [=[
# Define components
set(@LibraryName@_REQUIRED_COMPONENTS @LibraryRequiredComponents@)
set(@LibraryName@_COMPONENTS @LibraryComponents@)

if (NOT DEFINED @LibraryName@_FIND_COMPONENTS OR @LibraryName@_FIND_COMPONENTS STREQUAL "")
    set(@LibraryName@_FIND_COMPONENTS @LibraryRequiredComponents@)
endif()

# Include requested components
foreach(component IN LISTS @LibraryName@_FIND_COMPONENTS)
    if (NOT ";${@LibraryName@_COMPONENTS};" MATCHES ";${component};")
        message( FATAL_ERROR "Unknown component: ${component}" )
    endif()

    include("${CMAKE_CURRENT_LIST_DIR}/@LibraryName@${component}-targets.cmake" OPTIONAL RESULT_VARIABLE _comp_found)

    if(NOT _comp_found)
        if(@LibraryName@_FIND_REQUIRED_${component} OR ";${@LibraryName@_REQUIRED_COMPONENTS};" MATCHES ";${component};")
            set(@LibraryName@_FOUND FALSE)
            set(@LibraryName@_NOT_FOUND_MESSAGE "Required component '${component}' not found")
            break()
        endif()
    else()
        set(@LibraryName@_${component}_FOUND ${_comp_found})
    endif()
endforeach()
    ]=] )

    set( CONFIG_IN_CONTENT_NO_COMP [=[
 include("${CMAKE_CURRENT_LIST_DIR}/@LibraryName@-targets.cmake")
 set(@LibraryName@_FOUND TRUE)
    ]=] )

    if (LibraryComponents)
        string( APPEND CONFIG_IN_CONTENT "${CONFIG_IN_CONTENT_COMP}" )
    else()
        string( APPEND CONFIG_IN_CONTENT "${CONFIG_IN_CONTENT_NO_COMP}" )
    endif()

    string( APPEND CONFIG_IN_CONTENT "\ncheck_required_components(@LibraryName@)\n" )


    foreach (target IN LISTS CONFIG_EXPORT_TARGET_NAMES)
        if (target STREQUAL LibraryName OR NOT LibraryComponents)
            set( _file_dest_name "${LibraryName}-targets.cmake" )
        else()
            set( _file_dest_name "${LibraryName}${target}-targets.cmake" )
        endif()

        if (LibraryComponents)
            install(
                EXPORT ${target}Targets
                COMPONENT ${target}
                CONFIGURATIONS ${CMAKE_CONFIGURATION_TYPES}
                NAMESPACE ${LibraryName}::
                FILE ${_file_dest_name}
                DESTINATION ${LibraryInstallCmakeDir}
                EXPORT_LINK_INTERFACE_LIBRARIES
                )
        else()
            install(
                EXPORT ${target}Targets
                CONFIGURATIONS ${CMAKE_CONFIGURATION_TYPES}
                NAMESPACE ${LibraryName}::
                FILE ${_file_dest_name}
                DESTINATION ${LibraryInstallCmakeDir}
                EXPORT_LINK_INTERFACE_LIBRARIES
                )
        endif()
    endforeach()

    set( PACKAGE_CONFIG_IN_FILE "${CMAKE_CURRENT_BINARY_DIR}/${LibraryName}Config.cmake.in" )
    file( WRITE "${PACKAGE_CONFIG_IN_FILE}" "${CONFIG_IN_CONTENT}" )

    set( PACKAGE_CONFIG_FILE "${CMAKE_CURRENT_BINARY_DIR}/${LibraryName}Config.cmake" )
    configure_package_config_file(
        "${PACKAGE_CONFIG_IN_FILE}"
        "${PACKAGE_CONFIG_FILE}"
        INSTALL_DESTINATION ${LibraryInstallCmakeDir}
        )


    set( PACKAGE_CONFIG_VERSION_FILE "${CMAKE_CURRENT_BINARY_DIR}/${LibraryName}ConfigVersion.cmake" )
    write_basic_package_version_file(
        "${PACKAGE_CONFIG_VERSION_FILE}"
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY AnyNewerVersion
        )

    install(
        FILES
        "${PACKAGE_CONFIG_FILE}"
        "${PACKAGE_CONFIG_VERSION_FILE}"
        DESTINATION ${LibraryInstallCmakeDir}
        )

endmacro(  )
