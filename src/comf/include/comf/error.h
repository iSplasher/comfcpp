/**
 * \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once

#include <bitset>
#include <concepts>
#include <expected>
#include <format>
#include <optional>
#include <type_traits>

#include "comf/constants.h"
#include "comf/format.h"
#include <typeinfo>

#include "error.h"
#include <fmt/compile.h>


namespace
COMF_NAMESPACE {


// forward declarations

template< typename T >
struct BaseError;

template< typename T >
concept IsErrorT = requires
{
    std::is_base_of_v<
        BaseError< typename T::ValueType >,
        T >;
};

template< IsErrorT E >
struct maybe_error;


// --------------------------------------------------------------------------------------------------------------------

/**
 * @brief Represents a single ErrorCode type
 *
 * @tparam C Class that defines the error codes, used to distinguish between different error classes.
 * @tparam T underlying value type, default is unsigned int. TODO: maybe change to uint_8?
 */
template< class C, typename T = unsigned >
    requires std::unsigned_integral< T >
struct ErrorType {
    using CodeType  = std::unwrap_ref_decay_t< C >;
    using ValueType = T;


    explicit constexpr ErrorType( const ValueType value )
        : value( value ) { }

    constexpr ErrorType( const ValueType value, const std::string_view default_message )
        : value( value ),
          message( default_message ) { }

    ErrorType( const ErrorType& c ) = default;

    template< typename D, template<typename, typename> typename Self >
        requires std::is_base_of_v< D, C >
    constexpr ErrorType( const Self< D, ValueType >& c )
        : value( c.value ),
          message( c.message ) { }

    template< typename D, template<typename, typename> typename Self >
        requires std::is_base_of_v< D, C >
    constexpr ErrorType( const Self< D, T >& c, const std::string_view message )
        : value( c.value ),
          message( message ) { }

    explicit constexpr ErrorType( const std::string_view message )
        : value( 1 << 0 ),
          message( message ) { }

    explicit constexpr operator bool() const { return value; }

    template< typename D, template<typename, typename> typename Self >
        requires std::is_base_of_v< C, D >
    explicit constexpr operator ErrorType< D, ValueType >( this Self< D, ValueType >&& self ) {
        return Self< D, ValueType >{ self.value, self.message };
    }

    template< typename D, template<typename, typename> typename Self >
        requires std::is_base_of_v< C, D >
    [[nodiscard]]
    constexpr Self< D, T >&& clone( this const Self< C, T >& self ) {
        return Self< D, T >{ self.value, self.message };
    }

    const ValueType        value;
    const std::string_view message;
};


constexpr unsigned BASE_ERROR_CODE_BITMASK = 2;

/**
 * @brief Represents a set of ErrorCode types (this is a type alias)
 *
 * @tparam C Class that defines the error codes, used to distinguish between different error classes.
 */
template< class C >
struct BaseErrorCode : ErrorType< std::unwrap_ref_decay_t< C >, typename C::ValueType > {
private:
    using BaseType = ErrorType< std::unwrap_ref_decay_t< C >, typename C::ValueType >;

public:
    using CodeType  = typename BaseType::CodeType;
    using ValueType = typename BaseType::ValueType;

    explicit constexpr BaseErrorCode( const ValueType value )
        : ErrorType< CodeType, ValueType >( value << BASE_ERROR_CODE_BITMASK ) { }

    constexpr BaseErrorCode( const ValueType value, const std::string_view default_message )
        : ErrorType< CodeType, ValueType >( value << BASE_ERROR_CODE_BITMASK, default_message ) { }

    template< typename... Args >
    explicit constexpr BaseErrorCode( Args&&... args )
        : ErrorType< CodeType, ValueType >( std::forward< Args >( args )... ) { }

    template< typename B, typename... Args >
        requires std::is_base_of_v< B, CodeType >
    explicit constexpr BaseErrorCode( Args&&... args )
        : ErrorType< B, ValueType >( std::forward< Args >( args )... ) { }

    template< typename B, typename... Args >
        requires std::is_base_of_v< std::decay_t< B >, CodeType >
    constexpr BaseErrorCode( const std::decay_t< B >& error )
        : ErrorType< B, ValueType >( error.message, error.value ) { }
};


template< class C >
using ErrorCode = const BaseErrorCode< std::unwrap_ref_decay_t< C > >;


/**
 * @brief Base class for errors
 *
 * @tparam T underlying value type
 */
template< typename T >
struct BaseError {
    using ValueType = T;
    using __E       = ErrorType< BaseError, ValueType >;

    constexpr static
    __E                  any{ 0xF };
    constexpr static __E unknown{ 1 << 0 };
    constexpr static __E rust_error{ 1 << 1 };
    // IMPORTANT: remember to update the BASE_ERROR_CODE_BITMASK if you add more error codes

    constexpr static __E rust_msg_error( std::string_view msg ) {
        return { rust_error.value, msg };
    }

};


/**
 * @brief Base class for error codes (this is a type alias)
 *
 * @tparam T underlying value type, default is unsigned int
 */
template< typename T = unsigned >
using Error = BaseError< T >;


// This part here are all operator overloads for ErrorType

template< class C, typename T >
std::ostream& operator<<( std::ostream& stream, const ErrorType< C, T >& error ) {
    const auto val = std::format( "{}({})", std::bitset< sizeof( T ) >( error.value ).to_string(), error.value );
    stream << error.message.size() ? std::format( "{}|{}", val, error.message ) : val;
    return stream;
};

// template<class C, typename T>
// struct fmt::formatter<ErrorType<C, T>> : default_string_formatter {
//
//   template<FmtContext F>
//   auto format(const ErrorType<C, T> v, F& ctx) {
//
//     return default_string_formatter::format(
//       "",
//       ctx
//     );
//   }
// };


template< class C, typename T >
constexpr inline bool flags( const ErrorType< C, T > x ) {
    return static_cast< ErrorType< C, T > >( x ) != 0;
};

template< class C, typename T >
constexpr inline const ErrorType< C, T > operator+( const ErrorType< C, T > x, T y ) {
    return static_cast< ErrorType< C, T > >( static_cast< T >( x ) + static_cast< T >( y ) );
};

template< class C, typename T >
constexpr inline const ErrorType< C, T > operator&( const ErrorType< C, T > x, const ErrorType< C, T > y ) {
    return static_cast< ErrorType< C, T > >( static_cast< T >( x ) & static_cast< T >( y ) );
};

// for Error<T>
template< class C, typename T >
constexpr inline const ErrorType< C, T > operator&( const BaseError< T > x, const ErrorType< C, T > y ) {
    return static_cast< ErrorType< C, T > >( static_cast< T >( x ) & static_cast< T >( y ) );
};

template< class C, typename T >
constexpr inline const ErrorType< C, T > operator|( const ErrorType< C, T > x, const ErrorType< C, T > y ) {
    return static_cast< ErrorType< C, T > >( static_cast< T >( x ) | static_cast< T >( y ) );
};

// for Error<T>
template< class C, typename T >
constexpr inline const ErrorType< C, T > operator|( const BaseError< T > x, const ErrorType< C, T > y ) {
    return static_cast< ErrorType< C, T > >( static_cast< T >( x ) | static_cast< T >( y ) );
};

template< class C, typename T >
constexpr inline const ErrorType< C, T > operator^( const ErrorType< C, T > x, const ErrorType< C, T > y ) {
    return static_cast< ErrorType< C, T > >( static_cast< T >( x ) ^ static_cast< T >( y ) );
};

template< class C, typename T >
constexpr inline const ErrorType< C, T > operator~( const ErrorType< C, T > x ) {
    return static_cast< ErrorType< C, T > >( ~static_cast< T >( x ) );
};

template< class C, typename T >
constexpr inline const ErrorType< C, T >& operator&=( const ErrorType< C, T >& x, const ErrorType< C, T > y ) {
    x = x & y;
    return x;
};

template< class C, typename T >
constexpr inline const ErrorType< C, T >& operator|=( const ErrorType< C, T >& x, const ErrorType< C, T > y ) {
    x = x | y;
    return x;
};

template< class C, typename T >
constexpr inline const ErrorType< C, T >& operator^=( const ErrorType< C, T >& x, const ErrorType< C, T > y ) {
    x = x ^ y;
    return x;
};

template< class C, typename T >
constexpr inline bool operator==( const ErrorType< C, T >& x, const ErrorType< C, T > y ) {
    return x.value == y.value;
};


// --------------------------------------------------------------------------------------------------------------------


inline auto no_error = std::nullopt;


/**
 * @brief A result class that can be used to optionally return errors from functions.
 *        Has the same interface as std::optional.
 *\note A bool test returns true if there is no error.
 * @param E The error type.
 */

template< IsErrorT E >
struct maybe_error {
private:
    using ErrCode__    = std::unwrap_ref_decay_t< ErrorCode< E > >;
    using OptionalType = std::optional< ErrCode__ >;

public:
    template< typename... Args >
    maybe_error( Args&&... args )
        : _value( std::forward< Args >( args )... ) { }

    constexpr maybe_error& operator=( auto&& other ) {
        _value = std::forward< decltype( other ) >( other );
        return *this;
    }

    constexpr maybe_error( ErrCode__&& error ) = delete;

    [[nodiscard]]
    constexpr auto get() {
        if constexpr ( _value.has_value() ) {
            app_assert( false, "Attempted to get non-existent error value" );
        }
        return _value.value();
    }


    [[nodiscard]]
    operator const bool() const noexcept {
        return !_value.has_value();
    }

    template< typename T2 >
        requires std::equality_comparable_with< ErrCode__, T2 >
    constexpr auto operator==(
        this auto&& self,
        const T2&   rhs
    ) {
        return self._value == rhs;
    }

    constexpr bool operator==(
        this auto&&         self,
        const OptionalType& rhs
    ) {
        return self._value == rhs;
    }

    constexpr bool operator==(
        this auto&& self,
        const bool& rhs
    ) {
        auto r = ( !self._value.has_value() );
        return r == rhs;
    }

    template< typename T >
    operator T() const = delete;

    [[nodiscard]]
    auto has_error() {
        return !_value.has_value();
    }

    [[nodiscard]]
    ErrCode__& error() {
        return _value.value();
    }


    template< typename T >
    [[nodiscard]]
    auto error_or( T&& v ) {
        return _value.value_or( v );
    }

private:
    OptionalType _value;
};


/**
 * @brief A result class that can be used to optionally return errors from functions.
 *        Has the same interface as std::optional.
 *
 * @param Result Value to return if no error occured
 * @param E The error type.
 */
template< class Result, IsErrorT E >
struct maybe {
private:
    using ExpectedType = std::expected< Result, std::unwrap_ref_decay_t< ErrorCode< E > > >;

public:
    using ECode = std::unwrap_ref_decay_t< ErrorCode< std::unwrap_ref_decay_t< E > > >;

    template< typename D, template<typename, typename> typename O >
        requires std::is_base_of_v< D, E >
    constexpr maybe( const O< D, typename E::ValueType >& error )
        : _value( std::unexpected< ECode >( error.template clone< E >() ) ) { }

    constexpr maybe( const maybe_error< ECode >& ) {
        app_static_assert( false, "Cannot convert maybe_error to maybe. Use maybe_error::error() to get the error" );
    }

    constexpr maybe& operator=( auto&& other ) {
        _value = std::forward< decltype( other ) >( other );
        return *this;
    }

    constexpr maybe( const ECode&& error ) = delete;


    template< typename... Args >
        requires std::constructible_from< ExpectedType, Args... >
    constexpr maybe( Args&&... args )
        : _value( std::forward< Args >( args )... ) { }


    constexpr maybe& operator=( const ECode& error ) {
        _value = std::unexpected< std::remove_const_t< ECode > >( error.clone() );
        return *this;
    }

    constexpr operator bool() noexcept {
        return static_cast< bool >( _value );
    }

    template< typename T2 >
        requires std::equality_comparable_with< ExpectedType, T2 >
    constexpr auto operator==(
        this auto&& self,
        const T2&   rhs
    ) {
        return self._value == rhs;
    }

    constexpr auto operator*() {
        return *_value;
    }

    constexpr auto value() {
        app_assert( _value->has_value(), "Result contains error value" );
        return _value->value();
    }

    constexpr auto value_or() {
        return _value->value_or();
    }

    constexpr auto error() {
        app_assert( !_value->has_value(), "Result contains value" );
        return _value->error();
    }

    template< typename... Args >
    constexpr auto has_value( Args&&... args ) {
        return _value.has_value( std::forward< Args >( args )... );
    }

private:
    ExpectedType _value;
};


// --------------------------------------------------------------------------------------------------------------------


/**
 * @brief Common and general error types
 *
 */
struct CoreError : Error< > { };


}


namespace fmt {
using namespace COMF_NAMESPACE;


template< IsErrorT E >

struct fmt::formatter< maybe_error< E > > : default_string_formatter {
    template< FmtContext F >
    auto format( const maybe_error< E > v, F& ctx ) {
        return default_string_formatter::format(
                                                fmt::format( "maybe_error<{}>", v.has_error() ? v.error() : no_error ),
                                                ctx
                                               );
    }
};
}
