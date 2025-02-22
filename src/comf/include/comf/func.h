/**
 * \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once

#include <function2/function2.hpp>

#include "comf/constants.h"
#include "comf/concepts.h"
#include "comf/private/_hana.h"


namespace
COMF_NAMESPACE {


/*
*  https://github.com/Naios/function2?tab=readme-ov-file#adapt-function2
    IsThrowing defines if empty function calls throw an fu2::bad_function_call exception, otherwise std::abort is called.
    HasStrongExceptGuarantee defines whether the strong exception guarantees shall be met.
    Signatures: defines the signatures of the function.
*/

/**
 * \brief An owning copyable function wrapper for arbitrary callable types.
 *
 * \details func<void(int, float) const>
 *   Return type ~^   ^     ^     ^
 *   Parameters  ~~~~~|~~~~~|     ^
 *   Qualifier ~~~~~~~~~~~~~~~~~~~|
 */
template< typename... Signatures >
using func = fu2::function_base< true, true, fu2::capacity_default, //
                                 true, false, Signatures... >;

/**
 * \brief  An owning non copyable function wrapper for arbitrary callable types.
 * Also works with non copyable functors/ lambdas.
 *
 * \details func<void(int, float) const>
 *   Return type ~^   ^     ^     ^
 *   Parameters  ~~~~~|~~~~~|     ^
 *   Qualifier ~~~~~~~~~~~~~~~~~~~|
 */
template< typename... Signatures >
using func_unique = fu2::function_base< true, false, fu2::capacity_default, //
                                        true, false, Signatures... >;

/**
 * \brief A non owning copyable function wrapper for arbitrary callable types.
 * Can be used to create a non owning view on a persistent object.
 * Note that the view is only valid as long as the object lives.
 *
 * \details func<void(int, float) const>
 *   Return type ~^   ^     ^     ^
 *   Parameters  ~~~~~|~~~~~|     ^
 *   Qualifier ~~~~~~~~~~~~~~~~~~~|
 */
template< typename... Signatures >
using func_view = fu2::function_base< false, true, fu2::capacity_default, //
                                      true, false, Signatures... >;


namespace meta {

    // -------------------------------------------------------------------------- //
    namespace impl {
        using const_opts    = hana::integral_constant< int, 1 >;
        using noexcept_opts = hana::integral_constant< int, 2 >;
        using lambda_opts   = hana::integral_constant< int, 3 >;


        template< typename... Args >
        using func_traits_opts = std::tuple< Args... >;


        template< meta::IsTuple opts, typename Func, typename R, typename... Args >
        struct function_traits_helper {
            static const size_t nargs = sizeof...( Args );

            using result_type = R;


            struct options {
                constexpr static bool is_const    = meta::apply_partial_1_t< const_opts, opts, meta::contains_type >::value;
                constexpr static bool is_noexcept = meta::apply_partial_1_t< noexcept_opts, opts, meta::contains_type >::value;
                constexpr static bool is_lambda   = meta::apply_partial_1_t< lambda_opts, opts, meta::contains_type >::value;
            };


            template< size_t i >
            struct arg {
                using type = std::tuple_element_t< i, std::tuple< Args... > >;
            };


            using args = meta::map_tuple_t< std::tuple< Args... >, std::type_identity_t >;

            using signature = std::conditional_t<
                options::is_const,
                std::conditional_t< options::is_noexcept,
                                    std::conditional_t< ( nargs > 0 ),
                                                        R( Args... ) const noexcept,
                                                        R() const noexcept >,
                                    std::conditional_t< ( nargs > 0 ),
                                                        R( Args... ) const,
                                                        R() const >
                >,
                std::conditional_t< options::is_noexcept,
                                    std::conditional_t< ( nargs > 0 ),
                                                        R( Args... ) noexcept,
                                                        R() noexcept >,
                                    std::conditional_t< ( nargs > 0 ),
                                                        R( Args... ),
                                                        R() >
                >
            >;
        };
    }


    template< typename T >
    struct function_traits;


    template< typename R, bool NoExcept, typename... Args >
    struct function_traits< R( Args... ) noexcept(NoExcept) >
            : impl::function_traits_helper<
                impl::func_traits_opts< std::conditional_t< NoExcept, impl::noexcept_opts, void > >,
                R( Args... ), R, Args... > { };


    template< typename R, bool NoExcept, typename... Args >
    struct function_traits< R( Args... ) const noexcept(NoExcept) >
            : impl::function_traits_helper<
                impl::func_traits_opts<
                    impl::const_opts,
                    std::conditional_t< NoExcept, impl::noexcept_opts, void > >,
                R( Args... ), R, Args... > { };


    // Specialization for function pointers
    template< typename R, bool NoExcept, typename... Args >
    struct function_traits< R( * )( Args... ) noexcept(NoExcept) >
            : impl::function_traits_helper<
                impl::func_traits_opts< std::conditional_t< NoExcept, impl::noexcept_opts, void > >, R( Args... ), R, Args... > { };


    // Specialization for member function pointers
    template< typename C, typename R, bool NoExcept, typename... Args >
    struct function_traits< R( C::* )( Args... ) noexcept(NoExcept) >
            : impl::function_traits_helper<
                impl::func_traits_opts< std::conditional_t< NoExcept, impl::noexcept_opts, void > >, R( Args... ), R, Args... > { };


    // Specialization for const member function pointers
    template< typename C, typename R, bool NoExcept, typename... Args >
    struct function_traits< R( C::* )( Args... ) const noexcept(NoExcept) >
            : impl::function_traits_helper<
                impl::func_traits_opts<
                    impl::const_opts,
                    std::conditional_t< NoExcept, impl::noexcept_opts, void > >, R( Args... ), R, Args... > { };


    // Specialization for lambdas and other callables
    template< typename T >
    struct function_traits : function_traits< decltype(&T::operator()) > { };


    template< typename R, typename... Args >
    struct function_traits< std::function< R( Args... ) > > : impl::function_traits_helper< impl::func_traits_opts< >, R( Args... ), R, Args... > { };


    template< typename R, typename... Args >
    struct function_traits< std::function< R( Args... ) const > > : impl::function_traits_helper< impl::func_traits_opts< impl::const_opts >, R( Args... ), R, Args... > { };


    template< typename R, bool NoExcept, typename... Args >
    struct function_traits< func< R( Args... ) noexcept(NoExcept) > >
            : impl::function_traits_helper<
                impl::func_traits_opts< std::conditional_t< NoExcept, impl::noexcept_opts, void > >, R( Args... ), R, Args... > { };


    template< typename R, bool NoExcept, typename... Args >
    struct function_traits< func< R( Args... ) const noexcept(NoExcept) > >
            : impl::function_traits_helper<
                impl::func_traits_opts<
                    impl::const_opts,
                    std::conditional_t< NoExcept, impl::noexcept_opts, void > >, R( Args... ), R, Args... > { };


    template< typename R, bool NoExcept, typename... Args >
    struct function_traits< func_unique< R( Args... ) noexcept(NoExcept) > >
            : impl::function_traits_helper<
                impl::func_traits_opts< std::conditional_t< NoExcept, impl::noexcept_opts, void > >, R( Args... ), R, Args... > { };


    template< typename R, bool NoExcept, typename... Args >
    struct function_traits< func_unique< R( Args... ) const noexcept(NoExcept) > >
            : impl::function_traits_helper<
                impl::func_traits_opts<
                    impl::const_opts,
                    std::conditional_t< NoExcept, impl::noexcept_opts, void > >, R( Args... ), R, Args... > { };


    template< typename R, bool NoExcept, typename... Args >
    struct function_traits< func_view< R( Args... ) noexcept(NoExcept) > >
            : impl::function_traits_helper<
                impl::func_traits_opts< std::conditional_t< NoExcept, impl::noexcept_opts, void > >, R( Args... ), R, Args... > { };


    template< typename R, bool NoExcept, typename... Args >
    struct function_traits< func_view< R( Args... ) const noexcept(NoExcept) > >
            : impl::function_traits_helper<
                impl::func_traits_opts<
                    impl::const_opts,
                    std::conditional_t< NoExcept, impl::noexcept_opts, void > >, R( Args... ), R, Args... > { };


    template< typename T >
    using return_type_t = typename function_traits< T >::result_type;

    // --------------------------------------------------------------------------

    template< typename T, typename... S >
    concept IsCallable = requires( T t )
    {
        std::is_constructible_v< func< S... >, decltype(t) >
        || std::is_constructible_v< func_view< S... >, decltype(t) >
        || std::is_constructible_v< func_unique< S... >, decltype(t) >;
    };


    template< typename T >
    concept IsFunction = IsCallable< T > && requires
    {
        typename T;
    };

    template< typename T >
    concept IsFunctionOrVoid = IsFunction< T > || std::is_void_v< T >;

}

}
