include_guard( GLOBAL )


set(COMF_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}/@LIB_NAME@/cmake" CACHE INTERNAL "Comf CMake directory" )

macro( configure_package_install library_name )

    cmake_parse_arguments( CONFIG "" "" "COMPONENTS;REQUIRED_COMPONENTS;EXPORT_TARGET_NAMES;FIND_DEPS;FIND_DEPS_OPTIONAL" ${ARGN} )

    include( GNUInstallDirs )
    include( CMakePackageConfigHelpers )

    set( LibraryName "${library_name}" )

    if (NOT CONFIG_EXPORT_TARGET_NAMES)
        message( FATAL_ERROR "At least one export target name is required" )
    endif()

    set( LibraryComponents ${CONFIG_COMPONENTS} )
    set( LibraryRequiredComponents ${CONFIG_REQUIRED_COMPONENTS} )

    set( LibraryInstallCmakeDir "${CMAKE_INSTALL_LIBDIR}/cmake/${LibraryName}" )
    set( LibraryInstallIncludeDir "${CMAKE_INSTALL_INCLUDEDIR}" )


    set( FIND_DEPS_CONTENT "" )
    if (CONFIG_FIND_DEPS)
        foreach( dep IN LISTS CONFIG_FIND_DEPS )
            string( APPEND FIND_DEPS_CONTENT "find_dependency( ${dep} REQUIRED )\n" )
        endforeach()
    endif()

    if (CONFIG_FIND_DEPS_OPTIONAL)
        foreach( dep IN LISTS CONFIG_FIND_DEPS_OPTIONAL )
            string( APPEND FIND_DEPS_CONTENT "find_dependency( ${dep} )\n" )
        endforeach()
    endif()

    get_target_property( _target_find_deps ${LibraryName} FIND_DEPS )
        foreach (dep IN LISTS _target_find_deps)
        if (dep AND NOT dep MATCHES "NOTFOUND")
                string( APPEND FIND_DEPS_CONTENT "find_dependency( ${dep} REQUIRED )\n" )
        endif()
        endforeach()
    get_target_property( _target_find_deps_optional ${LibraryName} FIND_DEPS_OPTIONAL )
        foreach (dep IN LISTS _target_find_deps_optional)
    if (dep AND NOT dep MATCHES "NOTFOUND")
            string( APPEND FIND_DEPS_CONTENT "find_dependency( ${dep} )\n" )
    endif()
        endforeach()

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



function( target_find_deps target )
    set( options REQUIRED )
    set( oneValueArgs )
    set( multiValueArgs DEPS )
    cmake_parse_arguments( F_ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
    if (F_ARG_UNPARSED_ARGUMENTS)
        message( FATAL_ERROR "Unknown arguments: ${F_ARG_UNPARSED_ARGUMENTS}" )
    endif ()

    if (F_ARG_REQUIRED)
        set( PROP FIND_DEPS )
    else()
        set( PROP FIND_DEPS_OPTIONAL )
    endif()

    get_target_property( ${target}_EXISTING_FIND_DEPS ${target} ${PROP} )
    list( APPEND ${target}_EXISTING_FIND_DEPS ${F_ARG_DEPS} )
    # remove items matching NOTFOUND and duplicates

    set( ${target}_EXISTING_FIND_DEPS_CLEAN "" )

    foreach (dep IN LISTS ${target}_EXISTING_FIND_DEPS)
        if (NOT dep MATCHES "NOTFOUND" AND NOT dep IN_LIST ${target}_EXISTING_FIND_DEPS_CLEAN)
            list( APPEND ${target}_EXISTING_FIND_DEPS_CLEAN ${dep} )
        endif()
    endforeach()

    set_target_properties( ${target} PROPERTIES ${PROP} "${${target}_EXISTING_FIND_DEPS_CLEAN}" )
endfunction()
