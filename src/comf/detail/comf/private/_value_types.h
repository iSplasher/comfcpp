/**
 * \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once

#include <indirect.h>
#include <polymorphic.h>


namespace value_types {

/**
 * \brief An instance of value_type<T> owns an object of class T.
 *
 *  Behaves as value types and allow special member functions for a class that contains them as members to be generated correctly.
 *  Our experience suggests that use of these class templates can significantly decrease the burden of writing and
 *  maintaining error-prone boilerplate code.
 */
template< class T, class A = std::allocator< T > >
using value_type = xyz::indirect< T, A >;

/**
 * \brief An instance of poly_type<T> owns an object of class T or a class derived from T.
 *
 *  Behaves as value types and allow special member functions for a class that contains them as members to be generated correctly.
 *  Our experience suggests that use of these class templates can significantly decrease the burden of writing and
 *  maintaining error-prone boilerplate code.
 */

template< class T, class A = std::allocator< T > >
using poly_type = xyz::polymorphic< T, A >;
}
