/**
 * \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once

#include <tuple>
#include <type_traits>
#include <variant>
#include <fmt/compile.h>

#include "comf/constants.h"
#include "private/_experimental_std.h"
#include "private/_hana.h"


namespace
COMF_NAMESPACE::meta {
/**
 * \brief Reveal template type information at compile-time
 */
template< typename... Args >
void dbg_reveal_type();


template< template <typename...> class Base, typename Derived >
struct is_base_of_template {
    // A function which can only be called by something convertible to a Base<Ts...>*
    // We return a std::variant here as a way of "returning" a parameter pack
    template< typename... Ts >
    static constexpr std::variant< Ts... > is_callable( Base< Ts... >* );

    // Detector, will return type of calling is_callable, or it won't compile if that can't be done
    template< typename T >
    using is_callable_t = decltype( is_callable( std::declval< T* >() ) );

    // Is it possible to call is_callable which the Derived type
    static inline constexpr bool value = exp_std::is_detected_v< is_callable_t, Derived >;

    // If it is possible to call is_callable with the Derived type what would it return, if not type is a void
    using type = exp_std::detected_or_t< void, is_callable_t, Derived >;
};


template< template <typename...> class Base, typename Derived >
using is_base_of_template_t = typename is_base_of_template< Base, Derived >::type;

template< template <typename...> class Base, typename Derived >
inline constexpr bool is_base_of_template_v = is_base_of_template< Base, Derived >::value;

/**
 * Whether a type is a singleton or not.
 */
template< typename T >
concept IsSingleton = requires
{
    T::singleton;
    T::create();
};

template< class T >
concept IsTypeComplete = requires( T self )
{
    {
        // You can't apply sizeof to an incomplete type
        sizeof( self )
    };
};

template< typename T >
concept HasValue = requires
{
    T::value;
};

template< typename T >
concept HasType = requires
{
    typename T::type;
};

template< template <typename...> typename T, typename... Derived >
concept HasCommonTemplateBase = std::conjunction_v< is_base_of_template_t< T, Derived >... >;

IMPLEMENTATION_START

    template< typename Base, template <typename...> typename T, typename... TArgs >
    using TemplateHasBase = std::is_base_of< Base, T< TArgs... > >;

    IMPLEMENTATION_END


template< typename Base, template <typename...> typename... Ts >
concept TemplatesHasBase = std::conjunction_v< impl::TemplateHasBase< Base, Ts >... >;

// --------------------------------------------------------------------------

// Type trait to check if a type is an instance of std::tuple
template< typename T >
struct is_tuple : std::false_type { };


template< typename... Args >
struct is_tuple< std::tuple< Args... > > : std::true_type { };


template< typename T >
inline constexpr bool is_tuple_v = is_tuple< std::remove_cvref_t< T > >::value;

template< typename T >
concept IsTuple = is_tuple_v< T >;

// --------------------------------------------------------------------------

template< typename T, typename... Args >
struct contains_type : std::false_type { };


// Specialization: T is the same as the first type in the list
template< typename T, typename First, typename... Rest >
struct contains_type< T, First, Rest... >
        : std::conditional_t< std::is_same_v< T, First >, std::true_type, contains_type< T, Rest... > > { };


template< typename T, typename... Args >
inline constexpr bool contains_type_v = contains_type< T, Args... >::value;

template< typename T, typename... Args >
using contains_type_t = typename contains_type< T, Args... >::type;


// --------------------------------------------------------------------------

/**
 * \brief Unpack a tuple into a template type
 * \remarks using SomeTuple = std::tuple<int, double, char>;\n
 * // Unpack the tuple into a template type (std::pair in this case)\n
 * using ResultType = unpack<MyTuple>::template apply<std::pair>::type;
 */
template< IsTuple Tuple, std::size_t N = std::tuple_size_v< std::remove_cvref_t< Tuple > > >
struct unpack;


/**
 * \brief Recursively unpack a tuple into a template type
 * \remarks using SomeTuple = std::tuple<int, double, char>;\n
 * // Unpack the tuple into a template type (std::pair in this case)\n
 * using ResultType = unpack<MyTuple>::template apply<std::pair>::type;
 */
template< typename Arg1, typename... Args, std::size_t N >
struct unpack< std::tuple< Arg1, Args... >, N > {
    // Extract the first type
    using FirstType = Arg1;

    // Recursively unpack the rest of the tuple
    using RestTuple = unpack< std::tuple< Args... >, N - 1 >;


    // Construct the template type using the first type and the recursively unpacked types
    template< template<typename...> typename Template, typename... TArgs >
    struct apply {
        using type = typename RestTuple::template apply< Template, TArgs..., FirstType >::type;
    };


    template< template<typename> typename FuncTemplate, template<typename...> class Template, typename... TArgs >
    struct map {
        using type = typename RestTuple::template map< FuncTemplate, Template, TArgs..., FuncTemplate< FirstType > >::type;
    };


    template< template<typename> typename FuncTemplate, typename... TArgs >
    struct transform {
        using type = typename RestTuple::template map< FuncTemplate, std::tuple, TArgs..., FuncTemplate< FirstType > >::type;
    };

};


/**
 * \brief Specialization for the base case (empty tuple)
 * \remarks using SomeT = std::tuple<int, double, char>;\n
 * // Unpack the tuple into a template type (std::pair in this case)\n
 * using ResultType = unpack<SomeT>::template apply<std::pair>::type;
 */
template<>
struct unpack< std::tuple< >, 0 > {
    // Define an empty apply struct for the base case
    template< template<typename...> typename Template, typename... TArgs >
    struct apply {
        using type = Template< TArgs... >;
    };


    template< template<typename> typename FuncTemplate, template<typename...> class Template, typename... TArgs >
    struct map {
        using type = Template< TArgs... >;
    };


    template< template<typename> typename FuncTemplate, typename... TArgs >
    struct transform {
        using type = std::tuple< TArgs... >;
    };

};


// --------------------------------------------------------------------------

namespace impl {

    // Helper type trait to concatenate two tuples
    template< IsTuple Tuple1, IsTuple Tuple2 >
    struct tuple_concat;


    // Specialization for concatenating two tuples
    template< typename... Ts1, typename... Ts2 >
    struct tuple_concat< std::tuple< Ts1... >, std::tuple< Ts2... > > {
        using type = std::tuple< Ts1..., Ts2... >;
    };


    // Convenience alias template
    template< IsTuple Tuple1, IsTuple Tuple2 >
    using tuple_concat_t = typename tuple_concat< Tuple1, Tuple2 >::type;

    // Primary template for concatenating multiple tuples
    template< IsTuple... Tuples >
    struct tuple_cat_impl;


    // Specialization for the base case of a single tuple
    template< IsTuple Tuple >
    struct tuple_cat_impl< Tuple > {
        using type = Tuple;
    };


    // Specialization for the recursive case
    template< IsTuple Tuple1, IsTuple Tuple2, IsTuple... Rest >
    struct tuple_cat_impl< Tuple1, Tuple2, Rest... > {
        using type = typename tuple_cat_impl< tuple_concat_t< Tuple1, Tuple2 >, Rest... >::type;
    };
}


/**
 * \brief Concatenate multiple tuples into a single tuple
 * \remarks using Tuple1 = std::tuple<int, double>;\n
 * using Tuple2 = std::tuple<char, bool>;\n
 * using Tuple3 = std::tuple<float, long>;\n
 * // Concatenate the tuples\n
 * using ResultType = tuple_cat_t<Tuple1, Tuple2, Tuple3>;
 */
template< IsTuple... Tuples >
using tuple_cat_t = typename impl::tuple_cat_impl< Tuples... >::type;

// --------------------------------------------------------------------------

namespace impl {

    template< typename Template, IsTuple Args >
    struct unwrap_t_helper {
        using type = Args;


        template< size_t i >
        struct arg_t {
            using type = std::tuple_element_t< i, Args >;
        };
    };

}


/**
 * \brief Unwrap a template type into its template argument types
 * \remarks template<int, double> struct SomeType;\n
 * // Unwrap the template type\n
 * using ResultType = unwrap<SomeType>::type;\n
 * // ResultType is std::tuple<int, double>
 */
template< template<typename...> typename Template, typename... _Args >
struct unwrap : impl::unwrap_t_helper< Template< _Args... >, std::tuple< _Args... > > { };


/**
 * \brief Unwrap a template type into its template argument types
 * \remarks template<int, double> struct SomeType;\n
 * // Unwrap the template type\n
 * using ResultType = unwrap_t<SomeType>;\n
 * // ResultType is std::tuple<int, double>
 */
template< template<typename...> typename Template >
using unwrap_t = typename unwrap< Template >::type;

// --------------------------------------------------------------------------

namespace impl {

    template< typename, template<typename> typename, template<typename...> typename, typename... >
    struct map_t_helper;

    template< typename T >
    struct map_t_helper_t;


    template< IsTuple Template, template<typename> typename FuncTemplate >
    struct map_t_helper< Template, FuncTemplate, map_t_helper_t > {
        using type = typename unpack< Template >::template transform< FuncTemplate >::type;
    };


    template< template<typename...> typename Template, template<typename> typename FuncTemplate >
    struct map_t_helper< void, FuncTemplate, Template > {
        using type = typename unpack< unwrap_t< Template > >::template map< FuncTemplate, Template >::type;
    };

}


/**
 * \brief Map a template type to a tuple's template arguments
 * \remarks using SomeT = std::tuple<int, double>;\n
 * using ResultType = map_t<SomeT, std::add_const>;\n
 * // ResultType is std::tuple<std::add_const<int>, std::add_const<double>>
 */
template< template<typename...> typename Template, template<typename> typename FuncTemplate >
using map_t = typename impl::map_t_helper< void, FuncTemplate, Template >::type;


/**
 * \brief Map a template type to a another type's template arguments
 * \remarks using SomeT = std::pair<int, double>;\n
 * using ResultType = map_t<SomeT, std::add_const>;\n
 * // ResultType is std::pair<std::add_const<int>, std::add_const<double>>
 */
template< IsTuple Template, template<typename> typename FuncTemplate >
using map_tuple_t = typename impl::map_t_helper< Template, FuncTemplate, impl::map_t_helper_t >::type;


// --------------------------------------------------------------------------

/**
 * \brief Apply a template type to a tuple
 * \remarks using SomeTuple = std::tuple<int, double, char>;\n
 * // Apply the template type (std::pair in this case) to the tuple\n
 * using ResultType = apply_t<MyTuple, std::pair>;
 */
template< IsTuple ArgsTuple, template<typename...> typename Template >
using apply_t = typename unpack< ArgsTuple >::template apply< Template >::type;

/**
 * \brief Apply a template type to a tuple with one additional type
 * \remarks using SomeTuple = std::tuple<int, double, char>;\n
 * // Apply the template type (std::pair in this case) to the tuple\n
 * using ResultType = apply_partial_1_t<int, MyTuple, std::pair>;
 */
template< typename T1, typename ArgsTuple, template<typename, typename...> typename Template >
using apply_partial_1_t = typename unpack< tuple_cat_t< std::tuple< T1 >, ArgsTuple > >::template apply< Template >::type;

/**
 * \brief Apply a template type to a tuple with two additional types
 * \remarks using SomeTuple = std::tuple<int, double, char>;\n
 * // Apply the template type (std::pair in this case) to the tuple\n
 * using ResultType = apply_partial_2_t<int, double, MyTuple, std::pair>;
 */
template< typename T1, typename T2, typename ArgsTuple, template<typename, typename, typename...> typename Template >
using apply_partial_2_t = typename unpack< tuple_cat_t< std::tuple< T1, T2 >, ArgsTuple > >::template apply< Template >::type;

/**
 * \brief Apply a template type to a tuple with three additional types
 * \remarks using SomeTuple = std::tuple<int, double, char>;\n
 * // Apply the template type (std::pair in this case) to the tuple\n
 * using ResultType = apply_partial_3_t<int, double, char, MyTuple, std::pair>;
 */
template< typename T1, typename T2, typename T3, typename ArgsTuple, template<typename, typename, typename, typename...> typename Template >
using apply_partial_3_t = typename unpack< tuple_cat_t< std::tuple< T1, T2, T3 >, ArgsTuple > >::template apply< Template >::type;

// --------------------------------------------------------------------------

template< template<typename...> typename T, typename... NewTypes >
constexpr auto self_reflect = []<typename... Args>( Args... args ) -> decltype(auto) {
    return T< NewTypes... >{ std::forward< Args >( args )... };
};


// --------------------------------------------------------------------------

template< typename... >
struct ConceptValue : std::true_type { };


template< typename T, typename... Rest >
concept ConceptValueT = std::is_same_v< T, ConceptValue< Rest... > > || std::is_void_v< T >;

// --------------------------------------------------------------------------

IMPLEMENTATION_START

    template< typename _Empty, template<typename...> typename Concept, typename... Ts >
        requires ( std::is_void_v< Concept< > > || (Concept< Ts >::value && ... ) )
    struct BaseTypeContainer {

        static constexpr auto values = std::array< std::optional< type_value_index >, sizeof...( Ts ) >{ std::nullopt };
        using Types                  = std::tuple< Ts... >;
        using Values                 = decltype( values );

        template< typename T >
            requires ( std::is_void_v< Concept< > > || Concept< T >::value )
        constexpr auto has( auto&& t = meta::impl::hana::type_c< T > ) const {
            return meta::impl::hana::contains( values, t );
        }

        template< typename... OtherT >
            requires ( std::is_void_v< Concept< > > || (Concept< OtherT >::value && ...) )
        constexpr auto has_all( auto&& t = meta::impl::hana::make_set( meta::impl::hana::type_c< OtherT >... ) ) const {
            return meta::impl::hana::all_of( t, [&]( auto c ) { return has( c ); } );
        }

        template< typename... OtherT >
            requires ( std::is_void_v< Concept< > > || (Concept< OtherT >::value && ...) )
        constexpr static auto create( auto&& t = meta::impl::hana::make_set( meta::impl::hana::type_c< OtherT >... ) ) {
            return BaseTypeContainer< std::false_type, Concept, OtherT... >{};
        }

        constexpr static auto create() {
            return BaseTypeContainer< std::false_type, Concept, Ts... >{};
        }

        static constexpr decltype(auto) type_index() {
            auto r = hana::fold_left( values, hana::make_set(), []( auto acc, auto v ) {
                return hana::insert( acc, v );
            } );

            return type_value_index( hana::typeid_( r ) );
        }

        constexpr bool operator==( this auto&& self, const auto& other ) {
            return self.type_index() == other.type_index();
        }

    };


    template< template<typename...> typename Concept, typename... Ts >
    struct BaseTypeContainer< std::false_type, Concept, Ts... > {
        static constexpr auto values = meta::impl::hana::make_set( meta::impl::hana::type_c< Ts >... );
    };


    template< template<typename...> typename Concept, typename... Ts >
    struct BaseTypeContainer< std::true_type, Concept, Ts... > {
        static constexpr typename unpack< std::tuple< Ts... > >::template apply< impl::hana::set >::type values{};
    };


    IMPLEMENTATION_END


template< template<typename...> typename Concept = std::void_t, typename... Ts >
struct TypeContainer : impl::BaseTypeContainer< std::false_type, Concept, Ts... > {
    using Empty = impl::BaseTypeContainer< std::true_type, Concept, Ts... >;
};


IMPLEMENTATION_START

    // define concept of `common_type<A,B>` existing
    template< typename A, typename B >
    concept has_in_common_ordered = HasType< std::common_type< A, B > > && !HasType< std::common_type< B, A > > ;

    IMPLEMENTATION_END


}


// https://stackoverflow.com/questions/69984704/how-can-i-specialize-stdcommon-typea-b-so-that-its-naturally-commutative
// define common_type<A,B> if common_type<B,A>::type exists:
template< typename A, COMF_NAMESPACE::meta::impl::has_in_common_ordered< A > B >
struct std::common_type< A, B > : public std::common_type< B, A > { };



