/**
 * \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once
// ReSharper disable once CppUnusedIncludeDirective
#include "comf/private/_constants.h"
// ReSharper disable once CppUnusedIncludeDirective
#include "comf/assert.h"
// ReSharper disable once CppUnusedIncludeDirective
#include "comf/embed.h"


namespace
COMF_NAMESPACE {
IMPLEMENTATION_START
    template< bool T >
    struct TrueType {
        // intentionally implicit
        constexpr TrueType( bool v ) {
            app_static_assert( T == true, "TrueType must be the bool true" );
        }

        static constexpr bool value = true;

        constexpr operator bool() const {
            return value;
        }

        constexpr bool operator==( const TrueType & ) const {
            return true;
        }

        constexpr bool operator==( const bool &v ) const {
            return v == true;
        }
    };


    IMPLEMENTATION_END}
