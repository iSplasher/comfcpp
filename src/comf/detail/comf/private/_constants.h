/**
 * \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once

#include <expected>
#include <optional>


#ifdef DEBUG
#pragma message( "Debug environment detected" )
#endif

#define EXPAND_MACRO(x) x

#ifdef COMF_NAMESPACE
#error "COMF_NAMESPACE already defined"
#endif

#define COMF_NAMESPACE comf

#ifdef COMF_UTIL_NAMESPACE
#error "COMF_UTIL_NAMESPACE already defined"
#endif
#define COMF_UTIL_NAMESPACE COMF_NAMESPACE::util

#define IMPL_NAMESPACE impl
#define IMPLEMENTATION_START namespace IMPL_NAMESPACE {
#define IMPLEMENTATION_END }

// Amount of component types to support
#define COMPONENT_TYPE_COUNT 64



#if defined(__cplusplus)
# if defined(_MSVC_LANG) && _MSVC_LANG != __cplusplus
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmacro-redefined"
#  define _MSVC_LANG EXPAND_MACRO( __cplusplus )
#pragma clang diagnostic pop
# endif
#endif


namespace
COMF_NAMESPACE {


IMPLEMENTATION_START
    struct nothing_cls {
        // intentionally implicit
        constexpr nothing_cls() = default;

        constexpr nothing_cls( auto && ) = delete;

        constexpr nothing_cls& operator=( auto && ) {
            return *this;
        }

        // evaluate to false
        constexpr operator bool() const {
            return false;
        }

        // equals with std::nullopt
        constexpr bool operator==( const std::nullopt_t & ) const {
            return true;
        }

        // turns to std::nullopt in std::optional
        template< typename T >
        constexpr operator std::optional< T >() const {
            return std::nullopt;
        }

        // equals with std::unexpected
        constexpr bool operator==( const std::unexpect_t & ) const {
            return true;
        }

        // turns to std::nullopt in std::optional
        template< typename T, typename Err >
        constexpr operator std::expected< T, Err >() const {
            return std::unexpect;
        }
    };


    IMPLEMENTATION_END


/**
 * \brief A type that represents nothing.
 *
 */
using nothing_t = impl::nothing_cls;

/**
 * \brief A constant that represents nothing.
 *
 */
static constexpr nothing_t nothing{};

/**
 * \brief Byte value that has all bits set to 0.
 *
 */
static constexpr auto ALL_ZEROS_BYTE = std::byte{ 0 };
/**
 * \brief Byte value that has all bits set to 1.
 *
 */
static constexpr auto ALL_ONES_BYTE = ~ALL_ZEROS_BYTE;
/**
 * \brief Byte value that has only the first bit set to 1, e.g. 00000001.
 *
 */
static constexpr auto SINGLE_ONE_BYTE = std::byte{ 1 };


template< typename T >
struct no_delete_t {
    void operator()( T* ) const noexcept { }
};


template< typename T >
static constexpr no_delete_t< T > no_delete{};

}

