// @formatter:off
// https://github.com/gpakosz/ppk_assert

// see README.md for usage instructions.
// (‑●‑●)> released under the WTFPL v2 license, by Gregory Pakosz (@gpakosz)

// -- usage --------------------------------------------------------------------
/*

  run-time assertions:

    app_assert(expression);
    app_assert(expression, message, ...);

    app_assert_warning(expression);
    app_assert_warning(expression, message, ...);

    app_assert_debug(expression);
    app_assert_debug(expression, message, ...);

    app_assert_error(expression);
    app_assert_error(expression, message);

    app_assert_fatal(expression);
    app_assert_fatal(expression, message, ...);

    app_assert_custom(level, expression);
    app_assert_custom(level, expression, message, ...);

    app_assert_used(type)
    app_assert_used_warning(type)
    app_assert_used_debug(type)
    app_assert_used_error(type)
    app_assert_used_fatal(type)
    app_assert_used_custom(level, type)

    app_assert_used(bool) foo()
    {
      return true;
    }

  compile-time assertions:

    app_static_assert(expression)
    app_static_assert(expression, message)

*/

#pragma once

#if !defined(app_assert_enabled)
  #if !defined(NDEBUG) // if we are in debug mode
    #define app_assert_enabled 1 // enable them
  #endif
#endif

#if !defined(app_assert_default_level)
  #define app_assert_default_level Debug
#endif

// -- implementation -----------------------------------------------------------

#if (defined(__GNUC__) && ((__GNUC__ * 1000 + __GNUC_MINOR__ * 100) >= 4600)) || defined(__clang__)
  #pragma GCC diagnostic push
  #pragma GCC diagnostic ignored "-Wvariadic-macros"
#endif

#if defined(__clang__)
  #pragma GCC diagnostic ignored "-Wgnu-zero-variadic-macro-arguments"
  #pragma GCC diagnostic ignored "-Wdeprecated-dynamic-exception-spec"
#endif

#if !defined(app_assert_h)
  #define app_assert_h

  #define app_assert(...)                    app_assert_(ppk::assert::implementation::AssertLevel::app_assert_default_level, __VA_ARGS__)
  #define app_assert_warning(...)            app_assert_(ppk::assert::implementation::AssertLevel::Warning, __VA_ARGS__)
  #define app_assert_debug(...)              app_assert_(ppk::assert::implementation::AssertLevel::Debug, __VA_ARGS__)
  #define app_assert_error(...)              app_assert_(ppk::assert::implementation::AssertLevel::Error, __VA_ARGS__)
  #define app_assert_fatal(...)              app_assert_(ppk::assert::implementation::AssertLevel::Fatal, __VA_ARGS__)
  #define app_assert_custom(level, ...)      app_assert_(level, __VA_ARGS__)

  #define app_assert_used(...)               app_assert_used_(__VA_ARGS__)
  #define app_assert_used_warning(...)       app_assert_used_(ppk::assert::implementation::AssertLevel::Warning, __VA_ARGS__)
  #define app_assert_used_debug(...)         app_assert_used_(ppk::assert::implementation::AssertLevel::Debug, __VA_ARGS__)
  #define app_assert_used_error(...)         app_assert_used_(ppk::assert::implementation::AssertLevel::Error, __VA_ARGS__)
  #define app_assert_used_fatal(...)         app_assert_used_(ppk::assert::implementation::AssertLevel::Fatal, __VA_ARGS__)
  #define app_assert_used_custom(level, ...) app_assert_used_(level, __VA_ARGS__)


  #define app_assert_join(lhs, rhs)   app_assert_join_(lhs, rhs)
  #define app_assert_join_(lhs, rhs)  app_assert_join__(lhs, rhs)
  #define app_assert_join__(lhs, rhs) lhs##rhs

  #define app_assert_file __FILE__
  #define app_assert_line __LINE__
  #if defined(__GNUC__) || defined(__clang__)
    #define app_assert_function __PRETTY_FUNCTION__
  #elif defined(_MSC_VER)
    #define app_assert_function __FUNCSIG__
  #elif defined(__SUNPRO_CC)
    #define app_assert_function __func__
  #else
    #define app_assert_function __FUNCTION__
  #endif

  #if defined(_MSC_VER)
    #define app_assert_always_inline __forceinline
  #elif defined(__GNUC__) || defined(__clang__)
    #define app_assert_always_inline inline __attribute__((always_inline))
  #else
    #define app_assert_always_inline inline
  #endif

  #define app_assert_no_macro

  #define app_assert_apply_va_args(M, ...) app_assert_apply_va_args_(M, (__VA_ARGS__))
  #define app_assert_apply_va_args_(M, args) M args

  #define app_assert_narg(...) app_assert_apply_va_args(app_assert_narg_, app_assert_no_macro,##__VA_ARGS__,\
    32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16,\
    15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, app_assert_no_macro)
  #define app_assert_narg_( _0, _1, _2, _3, _4, _5, _6, _7, _8,\
                            _9, _10, _11, _12, _13, _14, _15, _16,\
                            _17, _18, _19, _20, _21, _22, _23, _24,\
                            _25, _26, _27, _28, _29, _30, _31, _32, _33, ...) _33

  #define app_assert_has_one_arg(...) app_assert_apply_va_args(app_assert_narg_, app_assert_no_macro,##__VA_ARGS__,\
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,\
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, app_assert_no_macro)

  #if defined(__GNUC__) || defined(__clang__)
    #define app_assert_likely(arg) __builtin_expect(!!(arg), !0)
    #define app_assert_unlikely(arg) __builtin_expect(!!(arg), 0)
  #else
    #define app_assert_likely(arg) (arg)
    #define app_assert_unlikely(arg) (arg)
  #endif

  #define app_assert_unused(expression) (void)(true ? (void)0 : ((void)(expression)))

  #if !defined(app_assert_debug_break)
    #if defined(_WIN32) && !defined(__GNUC__)
      extern void __cdecl __debugbreak(void);
      #define app_assert_debug_break() __debugbreak()
    #else
      #if defined(__APPLE__)
        #include <TargetConditionals.h>
      #endif
      #if defined(__clang__) && !TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        #define app_assert_debug_break() __builtin_debugtrap()
      #elif defined(linux) || defined(__linux) || defined(__linux__) || defined(__APPLE__)
        #include <signal.h>
        #define app_assert_debug_break() raise(SIGTRAP)
      #elif defined(__GNUC__)
        #define app_assert_debug_break() __builtin_trap()
      #else
        #define app_assert_debug_break() ((void)0)
      #endif
    #endif
  #endif

  #if (defined (__cplusplus) && (__cplusplus > 199711L)) || (defined(_MSC_FULL_VER) && (_MSC_FULL_VER >= 150020706))
    #define app_assert_cxx11
  #endif

  #if defined(app_assert_cxx11)
    #define app_assert_nullptr nullptr
  #else
    #define app_assert_nullptr 0
  #endif

  #define app_assert_(level, ...)          app_assert_join(app_assert_, app_assert_has_one_arg(__VA_ARGS__))(level, __VA_ARGS__)
  #define app_assert_0(level, ...)         app_assert_apply_va_args(app_assert_2, level, __VA_ARGS__)
  #define app_assert_1(level, expression)  app_assert_2(level, expression, app_assert_nullptr)

  #if defined(_MSC_FULL_VER) && (_MSC_FULL_VER >= 140050215)

    #if defined(app_assert_disable_ignore_line)

      #define app_assert_3(level, expression, ...)\
        __pragma(warning(push))\
        __pragma(warning(disable: 4127))\
        do\
        {\
          if (app_assert_likely(expression) || ppk::assert::implementation::ignoreAllAsserts());\
          else\
          {\
            if (ppk::assert::implementation::handleAssert(app_assert_file, app_assert_line, app_assert_function, #expression, level, app_assert_nullptr, __VA_ARGS__) == ppk::assert::implementation::AssertAction::Break)\
              app_assert_debug_break();\
          }\
        }\
        while (false)\
        __pragma(warning(pop))

    #else

      #define app_assert_3(level, expression, ...)\
        __pragma(warning(push))\
        __pragma(warning(disable: 4127))\
        do\
        {\
          static bool _ignore = false;\
          if (app_assert_likely(expression) || _ignore || ppk::assert::implementation::ignoreAllAsserts());\
          else\
          {\
            if (ppk::assert::implementation::handleAssert(app_assert_file, app_assert_line, app_assert_function, #expression, level, &_ignore, __VA_ARGS__) == ppk::assert::implementation::AssertAction::Break)\
              app_assert_debug_break();\
          }\
        }\
        while (false)\
        __pragma(warning(pop))

    #endif

  #else

    #if (defined(__GNUC__) && ((__GNUC__ * 1000 + __GNUC_MINOR__ * 100) >= 4600)) || defined(__clang__)
      #define _pragma(x) _Pragma(#x)
      #define _app_assert_wformat_as_error_begin\
        _pragma(GCC diagnostic push)\
        _pragma(GCC diagnostic error "-Wformat")
      #define _app_assert_wformat_as_error_end\
        _pragma(GCC diagnostic pop)
    #else
      #define _app_assert_wformat_as_error_begin
      #define _app_assert_wformat_as_error_end
    #endif

    #if defined(app_assert_disable_ignore_line)

      #define app_assert_3(level, expression, ...)\
        do\
        {\
          if (app_assert_likely(expression) || ppk::assert::implementation::ignoreAllAsserts());\
          else\
          {\
            _app_assert_wformat_as_error_begin\
            if (ppk::assert::implementation::handleAssert(app_assert_file, app_assert_line, app_assert_function, #expression, level, app_assert_nullptr, __VA_ARGS__) == ppk::assert::implementation::AssertAction::Break)\
              app_assert_debug_break();\
            _app_assert_wformat_as_error_end\
          }\
        }\
        while (false)

    #else

      #define app_assert_3(level, expression, ...)\
        do\
        {\
          static bool _ignore = false;\
          if (app_assert_likely(expression) || _ignore || ppk::assert::implementation::ignoreAllAsserts());\
          else\
          {\
            _app_assert_wformat_as_error_begin\
            if (ppk::assert::implementation::handleAssert(app_assert_file, app_assert_line, app_assert_function, #expression, level, &_ignore, __VA_ARGS__) == ppk::assert::implementation::AssertAction::Break)\
              app_assert_debug_break();\
            _app_assert_wformat_as_error_end\
          }\
        }\
        while (false)

    #endif

  #endif

  #define app_assert_used_(...)            app_assert_used_0(app_assert_narg(__VA_ARGS__), __VA_ARGS__)
  #define app_assert_used_0(N, ...)        app_assert_join(app_assert_used_, N)(__VA_ARGS__)

  #define app_static_assert(...)           app_assert_apply_va_args(app_assert_join(PPK_STATIC_ASSERT_, app_assert_has_one_arg(__VA_ARGS__)), __VA_ARGS__)
  #if defined(app_assert_cxx11)
    #define PPK_STATIC_ASSERT_0(expression, message) static_assert(expression, message)
  #else
    #define PPK_STATIC_ASSERT_0(expression, message)\
      struct app_assert_join(_ppk_static_assertion_at_line_, app_assert_line)\
      {\
        ppk::assert::implementation::StaticAssertion<static_cast<bool>((expression))> app_assert_join(STATIC_ASSERTION_FAILED_AT_LINE_, app_assert_line);\
      };\
      typedef ppk::assert::implementation::StaticAssertionTest<sizeof(app_assert_join(_ppk_static_assertion_at_line_, app_assert_line))> app_assert_join(_ppk_static_assertion_test_at_line_, app_assert_line)
      // note that we wrap the non existing type inside a struct to avoid warning
      // messages about unused variables when static assertions are used at function
      // scope
      // the use of sizeof makes sure the assertion error is not ignored by SFINAE
  #endif
  #define PPK_STATIC_ASSERT_1(expression)  PPK_STATIC_ASSERT_0(expression, #expression)

  #if !defined (app_assert_cxx11)
    namespace ppk {
    namespace assert {
    namespace implementation {

      template <bool>
      struct StaticAssertion;

      template <>
      struct StaticAssertion<true>
      {
      }; // StaticAssertion<true>

      template<int i>
      struct StaticAssertionTest
      {
      }; // StaticAssertionTest<int>

    } // namespace implementation
    } // namespace assert
    } // namespace ppk
  #endif

  #if !defined(app_assert_disable_stl)
    #if defined(_MSC_VER)
      #pragma warning(push)
      #pragma warning(disable: 4548)
      #pragma warning(disable: 4710)
    #endif
    #include <stdexcept>
    #if defined(_MSC_VER)
      #pragma warning(pop)
    #endif
  #endif

  #if !defined(app_assert_exception_message_buffer_size)
    #define app_assert_exception_message_buffer_size 1024
  #endif

  #if defined(app_assert_cxx11) && !defined(_MSC_VER)
    #define app_assert_exception_no_throw noexcept(true)
  #else
    #define app_assert_exception_no_throw throw()
  #endif

  #if defined(app_assert_cxx11)
    #include <utility>
  #endif

  namespace ppk {
  namespace assert {

  #if !defined(app_assert_disable_stl)
    class AssertionException: public std::exception
  #else
    class AssertionException
  #endif
    {
      public:
      explicit AssertionException(const char* file,
                                  int line,
                                  const char* function,
                                  const char* expression,
                                  const char* message);

      AssertionException(const AssertionException& rhs);

      virtual ~AssertionException() app_assert_exception_no_throw;

      AssertionException& operator = (const AssertionException& rhs);

      virtual const char* what() const app_assert_exception_no_throw;

      const char* file() const;
      int line() const;
      const char* function() const;
      const char* expression() const;

      private:
      const char* _file;
      int _line;
      const char* _function;
      const char* _expression;

      enum
      {
        request = app_assert_exception_message_buffer_size,
        size = request > sizeof(char*) ? request : sizeof(char*) + 1
      };

      union
      {
        char  _stack[size];
        char* _heap;
      };

      app_static_assert(size > sizeof(char*), "invalid_size");
    }; // AssertionException

    app_assert_always_inline const char* AssertionException::file() const
    {
      return _file;
    }

    app_assert_always_inline int AssertionException::line() const
    {
      return _line;
    }

    app_assert_always_inline const char* AssertionException::function() const
    {
      return _function;
    }

    app_assert_always_inline const char* AssertionException::expression() const
    {
      return _expression;
    }

    namespace implementation {

    #if defined(_MSC_VER) && !defined(_CPPUNWIND)
      #if !defined(app_assert_disable_exceptions)
        #define app_assert_disable_exceptions
      #endif
    #endif

    #if !defined(app_assert_disable_exceptions)

      template<typename E>
      inline void throwException(const E& e)
      {
        throw e;
      }

    #else

      // user defined, the behavior is undefined if the function returns
      void throwException(const ppk::assert::AssertionException& e);

    #endif

    namespace AssertLevel {

      enum AssertLevel
      {
        Warning = 32,
        Debug   = 64,
        Error   = 128,
        Fatal   = 256

      }; // AssertLevel

    } // AssertLevel

    namespace AssertAction {

      enum AssertAction
      {
        None,
        Abort,
        Break,
        Ignore,
      #if !defined(app_assert_disable_ignore_line)
        IgnoreLine,
      #endif
        IgnoreAll,
        Throw

      }; // AssertAction

    } // AssertAction

    #if !defined(app_assert_call)
      #define app_assert_call
    #endif

    typedef AssertAction::AssertAction (app_assert_call *AssertHandler)(const char* file,
                                                                        int line,
                                                                        const char* function,
                                                                        const char* expression,
                                                                        int level,
                                                                        const char* message);


  #if defined(__GNUC__) || defined(__clang__)
    #define app_assert_handle_assert_format __attribute__((format (printf, 7, 8)))
  #else
    #define app_assert_handle_assert_format
  #endif

  #if !defined(app_assert_funcspec)
    #define app_assert_funcspec
  #endif

    app_assert_funcspec
    AssertAction::AssertAction app_assert_call handleAssert(const char* file,
                                                            int line,
                                                            const char* function,
                                                            const char* expression,
                                                            int level,
                                                            bool* ignoreLine,
                                                            const char* message, ...) app_assert_handle_assert_format;

    app_assert_funcspec
    AssertHandler app_assert_call setAssertHandler(AssertHandler handler);

    app_assert_funcspec
    void app_assert_call ignoreAllAsserts(bool value);

    app_assert_funcspec
    bool app_assert_call ignoreAllAsserts();

  #if defined(app_assert_cxx11)

    template<int level, typename T>
    class AssertUsedWrapper
    {
      public:
      AssertUsedWrapper(T&& t);
      ~AssertUsedWrapper() app_assert_exception_no_throw;

      operator T();

      private:
      const AssertUsedWrapper& operator = (const AssertUsedWrapper&); // not implemented on purpose (and only VS2013 supports deleted functions)

      T t;
      mutable bool used;

    }; // AssertUsedWrapper<int, T>

    template<int level, typename T>
    inline AssertUsedWrapper<level, T>::AssertUsedWrapper(T&& _t)
      : t(std::forward<T>(_t)), used(false)
    {}

    template<int level, typename T>
    inline AssertUsedWrapper<level, T>::operator T()
    {
      used = true;
      return std::move(t);
    }

    template<int level, typename T>
    inline AssertUsedWrapper<level, T>::~AssertUsedWrapper() app_assert_exception_no_throw
    {
      app_assert_3(level, used, "unused value");
    }

  #else

    template<int level, typename T>
    class AssertUsedWrapper
    {
      public:
      AssertUsedWrapper(const T& t);
      AssertUsedWrapper(const AssertUsedWrapper& rhs);
      ~AssertUsedWrapper() app_assert_exception_no_throw;

      operator T() const;

      private:
      const AssertUsedWrapper& operator = (const AssertUsedWrapper&); // not implemented on purpose

      T t;
      mutable bool used;

    }; // AssertUsedWrapper<int, T>

    template<int level, typename T>
    app_assert_always_inline AssertUsedWrapper<level, T>::AssertUsedWrapper(const T& _t)
      : t(_t), used(false)
    {}

    template<int level, typename T>
    app_assert_always_inline AssertUsedWrapper<level, T>::AssertUsedWrapper(const AssertUsedWrapper& rhs)
      : t(rhs.t), used(rhs.used)
    {}

    // /!\ GCC is not so happy if we inline that destructor
    template<int level, typename T>
    AssertUsedWrapper<level, T>::~AssertUsedWrapper() app_assert_exception_no_throw
    {
      app_assert_3(level, used, "unused value");
    }

    template<int level, typename T>
    app_assert_always_inline AssertUsedWrapper<level, T>::operator T() const
    {
      used = true;
      return t;
    }

  #endif

  } // namespace implementation

  } // namespace assert
  } // namespace ppk

#endif

#undef app_assert_2
#undef app_assert_used_1
#undef app_assert_used_2

#if defined(_MSC_VER) && defined(_PREFAST_)

  #define app_assert_2(level, expression, ...) __analysis_assume(!!(expression))
  #define app_assert_used_1(type)              type
  #define app_assert_used_2(level, type)       type

#elif defined(__clang__) && defined(__clang_analyzer__)

  void its_going_to_be_ok(bool expression) __attribute__((analyzer_noreturn));
  #define app_assert_2(level, expression, ...) its_going_to_be_ok(!!(expression))
  #define app_assert_used_1(type)              type
  #define app_assert_used_2(level, type)       type

#else

  #if app_assert_enabled

    #define app_assert_2(level, expression, ...) app_assert_3(level, expression, __VA_ARGS__)
    #define app_assert_used_1(type)              ppk::assert::implementation::AssertUsedWrapper<ppk::assert::implementation::AssertLevel::app_assert_default_level, type>
    #define app_assert_used_2(level, type)       ppk::assert::implementation::AssertUsedWrapper<level, type>

  #else

    #define app_assert_2(level, expression, ...) app_assert_unused(expression)
    #define app_assert_used_1(type)              type
    #define app_assert_used_2(level, type)       type

  #endif

#endif

#if (defined(__GNUC__) && ((__GNUC__ * 1000 + __GNUC_MINOR__ * 100) >= 4600)) || defined(__clang__)
  #pragma GCC diagnostic pop
#endif
