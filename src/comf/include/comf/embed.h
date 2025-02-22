#pragma once

#include "comf/private/_constants.h"

#if defined(BATTERY_EMBED_ENABLED)
#pragma message( "Enabled embed support" )

#include "battery/embed.hpp"


namespace
COMF_NAMESPACE {namespace embed {
    template< b::embed_string_literal identifier >
    constexpr auto get() {
        return b::embed< identifier >();
    }

    template< b::embed_string_literal identifier >
    constexpr auto str() {
        return b::embed< identifier >().str();
    }

    template< b::embed_string_literal identifier >
    constexpr auto ptr() {
        return b::embed< identifier >().data();
    }

    template< b::embed_string_literal identifier >
    constexpr auto size() {
        return b::embed< identifier >().size();
    }

    template< b::embed_string_literal identifier >
    constexpr auto vec() {
        return b::embed< identifier >().vec();
    }

    template< b::embed_string_literal identifier >
    constexpr auto length() {
        return b::embed< identifier >().length();
    }
}}
#endif
