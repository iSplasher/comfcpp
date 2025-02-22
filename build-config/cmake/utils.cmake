include_guard( GLOBAL )

function( gnu_to_clangcl INPUT_FLAGS OUTPUT_VAR )
    # Start with the input string
    set( _result "${INPUT_FLAGS}" )

    macro( map_flag input_flags out )
        set( new_flags "" )
        foreach (flag IN LISTS ${input_flags})
            # Map every prefix every gnu flag with /clang
            if (flag MATCHES "^-")
                list( APPEND new_flags "/clang:${flag}" )
            else ()
                list( APPEND new_flags "${flag}" )
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
