/**
 * \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#include "comf/assert.h"
#include "comf/constants.h"

#include <cassert>

using namespace COMF_NAMESPACE;

APP_ASSERT_NAMESPACE::AssertAction::AssertAction COMF_NAMESPACE::IMPL_NAMESPACE::app_assert_handler(
    const char* file,
    int         line,
    const char* function,
    const char* expression,
    int         level,
    const char* message
) {
    throw std::logic_error( "Not implemented" );
}
