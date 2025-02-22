/**
* \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once

#include <string>
#include <string_view>
#include <ranges>
#include <ztd/text.hpp>
#include <ranges>
#include <concepts>


#include "comf/constants.h"
#include "comf/concepts.h"


namespace
COMF_NAMESPACE {

using str_char = char;
using str      = std::string;
using str_view = std::string_view;
using strpos   = std::streampos;

// Compile-time string type using Hana
template< typename CharT, CharT... chars >
using compstr_t = meta::impl::hana::string< chars... >;


// Concept for string-like types
template< typename T >
concept IsStringLike = std::is_convertible_v< T, str_view >;

// Concept for string container types
template< typename T >
concept IsStringContainer = requires( T t )
{
    typename T::value_type;
    requires IsStringLike< typename T::value_type >;
    { t.begin() } -> std::input_iterator;
    { t.end() } -> std::input_iterator;
};


namespace meta {
    template< typename T >
    concept OtherStringType = ( !std::is_same_v< T, str > && !std::is_same_v< T, str_char > ) &&
                              ( std::is_same_v< T, const char* >
                                || std::is_same_v< T, const char8_t* >
                                || std::is_same_v< T, const char16_t* >
                                || std::is_same_v< T, const char32_t* >
                                || std::is_same_v< T, const wchar_t* >
                                || std::is_convertible_v< T, std::string_view >
                                || std::is_convertible_v< T, std::string >
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

        constexpr ToStringLiteral( const char (& pp)[ N ] )
            : data( pp ) { }
    };


    template< std::size_t N >
    struct ToStringViewLiteral {
        str_view data;

        constexpr ToStringViewLiteral( const char (& pp)[ N ] )
            : data( pp, N - 1 ) { }
    };


    // Helper to efficiently convert to string_view
    template< IsStringLike T >
    constexpr auto to_view( T &&s ) {
        if constexpr( std::is_same_v< std::remove_cvref_t< T >, str_view > ) {
            return s;
        } else {
            return str_view{ std::forward< T >( s ) };
        }
    }

    // Helper to deduce return type based on input
    template< IsStringLike T >
    using string_return_t = std::conditional_t<
        std::is_lvalue_reference_v< T >,
        str_view,
        str
    >;


    IMPLEMENTATION_END


namespace meta {
    IMPLEMENTATION_START

        // Convert string_view to hana::string at compile time
        template< size_t N >
        constexpr auto to_hana_string( const char (& str)[ N ] ) {
            return hana::make_string( str );
        }

        IMPLEMENTATION_END


    constexpr auto to_runtime_string( auto &&xs ) {
        if constexpr( IsHanaStringCompatible< std::remove_cvref_t< decltype(xs) > > ) {
            return impl::hana::to< const char* >( std::forward< decltype(xs) >( xs ) );
        } else {
            return str_view{ std::forward< decltype(xs) >( xs ) };
        }
    }

}


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

    // [[nodiscard]] static constexpr str&& join( auto &&xs, const str_view sep ) {
    //     return meta::impl::hana::fold(
    //                                   meta::impl::hana::intersperse( std::forward< decltype(xs) >( xs ), sep ),
    //                                   "",
    //                                   meta::impl::hana::_ + meta::impl::hana::_ );
    // }

    [[nodiscard]]
    static constexpr auto join( auto &&container, auto &&delim ) {
        auto hdel = meta::impl::hana::make_string( meta::to_runtime_string( std::forward< decltype(delim) >( delim ) ) );

        // Convert container to Hana tuple
        auto htuple = meta::impl::hana::to_tuple( std::forward< decltype(container) >( container ) );

        // Use Hana algorithms to join strings
        return meta::impl::hana::fold_left(
                                           meta::impl::hana::drop_front( htuple ),
                                           meta::impl::hana::front( htuple ),
                                           [hdel]( auto acc, auto elem ) {
                                               return acc + hdel + meta::impl::hana::make_string( meta::to_runtime_string( elem ) );
                                           }
                                          );
    }


    [[nodiscard]] static constexpr str&& quote( const str_view s ) { return "\""_str + str( s ) + "\""_str; }
    [[nodiscard]] static constexpr str&& quote( const str_char* s ) { return "\""_str + s + "\""_str; }


    [[nodiscard]]
    static constexpr auto trim( auto &&str )
        requires meta::IsHanaStringCompatible< std::remove_cvref_t< decltype(str) > > {
        namespace rv = std::ranges::views;

        // Convert to Hana string if possible
        auto hstr = meta::impl::hana::make_string( meta::to_runtime_string( std::forward< decltype(str) >( str ) ) );

        // Create compile-time lambdas for whitespace checking
        constexpr auto is_space  = BOOST_HANA_STRING( " \f\t\n\r" );
        constexpr auto not_space = []( auto c ) {
            return meta::impl::hana::find( is_space, c ) == meta::impl::hana::nothing;
        };

        // Use Hana algorithms for trimming
        auto trimmed = meta::impl::hana::drop_while( hstr,
                                                     []( auto c ) {
                                                         return !not_space( c );
                                                     } );
        trimmed = meta::impl::hana::reverse( meta::impl::hana::drop_while(
                                                                          meta::impl::hana::reverse( trimmed ),
                                                                          []( auto c ) { return !not_space( c ); }
                                                                         ) );

        return trimmed;
    }

    template< IsStringLike T >
    [[nodiscard]]
    static constexpr auto trim( T &&xs ) -> impl::string_return_t< T&& >
        requires ( !meta::IsHanaStringCompatible< std::remove_cvref_t< T > > ) {
        using std::ranges::find_if;
        using CharT = std::remove_reference_t< decltype(xs[ 0 ]) >;

        auto view = impl::to_view( std::forward< T >( xs ) );

        constexpr auto not_space = []( CharT c ) {
            return !std::isspace( static_cast< unsigned char >( c ) );
        };

        auto start = find_if( view, not_space );
        auto end   = find_if( view | std::views::reverse, not_space ).base();

        if( start >= end ) {
            if constexpr( std::is_lvalue_reference_v< T > ) {
                return std::string_view{};
            } else {
                return std::string{};
            }
        }

        auto result = view.substr( start - view.begin(), end - start );

        if constexpr( std::is_lvalue_reference_v< T > ) {
            return result;
        } else {
            return std::string{ result };
        }
    }


    template< typename OutputView = str_view, typename U = str_view >
    [[nodiscard]]
    static constexpr auto&& to_utf8( U &s ) {
        throw std::logic_error( "Not implemented" );

        OutputView out( reinterpret_cast< const typename OutputView::value_type* >( s.data() ), s.size() );

        auto out_range = ztd::ranges::make_subrange( out );

        auto result = ztd::text::transcode_into( s, ztd::text::utf8, out_range, ztd::text::compat_utf8, ztd::text::replacement_handler );

        return out;
    }

    template< typename OutputView = str_view, typename InputView = str_view >
    [[nodiscard]]
    static constexpr OutputView&& to_view( InputView &s ) noexcept {
        return OutputView{ reinterpret_cast< const typename OutputView::value_type* >( s.data() ), s.size() };
    }


};


template< char... chars >
struct compstr {
    static constexpr auto value = meta::impl::hana::string_c< chars... >;

    // Enable compile-time operations
    static constexpr auto trim() {
        return string_util::trim( value );
    }

    //     template< char... other >
    //     static constexpr auto split( ct_string< other... > ) {
    //         return smake::split( value, ct_string< other... >::value );
    //     }
    //
    //     template< char... other >
    //     static constexpr auto replace_all( ct_string< other... > from, ct_string< other... > to ) {
    //         return smake::replace_all( value, from.value, to.value );
    //     }
};


}


namespace
COMF_NAMESPACE {
using string_util = COMF_UTIL_NAMESPACE::string_util;
}
