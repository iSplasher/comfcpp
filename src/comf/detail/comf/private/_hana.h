/**
* \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once

#include <typeindex>
#include <boost/hana.hpp>
#include <boost/hana/type.hpp>
#include <boost/hana/ext/std/integral_constant.hpp>
#include <boost/hana/ext/std/tuple.hpp>

#include "comf/constants.h"


namespace
COMF_NAMESPACE::meta {


IMPLEMENTATION_START
    namespace hana = boost::hana;
    IMPLEMENTATION_END


#define META_INTROSPECT_STRUCT( ... ) \
    BOOST_HANA_ADAPT_STRUCT( __VA_ARGS__ )

template< typename T >
using Integral = impl::hana::IntegralConstant< T >;


// Concept for Hana-compatible string types
template< typename T >
concept IsHanaStringCompatible = requires( T t )
{
    { meta::impl::hana::is_a< meta::impl::hana::string_tag >( t ) } -> std::same_as< bool >;
};


template< typename T >
concept UnsignedIntegral = Integral< T >::value && impl::hana::size_c< 0 > <= Integral< T >::value;


template< UnsignedIntegral T >
struct UnsignedIntegralConstant : Integral< T > {
    static_assert( impl::hana::size_c< 0 > <= Integral< T >::value, "Value must be unsigned" );
};


template< typename T >
concept PositiveIntegral = Integral< T >::value && impl::hana::size_c< 1 > <= Integral< T >::value;


template< PositiveIntegral T >
struct PositiveIntegralConstant : Integral< T > {
    static_assert( impl::hana::size_c< 1 > < Integral< T >::value, "Value must be positive" );
};


template< typename T >
concept IsTypeValue = std::is_same_v< impl::hana::tag_of_t< T >, impl::hana::type_tag >;

constexpr auto is_type_value_equal = impl::hana::equal;

template< template <typename...> typename T >
constexpr auto template_apply = impl::hana::template_< T >;

template< template <typename...> typename T >
constexpr auto type_apply = impl::hana::metafunction< T >;

constexpr auto for_each = impl::hana::for_each;

template< typename T >
concept IsSequence = impl::hana::Sequence< T >::value;

template< typename T >
concept IsStruct = impl::hana::Struct< T >::value;

constexpr auto transform = impl::hana::transform;

template< typename T, T v >
using h_integral_constant = impl::hana::integral_constant< T, v >;

constexpr auto h_sizeof  = impl::hana::sizeof_;
constexpr auto h_alignof = impl::hana::alignof_;

constexpr auto is_valid_expr = impl::hana::is_valid;

using h_true_t         = impl::hana::true_;
constexpr auto h_true  = impl::hana::true_c;
using h_false_t        = impl::hana::false_;
constexpr auto h_false = impl::hana::false_c;

constexpr auto h_nothing = impl::hana::nothing;
using h_nothing_t        = std::decay_t< decltype(h_nothing) >;

constexpr auto conditional_v = impl::hana::if_;

constexpr auto make_h_tuple = impl::hana::make_tuple;
constexpr auto h_concat     = impl::hana::concat;
constexpr auto h_tuple_cat  = h_concat;

template< typename T >
constexpr auto type_value = impl::hana::type_c< T >;

template< typename T >
using type_value_t = impl::hana::type< T >;


struct type_value_index {

    std::type_index idx;

    template< typename T >
    constexpr type_value_index( const T &v ) noexcept
        requires ( IsTypeValue< T > )
        : idx( typeid( v ) ) { }

    constexpr type_value_index( const type_value_index &other ) noexcept
        : idx( other.idx ) { }

    auto operator<=>( const type_value_index &other ) const noexcept = default;

    constexpr bool operator==( const type_value_index &other ) const noexcept {
        return idx == other.idx;
    }

    [[nodiscard]] constexpr auto hash_code() const noexcept {
        return idx.hash_code();
    }
};


constexpr auto fold_left = impl::hana::fold_left;


template< typename... T >
using make_h_tuple_type_values_t = impl::hana::tuple< impl::hana::type< T >... >;

template< typename... T >
constexpr auto make_h_tuple_type_values = make_h_tuple( type_value< T >... );


IMPLEMENTATION_START

    struct reveal_h_type_impl {

        template< typename T >
        decltype(auto) operator()( const T &t ) const
            requires ( IsTypeValue< T > ) {
            return +t;
        }

        template< typename T >
        std::remove_cvref_t< T > operator()( const T &t ) const
            requires ( !IsTypeValue< T > ) {
            return t;
        }
    };


    IMPLEMENTATION_END


constexpr auto reveal_h_type = impl::reveal_h_type_impl{};

template< typename T >
    requires IsTypeValue< T >
using reveal_h_type_t = typename T::type;

IMPLEMENTATION_START


    struct is_type_base_of_impl {
        template< typename Base, typename Derived >
        constexpr decltype(auto) operator()( Base &&base, Derived &&derived ) const {
            return std::is_base_of_v< std::remove_cvref_t< Base >, std::remove_cvref_t< Derived > >;
        }

        template< typename Base, typename Derived >
        constexpr decltype(auto) operator()( type_value_t< Base > &&base, type_value_t< Derived > &&derived ) const {
            return std::is_base_of_v< std::remove_cvref_t< Base >, std::remove_cvref_t< Derived > >;
        }
    };


    template< typename T >
    struct is_type_base_of_type_helper {
        using type = T;
    };


    template< typename T, template<typename> typename V >
        requires IsTypeValue< V< T > >
    struct is_type_base_of_type_helper< V< T > > {
        using type = typename is_type_base_of_type_helper< std::remove_cvref_t< T > >::type;
    };


    template< typename T >
        requires IsTypeValue< T >
    struct is_type_base_of_type_helper< T > {
        using type = typename is_type_base_of_type_helper< reveal_h_type_t< std::remove_cvref_t< T > > >::type;
    };


    template< typename T >
    using is_type_base_of_type_helper_t = typename is_type_base_of_type_helper< T >::type;


    template< typename Base, typename Derived >
    struct is_type_base_of_impl_t : std::false_type {
        using type    = std::false_type;
        using Base    = Base;
        using Derived = Derived;
    };


    template< template<typename> typename V, typename Base, typename Derived >
        requires IsTypeValue< V< Base > > && IsTypeValue< V< Derived > >
    struct is_type_base_of_impl_t< V< Base >, V< Derived > > : is_type_base_of_impl_t< is_type_base_of_type_helper_t< Base >, is_type_base_of_type_helper_t< Derived > > { };


    template< template<typename> typename V, typename Base, typename Derived >
        requires IsTypeValue< V< Derived > >
    struct is_type_base_of_impl_t< Base, V< Derived > > : is_type_base_of_impl_t< is_type_base_of_type_helper_t< Base >, is_type_base_of_type_helper_t< Derived > > { };


    template< template<typename> typename V, typename Base, typename Derived >
        requires IsTypeValue< V< Base > >
    struct is_type_base_of_impl_t< V< Base >, Derived > : is_type_base_of_impl_t< is_type_base_of_type_helper_t< Base >, is_type_base_of_type_helper_t< Derived > > { };


    template< typename Base, typename Derived >
        requires ( !IsTypeValue< Base > && IsTypeValue< Derived > )
    struct is_type_base_of_impl_t< Base, Derived > : is_type_base_of_impl_t< is_type_base_of_type_helper_t< Base >, is_type_base_of_type_helper_t< Derived > > { };


    template< typename Base, typename Derived >
        requires ( IsTypeValue< Base > && !IsTypeValue< Derived > )
    struct is_type_base_of_impl_t< Base, Derived > : is_type_base_of_impl_t< is_type_base_of_type_helper_t< Base >, is_type_base_of_type_helper_t< Derived > > { };


    template< typename Base, typename Derived >
        requires std::is_base_of_v< Base, Derived > || std::is_same_v< Base, Derived >
    struct is_type_base_of_impl_t< Base, Derived > : std::true_type {
        using type    = std::true_type;
        using Base    = Base;
        using Derived = Derived;
    };


    IMPLEMENTATION_END


constexpr auto is_type_base_of = impl::is_type_base_of_impl{};


template< typename Base, typename Derived >
using is_type_base_of_t = impl::is_type_base_of_impl_t< Base, Derived >;


template< typename Base, typename Derived >
constexpr auto is_type_base_of_v = is_type_base_of_t< Base, Derived >::value;


template< typename T >
struct is_truthy : std::conjunction< std::bool_constant< T::value >, std::true_type > { };


template< typename T >
constexpr auto is_truthy_v = is_truthy< T >::value;


constexpr auto h_make_tag = []<typename T0>( T0 t ) -> impl::hana::tag_of_t< T0 > {
    return {};
};


template< typename T1, typename T2 >
concept HasCommon = requires
{
    typename impl::hana::common_t< T1, T2 >;
};


template< typename T1, typename T2 >
struct common_type {
    using type = std::void_t< >;
};


template< typename T1, typename T2 >
    requires HasCommon< T1, T2 >
struct common_type< T1, T2 > {
    using type = impl::hana::common_t< T1, T2 >;
};


template< typename T1, typename T2 >
using common_type_t = typename common_type< T1, T2 >::type;


// --------------------------------------------------------------------------

// template< typename T >
// constexpr auto class_apply = impl::hana::metafunction_class< T >;


}


template< typename AA, typename BA >
struct std::common_type< COMF_NAMESPACE::meta::impl::hana::basic_tuple< AA >, COMF_NAMESPACE::meta::impl::hana::basic_tuple< BA > > : public std::common_type< AA, BA > { };


// Custom specialization of std::hash can be injected in namespace std.
template<>
struct std::hash< COMF_NAMESPACE::meta::type_value_index > {
    std::size_t operator()( const COMF_NAMESPACE::meta::type_value_index &s ) const noexcept {
        return s.hash_code();
    }
};
