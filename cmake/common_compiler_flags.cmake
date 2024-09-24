# Set some helper variables for readability
set(compiler_is_clang "$<OR:$<CXX_COMPILER_ID:AppleClang>,$<CXX_COMPILER_ID:Clang>>")
set(compiler_is_gnu "$<CXX_COMPILER_ID:GNU>")
set(compiler_is_msvc "$<CXX_COMPILER_ID:MSVC>")

# Add warnings based on compiler & version
# Set some helper variables for readability
set(compiler_less_than_v8 "$<VERSION_LESS:$<CXX_COMPILER_VERSION>,8>")
set(compiler_greater_than_or_equal_v9 "$<VERSION_GREATER_EQUAL:$<CXX_COMPILER_VERSION>,9>")
set(compiler_greater_than_or_equal_v11 "$<VERSION_GREATER_EQUAL:$<CXX_COMPILER_VERSION>,11>")
set(compiler_less_than_v11 "$<VERSION_LESS:$<CXX_COMPILER_VERSION>,11>")
set(compiler_greater_than_or_equal_v12 "$<VERSION_GREATER_EQUAL:$<CXX_COMPILER_VERSION>,12>")

# Workaround of $<CONFIG> expanding to "" when default build set
set(CONFIG "$<IF:$<STREQUAL:,$<CONFIG>>,${CMAKE_BUILD_TYPE},$<CONFIG>>")

# Default optimization levels if GODOT_OPTIMIZE=AUTO, for multi-config support
set(DEFAULT_OPTIMIZATION_DEBUG_FEATURES "$<OR:$<STREQUAL:${GODOT_TARGET},editor>,$<STREQUAL:${GODOT_TARGET},template_debug>>")
set(DEFAULT_OPTIMIZATION "$<NOT:${DEFAULT_OPTIMIZATION_DEBUG_FEATURES}>")

set(GODOT_DEBUG_SYMBOLS_ENABLED "$<OR:$<BOOL:${GODOT_DEBUG_SYMBOLS}>,$<IN_LIST:${CONFIG},${GODOT_CONFIGS_WITH_DEBUG}>>")

list(APPEND GODOT_DEFINITIONS
	$<${compiler_is_msvc}:
		$<$<BOOL:${GODOT_DISABLE_EXCEPTIONS}>:
			_HAS_EXCEPTIONS=0
		>
	>
)

list(APPEND GODOT_C_FLAGS
	$<${compiler_is_msvc}:
		$<${GODOT_DEBUG_SYMBOLS_ENABLED}:
			/Zi
			/FS
		>

		$<$<STREQUAL:${GODOT_OPTIMIZE},auto>:
			$<$<OR:$<CONFIG:Release>,$<CONFIG:RelWithDebInfo>>:
				$<${DEFAULT_OPTIMIZATION}:
					/O2
				>
				$<${DEFAULT_OPTIMIZATION_DEBUG_FEATURES}:
					/O2
				>
			>
			$<$<CONFIG:MinSizeRel>:
				/O1
			>
			$<$<OR:$<CONFIG:Debug>,$<CONFIG:>>:
				/Od
			>
		>
		$<$<STREQUAL:${GODOT_OPTIMIZE},speed>:/O2>
		$<$<STREQUAL:${GODOT_OPTIMIZE},speed_trace>:/O2>
		$<$<STREQUAL:${GODOT_OPTIMIZE},size>:/O1>
		$<$<STREQUAL:${GODOT_OPTIMIZE},debug>:/Od>
		$<$<STREQUAL:${GODOT_OPTIMIZE},none>:/Od>

	>
	$<$<NOT:${compiler_is_msvc}>:
		$<${GODOT_DEBUG_SYMBOLS_ENABLED}:
			-gdwarf-4

			$<$<BOOL:${GODOT_DEV_BUILD}>:
				-g3
			>
			$<$<NOT:$<BOOL:${GODOT_DEV_BUILD}>>:
				-g2
			>
		>

		$<$<STREQUAL:${GODOT_OPTIMIZE},auto>:
			$<$<OR:$<CONFIG:Release>,$<CONFIG:RelWithDebInfo>>:
				$<${DEFAULT_OPTIMIZATION}:
					-O3
				>
				$<${DEFAULT_OPTIMIZATION_DEBUG_FEATURES}:
					-O2
				>
			>
			$<$<CONFIG:MinSizeRel>:
				-Os
			>
			$<$<OR:$<CONFIG:Debug>,$<CONFIG:>>:
				-Og
			>
		>
		$<$<STREQUAL:${GODOT_OPTIMIZE},speed>:-O3>
		$<$<STREQUAL:${GODOT_OPTIMIZE},speed_trace>:-O2>
		$<$<STREQUAL:${GODOT_OPTIMIZE},size>:-Os>
		$<$<STREQUAL:${GODOT_OPTIMIZE},debug>:-Og>
		$<$<STREQUAL:${GODOT_OPTIMIZE},none>:-O0>
	>
)

list(APPEND GODOT_CXX_FLAGS
	$<${compiler_is_msvc}:
		$<$<NOT:$<BOOL:${GODOT_DISABLE_EXCEPTIONS}>>:
			/EHsc
		>
	>
	$<$<NOT:${compiler_is_msvc}>:
		$<$<BOOL:${GODOT_DISABLE_EXCEPTIONS}>:
			-fno-exceptions
		>
	>
)

list(APPEND GODOT_LINK_FLAGS
	$<${compiler_is_msvc}:
		$<${GODOT_DEBUG_SYMBOLS_ENABLED}:
			/DEBUG:FULL
		>

		$<$<STREQUAL:${GODOT_OPTIMIZE},auto>:
		$<$<OR:$<CONFIG:Release>,$<CONFIG:RelWithDebInfo>>:
				$<${DEFAULT_OPTIMIZATION}:
					/OPT:REF
				>
				$<${DEFAULT_OPTIMIZATION_DEBUG_FEATURES}:
					/OPT:REF
					/OPT:NOICF
				>
			>
			$<$<CONFIG:MinSizeRel>:
				/OPT:REF
			>
		>
		$<$<STREQUAL:${GODOT_OPTIMIZE},speed>:/OPT:REF>
		$<$<STREQUAL:${GODOT_OPTIMIZE},speed_trace>:/OPT:REF /OPT:NOICF>
		$<$<STREQUAL:${GODOT_OPTIMIZE},size>:/OPT:REF>
	>
	$<$<NOT:${compiler_is_msvc}>:
		$<$<NOT:${GODOT_DEBUG_SYMBOLS_ENABLED}>:
			$<$<CXX_COMPILER_ID:AppleClang>: # SCons: not is_vanilla_clang(env)
				"-Wl,-S"
				"-Wl,-x"
				"-Wl,-dead_strip"
			>
			$<$<NOT:$<CXX_COMPILER_ID:AppleClang>>:
				"-s"
			>
		>
	>
)

# These compiler options reflect what is in godot/SConstruct.
list(APPEND GODOT_COMPILE_WARNING_FLAGS
    # MSVC only
    $<${compiler_is_msvc}:
        /W4

        # Disable warnings which we don't plan to fix.
        /wd4100  # C4100 (unreferenced formal parameter): Doesn't play nice with polymorphism.
        /wd4127  # C4127 (conditional expression is constant)
        /wd4201  # C4201 (non-standard nameless struct/union): Only relevant for C89.
        /wd4244  # C4244 C4245 C4267 (narrowing conversions): Unavoidable at this scale.
        /wd4245
        /wd4267
        /wd4305  # C4305 (truncation): double to float or real_t, too hard to avoid.
        /wd4514  # C4514 (unreferenced inline function has been removed)
        /wd4714  # C4714 (function marked as __forceinline not inlined)
        /wd4820  # C4820 (padding added after construct)
    >

    # Clang and GNU common options
    $<$<OR:${compiler_is_clang},${compiler_is_gnu}>:
        -Wall
        -Wctor-dtor-privacy
        -Wextra
        -Wno-unused-parameter
        -Wnon-virtual-dtor
        -Wwrite-strings
    >

    # Clang only
    $<${compiler_is_clang}:
        -Wimplicit-fallthrough
        -Wno-ordered-compare-function-pointers
    >

    # GNU only
    $<${compiler_is_gnu}:
        -Walloc-zero
        -Wduplicated-branches
        -Wduplicated-cond
        -Wno-misleading-indentation
        -Wplacement-new=1
        -Wshadow-local
        -Wstringop-overflow=4
    >
    $<$<AND:${compiler_is_gnu},${compiler_less_than_v8}>:
        # Bogus warning fixed in 8+.
        -Wno-strict-overflow
    >
    $<$<AND:${compiler_is_gnu},${compiler_greater_than_or_equal_v9}>:
        -Wattribute-alias=2
    >
    $<$<AND:${compiler_is_gnu},${compiler_greater_than_or_equal_v11}>:
        # Broke on MethodBind templates before GCC 11.
        -Wlogical-op
    >
    $<$<AND:${compiler_is_gnu},${compiler_less_than_v11}>:
        # Regression in GCC 9/10, spams so much in our variadic templates that we need to outright disable it.
        -Wno-type-limits
    >
    $<$<AND:${compiler_is_gnu},${compiler_greater_than_or_equal_v12}>:
        # False positives in our error macros, see GH-58747.
        -Wno-return-type
    >
)

# Treat warnings as errors
function(set_warning_as_error TARGET_NAME)
    message(STATUS "[${TARGET_NAME}] Treating warnings as errors")
    if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.24")
        set_target_properties(${TARGET_NAME}
            PROPERTIES
                COMPILE_WARNING_AS_ERROR ON
        )
    else()
        target_compile_options(${TARGET_NAME}
            PRIVATE
                $<${compiler_is_msvc}:/WX>
                $<$<OR:${compiler_is_clang},${compiler_is_gnu}>:-Werror>
        )
    endif()
endfunction()
