/**
 * \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once
#define CATCH_CONFIG_DISABLE_EXCEPTIONS

#include <concepts>
#include <catch2/catch_test_macros.hpp>
#include <catch2/catch_template_test_macros.hpp>
#include <catch2/catch_approx.hpp>
#include <catch2/generators/catch_generators_all.hpp>
#include <fmt/format.h>
#include <initializer_list>


#include "common/constants.h"


namespace
APP_NAMESPACE {

// helper
template< typename T, typename Context, typename Formatter = Context::template formatter_type< std::remove_const_t< T > > >
concept FormattableWithHelper = std::semiregular< Formatter > &&
                                requires( Formatter &f, const Formatter &cf, T &&t, Context fc, fmt::basic_format_parse_context< typename Context::char_type > pc )
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

template< APP_NAMESPACE::Formattable T >
struct StringMaker< T > {
    static std::string convert( const T &t ) {
        return fmt::format( "{}", t );
    }
};

}


// Generators

namespace {

// This class implements a simple generator for Catch tests using modern C++ features
template< typename... Ts >
class TupleValuesGenerator final : public Catch::Generators::IGenerator< std::tuple< Ts... > > {
    std::vector< std::tuple< Ts... > > m_values;
    size_t                             m_index = 0;

public:
    // Modern constructor using fold expressions and perfect forwarding
    template< typename... TuplePacks >
        requires (std::convertible_to< TuplePacks, std::tuple< Ts... > > && ...)
    explicit TupleValuesGenerator( TuplePacks &&... tuples )
        : m_values{ std::forward< TuplePacks >( tuples )... } { }

    // Constructor that takes a vector of tuples directly
    explicit TupleValuesGenerator( std::vector< std::tuple< Ts... > > values )
        : m_values( std::move( values ) ) { }

    std::tuple< Ts... > const& get() const override;

    // Advance to next value
    bool next() override {
        return ++m_index < m_values.size();
    }
};


// Avoids -Wweak-vtables
// Get current value - note the [[nodiscard]] to prevent accidental value dropping
template< typename... Ts >
[[nodiscard]]
std::tuple< Ts... > const& TupleValuesGenerator< Ts... >::get() const {
    return m_values.at( m_index ); // Using at() for bounds checking
}

// This helper function provides a nicer UX when instantiating the generator
// Notice that it returns an instance of GeneratorWrapper<T>, which
// is a value-wrapper around std::unique_ptr<IGenerator<T>.
template< typename... Ts >
[[nodiscard]]
auto tuplev( std::initializer_list< std::tuple< Ts... > > values ) {
    return Catch::Generators::GeneratorWrapper< std::tuple< Ts... > >(
                                                                      Catch::Detail::make_unique< TupleValuesGenerator< Ts... > >( values )
                                                                     );
}


// Helper function to create generators from initializer list of tuples
template< typename... Ts >
[[nodiscard]]
auto tuplev( std::initializer_list< std::initializer_list< Ts... > > values ) {
    return Catch::Generators::GeneratorWrapper< std::tuple< Ts... > >(
                                                                      Catch::Detail::make_unique< TupleValuesGenerator< Ts... > >( std::move( values ) )
                                                                     );
}


}
