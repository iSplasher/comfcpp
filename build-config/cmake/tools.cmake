include_guard( GLOBAL )

message( STATUS "Configuring and installing tools" )

# Install IWYU

option( USE_IWYU "Enable include-what-you-use reports during build" OFF )

if (USE_IWYU)
    if (NOT IWYU_PATH)
        message( STATUS "IWYU_PATH not set, downloading..." )

        # get path to compiler
        if (NOT CMAKE_CXX_COMPILER)
            message( FATAL_ERROR "CMAKE_CXX_COMPILER not set" )
        endif ()

        # expand path to compiler
        execute_process(
            COMMAND ${CMAKE_CXX_COMPILER} -print-runtime-dir
            OUTPUT_VARIABLE IWYU_LLVM_PATH
            )

        message( STATUS "Found LLVM path ${IWYU_LLVM_PATH}" )


        include( FetchContent )
        fetchcontent_declare( iwyu_repo
            GIT_REPOSITORY https://github.com/include-what-you-use/include-what-you-use.git
            GIT_BRANCH clang_18
            SYSTEM
            )
        fetchcontent_populate( iwyu_repo )
        cmake_print_variables( iwyu_repo_SOURCE_DIR )

        set( IWYU_PATH ${CMAKE_BINARY_DIR}/build-tools/bin/include-what-you-use )


        add_custom_command(
            OUTPUT ${IWYU_PATH}
            WORKING_DIRECTORY ${iwyu_repo_SOURCE_DIR}
            COMMAND
            ${CMAKE_COMMAND} -G "Unix Makefiles" -DCMAKE_PREFIX_PATH=${IWYU_LLVM_PATH} -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/tools
            COMMAND
            cd build && make -j4
            COMMAND
            make install
            COMMENT "Building IWYU and installing to ${IWYU_PATH}"
            DEPENDS iwyu_repo
            )
        #        get_filename_component( IWYU_INSTALL_DIR ${IWYU_PATH} DIRECTORY )
        add_custom_target( iwyu ALL
            DEPENDS ${IWYU_PATH} )
    endif ()

    message( STATUS "Found IWYU ${IWYU_PATH}" )
    set( CMAKE_CXX_INCLUDE_WHAT_YOU_USE ${IWYU_PATH} CXXFLAGS="-Xiwyu --error_always" )
endif ()

option( USE_CPPFRONT "Enable cppfront support" OFF )

if (USE_CPPFRONT)
    if (NOT CPPFRONT_PATH)
        message( STATUS "CPPFRONT_PATH not set, downloading..." )

        if (NOT CPPFRONT_VERSION)
            set( CPPFRONT_VERSION "v0.8.1" )
        endif ()

        include( FetchContent )
        fetchcontent_declare( cppfront_src
            GIT_REPOSITORY https://github.com/hsutter/cppfront.git
            GIT_TAG ${CPPFRONT_VERSION}
            SYSTEM
            )
        fetchcontent_makeavailable( cppfront_src )

        cmake_print_variables( cppfront_src_SOURCE_DIR )
        cmake_print_variables( cppfront_src_BINARY_DIR )

        # compile with default compiler
        set( build_cmd )
        if (WIN32)
            # use MSVC because doing it with clang crashes on windows
            set( build_cmd clang++ -std=c++20 cppfront.cpp -o cppfront )
        endif ()

        if (NOT EXISTS ${cppfront_src_BINARY_DIR}/cppfront${CMAKE_EXECUTABLE_SUFFIX})
            message( STATUS "No binary found at ${cppfront_BINARY_DIR}/cppfront${CMAKE_EXECUTABLE_SUFFIX}" )
            message( CHECK_START "Building cppfront '${build_cmd}'..." )
            execute_process( COMMAND ${build_cmd}
                WORKING_DIRECTORY ${cppfront_src_SOURCE_DIR}/source
                ERROR_VARIABLE build_error
                )
            if (build_error)
                message( CHECK_FAIL "error" )
                message( FATAL_ERROR "Failed to build cppfront: ${build_error}" )
            else ()
                message( CHECK_PASS "done" )
            endif ()
        endif ()

        set( CPPFRONT_PATH ${cppfront_src_BINARY_DIR}/cppfront${CMAKE_EXECUTABLE_SUFFIX} )
    endif ()
endif ()

#[=======================================================================[.rst:
setup_cppfront
-------------

Sets up the cppfront compiler target if it hasn't been set up already.
Requires CPPFRONT_PATH to be set to a valid cppfront executable path.

#]=======================================================================]
macro( setup_cppfront )
    if (NOT EXISTS "${CPPFRONT_PATH}")
        message( FATAL_ERROR "CPPFRONT_PATH not set" )
    endif ()

    if (NOT TARGET cppfront)
        add_custom_target( cppfront
            DEPENDS ${CPPFRONT_PATH}
            )

        set( cppfront cppfront PARENT_SCOPE )
    endif ()
endmacro()

#[=======================================================================[.rst:
add_cppfront_target
------------------

Adds cppfront compilation support to a target. Will process all .cpp2 and .h2
files in the given sources and generate corresponding .cpp and .h files.

Arguments:
  target
    Name of the target to add cppfront support to
  SOURCES
    List of source files or directories to process

Example:
  add_cppfront_target(mylib 
    SOURCES 
      src/file1.cpp2
      include
  )
#]=======================================================================]
function( add_cppfront_target target )
    cmake_parse_arguments( "arg" "" "" "SOURCES" ${ARGN} )
    if (arg_UNPARSED_ARGUMENTS)
        message( FATAL_ERROR "Unknown arguments: ${arg_UNPARSED_ARGUMENTS}" )
    endif ()


    if (NOT USE_CPPFRONT)
        return()
    endif ()

    setup_cppfront()

    set( target_out_root ${CMAKE_CURRENT_BINARY_DIR}/cppfront-out/${target} )
    get_target_property( target_in_root ${target} SOURCE_DIR )

    # get all cpp2 files from SOURCES
    set( cpp2_files )
    foreach (src ${arg_SOURCES})
        # if directory, get all cpp2 files
        if (IS_DIRECTORY ${src})
            file( GLOB_RECURSE cpp2_files LIST_DIRECTORIES false RELATIVE ${target_in_root} ${src}/*.cpp2 ${src}/*.h2 )

            # else if file ends with .cpp2, add to list
        elseif (src MATCHES ".*\\.cpp2$")
            # make relative to target root
            cmake_path( RELATIVE_PATH src ${target_in_root} )
            list( APPEND cpp2_files ${src} )
        endif ()
    endforeach ()

    # generate cpp files for all cpp2 files
    foreach (rel_cpp2_file IN LISTS cpp2_files)
        set( cpp2_file_in ${target_in_root}/${rel_cpp2_file} )
        # replace .cpp2/h2 extension
        string( REGEX REPLACE "\\.cpp2$" ".cpp" cpp_file_out ${rel_cpp2_file} )
        string( REGEX REPLACE "\\.h2$" ".h" cpp_file_out ${rel_cpp2_file} )

        set( cpp_file_out ${target_out_root}/${cpp_file_out} )

        message( STATUS "cppfront-map: ${rel_cpp2_file} -> ${cpp_file_out}" )

        add_custom_command( OUTPUT ${cpp_file_out}
            DEPENDS cppfront ${cpp2_file_in}
            COMMAND cppfront --output ${cpp_file_out} ${cpp2_file_in}
            COMMENT "cppfront-build: ${rel_cpp2_file} -> ${cpp_file_out}"
            MAIN_DEPENDENCY ${cpp2_file_in}
            )

        target_sources( ${target} PRIVATE ${cpp_file_out} )
    endforeach ()

    add_dependencies( ${target} cppfront )

endfunction()


macro( _install_embed )
    if (NOT TARGET battery-embed)
        include( FetchContent )
        fetchcontent_declare(
            battery-embed
            GIT_REPOSITORY https://github.com/batterycenter/embed.git
            GIT_TAG v1.2.19
            )
        fetchcontent_makeavailable( battery-embed )
    endif ()
endmacro()

#[=======================================================================[.rst:
target_embed
-----

Embeds resources into a target using battery-embed.
Processes source files and directories, including glob patterns.

Arguments:
  target
    Name of the target to embed resources into
  SOURCES
    List of source files, directories, or glob patterns to process

Example:
  target_embed(myapp
    SOURCES
      resources/*.png
      assets/textures
  )

  In C++:
    #include <iostream>
    #include "battery/embed.hpp"

    int main() {
        std::cout << b::embed<"resources/message.txt">() << std::endl;
        return 0;
    }
#]=======================================================================]
macro( target_embed target )
    cmake_parse_arguments( "arg" "" "" "SOURCES" ${ARGN} )
    if (arg_UNPARSED_ARGUMENTS)
        message( FATAL_ERROR "Unknown arguments: ${arg_UNPARSED_ARGUMENTS}" )
    endif ()


    _install_embed()

    set( sources )

    foreach (src IN LISTS arg_SOURCES)
        # check if its a glob string
        if (src MATCHES "\\*")
            file( GLOB_RECURSE files CONFIGURE_DEPENDS ${src} )
            list( APPEND sources ${files} )
        else ()
            set( _src ${src} )
            if (IS_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${src})
                set( _src ${CMAKE_CURRENT_LIST_DIR}/${src} )
            endif ()
            if (IS_DIRECTORY ${_src})
                file( GLOB_RECURSE files CONFIGURE_DEPENDS ${_src}/* )
                list( APPEND sources ${files} )
            else ()
                list( APPEND sources ${_src} )
            endif ()
        endif ()
    endforeach ()

    if (sources AND NOT TARGET ${target}-embeds)
        message( STATUS "[${target}]: Creating embed target for ${target} -> ${target}-embeds" )
        b_embed_proxy_target( ${target} ${target}-embeds )
        add_dependencies( ${target} ${target}-embeds )
        target_compile_definitions( ${target} PRIVATE BATTERY_EMBED_ENABLED )
    endif ()

    foreach (src IN LISTS sources)
        set( rel_src ${src} )
        cmake_path( RELATIVE_PATH rel_src BASE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} )

        set( out_src "${CMAKE_CURRENT_BINARY_DIR}/${target}-embeds/${rel_src}" )
        add_custom_command( OUTPUT ${out_src}
            COMMAND ${CMAKE_COMMAND} -E copy ${src} ${out_src}
            DEPENDS ${src}
            COMMENT "Copying ${src} to ${target}-embeds"
            )

        set( embed_target ${target}-embeds-${rel_src} )
        string( REPLACE "/" "_" embed_target ${embed_target} )
        string( REPLACE "\\" "_" embed_target ${embed_target} )
        string( REPLACE "." "_" embed_target ${embed_target} )

        add_custom_target( ${embed_target}
            DEPENDS ${out_src}
            )

        cmake_path( RELATIVE_PATH src BASE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} )
        message( STATUS "[${target}]: Embedding ${src}" )
        b_embed( ${target}-embeds ${src} )
        add_dependencies( ${target}-embeds ${embed_target} )
    endforeach ()
endmacro()
