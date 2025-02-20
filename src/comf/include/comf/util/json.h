/**
* \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once

#include "comf/string.h"
#include "comf/concepts.h"


namespace
COMF_UTIL_NAMESPACE {

struct json_util {

    template< typename T >
    [[nodiscard]] static constexpr auto to_json( T const& x ) -> decltype(std::to_string( x )) {
        return std::to_string( x );
    }

    [[nodiscard]] static constexpr str&& to_json( const str_char* c ) { return string_util::quote( c ); }
    [[nodiscard]] static constexpr str&& to_json( const str_view s ) { return string_util::quote( s ); }

    template< typename Xs >
    std::enable_if_t< meta::IsSequence< Xs >, str_view > to_json( Xs const& xs ) {
        auto json = meta::transform( xs, []( auto const& x ) {
            return to_json( x );
        } );

        return "["_strv + join( std::move( json ), ", "_strv ) + "]"_strv;
    }

    template< typename T >
    std::enable_if_t< meta::IsStruct< T >, str > to_json( T const& x ) {
        auto json = meta::transform( meta::impl::hana::keys( x ), [&]( auto name ) {
            auto const& member = meta::impl::hana::at_key( x, name );
            return quote( meta::impl::hana::to< str_char const* >( name ) ) + " : "_strv + to_json( member );
        } );

        return "{"_strv + join( std::move( json ), ", "_strv ) + "}"_strv;
    }


};

}
