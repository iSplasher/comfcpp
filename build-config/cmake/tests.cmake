include_guard( GLOBAL )
# - Test configuration and utilities
# Will include the Catch2 framework and enable testing if BUILD_TESTING is set
# and the target is in the TEST_TARGETS list or if the target list is empty.
# The target list is a list of targets that should be tested.
# Functions and macros:


function( should_build_test_target )
    set( options CHECK )
    set( oneValueArgs TARGET OUTPUT )
    set( multiValueArgs TARGETS )
    cmake_parse_arguments( F_ARG "${options}" "${oneValueArgs}"
        "${multiValueArgs}" ${ARGN} )
    if (F_ARG_UNPARSED_ARGUMENTS)
        message( FATAL_ERROR "Unknown arguments: ${F_ARG_UNPARSED_ARGUMENTS}" )
    endif ()

    if (NOT F_ARG_OUTPUT)
        message( FATAL_ERROR "OUTPUT arg is not defined" )
    endif ()

    set( _TARGET_NAMES "" )
    foreach (target ${F_ARG_TARGETS})
        list( APPEND _TARGET_NAMES ${target} )
    endforeach ()

    if (F_ARG_TARGET)
        list( APPEND _TARGET_NAMES ${F_ARG_TARGET} )
    endif ()

    set( ${F_ARG_OUTPUT} FALSE )

    if (F_ARG_CHECK)
        message( CHECK_START "Checking if test targets should be enabled: ${_TARGET_NAMES}" )
    endif ()

    if (ENABLE_TESTS)
        foreach (_TARGET_NAME ${_TARGET_NAMES})
            if (TARGET ${_TARGET_NAME})
                set( _index 1 )
                if (NOT "${TEST_TARGETS}" STREQUAL "")
                    list( FIND TEST_TARGETS ${_TARGET_NAME} _index )
                endif ()

                get_target_property( _target_labels ${_TARGET_NAME} LABELS )
                list( FIND _target_labels "DISABLED" _index_disabled )
                if (${_index_disabled} GREATER -1)
                    set( _index -1 )
                endif ()

                if (${_index} EQUAL -1)
                    if (F_ARG_CHECK)
                        message( CHECK_FAIL "... not enabled for: ${_TARGET_NAME}" )
                    endif ()
                    return( PROPAGATE ${F_ARG_OUTPUT} )
                endif ()
            endif ()
        endforeach ()
    endif ()

    if (F_ARG_CHECK)
        message( CHECK_PASS "... enabled for: ${_TARGET_NAMES}" )
    endif ()

    set( ${F_ARG_OUTPUT} TRUE )
    return( PROPAGATE ${F_ARG_OUTPUT} )
endfunction()


function( build_test_target )

    set( options DISABLE_ALL ENABLE_ALL )
    set( oneValueArgs OUTPUT )
    set( multiValueArgs ALL_TARGETS )
    cmake_parse_arguments( F_ARG "${options}" "${oneValueArgs}"
        "${multiValueArgs}" ${ARGN} )

    if (F_ARG_UNPARSED_ARGUMENTS)
        message( FATAL_ERROR "Unknown arguments: ${F_ARG_UNPARSED_ARGUMENTS}" )
    endif ()

    if (NOT F_ARG_OUTPUT)
        message( FATAL_ERROR "OUTPUT arg is not defined" )
    endif ()

    set( _TARGET_NAMES ${F_ARG_ALL_TARGETS} )
    set( ret ${F_ARG_OUTPUT} )

    set( ${ret} FALSE )

    message( CHECK_START "Checking if test targets should be enabled" )

    if (BUILD_TESTING AND (NOT F_ARG_DISABLE_ALL OR F_ARG_ENABLE_ALL))
        # check if list empty
        if ("${F_ARG_ALL_TARGETS}" STREQUAL "")
            message( CHECK_PASS "... enabling tests for all test targets" )
        else ()
            message( CHECK_PASS "... enabled for: ${F_ARG_ALL_TARGETS}" )
        endif ()
    else ()
        message( CHECK_FAIL "... not enabling tests" )
        if (F_ARG_DISABLE_ALL)
            message( CHECK_FAIL "... because all tests targets are disabled" )
        endif ()
    endif ()

    set( ${ret} TRUE )
    return( PROPAGATE ${ret} )
endfunction()

# -------------------------------------------------------

macro( setup_tests )
    if (NOT TARGET Catch2::Catch2WithMain)
        find_package( Catch2 3 CONFIG REQUIRED )
    endif ()


    set( TEST_TARGETS "" )

    set( _test_options DISABLE_ALL ENABLE_ALL )
    set( _test_oneValueArgs TARGET )
    set( _test_multiValueArgs EXTRA_ARGS ENABLE DISABLE )
    cmake_parse_arguments( M_SETUP_TESTS_ARG "${_test_options}" "${_test_oneValueArgs}"
        "${_test_multiValueArgs}" ${ARGN} )

    if (M_SETUP_TESTS_ARG_UNPARSED_ARGUMENTS)
        message( FATAL_ERROR "Unknown arguments: ${M_SETUP_TESTS_ARG_UNPARSED_ARGUMENTS}" )
    endif ()


    set( TEST_TARGET_MAIN_NAME ${M_SETUP_TESTS_ARG_TARGET} )

    foreach (enabled ${M_SETUP_TESTS_ARG_ENABLE})
        list( APPEND TEST_TARGETS ${enabled} )
    endforeach ()

    foreach (enabled ${M_SETUP_TESTS_ARG_DISABLE})
        list( REMOVE_ITEM TEST_TARGETS ${enabled} )
    endforeach ()

    set( _build_test_target_args "" )
    if (M_SETUP_TESTS_ARG_DISABLE_ALL)
        list( APPEND _build_test_target_args DISABLE_ALL )
    endif ()
    if (M_SETUP_TESTS_ARG_ENABLE_ALL)
        list( APPEND _build_test_target_args ENABLE_ALL )
    endif ()

    build_test_target( ${_build_test_target_args} OUTPUT ENABLE_TESTS ALL_TARGETS "${TEST_TARGETS}" )

    if (ENABLE_TESTS)
        message( STATUS "Configuring tests" )

        add_compile_definitions( APP_TESTING )
        add_executable( ${TEST_TARGET_MAIN_NAME} )
        # These tests can use the Catch2-provided main
        target_link_libraries( ${TEST_TARGET_MAIN_NAME} PRIVATE Catch2::Catch2WithMain )

        include( CTest )
        enable_testing()

        include( ${Catch2_DIR}/Catch.cmake )

        # pass arguments to the test executable
        catch_discover_tests( ${TEST_TARGET_MAIN_NAME} EXTRA_ARGS "${M_SETUP_TESTS_ARG_EXTRA_ARGS}" )
    endif ()

endmacro()

# -------------------------------------------------------

function( add_test_target )
    set( options DISABLE )
    set( oneValueArgs TARGET )
    set( multiValueArgs TARGETS SOURCES INCLUDES LINK_LIBRARIES COMPILE_DEFINITIONS )
    cmake_parse_arguments( F_ARG "${options}" "${oneValueArgs}"
        "${multiValueArgs}" ${ARGN} )
    if (F_ARG_UNPARSED_ARGUMENTS)
        message( FATAL_ERROR "Unknown arguments: ${F_ARG_UNPARSED_ARGUMENTS}" )
    endif ()

    set( _TARGET_NAMES "" )
    foreach (target ${F_ARG_TARGETS})
        list( APPEND _TARGET_NAMES ${target} )
    endforeach ()

    if (F_ARG_TARGET)
        list( APPEND _TARGET_NAMES ${F_ARG_TARGET} )
    endif ()

    set( ${OUTPUT} FALSE )


    message( CHECK_START "Adding test target for ${_TARGET_NAMES}" )

    if (F_ARG_DISABLE)
        message( CHECK_FAIL "... disabled" )
        return( PROPAGATE ${OUTPUT} )
    endif ()

    foreach (target IN LISTS _TARGET_NAMES)
        message( VERBOSE "[${target}]: Adding test target for ${target} -> ${target}-tests" )
        should_build_test_target( CHECK OUTPUT _enable_test_target TARGETS ${target} )
        if (_enable_test_target)
            set( _sources ${F_ARG_SOURCES} )

            get_target_property( src_dir ${target} SOURCE_DIR )

            if (NOT _sources)
                set( _sources "${src_dir}/tests/*.cpp" )
            endif ()

            get_target_property( ${target}_SOURCES ${target} SOURCES )
            add_library( ${target}-tests STATIC ${${target}_SOURCES} )
            get_target_property( ${target}_INCLUDE_DIR ${target} INCLUDE_DIRECTORIES )
            target_include_directories( ${target}-tests
                PUBLIC ${${target}_INCLUDE_DIR}
                PUBLIC "${src_dir}/tests/include"
                )
            get_target_property( ${target}_LIBRARIES ${target} LINK_LIBRARIES )
            target_link_libraries( ${target}-tests
                PUBLIC
                ${${target}_LIBRARIES}
                )
            get_target_property( ${target}_COMPILE_DEFINITIONS ${target} COMPILE_DEFINITIONS )
            target_compile_definitions( ${target}-tests PUBLIC ${${target}_COMPILE_DEFINITIONS} )

            foreach (source ${_sources})
                file( GLOB_RECURSE TEST_SOURCES CONFIGURE_DEPENDS ${source} )
                target_sources( ${TEST_TARGET_MAIN_NAME} PRIVATE
                    ${TEST_SOURCES}
                    )
            endforeach ()

            foreach (include ${F_ARG_INCLUDES})
                target_include_directories( ${TEST_TARGET_MAIN_NAME} PUBLIC ${include} )
            endforeach ()

            target_link_libraries( ${TEST_TARGET_MAIN_NAME} PRIVATE ${target}-tests )

            foreach (lib ${F_ARG_LINK_LIBRARIES})
                target_link_libraries( ${target}-tests PRIVATE ${lib} )
            endforeach ()

            foreach (def ${F_ARG_COMPILE_DEFINITIONS})
                target_compile_definitions( ${target}-tests PRIVATE ${def} )
            endforeach ()

            if (NOT ${OUTPUT})
                set( ${OUTPUT} "" )
            endif ()

            list( APPEND ${OUTPUT} ${target}-tests )
        endif ()
    endforeach ()

    if (${OUTPUT})
        message( CHECK_PASS "... added: ${OUTPUT}" )
    else ()
        message( CHECK_FAIL "... not added" )
    endif ()

endfunction()


