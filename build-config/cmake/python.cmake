include_guard( GLOBAL )
find_package (Python COMPONENTS Interpreter Development.Module )

# get the path to the python executable

# create a virtual environment
get_filename_component(PYTHON_ENV_DIR_ABS "${CMAKE_SOURCE_DIR}/venv" ABSOLUTE )
set(PYTHON_ENV_DIR ${PYTHON_ENV_DIR_ABS} CACHE PATH "Python virtual environment directory")

cmake_print_variables( Python3_EXECUTABLE )

if (Python_EXECUTABLE_DEBUG)
    set(Python_BINARY_EXECUTABLE ${Python_EXECUTABLE_DEBUG} CACHE FILEPATH "Python executable")
else ()
    set(Python_BINARY_EXECUTABLE ${Python_EXECUTABLE} CACHE FILEPATH "Python executable")
endif ()

if (NOT EXISTS ${PYTHON_ENV_DIR})
    message(STATUS "Creating virtual environment in ${PYTHON_ENV_DIR}")
    # if release mode, don't use the system python
    if (CMAKE_BUILD_TYPE STREQUAL "Release")
        execute_process(COMMAND ${Python_BINARY_EXECUTABLE} -m venv ${PYTHON_ENV_DIR} --without-pip)
    else ()
        execute_process(COMMAND ${Python_BINARY_EXECUTABLE} -m venv ${PYTHON_ENV_DIR})
    endif ()
endif ()

if (WIN32)
    set(PYTHON_ENV_EXECUTABLE ${PYTHON_ENV_DIR}/Scripts/python.exe)
else ()
    set(PYTHON_ENV_EXECUTABLE ${PYTHON_ENV_DIR}/bin/python)
endif ()

set(ENV{VIRTUAL_ENV} ${PYTHON_ENV_DIR})
set(ENV{PATH} "${PYTHON_ENV_DIR}/bin;$ENV{PATH}")
set(ENV{PATH} "${PYTHON_ENV_DIR}/Scripts;$ENV{PATH}")

#set(ENV{PYTHONHOME ${_VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/tools/python3)
set(ENV{PYTHONHOME ${PYTHON_ENV_DIR})

function( install_python_package target package_names )
    if (NOT Python_FOUND)
        set( CMAKE_FIND_DEBUG_MODE ON )
        find_package (Python COMPONENTS  Development.SABIModule)
    endif ()

    if (NOT Python_FOUND)
        message(FATAL_ERROR "Python not found")
    endif ()

    if (CMAKE_BUILD_TYPE STREQUAL "Debug")
        execute_process(COMMAND PYTHON_ENV_EXECUTABLE -m ensurepip)
        execute_process(COMMAND PYTHON_ENV_EXECUTABLE -m pip install --upgrade pip)
    endif ()

    foreach( package_name ${package_names} )
        message( CHECK_START "Installing Python package ${package_name}..." )
        execute_process( COMMAND ${PYTHON_ENV_EXECUTABLE} -m pip install --compile ${package_name})
        message( CHECK_PASS "OK")
        add_custom_target( python_package_${package_name}
#            COMMAND ${PYTHON_ENV_EXECUTABLE} -m pip install --compile ${package_name}
            COMMENT "Installing Python package ${package_name}..."
#            DEPENDS ${PYTHON_ENV_DIR}/Lib/site-packages/${package_name}
            VERBATIM
            )
        add_dependencies( ${target} python_package_${package_name} )
    endforeach()
endfunction()

macro( target_link_python target )
    if (TARGET Python::SABIModule)
        message( STATUS "Linking to SABI Python module")
        target_link_libraries( ${TARGET_NAME} PRIVATE Python::SABIModule )
    else ()
        target_link_libraries( ${TARGET_NAME} PRIVATE Python::Module )
    endif ()
    target_include_directories( ${TARGET_NAME} PUBLIC ${Python_INCLUDE_DIRS} )
endmacro( )
