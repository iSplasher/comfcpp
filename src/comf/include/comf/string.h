/**
* \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once

#include <string>
#include <string_view>
#include <ranges>

#include "comf/constants.h"
#include "comf/concepts.h"


namespace
COMF_NAMESPACE {

using str_char = char;
using str      = std::string;
using str_view = std::string_view;
using strpos   = std::streampos;


namespace meta {
    template< typename T >
    concept OtherStringType = ( !std::is_same_v< T, str > && !std::is_same_v< T, str_char > ) &&
                              ( std::is_same_v< T, const char* >
                                || std::is_same_v< T, const char8_t* >
                                || std::is_same_v< T, const char16_t* >
                                || std::is_same_v< T, const char32_t* >
                                || std::is_same_v< T, const wchar_t* >
                                || std::is_convertible_v< T, std::string >
                                || std::is_convertible_v< T, std::string_view >
                                || std::is_convertible_v< T, std::wstring >
                                || std::is_convertible_v< T, std::u8string_view >
                                || std::is_convertible_v< T, std::u8string >
                                || std::is_convertible_v< T, std::u16string_view >
                                || std::is_convertible_v< T, std::u16string >
                                || std::is_convertible_v< T, std::u32string_view >
                                || std::is_convertible_v< T, std::u32string >
                                || std::is_convertible_v< T, std::wstring_view >
                                || std::is_convertible_v< T, std::wstring > );
}


IMPLEMENTATION_START
    template< std::size_t N >
    struct ToStringLiteral {
        str data;

        constexpr ToStringLiteral( const char ( &pp )[N] )
            : data( pp ) { }
    };


    template< std::size_t N >
    struct ToStringViewLiteral {
        str_view data;

        constexpr ToStringViewLiteral( const char ( &pp )[N] )
            : data( pp, N - 1 ) { }
    };


    IMPLEMENTATION_END


constexpr auto operator""_str( const char* s, const std::size_t len ) {
    return str( s, len );
}

constexpr auto operator""_strv( const char* s, const std::size_t len ) {
    return str_view( s, len );
}


}


namespace
COMF_UTIL_NAMESPACE {

struct string_util {


    template< typename Xs >
    [[nodiscard]] static constexpr str&& join( Xs&& xs, const str_view sep ) {
        return meta::impl::hana::fold(
                                      meta::impl::hana::intersperse( std::forward< Xs >( xs ), sep ),
                                      "", meta::impl::hana::_ + meta::impl::hana::_ );
    }

    [[nodiscard]] static constexpr str&& quote( const str_view s ) { return "\""_str + str( s ) + "\""_str; }
    [[nodiscard]] static constexpr str&& quote( const str_char* s ) { return "\""_str + s + "\""_str; }


};

}
