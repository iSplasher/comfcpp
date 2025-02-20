cmake_minimum_required( VERSION 3.28 )


function( target_link_libraries_remove target libraries )
    # Get the LINK_LIBRARIES property for this target.
    get_target_property( linked_libs ${target} LINK_LIBRARIES )
    if (NOT linked_libs OR linked_libs STREQUAL "linked_libs-NOTFOUND")
        return()
    endif ()
    # Remove one item from the list, and overwrite the previous LINK_LIBRARIES property for e3.
    list( REMOVE_ITEM linked_libs ${libraries} )
    set_property( TARGET ${target} PROPERTY LINK_LIBRARIES ${linked_libs} )
endfunction()

execute_process( COMMAND "${CMAKE_COMMAND}" "--help-property-list" "${CMAKE_BINARY_DIR}/--help-property-list.txt" )
file( STRINGS "${CMAKE_BINARY_DIR}/--help-property-list.txt" property_list )

function( copy_target_props src_target dest_target )
    set( config_types "${CMAKE_CONFIGURATION_TYPES}" )
    if (NOT DEFINED CMAKE_CONFIGURATION_TYPES)
        set( config_types "Release;Debug;RelWithDebInfo;MinSizeRel" )
    endif ()

    set( IGNORE_PROPS "" )
    get_target_property( src_type ${src_target} TYPE )
    if (src_type MATCHES "INTERFACE")
        list( APPEND IGNORE_PROPS BINARY_DIR )
    endif ()

    foreach (prop_name ${property_list})
        if ("${prop_name}" MATCHES "(^LOCATION)|^VS_DEPLOYMENT_LOCATION$|^MACOSX_PACKAGE_LOCATION$|^CXX_MODULE_SETS$|^HEADER_SETS$|^IMPORTED_GLOBAL$|^INTERFACE_CXX_MODULE_SETS$|^INTERFACE_HEADER_SETS$|^NAME$|^TYPE$")
            continue()
        endif ()
        if ("${prop_name}" MATCHES "<CONFIG>")
            foreach (config ${config_types})
                string( REPLACE "<CONFIG>" "${config}" config_prop_name "${prop_name}" )
                get_target_property( prop_val "${src_target}" "${config_prop_name}" )
                if (NOT "${prop_val}" STREQUAL "prop_val-NOTFOUND")
                    #message("${config_prop_name}: ${prop_val}")
                    set_property( TARGET "${dest_target}" PROPERTY "${config_prop_name}" "${prop_val}" )
                endif ()
            endforeach ()
        else ()
            get_target_property( prop_val "${src_target}" "${prop_name}" )
            if (NOT "${prop_val}" STREQUAL "prop_val-NOTFOUND")
                #message("${prop_name}: ${prop_val}")
                set_property( TARGET "${dest_target}" PROPERTY "${prop_name}" "${prop_val}" )
            endif ()
        endif ()
    endforeach ()
    set( prop_name "IMPORTED_GLOBAL" )
    get_target_property( prop_val "${src_target}" "${prop_name}" )
    if ((NOT "${prop_val}" STREQUAL "prop_val-NOTFOUND") AND "${prop_val}")
        #message("${config_prop_name}: ${prop_val}")
        set_property( TARGET "${dest_target}" PROPERTY "${prop_name}" "${prop_val}" )
    endif ()
endfunction()

function( clone_target_as new_target original_target )
    # This function supports two optional named arguments:
    #   IMPORTED_LOCATION: If provided, use this value as the IMPORTED_LOCATION;
    #     otherwise, use a default computed from the install prefix and CMAKE_INSTALL_LIBDIR.
    #   EXTRA_PROPERTIES: A semicolon‐separated list of additional INTERFACE properties
    #     to copy from the original target.
    cmake_parse_arguments(
        CLONE
        "IMPORTED;NO_SYSTEM;INHERIT_TYPE;NO_DEPENDENCIES"                                     # no options without value
        "RESULT;TYPE;IMPORTED_LOCATION;IMPORTED_LOCATION_DEBUG;IMPORTED_LOCATION_RELEASE"                    # one-value arguments
        "CLONE;CONFIGURATIONS"                     # multi-value arguments
        ${ARGN}
        )

    # if the orig target is already imported, we can't clone it, just alias it
    if (CLONE_IMPORTED)
        get_target_property( orig_imported ${original_target} IMPORTED )
        if (orig_imported)
            add_library( ${new_target} ALIAS ${original_target} )
            if (CLONE_RESULT)
                set( ${CLONE_RESULT} OFF PARENT_SCOPE )
            endif ()
            return()
        endif ()
    endif ()


    set( target_type "INTERFACE" )
    if (CLONE_INHERIT_TYPE)
        get_target_property( ori_target_type ${original_target} TYPE )
        if (ori_target_type MATCHES "STATIC")
            set( target_type "STATIC" )
        elseif (ori_target_type MATCHES "SHARED")
            set( target_type "SHARED" )
        elseif (ori_target_type MATCHES "MODULE")
            set( target_type "MODULE" )
        endif ()
        message( STATUS "Inheriting type ${target_type} from ${original_target}" )
    endif ()
    if (CLONE_TYPE)
        set( target_type ${CLONE_TYPE} )
    endif ()

    set( configurations DEBUG RELEASE )
    if (CLONE_CONFIGURATIONS)
        set( configurations ${CLONE_CONFIGURATIONS} )
    endif ()

    set( IMPORTED )
    if (CLONE_IMPORTED)
        set( IMPORTED IMPORTED )
    endif ()

    add_library( ${new_target} ${target_type} ${IMPORTED} )
    add_dependencies( ${new_target} ${original_target} )
    if (target_type STREQUAL "INTERFACE" AND CLONE_IMPORTED)
        set_target_properties( ${new_target} PROPERTIES IMPORTED_LIBNAME ${original_target} )
    endif ()

    # The default list of INTERFACE properties to copy.
    set( map_props
        INCLUDE_DIRECTORIES
        HEADER_DIRS
        FOLDER
        DEFINE_SYMBOL
        DEBUG_POSTFIX
        COMPILE_FLAGS
        COMPILE_OPTIONS
        COMPILE_PDB_NAME
        INTERPROCEDURAL_OPTIMIZATION
        INSTALL_NAME_DIR
        LOCATION
        LIBRARY_OUTPUT_DIRECTORY
        LIBRARY_OUTPUT_NAME
        LINK_DEPENDS
        LINK_DEPENDS_NO_SHARED
        LINK_DIRECTORIES
        LINK_FLAGS
        LINK_LIBRARIES
        LINK_LIBRARIES_ONLY_TARGETS
        LINK_LIBRARIES_STRATEGY
        LINK_LIBRARY_OVERRIDE
        LINK_OPTIONS
        LINK_SEARCH_END_STATIC
        LINK_SEARCH_START_STATIC
        LINK_WHAT_YOU_USE
        LINKER_TYPE
        LINKER_LANGUAGE
        LABELS
        RUNTIME_OUTPUT_NAME
        RUNTIME_OUTPUT_DIRECTORY
        VERSION
        SUFFIX
        PREFIX
        PRIVATE_HEADER
        PUBLIC_HEADER
        RESOURCE
        NO_SONAME
        STATIC_LIBRARY_FLAGS
        STATIC_LIBRARY_OPT
        PDB_NAME
        C_STANDARD
        C_STANDARD_REQUIRED
        CXX_STANDARD
        CXX_STANDARD_REQUIRED
        BINARY_DIR
        BUNDLE
        BUNDLE_EXTENSION
        FRAMEWORK
        FRAMEWORK_VERSION
        CXX_EXTENSIONS
        CUDA_ARCHITECTURES
        CUDA_CUBIN_COMPILATION
        CUDA_EXTENSIONS
        CUDA_FATBIN_COMPILATION
        CUDA_OPTIX_COMPILATION
        CUDA_PTX_COMPILATION
        CUDA_RESOLVE_DEVICE_SYMBOLS
        CUDA_RUNTIME_LIBRARY
        CUDA_SEPARABLE_COMPILATION
        CUDA_STANDARD
        CUDA_STANDARD_REQUIRED
        IMPORT_SUFFIX
        IMPORT_PREFIX
        IMPLICIT_DEPENDS_INCLUDE_TRANSFORM
        INTERFACE_HEADER_SETS
        INTERFACE_HEADER_SETS_TO_VERIFY
        TYPE
        )

    foreach (conf IN LISTS configurations)
        list( APPEND map_props ${conf}_OUTPUT_NAME )
        list( APPEND map_props ${conf}_POSTFIX )
        list( APPEND map_props LIBRARY_OUTPUT_DIRECTORY_${conf} )
        list( APPEND map_props LINK_INTERFACE_LIBRARIES_${conf} )
        list( APPEND map_props LIBRARY_OUTPUT_NAME_${conf} )
        list( APPEND map_props LOCATION_${conf} )
        list( APPEND map_props LINK_FLAGS_${conf} )
        list( APPEND map_props LINK_INTERFACE_MULTIPLICITY_${conf} )
        list( APPEND map_props INTERPROCEDURAL_OPTIMIZATION_${conf} )
        list( APPEND map_props FRAMEWORK_MULTI_CONFIG_POSTFIX_${conf} )

    endforeach ()

    # Append any additional properties the caller provided.
    if (CLONE_CLONE)
        list( APPEND map_props ${CLONE_CLONE} )
    endif ()

    set( default_props
        INTERFACE_LINK_DEPENDS
        INTERFACE_LINK_LIBRARIES
        INTERFACE_LINK_LIBRARIES_DIRECT
        INTERFACE_LINK_LIBRARIES_DIRECT_EXCLUDE
        INTERFACE_INCLUDE_DIRECTORIES
        INTERFACE_SYSTEM_INCLUDE_DIRECTORIES
        INTERFACE_POSITION_INDEPENDENT_CODE
        INTERFACE_COMPILE_DEFINITIONS
        INTERFACE_PRECOMPILE_HEADERS
        INTERFACE_COMPILE_OPTIONS )

    if (NOT CLONE_IMPORTED AND CLONE_NO_DEPENDENCIES)
        list( REMOVE_ITEM default_props INTERFACE_LINK_LIBRARIES )
        #        list( REMOVE_ITEM default_props INTERFACE_LINK_DEPENDS )
        #        list( REMOVE_ITEM default_props INTERFACE_LINK_LIBRARIES_DIRECT )
    endif ()

    get_target_property( exp_props ${original_target} EXPORT_PROPERTIES )
    if (exp_props MATCHES "NOTFOUND")
        set( exp_props "" )
    endif ()

    foreach (prop IN LISTS map_props)
        if (NOT prop MATCHES "^(INTERFACE_|IMPORTED_)")
            list( APPEND exp_props ${prop} )
        endif ()
    endforeach ()

    set_target_properties( ${new_target} PROPERTIES EXPORT_PROPERTIES "${exp_props}" )

    # Loop over each property and copy it from the original target, if it exists.
    foreach (prop IN LISTS default_props)
        get_target_property( val ${original_target} ${prop} )
        if (val AND NOT val MATCHES "NOTFOUND")
            set_target_properties( ${new_target} PROPERTIES ${prop} "${val}" )
        endif ()
    endforeach ()


    if (CLONE_IMPORTED)

        foreach (prop IN LISTS map_props)
            get_target_property( val ${original_target} ${prop} )
            if (val AND NOT val MATCHES "NOTFOUND")
                set_target_properties( ${new_target} PROPERTIES MAP_IMPORTED_CONFIG_${prop} "${val}" )
            endif ()
        endforeach ()

        set( imported_props
            LINK_INTERFACE_LIBRARIES
            LINK_INTERFACE_MULTIPLICITY )

        foreach (prop IN LISTS imported_props)
            list( APPEND imported_props ${prop}_${conf} )
        endforeach ()

        foreach (prop IN LISTS imported_props)
            get_target_property( var ${original_target} ${prop} )
            if (var AND NOT var MATCHES "NOTFOUND")
                set_target_properties( ${new_target} PROPERTIES IMPORTED_${prop} "${var}" )
            endif ()
        endforeach ()

        # Determine the IMPORTED_LOCATION:
        # If the caller provided one, use it; otherwise, use a default.
        if (CLONE_IMPORTED_LOCATION)
            set( import_location ${CLONE_IMPORTED_LOCATION} )
        else ()
            # Here we assume that the installed library will reside in the standard
            # lib directory (given by CMAKE_INSTALL_LIBDIR) under the install prefix.
            set( import_location "$<INSTALL_PREFIX>/${CMAKE_INSTALL_LIBDIR}/$<TARGET_FILE_NAME:${original_target}>" )
        endif ()
        set_target_properties( ${new_target} PROPERTIES IMPORTED_LOCATION "${import_location}" )

        if (CLONE_IMPORTED_LOCATION_DEBUG)
            set_target_properties( ${new_target} PROPERTIES IMPORTED_LOCATION_DEBUG "${CLONE_IMPORTED_LOCATION_DEBUG}" )
        endif ()

        if (CLONE_IMPORTED_LOCATION_RELEASE)
            set_target_properties( ${new_target} PROPERTIES IMPORTED_LOCATION_RELEASE "${CLONE_IMPORTED_LOCATION_RELEASE}" )
        endif ()

    endif ()

    # exporting
    if (CLONE_NO_SYSTEM)
        set_target_properties( ${new_target} PROPERTIES NO_SYSTEM_FROM_IMPORTED TRUE )
        set_target_properties( ${new_target} PROPERTIES EXPORT_NO_SYSTEM TRUE )
    endif ()
    set_target_properties( ${new_target} PROPERTIES EXPORT_FIND_PACKAGE_NAME ${original_target} )

    if (CLONE_RESULT)
        set( ${CLONE_RESULT} ON PARENT_SCOPE )
    endif ()

endfunction()


# Conditionally set a variable to its name or undefined, for forwarding options.
macro( set_if target condition )
    if (${condition})
        set( ${target} "${target}" )
    else ()
        set( ${target} )
    endif ()
endmacro()


# Recursively traverse LINK_LIBRARIES to find all link dependencies.
# Options:
#   NO_STATIC - prune static libraries
#   NO_SYSTEM - skip SYSTEM targets (in >=3.25)
#       ^ REQUIRED if you want to install() the result, due to non-existent IMPORTED targets
# Caveats:
#   Non-targets in LINK_LIBRARIES like "m" (as in "libm") are ignored.
#   ALIAS target names are resolved.
function( get_all_dependencies target output_list )
    # Check if the NO_STATIC or NO_SYSTEM flag is provided
    set( options NO_STATIC NO_SYSTEM )
    set( oneValueArgs )
    set( multiValueArgs _CHILD )
    cmake_parse_arguments( PARSE_ARGV 2 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" )
    set_if( NO_STATIC ARG_NO_STATIC )
    set_if( NO_SYSTEM ARG_NO_SYSTEM )

    # Get dependencies of the target
    get_target_property( current_deps ${target} LINK_LIBRARIES )
    get_target_property( current_deps_2 ${target} INTERFACE_LINK_LIBRARIES )
    if (current_deps_2)
        list( APPEND current_deps ${current_deps_2} )
    endif ()

    if (NOT current_deps)
        set( current_deps "" ) # if no dependencies, replace "current_deps-NOTFOUND" with empty list
    endif ()

    # Remove entries between ::@(directory-id) and ::@
    # Such entries are added by target_link_libraries() calls outside the target's directory
    set( filtered_deps "" )
    set( in_special_block FALSE )
    foreach (dep IN LISTS current_deps)
        if ("${dep}" MATCHES "^::@\\(.*\\)$")
            set( in_special_block TRUE )  # Latch on
        elseif ("${dep}" STREQUAL "::@")
            set( in_special_block FALSE )  # Latch off
        elseif (NOT in_special_block)
            if (TARGET ${dep})  # Exclude non-targets like m (= libm)
                # Exclude SYSTEM targets (prevents  "install TARGETS given target "Perl" which does not exist")
                get_target_property( _is_system ${dep} SYSTEM )
                if (NOT _is_system OR NOT NO_SYSTEM)
                    # Resolve ALIAS targets (CMake issue #20979)
                    get_target_property( _aliased_dep ${dep} ALIASED_TARGET )
                    if (_aliased_dep)
                        list( APPEND filtered_deps ${_aliased_dep} )
                    else ()
                        list( APPEND filtered_deps ${dep} )
                    endif ()
                else ()
                    message( VERBOSE "get_all_dependencies ignoring ${target} -> ${dep} (system)" )
                endif ()
            else ()
                message( VERBOSE "get_all_dependencies ignoring ${target} -> ${dep} (not a target)" )
            endif ()
        else ()
            message( STATUS "get_all_dependencies ignoring ${target} -> ${dep} (added externally)" )
        endif ()
    endforeach ()

    set( all_deps ${filtered_deps} )

    if (NOT ARG__CHILD)
        set( ARG__CHILD "" )
    endif ()

    foreach (dep IN LISTS filtered_deps)
        # Avoid infinite recursion if the target has a cyclic dependency
        if (NOT "${dep}" IN_LIST ARG__CHILD)
            get_all_dependencies( ${dep} dep_child_deps ${NO_SYSTEM} _CHILD ${target} ${ARG__CHILD} )
            list( APPEND all_deps ${dep_child_deps} )
        endif ()
    endforeach ()

    # Remove duplicates
    list( REMOVE_DUPLICATES all_deps )

    # Remove static libraries if the NO_STATIC flag is set
    if (ARG_NO_STATIC)
        foreach (dep IN LISTS all_deps)
            get_target_property( dep_type ${dep} TYPE )
            if (dep_type STREQUAL "STATIC_LIBRARY")
                message( STATUS "get_all_dependencies pruning ${target} -> ${dep} (static)" )
                list( REMOVE_ITEM all_deps ${dep} )
            endif ()
        endforeach ()
    endif ()

    set( ${output_list} "${all_deps}" PARENT_SCOPE )
endfunction()


macro( get_all_targets_recursive targets dir )
    get_property( subdirectories DIRECTORY ${dir} PROPERTY SUBDIRECTORIES )
    foreach (subdir ${subdirectories})
        get_all_targets_recursive( ${targets} ${subdir} )
    endforeach ()

    get_property( current_targets DIRECTORY ${dir} PROPERTY BUILDSYSTEM_TARGETS )
    list( APPEND ${targets} ${current_targets} )
endmacro()


# Function to check if target is installable (not INTERFACE, IMPORTED, ALIAS, or UTILITY)
function( is_installable_target target var )
    if (NOT TARGET ${target})
        set( ${var} FALSE PARENT_SCOPE )
        return()
    endif ()

    get_target_property( target_type ${target} TYPE )
    if (target_type STREQUAL "UNKNOWN" OR target_type STREQUAL "UTILITY")
        set( ${var} FALSE PARENT_SCOPE )
        return()
    endif ()

    get_target_property( imported ${target} IMPORTED )
    if (imported)
        set( ${var} FALSE PARENT_SCOPE )
        return()
    endif ()

    get_target_property( alias ${target} ALIASED_TARGET )
    if (alias)
        set( ${var} FALSE PARENT_SCOPE )
        return()
    endif ()

    set( ${var} TRUE PARENT_SCOPE )
endfunction()


function( get_all_targets var )
    cmake_parse_arguments( PARSE_ARGV 1 ARG
        "INSTALLABLE"
        ""
        ""
        )

    set( targets )
    get_all_targets_recursive( targets ${CMAKE_CURRENT_SOURCE_DIR} )
    if (ARG_INSTALLABLE)
        foreach (target ${targets})
            is_installable_target( ${target} is_installable )
            if (NOT is_installable)
                list( REMOVE_ITEM targets ${target} )
            endif ()
        endforeach ()
    endif ()

    set( ${var} ${targets} PARENT_SCOPE )
endfunction()

# Function to fix absolute paths in target properties
function( fix_install_paths target )
    cmake_parse_arguments( "arg" "" "INCLUDEDIR" "" ${ARGN} )

    if (arg_INCLUDEDIR)
        set( INCLUDEDIR ${arg_INCLUDEDIR} )
    else ()
        set( INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR} )
    endif ()

    if (NOT TARGET ${target})
        return()
    endif ()

    get_target_property( include_dirs ${target} INTERFACE_INCLUDE_DIRECTORIES )
    if (include_dirs)
        # Create a new list for modified include directories
        set( new_include_dirs "" )

        foreach (dir ${include_dirs})
            # is absolute or starts with absolute path
            if (IS_ABSOLUTE ${dir} OR dir MATCHES "^[A-Za-z]:" OR dir MATCHES "^/")
                # Convert absolute path to relative path from current source dir
                file( RELATIVE_PATH rel_dir ${CMAKE_CURRENT_SOURCE_DIR} ${dir} )

                # Use generator expression to handle both build and install cases
                list( APPEND new_include_dirs
                    "$<BUILD_INTERFACE:${dir}>"
                    "$<INSTALL_INTERFACE:${INCLUDEDIR}/${rel_dir}>"
                    )

                message( STATUS "Fixed include directory for ${target}: ${dir} -> ${rel_dir}" )
            else ()
                list( APPEND new_include_dirs ${dir} )
            endif ()
        endforeach ()

        # Set the modified include directories
        set_target_properties( ${target} PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${new_include_dirs}"
            )
    endif ()
endfunction()

