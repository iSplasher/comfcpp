/**
 * \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once

#include "comf/constants.h"
#include "comf/concepts.h"
#include <memory>


namespace
COMF_NAMESPACE {
template< meta::IsSingleton T >
std::shared_ptr< T > get() {
    app_assert( T::singleton, "Singleton not initialized" );
    return T::singleton;
}


template< meta::IsSingleton T, typename... Args >
std::shared_ptr< T > create( Args... args ) {
    app_assert( !T::singleton, "Singleton already initialized" );
    return T::create( std::forward< Args >( args )... );
}
}


namespace
COMF_UTIL_NAMESPACE {

template< typename T, T MaxValue = std::numeric_limits< T >::max() >
struct WrappingVersion {
    app_static_assert( std::is_integral_v<T>, "T must be an integral type" );

    constexpr WrappingVersion()
        : value( 0 ) { }

    constexpr WrappingVersion( const T& value )
        : value( value ) { }

    constexpr WrappingVersion& operator++() noexcept {
        value = ( value == MaxValue ) ? 0 : value + 1;
        return *this;
    }

    [[maybe_unused]] constexpr WrappingVersion operator++( int v ) noexcept {
        WrappingVersion tmp = *this;

        value = ( ( value == MaxValue ) ? 0 : value ) + v;
        return tmp;
    }

    constexpr bool operator==( const WrappingVersion& rhs ) const noexcept {
        return value == rhs.value;
    }

    constexpr bool operator==( const T& rhs ) const noexcept {
        return value == rhs;
    }

    constexpr bool operator>( const WrappingVersion& rhs ) const noexcept {
        return value > rhs.value;
    }

    constexpr bool operator>( const T& rhs ) const noexcept {
        return value > rhs;
    }

    constexpr T operator*() const {
        return value;
    }

private:
    T value;
};


using WrappingVersionSize = WrappingVersion< std::size_t >;

}

