/**
 * \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once

#include <format>
#include <string_view>
#include <spdlog/spdlog.h>

#include "comf/constants.h"

#ifdef APP_TESTING
#pragma message("Testing environment detected, logger will use test::log instead of spdlog")
#include <iostream>
#include <spdlog/pattern_formatter.h>
#endif


namespace
COMF_NAMESPACE {
#ifdef APP_TESTING
static auto spdlog_formatter = spdlog::pattern_formatter();
#endif

template< typename T, typename = std::void_t< > >
inline constexpr bool HAS_TO_STRING = false;
template< typename T >
inline constexpr bool HAS_TO_STRING< T, std::void_t< decltype(std::declval< T >().toString()) > > = true;


struct logger {
    // Log levels supported by spdlog
    enum class Level {
        trace,
        debug,
        info,
        warn,
        error,
        critical
    };


    // Log a message with a specific log level
    constexpr static void log( Level level, std::string_view msg, auto&&... args ) {
        const auto message = std::vformat( msg, std::make_format_args( std::forward< decltype(args) >( args )... ) );

#ifdef APP_TESTING
        spdlog::memory_buf_t buf;
        spdlog_formatter.format(
                                spdlog::details::log_msg(
                                                         "test_logger", spdlog::level::info,
                                                         message
                                                        ), buf );

        std::cout << fmt::to_string( buf ) << std::endl;
        return;
#endif

        switch ( level ) {
            case Level::trace:
                spdlog::trace( message );
                break;
            case Level::debug:
                spdlog::debug( message );
                break;
            case Level::info:
                spdlog::info( message );
                break;
            case Level::warn:
                spdlog::warn( message );
                break;
            case Level::error:
                spdlog::error( message );
                break;
            case Level::critical:
                spdlog::critical( message );
                break;
            default:
                spdlog::info( message );
        }
    }

    // Shorthand methods for specific log levels

    constexpr static void trace( auto&&... args ) {
        log( Level::trace, std::forward< decltype(args) >( args )... );
    }

    constexpr static void debug( auto&&... args ) {
        log( Level::debug, std::forward< decltype(args) >( args )... );
    }

    constexpr static void info( auto&&... args ) {
        log( Level::info, std::forward< decltype(args) >( args )... );
    }

    constexpr static void warn( auto&&... args ) {
        log( Level::warn, std::forward< decltype(args) >( args )... );
    }

    constexpr static void error( auto&&... args ) {
        log( Level::error, std::forward< decltype(args) >( args )... );
    }

    constexpr static void critical( auto&&... args ) {
        log( Level::critical, std::forward< decltype(args) >( args )... );
    }
};


bool setupLogger();
}
