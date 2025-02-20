/**
 * \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#include "comf/logger.h"

#include <spdlog/sinks/stdout_color_sinks.h>


using namespace COMF_NAMESPACE;

bool COMF_NAMESPACE::setupLogger() {
    auto console_sink = std::make_shared< spdlog::sinks::stdout_color_sink_mt >();
    spdlog::set_default_logger( std::make_shared< spdlog::logger >( "app", console_sink ) );
    spdlog::set_pattern( "[%Y-%m-%d %H:%M:%S.%e] [%^%l%$] %v" );
    spdlog::set_level( spdlog::level::trace );

    return true;
}
