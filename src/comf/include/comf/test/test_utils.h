/**
 * \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once
#define CATCH_CONFIG_DISABLE_EXCEPTIONS

#include <concepts>
#include <catch2/catch_test_macros.hpp>
#include <fmt/format.h>

#include "comf/constants.h"


namespace
COMF_NAMESPACE {

// helper
template< typename T, typename Context, typename Formatter = Context::template formatter_type< std::remove_const_t< T > > >
concept FormattableWithHelper = std::semiregular< Formatter > &&
                                requires( Formatter& f, const Formatter& cf, T&& t, Context fc, fmt::basic_format_parse_context< typename Context::char_type > pc )
                                {
                                    { f.parse( pc ) } -> std::same_as< typename decltype(pc)::iterator >;
                                    { cf.format( t, fc ) } -> std::same_as< typename Context::iterator >;
                                };

// check if type is formattable with std::format
template< typename T, typename CharT = char >
concept Formattable = FormattableWithHelper< std::remove_reference_t< T >, fmt::basic_format_context< std::back_insert_iterator< fmt::detail::buffer< CharT > >, CharT > >;

}


// Catch2 StringMaker specialization
namespace Catch {

template< COMF_NAMESPACE::Formattable T >
struct StringMaker< T > {
    static std::string convert( const T& t ) {
        return fmt::format( "{}", t );
    }
};

}
