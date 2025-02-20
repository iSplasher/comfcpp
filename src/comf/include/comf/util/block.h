/**
 * \brief $END$
 *        $BDESCRIPTION$
 * $BODY$
 */

#pragma once

#include <array>
#include <bitset>
#include <format>
#include <vector>
#include <memory>
#include <type_traits>

#include "comf/constants.h"
#include "private/_hana.h"


namespace
COMF_UTIL_NAMESPACE {
template< meta::UnsignedIntegralConstant N >
struct block {
    using array = std::array< std::byte, N >;

    using size_type  = std::decay< decltype(N) >;
    using value_type = std::byte;

    using pointer         = value_type*;
    using const_pointer   = const value_type*;
    using reference       = value_type&;
    using const_reference = const value_type&;

    using difference_type = typename array::difference_type;

    using iterator               = typename array::iterator;
    using const_iterator         = typename array::const_iterator;
    using reverse_iterator       = typename array::reverse_iterator;
    using const_reverse_iterator = typename array::const_reverse_iterator;


    constexpr block() = default;

    constexpr auto operator<=>( const block& ) const = default;

    constexpr block( std::initializer_list< std::byte > init ) {
        std::copy_n( init.begin(), std::min( N, init.size() ), _data.begin() );
#ifdef DEBUG
        if ( init.size() > N ) {
            throw std::out_of_range( std::format( "block::block<{}>( std::initializer_list< std::byte > ) : init.size[{}]() > {}", N, init.size(), N ) );
        }
#endif
    }

    template< typename T, meta::UnsignedIntegralConstant S = meta::h_sizeof( meta::type_value< T > ), typename... Args >
    [[nodiscard]] static constexpr block< S >&& create( Args&&... args ) {
        block< meta::h_sizeof( S ) > b;

        new( b.data() ) T( std::forward< Args >( args )... );

        return std::move( b );
    }

    template< typename T >
    [[nodiscard]] constexpr T* to_type( this auto&& self ) {
        return reinterpret_cast< T* >( self.data() );
    }

    constexpr auto&& operator[]( this auto&& self, const size_type index ) {
        return self._data[index];
    }

    [[nodiscard]] constexpr auto&& data( this auto&& self ) { return self._data.data(); }


    [[nodiscard]] constexpr iterator               begin( this auto&& self ) { return self._data.begin(); }
    [[nodiscard]] constexpr const_iterator         cbegin( this auto&& self ) { return self._data.cbegin(); }
    [[nodiscard]] constexpr reverse_iterator       rbegin( this auto&& self ) { return self._data.rbegin(); }
    [[nodiscard]] constexpr const_reverse_iterator crbegin( this auto&& self ) { return self._data.crbegin(); }

    [[nodiscard]] constexpr iterator               end( this auto&& self ) { return self._data.end(); }
    [[nodiscard]] constexpr const_iterator         cend( this auto&& self ) { return self._data.cend(); }
    [[nodiscard]] constexpr reverse_iterator       rend( this auto&& self ) { return self._data.rend(); }
    [[nodiscard]] constexpr const_reverse_iterator crend( this auto&& self ) { return self._data.crend(); }

    [[nodiscard]] constexpr auto&& empty( this auto&& self ) { return self._data.empty(); }
    [[nodiscard]] constexpr auto&& size( this auto&& self ) { return self._data.size(); }
    [[nodiscard]] constexpr auto&& max_size( this auto&& self ) { return self._data.max_size(); }

    constexpr void swap( this auto&& self, block& other ) noexcept {
        self._data.swap( other._data );
    }

    constexpr void fill( this auto&& self, const std::byte& value ) {
        self._data.fill( value );
    }

private:
    array _data{};
};


template< meta::UnsignedIntegralConstant N >
constexpr void swap( block< N >& lhs, block< N >& rhs ) noexcept {
    lhs.swap( rhs );
}

// ----------------------------------------------------------------------------

class sized_block {

public:
    template< meta::UnsignedIntegral N >
    explicit sized_block( const N size )
        : _block( std::make_unique< block_derived< size > >() ) { }

    template< meta::UnsignedIntegralConstant N >
    explicit sized_block( const block< N >& blk )
        : _block( std::make_unique< block_derived< N > >( blk ) ) { }

    template< meta::UnsignedIntegralConstant N >
    explicit sized_block( block< N >&& blk )
        : _block( std::make_unique< block_derived< N > >( std::move( blk ) ) ) { }

    sized_block( const sized_block& other )
        : _block( other._block ? other._block->clone() : nullptr ) { }

    sized_block( sized_block&& other ) noexcept
        : _block( std::move( other._block ) ) { }


    sized_block& operator=( sized_block&& other ) noexcept {
        if ( this != &other ) {
            _block = std::move( other._block );
        }
        return *this;
    }

    [[nodiscard]] const std::byte* data() const {
        return _block->data();
    }

    [[nodiscard]] std::size_t size() const {
        return _block->size();
    }

private:
    struct block_base {
        virtual ~block_base() = default;

        [[nodiscard]] virtual const std::byte* data() const = 0;

        [[nodiscard]] virtual std::size_t size() const = 0;

        [[nodiscard]] virtual block_base* clone() const = 0;

    };


    template< meta::UnsignedIntegralConstant N >
    struct block_derived final : block_base {
        block_derived() = default;

        template< typename... Args >
        explicit block_derived( Args&&... args )
            : blk( std::forward< Args >( args )... ) { }

        explicit block_derived( const block< N >& blk )
            : blk( blk ) { }

        explicit block_derived( block< N >&& blk )
            : blk( std::move( blk ) ) { }

        [[nodiscard]] const std::byte* data() const override {
            return blk.data();
        }

        [[nodiscard]] std::size_t size() const override {
            return N;
        }

        [[nodiscard]] block_base* clone() const override {
            return new block_derived( blk );
        }

        block< N > blk;
    };


    std::unique_ptr< block_base > _block;
};


// ----------------------------------------------------------------------------

class dynamic_blocks {
public:
    template< meta::UnsignedIntegralConstant N >
    void push_back( const block< N >& blk ) {
        data.push_back( std::make_unique< block_base >( blk ) );
    }

    template< meta::UnsignedIntegralConstant N >
    void push_back( block< N >&& blk ) {
        data.push_back( std::make_unique< block_base >( std::move( blk ) ) );
    }


    [[nodiscard]] std::size_t size() const {
        return data.size();
    }

    [[nodiscard]] bool empty() const {
        return data.empty();
    }

    void clear() {
        data.clear();
    }

    [[nodiscard]] const std::byte* data_ptr( const std::size_t index ) const {
        return data[index]->data();
    }

    [[nodiscard]] std::size_t block_size( const std::size_t index ) const {
        return data[index]->size();
    }


    class iterator {
    public:
        using iterator_category = std::forward_iterator_tag;
        using value_type        = std::byte;
        using difference_type   = std::ptrdiff_t;
        using pointer           = const std::byte*;
        using reference         = const std::byte&;

        iterator( const dynamic_blocks& blocks, const std::size_t block_index, const std::size_t byte_index )
            : blocks( blocks ), block_index( block_index ), byte_index( byte_index ) { }

        iterator& operator++() {
            ++byte_index;
            if ( byte_index == blocks.block_size( block_index ) ) {
                ++block_index;
                byte_index = 0;
            }
            return *this;
        }

        iterator operator++( int ) {
            iterator tmp = *this;
            ++( *this );
            return tmp;
        }

        bool operator==( const iterator& other ) const {
            return &blocks == &other.blocks && block_index == other.block_index && byte_index == other.byte_index;
        }

        bool operator!=( const iterator& other ) const {
            return !( *this == other );
        }

        reference operator*() const {
            return *( blocks.data_ptr( block_index ) + byte_index );
        }

        pointer operator->() const {
            return blocks.data_ptr( block_index ) + byte_index;
        }

    private:
        const dynamic_blocks& blocks;
        std::size_t           block_index;
        std::size_t           byte_index;
    };


    [[nodiscard]] iterator begin() const {
        return { *this, 0, 0 };
    }

    [[nodiscard]] iterator end() const {
        return { *this, data.size(), 0 };
    }

private:
    struct block_base {
        virtual ~block_base() = default;

        [[nodiscard]] virtual const std::byte* data() const = 0;

        [[nodiscard]] virtual std::size_t size() const = 0;
    };


    template< meta::UnsignedIntegralConstant N >
    struct block_derived : block_base {
        explicit block_derived( const block< N >& blk )
            : blk( blk ) { }

        explicit block_derived( block< N >&& blk )
            : blk( std::move( blk ) ) { }

        [[nodiscard]] const std::byte* data() const override {
            return blk.data();
        }

        [[nodiscard]] std::size_t size() const override {
            return N;
        }

        block< N > blk;
    };


    std::vector< std::unique_ptr< block_base > > data;
};


}


namespace boost::hana {
template< COMF_NAMESPACE::meta::UnsignedIntegralConstant N >
struct tag_of< COMF_UTIL_NAMESPACE::block< N > > {
    using type = range_tag;
};


template< COMF_NAMESPACE::meta::UnsignedIntegralConstant N >
struct make_impl< range_tag, COMF_UTIL_NAMESPACE::block< N > > {
    template< typename... Xs >
    static constexpr auto apply( Xs&&... xs ) {
        return COMF_UTIL_NAMESPACE::block< N >{ std::byte{ static_cast< unsigned char >( xs ) }... };
    }
};


template< COMF_NAMESPACE::meta::UnsignedIntegralConstant N, typename I >
struct at_impl< COMF_UTIL_NAMESPACE::block< N >, I > {
    static constexpr auto apply( COMF_UTIL_NAMESPACE::block< N >& b ) {
        return b[I::value];
    }
};
}
