/**
 * \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once

#include "comf/constants.h"
#include "fmt/format.h"
#include "fmt/compile.h"
#include <typeinfo>


namespace
COMF_NAMESPACE::mixin {

struct stringifiable {
    constexpr std::string_view toString( this auto&& self ) {
        auto content = self.contentStr();
        if constexpr ( content.empty() ) {
            return fmt::format( FMT_COMPILE( "<{}>" ), self.typeStr(), content );
        }
        return fmt::format( FMT_COMPILE( "<{}: {}>" ), self.typeStr(), content );
    }

    constexpr std::string_view typeStr( this auto&& self ) {
        return typeid( self ).name();
    }

    constexpr std::string_view contentStr( this auto&& self ) {
        return "";
    }
};

}
