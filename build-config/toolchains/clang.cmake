include_guard( DIRECTORY )

# Inspo:
# https://github.com/Neumann-A/my-vcpkg-triplets/blob/master/x64-win-llvm/x64-win-llvm.toolchain.cmake
#  https://github.com/microsoft/vcpkg/pull/31028

macro( use_sanitizer )
    set( sanitizers "alignment,null" )
    if (VCPKG_USE_LTO)
        string( APPEND sanitizers ",cfi" )
    else ()
        string( APPEND sanitizers ",address" ) # lld-link: error: /alternatename: conflicts: __sanitizer_on_print=__sanitizer_on_print__def
    endif ()
    if (VCPKG_CRT_LINKAGE STREQUAL "static")
        string( APPEND sanitizers ",undefined" )
    endif ()
    string( APPEND CLANG_FLAGS_RELEASE "-fsanitize=${sanitizers} /Oy- /GF-" )
    if (NOT DEFINED ENV{LLVMToolsVersion})
        file( GLOB clang_ver_path LIST_DIRECTORIES true "${LLVM_BIN_DIR}/../lib/clang/*" )
    else ()
        set( clang_ver_path "${LLVM_BIN_DIR}/../lib/clang/$ENV{LLVMToolsVersion}" )
    endif ()
    #set(ENV{PATH} "$ENV{PATH};${clang_ver_path}/lib/windows")

    #set(ENV{LINK} "$ENV{LINK} /LIBPATH:\"${clang_ver_path}/lib/windows\"")
    #set(sanitizer_path "/LIBPATH:\\\\\"${clang_ver_path}/lib/windows\\\\\"" )
    if (VCPKG_CRT_LINKAGE STREQUAL "dynamic")
        set( sanitizer_libs_exe "-include:__asan_seh_interceptor clang_rt.asan_dynamic-x86_64.lib clang_rt.asan_dynamic_runtime_thunk-x86_64.lib /wholearchive:clang_rt.asan_dynamic_runtime_thunk-x86_64.lib" )
        set( sanitizer_libs_dll "${sanitizer_libs_exe}" )
    else ()
        set( sanitizer_libs "clang_rt.ubsan_standalone-x86_64.lib clang_rt.ubsan_standalone_cxx-x86_64.lib" )
        set( sanitizer_libs_exe "${sanitizer_libs} /wholearchive:clang_rt.asan-x86_64.lib /wholearchive:clang_rt.asan_cxx-x86_64.lib" )
        set( sanitizer_libs_dll "clang_rt.asan_dll_thunk-x86_64.lib" )
    endif ()

    set( CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} ${sanitizer_libs_exe}" PARENT_SCOPE CACHE STRING "" FORCE )
    set( CMAKE_EXE_LINKER_FLAGS_MINSIZEREL "${CMAKE_EXE_LINKER_FLAGS_MINSIZEREL} ${sanitizer_libs_exe}" PARENT_SCOPE CACHE STRING "" FORCE )
    set( CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO} ${sanitizer_libs_exe}" PARENT_SCOPE CACHE STRING "" FORCE )
    set( CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} ${sanitizer_libs_dll}" PARENT_SCOPE CACHE STRING "" FORCE )
    set( CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL "${CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL} ${sanitizer_libs_dll}" PARENT_SCOPE CACHE STRING "" FORCE )
    set( CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO} ${sanitizer_libs_dll}" PARENT_SCOPE CACHE STRING "" FORCE )
    set( CMAKE_MODULE_LINKER_FLAGS_RELEASE "${CMAKE_MODULE_LINKER_FLAGS_RELEASE} ${sanitizer_libs_dll}" PARENT_SCOPE CACHE STRING "" FORCE )
    set( CMAKE_MODULE_LINKER_FLAGS_MINSIZEREL "${CMAKE_MODULE_LINKER_FLAGS_MINSIZEREL} ${sanitizer_libs_dll}" PARENT_SCOPE CACHE STRING "" FORCE )
    set( CMAKE_MODULE_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_MODULE_LINKER_FLAGS_RELWITHDEBINFO} ${sanitizer_libs_dll}" PARENT_SCOPE CACHE STRING "" FORCE )
    unset( clang_ver_path )
    unset( sanitizers )
    unset( sanitizer_libs )
    unset( sanitizer_libs_exe )
    unset( sanitizer_libs_dll )
endmacro()


function( msvc_to_clang INPUT_FLAGS OUTPUT_VAR )
    # Start with the input string
    set( _result "${INPUT_FLAGS}" )

    macro( map_flag input_flags out )
        set( new_flags "" )
        foreach (flag IN LISTS ${input_flags})
            # Map MSVC flags to Clang/GNU equivalents
            # flags to be ignored
            if (flag MATCHES "^/(logo|nologo)$")
                continue()
            elseif (flag MATCHES "^/MP([0-9]*)$")
                continue()
            elseif (flag MATCHES "^/arch:([A-Za-z0-9]+)$")
                # Architecture
                set( arch_value ${CMAKE_MATCH_1} )
                if (arch_value STREQUAL "AVX" OR arch_value STREQUAL "AVX2")
                    list( APPEND new_flags "-m${arch_value}" )
                elseif (arch_value STREQUAL "SSE" OR arch_value STREQUAL "SSE2")
                    list( APPEND new_flags "-m${arch_value}" )
                endif ()
            elseif (flag STREQUAL "/RTC1") # Runtime checks
                use_sanitizer()
            elseif (flag STREQUAL "/Oi")
                list( APPEND new_flags "-fbuiltin" )
            elseif (flag STREQUAL "/Oi-")
                list( APPEND new_flags "-fno-builtin" )

                # Optimization flags
            elseif (flag STREQUAL "/O0" OR flag STREQUAL "/Od")
                list( APPEND new_flags "-O0" )
            elseif (flag STREQUAL "/O1")
                list( APPEND new_flags "-Os" )
            elseif (flag STREQUAL "/O2" OR flag STREQUAL "/Ox")
                list( APPEND new_flags "-O2" )
            elseif (flag STREQUAL "/Ob0")
                list( APPEND new_flags "-fno-inline" )
            elseif (flag STREQUAL "/Ob1")
                list( APPEND new_flags "-finline-hint-functions" )
            elseif (flag STREQUAL "/Ob2" OR flag STREQUAL "/Ob3")
                list( APPEND new_flags "-finline-functions" )
            elseif (flag STREQUAL "/Os")
                list( APPEND new_flags "-Os" )
            elseif (flag STREQUAL "/Ot")
                list( APPEND new_flags "-O3" )

                # Debug information
            elseif (flag STREQUAL "/Z7" OR flag STREQUAL "/Zi")
                list( APPEND new_flags "-g" )

                # Exception handling
            elseif (flag STREQUAL "/EHsc" OR flag STREQUAL "/GX")
                list( APPEND new_flags "-fexceptions" "-fcxx-exceptions" )
            elseif (flag STREQUAL "/GX-")
                list( APPEND new_flags "-fno-exceptions" )

                # RTTI
            elseif (flag STREQUAL "/GR")
                list( APPEND new_flags "-frtti" )
            elseif (flag STREQUAL "/GR-")
                list( APPEND new_flags "-fno-rtti" )

                # Calling conventions
            elseif (flag STREQUAL "/Gd")
                list( APPEND new_flags "-fcdecl" )
            elseif (flag STREQUAL "/Gr")
                list( APPEND new_flags "-ffastcall" )
            elseif (flag STREQUAL "/Gz")
                list( APPEND new_flags "-fstdcall" )
            elseif (flag STREQUAL "/Gv")
                list( APPEND new_flags "-fvectorcall" )

                # Buffer security
            elseif (flag STREQUAL "/GS")
                list( APPEND new_flags "-fstack-protector" )
            elseif (flag STREQUAL "/GS-")
                list( APPEND new_flags "-fno-stack-protector" )

                # Function sections
            elseif (flag STREQUAL "/Gy")
                list( APPEND new_flags "-ffunction-sections" )
            elseif (flag STREQUAL "/Gy-")
                list( APPEND new_flags "-fno-function-sections" )

                # Data sections
            elseif (flag STREQUAL "/Gw")
                list( APPEND new_flags "-fdata-sections" )
            elseif (flag STREQUAL "/Gw-")
                list( APPEND new_flags "-fno-data-sections" )

                # Floating point
            elseif (flag STREQUAL "/fp:fast")
                list( APPEND new_flags "-ffast-math" )
            elseif (flag STREQUAL "/fp:precise")
                list( APPEND new_flags "-ffp-model=precise" )
            elseif (flag STREQUAL "/fp:strict")
                list( APPEND new_flags "-ffp-model=strict" )

                # Warning levels
            elseif (flag STREQUAL "/W0" OR flag STREQUAL "/w")
                list( APPEND new_flags "-w" )
            elseif (flag STREQUAL "/W1" OR flag STREQUAL "/W2" OR flag STREQUAL "/W3")
                list( APPEND new_flags "-Wall" )
            elseif (flag STREQUAL "/W4")
                list( APPEND new_flags "-Wall" "-Wextra" )
            elseif (flag STREQUAL "/Wall")
                list( APPEND new_flags "-Weverything" )
            elseif (flag STREQUAL "/WX")
                list( APPEND new_flags "-Werror" )
            elseif (flag STREQUAL "/WX-")
                list( APPEND new_flags "-Wno-error" )

                # Language standards
            elseif (flag MATCHES "^/std:c\\+\\+([0-9]+)$")
                list( APPEND new_flags "-std=c++${CMAKE_MATCH_1}" )
            elseif (flag MATCHES "^/std:c([0-9]+)$")
                list( APPEND new_flags "-std=c${CMAKE_MATCH_1}" )

                # Preprocessing
            elseif (flag STREQUAL "/E")
                list( APPEND new_flags "-E" )
            elseif (flag STREQUAL "/EP")
                list( APPEND new_flags "-E" "-P" )
            elseif (flag STREQUAL "/P")
                list( APPEND new_flags "-E" "-o" "${CMAKE_CURRENT_BINARY_DIR}/preprocessed.i" )

                # Include directories
            elseif (flag MATCHES "^/I[ ]?(.+)$")
                list( APPEND new_flags "-I${CMAKE_MATCH_1}" )

                # Macros
            elseif (flag MATCHES "^/D[ ]?([^ =]+)=?(.*)$")
                if ("${CMAKE_MATCH_2}" STREQUAL "")
                    list( APPEND new_flags "-D${CMAKE_MATCH_1}" )
                else ()
                    list( APPEND new_flags "-D${CMAKE_MATCH_1}=${CMAKE_MATCH_2}" )
                endif ()
            elseif (flag MATCHES "^/U[ ]?(.+)$")
                list( APPEND new_flags "-U${CMAKE_MATCH_1}" )

                # Char type
            elseif (flag STREQUAL "/J")
                list( APPEND new_flags "-funsigned-char" )

                # Utf-8
            elseif (flag STREQUAL "/utf-8")
                list( APPEND new_flags "-finput-charset=UTF-8" "-fexec-charset=UTF-8" )

                # Zc flags (conformance)
            elseif (flag STREQUAL "/Zc:char8_t")
                list( APPEND new_flags "-fchar8_t" )
            elseif (flag STREQUAL "/Zc:char8_t-")
                list( APPEND new_flags "-fno-char8_t" )
            elseif (flag STREQUAL "/Zc:strictStrings")
                list( APPEND new_flags "-fno-writable-strings" )
            elseif (flag STREQUAL "/Zc:threadSafeInit")
                list( APPEND new_flags "-fthreadsafe-statics" )
            elseif (flag STREQUAL "/Zc:threadSafeInit-")
                list( APPEND new_flags "-fno-threadsafe-statics" )
            elseif (flag STREQUAL "/Zc:trigraphs")
                list( APPEND new_flags "-ftrigraphs" )
            elseif (flag STREQUAL "/Zc:trigraphs-")
                list( APPEND new_flags "-fno-trigraphs" )

                # Show includes
            elseif (flag STREQUAL "/showIncludes")
                list( APPEND new_flags "-H" )

                # Vectorization
            elseif (flag STREQUAL "/Qvec")
                list( APPEND new_flags "-fvectorize" )
            elseif (flag STREQUAL "/Qvec-")
                list( APPEND new_flags "-fno-vectorize" )

                # Source and execution charset
            elseif (flag MATCHES "^/source-charset:(.+)$")
                list( APPEND new_flags "-finput-charset=${CMAKE_MATCH_1}" )
            elseif (flag MATCHES "^/execution-charset:(.+)$")
                list( APPEND new_flags "-fexec-charset=${CMAKE_MATCH_1}" )

                # Force include
            elseif (flag MATCHES "^/FI[ ]?(.+)$")
                list( APPEND new_flags "-include" "${CMAKE_MATCH_1}" )

                # Treat all sources as C/C++
            elseif (flag STREQUAL "/TC")
                list( APPEND new_flags "-x" "c" )
            elseif (flag STREQUAL "/TP")
                list( APPEND new_flags "-x" "c++" )
            elseif (flag MATCHES "^/Tc[ ]?(.+)$")
                # For individual files, add to sources with explicit language
                set_source_files_properties( ${CMAKE_MATCH_1} PROPERTIES LANGUAGE C )
            elseif (flag MATCHES "^/Tp[ ]?(.+)$")
                # For individual files, add to sources with explicit language
                set_source_files_properties( ${CMAKE_MATCH_1} PROPERTIES LANGUAGE CXX )

                # Volatile semantics
            elseif (flag STREQUAL "/volatile:iso")
                list( APPEND new_flags "-fstrict-volatile-bitfields" )
            elseif (flag STREQUAL "/volatile:ms")
                list( APPEND new_flags "-fms-volatile" )

                # Disable comments in preprocessing
            elseif (flag STREQUAL "/C")
                list( APPEND new_flags "-C" )

                # Precompiled headers
            elseif (flag MATCHES "^/Yc(.*)$")
                # Create precompiled header - more complex handling needed
                set( pch_file "${CMAKE_MATCH_1}" )
                # In real usage, would need more complex PCH setup
            elseif (flag MATCHES "^/Yu(.*)$")
                # Use precompiled header - more complex handling needed
                set( pch_file "${CMAKE_MATCH_1}" )
                # In real usage, would need more complex PCH setup
            elseif (flag STREQUAL "/Y-")
                # Disable precompiled headers
                # No direct flag, would need to unset PCH properties

                # Disable default include paths
            elseif (flag STREQUAL "/X")
                list( APPEND new_flags "-nostdinc" )

                # Output files
            elseif (flag MATCHES "^/Fo(.+)$")
                list( APPEND new_flags "-o" "${CMAKE_MATCH_1}" )
            elseif (flag MATCHES "^/Fe(.+)$")
                # Handle in link options instead
                set_target_properties( ${target} PROPERTIES OUTPUT_NAME "${CMAKE_MATCH_1}" )
            elseif (flag MATCHES "^/Fi(.+)$")
                list( APPEND new_flags "-E" "-o" "${CMAKE_MATCH_1}" )
            elseif (flag MATCHES "^/Fa(.+)$")
                list( APPEND new_flags "-save-temps" "-o" "${CMAKE_MATCH_1}" )

                # Struct packing
            elseif (flag MATCHES "^/Zp([0-9]*)$")
                if ("${CMAKE_MATCH_1}" STREQUAL "")
                    list( APPEND new_flags "-fpack-struct=1" )
                else ()
                    list( APPEND new_flags "-fpack-struct=${CMAKE_MATCH_1}" )
                endif ()

                # Sized deallocation
            elseif (flag STREQUAL "/Zc:sizedDealloc")
                list( APPEND new_flags "-fsized-deallocation" )
            elseif (flag STREQUAL "/Zc:sizedDealloc-")
                list( APPEND new_flags "-fno-sized-deallocation" )

                # Two-phase name lookup
            elseif (flag STREQUAL "/Zc:twoPhase")
                list( APPEND new_flags "-frelaxed-template-template-args" )
            elseif (flag STREQUAL "/Zc:twoPhase-")
                list( APPEND new_flags "-fno-delayed-template-parsing" )

                # Don't emit default libraries
            elseif (flag STREQUAL "/Zl")
                list( APPEND new_flags "-fno-use-cxa-atexit" )

                # Control Flow Guard
            elseif (flag MATCHES "^/guard:cf$")
                # No direct equivalent in clang/gcc, skip or use MS compatibility flag

                # Stack probes
            elseif (flag MATCHES "^/Gs([0-9]*)$")
                if ("${CMAKE_MATCH_1}" STREQUAL "")
                    # Default value, no change needed
                else ()
                    list( APPEND new_flags "-mstack-probe-size=${CMAKE_MATCH_1}" )
                endif ()

                # Runtime
            elseif (flag STREQUAL "/MT")
                # Static runtime - no direct equivalent, handled at linker level
                continue()
            elseif (flag STREQUAL "/MTd")
                # Static debug runtime - no direct equivalent, handled at linker level
                continue()
            elseif (flag STREQUAL "/MD")
                # Dynamic runtime - no direct equivalent, handled at linker level
                continue()
            elseif (flag STREQUAL "/MDd")
                # Dynamic debug runtime - no direct equivalent, handled at linker level
                continue()
                # Keep the flag if no mapping is found or it's a clang direct pass flag
            elseif (flag MATCHES "^/clang:(.+)$")
                list( APPEND new_flags "${CMAKE_MATCH_1}" )
            else ()
                # Check for compilation only
                if (flag STREQUAL "/c")
                    # This is usually handled by CMake's build system already
                    # But we can add it explicitly if needed
                    list( APPEND new_flags "-c" )
                    # Check for reproducible builds
                elseif (flag STREQUAL "/Brepro")
                    list( APPEND new_flags "-fdebug-compilation-dir=." "-ffile-compilation-dir=." )
                elseif (flag STREQUAL "/Brepro-")
                    # Default behavior, no flag needed
                    # Check for implementation-defined vtable layout
                elseif (flag MATCHES "^/vd([0-9])$")
                    # No direct equivalent, MS-specific
                    # Check for member pointer representation
                elseif (flag MATCHES "^/vm[bgmsv]$")
                    # No direct equivalent, MS-specific
                    # Semantic analyzer
                elseif (flag STREQUAL "/Zs")
                    list( APPEND new_flags "-fsyntax-only" )
                    # Diagnostics formatting
                elseif (flag MATCHES "^/diagnostics:(caret|classic|column)$")
                    list( APPEND new_flags "-fdiagnostics-format=${CMAKE_MATCH_1}" )
                    # If no direct mapping exists, keep the original flag but log a warning
                else ()
                    # If no direct mapping exists, keep the original flag but log a warning
                    if (flag MATCHES "^/")
                        message( WARNING "Unsupported MSVC flag: ${flag} - not converting" )
                        # Keep the original flag with slash for MSVC compatibility
                        list( APPEND new_flags "${flag}" )
                    else ()
                        list( APPEND new_flags "${flag}" )
                    endif ()
                endif ()
            endif ()


        endforeach ()

        set( ${out} "${new_flags}" )
    endmacro()

    # split on whitespace
    string( REGEX MATCHALL "[^ ]+" _flags "${_result}" )
    map_flag( _flags _mapped_flags )

    # Join the mapped flags back together
    string( REPLACE ";" " " _result "${_mapped_flags}" )

    # Remove any extra whitespace from the result
    string( STRIP "${_result}" _result )
    set( ${OUTPUT_VAR} "${_result}" PARENT_SCOPE )
endfunction()


message( STATUS "Looking for possible LLVM installation" )
if (DEFINED ENV{LLVMInstallDir})
    file( TO_CMAKE_PATH "$ENV{LLVMInstallDir}/bin" POSSIBLE_LLVM_BIN_DIR )
else ()

    if (WIN32)
        # Get Program Files root to lookup possible LLVM installation
        if (DEFINED ENV{ProgramW6432})
            file( TO_CMAKE_PATH "$ENV{ProgramW6432}" PROG_ROOT )
        else ()
            file( TO_CMAKE_PATH "$ENV{PROGRAMFILES}" PROG_ROOT )
        endif ()
        file( TO_CMAKE_PATH "${PROG_ROOT}/LLVM/bin" POSSIBLE_LLVM_BIN_DIR )
    else ()
        file( TO_CMAKE_PATH "" POSSIBLE_LLVM_BIN_DIR )
    endif ()

endif ()

if (EXISTS "${POSSIBLE_LLVM_BIN_DIR}" AND NOT POSSIBLE_LLVM_BIN_DIR STREQUAL "")
    set( windows_defs "/DWIN32" )
    if (VCPKG_TARGET_ARCHITECTURE STREQUAL x64)
        string( APPEND windows_defs " /D_WIN64" )
    endif ()
    string( APPEND windows_defs " /D_WIN32_WINNT=0x0A00 /DWINVER=0x0A00" ) # tweak for targeted windows
    string( APPEND windows_defs " /D_CRT_SECURE_NO_DEPRECATE /D_CRT_SECURE_NO_WARNINGS /D_CRT_NONSTDC_NO_DEPRECATE" )
    string( APPEND windows_defs " /D_ATL_SECURE_NO_DEPRECATE /D_SCL_SECURE_NO_WARNINGS" )
    string( APPEND windows_defs " /D_CRT_INTERNAL_NONSTDC_NAMES /D_CRT_DECLARE_NONSTDC_NAMES" ) # due to -D__STDC__=1 required for e.g. _fopen -> fopen and other not underscored functions/defines
    string( APPEND windows_defs " /D_FORCENAMELESSUNION" ) # Due to -D__STDC__ to access tagVARIANT members (ffmpeg)


    if (NOT INSIDE_TRIPLET)
        if ((VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore") OR (CMAKE_SYSTEM_NAME STREQUAL "WindowsStore"))
            include( "$ENV{VCPKG_ROOT}/scripts/toolchains//uwp.cmake" )
        elseif (DEFINED XBOX_CONSOLE_TARGET)
            include( "$ENV{VCPKG_ROOT}/scripts/toolchains//xbox.cmake" )
        else ()
            include( "$ENV{VCPKG_ROOT}/scripts/toolchains/windows.cmake" )
        endif ()

        unset( MSVC )
        if (VCPKG_TARGET_ARCHITECTURE STREQUAL x64)
            string( APPEND windows_defs " /D_WIN64" )
        endif ()

    else ()
        # Try to ignore /WX and -werror; A lot of ports mess up the compiler detection and add wrong flags!
        set( ignore_werror "/WX-" )
        cmake_language( DEFER CALL add_compile_options "/WX-" ) # make sure the flag is added at the end!
    endif ()

    set( LLVMInstallDir "${POSSIBLE_LLVM_BIN_DIR}/../" )
    cmake_path( SET LLVMInstallDir "${LLVMInstallDir}" NORMALIZE )

    set( ENV{LLVMInstallDir} "${LLVMInstallDir}" )
    message( "...found at ${LLVMInstallDir}" )

    cmake_path( SET llvmbin "$ENV{LLVMInstallDir}/bin" NORMALIZE )
    string( REPLACE "\"" "" llvmbin "${llvmbin}" )
    find_program( CMAKE_C_COMPILER "clang.exe" PATHS "${llvmbin}" REQUIRED NO_DEFAULT_PATH DOC "C Compiler" )
    find_program( CMAKE_CXX_COMPILER "clang++.exe" PATHS "${llvmbin}" REQUIRED NO_DEFAULT_PATH DOC "C++ Compiler" )
    find_program( CMAKE_AR "llvm-ar.exe" PATHS "${llvmbin}" REQUIRED NO_DEFAULT_PATH DOC "Archiver" )
    find_program( CMAKE_RC_COMPILER "llvm-rc.exe" PATHS "${llvmbin}" REQUIRED NO_DEFAULT_PATH DOC "Resource Compiler" )
    find_program( CMAKE_LINKER "lld-link.exe" PATHS "${llvmbin}" REQUIRED NO_DEFAULT_PATH DOC "Linker" )
    find_program( CMAKE_RANLIB "llvm-ranlib.exe" PATHS "${llvmbin}" REQUIRED NO_DEFAULT_PATH DOC "Ranlib" )

    set( CMAKE_ASM_MASM_COMPILER "ml64.exe" CACHE FILEPATH "MASM Compiler" )
    set( CMAKE_CXX_COMPILER_ID "Clang" CACHE STRING "C++ Compiler ID" FORCE )
    set( CMAKE_C_COMPILER_ID "Clang" CACHE STRING "C Compiler ID" FORCE )


    #    if (VCPKG_TARGET_ARCHITECTURE STREQUAL x64)
    #        set( CMAKE_C_COMPILER_TARGET "x86_64-windows-gnu" CACHE STRING "Compiler target" FORCE )
    #        set( CMAKE_CXX_COMPILER_TARGET "x86_64-windows-gnu" CACHE STRING "Compiler target" FORCE )
    #    elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL x86)
    #        set( CMAKE_C_COMPILER_TARGET "i686-windows-gnu" CACHE STRING "Compiler target" FORCE )
    #        set( CMAKE_CXX_COMPILER_TARGET "i686-windows-gnu" CACHE STRING "Compiler target" FORCE )
    #    endif ()
    #
    cmake_path( ABSOLUTE_PATH CMAKE_CXX_COMPILER NORMALIZE )
    cmake_path( ABSOLUTE_PATH CMAKE_C_COMPILER NORMALIZE )

    ### CUDA section nvcc

    if (NOT CUDA_C_COMPILER)
        # Due to nvcc error   : 'cudafe++' died with status 0xC0000409 |  clang-cl cannot currently be used to compile cu files.
        # The CUDA frontend probably has problems parsing preprocessed files from clang-cl
        find_program( CL_COMPILER NAMES cl )
        set( CUDA_C_COMPILER "${CL_COMPILER}" )
    endif ()

    string( APPEND CMAKE_CUDA_FLAGS " --keep --use-local-env --allow-unsupported-compiler -ccbin \"${CUDA_C_COMPILER}\"" )

    ### CUDA section clang (requires cmake changes)

    set( CLANG_C_LTO_FLAGS "-fuse-ld=lld-link" )
    set( CLANG_CXX_LTO_FLAGS "-fuse-ld=lld-link" )
    if (VCPKG_USE_LTO)
        set( CLANG_C_LTO_FLAGS "-flto -fuse-ld=lld-link" )
        set( CLANG_CXX_LTO_FLAGS "-flto -fuse-ld=lld-link -fwhole-program-vtables" )
    endif ()


    set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS}" )
    set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libstdc++" )

    set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${windows_defs} ${ignore_werror}" )
    set( CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${windows_defs} ${ignore_werror} " )
    set( CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} ${windows_defs} ${CLANG_C_LTO_FLAGS} ${ignore_werror}" )
    set( CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO} ${windows_defs} ${CLANG_C_LTO_FLAGS} ${ignore_werror}" )

    set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${windows_defs} ${ignore_werror}" )
    set( CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${windows_defs} ${ignore_werror}" )
    set( CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${windows_defs} ${CLANG_CXX_LTO_FLAGS} ${ignore_werror}" )
    set( CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL} ${windows_defs} ${CLANG_CXX_LTO_FLAGS} ${ignore_werror}" )
    set( CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} ${windows_defs} ${CLANG_CXX_LTO_FLAGS} ${ignore_werror}" )


    list( APPEND _transform_vars
        VCPKG_CRT_LINK_FLAG_PREFIX
        VCPKG_SET_CHARSET_FLAG
        VCPKG_C_FLAGS VCPKG_CXX_FLAGS
        VCPKG_C_FLAGS_DEBUG VCPKG_CXX_FLAGS_DEBUG
        VCPKG_C_FLAGS_RELEASE VCPKG_CXX_FLAGS_RELEASE
        VCPKG_LINKER_FLAGS VCPKG_LINKER_FLAGS_RELEASE VCPKG_LINKER_FLAGS_DEBUG
        CMAKE_C_FLAGS_DEBUG CMAKE_CXX_FLAGS_DEBUG
        CMAKE_C_FLAGS_RELEASE CMAKE_CXX_FLAGS_RELEASE
        CMAKE_C_FLAGS CMAKE_CXX_FLAGS
        CMAKE_C_FLAGS_INIT CMAKE_CXX_FLAGS_INIT
        CMAKE_C_FLAGS_DEBUG_INIT CMAKE_CXX_FLAGS_DEBUG_INIT
        CMAKE_C_FLAGS_RELEASE_INIT CMAKE_CXX_FLAGS_RELEASE_INIT
        CMAKE_C_FLAGS_MINSIZEREL_INIT CMAKE_CXX_FLAGS_MINSIZEREL_INIT
        CMAKE_C_FLAGS_RELWITHDEBINFO_INIT CMAKE_CXX_FLAGS_RELWITHDEBINFO_INIT
        CMAKE_EXE_LINKER_FLAGS CMAKE_EXE_LINKER_FLAGS_DEBUG CMAKE_EXE_LINKER_FLAGS_RELEASE
        CMAKE_EXE_LINKER_FLAGS_MINSIZEREL CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO
        CMAKE_SHARED_LINKER_FLAGS CMAKE_SHARED_LINKER_FLAGS_DEBUG CMAKE_SHARED_LINKER_FLAGS_RELEASE
        CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO
        CMAKE_MODULE_LINKER_FLAGS CMAKE_MODULE_LINKER_FLAGS_DEBUG CMAKE_MODULE_LINKER_FLAGS_RELEASE
        CMAKE_MODULE_LINKER_FLAGS_MINSIZEREL CMAKE_MODULE_LINKER_FLAGS_RELWITHDEBINFO
        )

    foreach (var IN LISTS _transform_vars)
        msvc_to_clang( "${${var}}" "${var}" )
        message( STATUS "After ${var}: ${${var}}" )
    endforeach ()


    set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS}" CACHE STRING "" FORCE )
    set( CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG}" CACHE STRING "" FORCE )
    set( CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}" CACHE STRING "" FORCE )
    set( CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL}" CACHE STRING "" FORCE )
    set( CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO}" CACHE STRING "" FORCE )

    set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}" CACHE STRING "" FORCE )
    set( CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}" CACHE STRING "" FORCE )
    set( CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}" CACHE STRING "" FORCE )
    set( CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL}" CACHE STRING "" FORCE )
    set( CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}" CACHE STRING "" FORCE )


    unset( _transform_vars )
    unset( windows_defs )
    unset( ignore_werror )
else ()
    message( "...LLVM not found" )
endif ()


if (LLVMInstallDir)
    message( "...compiler found (C++): ${CMAKE_CXX_COMPILER}" )
    message( "...compiler found (C): ${CMAKE_C_COMPILER}" )
endif ()

string( APPEND CMAKE_C_FLAGS_INIT "${VCPKG_C_FLAGS} " )
string( APPEND CMAKE_CXX_FLAGS_INIT " ${VCPKG_CXX_FLAGS} " )
string( APPEND CMAKE_C_FLAGS_DEBUG_INIT " ${VCPKG_C_FLAGS_DEBUG} " )
string( APPEND CMAKE_CXX_FLAGS_DEBUG_INIT " ${VCPKG_CXX_FLAGS_DEBUG} " )
string( APPEND CMAKE_C_FLAGS_RELEASE_INIT " ${VCPKG_C_FLAGS_RELEASE} " )
string( APPEND CMAKE_CXX_FLAGS_RELEASE_INIT " ${VCPKG_CXX_FLAGS_RELEASE} " )

macro( toolchain_set_cmake_policy_new )
    if (POLICY ${ARGN})
        cmake_policy( SET ${ARGN} NEW )
    endif ()
endmacro()
# Setup policies
toolchain_set_cmake_policy_new( CMP0137 )
toolchain_set_cmake_policy_new( CMP0128 )
toolchain_set_cmake_policy_new( CMP0126 )
toolchain_set_cmake_policy_new( CMP0117 )
toolchain_set_cmake_policy_new( CMP0092 )
toolchain_set_cmake_policy_new( CMP0091 )
toolchain_set_cmake_policy_new( CMP0012 )
unset( toolchain_set_cmake_policy_new )
