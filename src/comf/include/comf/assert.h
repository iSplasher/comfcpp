/**
 * \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once


#ifdef DEBUG
#define app_assert_log_file "./__assert__.log"
// runcate the log file upon each program invocation
#define app_assert_log_file_truncate

#endif

#ifndef APP_ASSERT_NAMESPACE
#define APP_ASSERT_NAMESPACE ppk::assert::implementation
#endif

#ifdef APP_TESTING
#define app_assert_default_action AssertAction::AssertAction::Throw
#endif

#include "private/_assert.h"

using AssertException = ppk::assert::AssertionException;

//


namespace comf::impl {

APP_ASSERT_NAMESPACE::AssertAction::AssertAction app_assert_handler(
    const char* file,
    int         line,
    const char* function,
    const char* expression,
    int         level,
    const char* message
);

}

