# This file contains variables needed by all platforms

### Options

set(GODOT_CONFIGS_WITH_DEBUG "Debug;RelWithDebInfo" CACHE STRING "Configurations that should have debug symbols (Modify if support for custom configurations is needed)")

# Default config
if("${CMAKE_BUILD_TYPE}" STREQUAL "")
	set(CMAKE_BUILD_TYPE "Debug")
endif()

set(GODOT_TARGET "TEMPLATE_DEBUG" CACHE STRING "Target platform (EDITOR, TEMPLATE_DEBUG, TEMPLATE_RELEASE)")

# Auto-detect platform
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
	set(DEFAULT_GODOT_PLATFORM "LINUX")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
	set(DEFAULT_GODOT_PLATFORM "WINDOWS")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
	set(DEFAULT_GODOT_PLATFORM "MACOS")
elseif(CMAKE_SYSTEM_NAME STREQUAL "iOS")
	set(DEFAULT_GODOT_PLATFORM "IOS")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Emscripten") # Set by providing Emscripten toolchain
	set(DEFAULT_GODOT_PLATFORM "WEB")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Android") # Set by providing Android toolchain
	set(DEFAULT_GODOT_PLATFORM "ANDROID")
else()
	set(DEFAULT_GODOT_PLATFORM "NOTFOUND")
endif()

set(GODOT_PLATFORM "${DEFAULT_GODOT_PLATFORM}" CACHE STRING "[Auto-detected] Target platform (LINUX, MACOS, WINDOWS, ANDROID, IOS, WEB)")

if("${GODOT_PLATFORM}" STREQUAL "NOTFOUND")
       message(FATAL_ERROR "Could not auto-detect platform for \"${CMAKE_SYSTEM_NAME}\" automatically, please specify with -DGODOT_PLATFORM=<platform>")
endif()

message(STATUS "Platform detected: ${GODOT_PLATFORM}")

set(GODOT_GDEXTENSION_DIR "${CMAKE_CURRENT_SOURCE_DIR}/gdextension" CACHE FILEPATH "Path to a directory containing GDExtension interface header")

set(GODOT_CUSTOM_API_FILE "${GODOT_GDEXTENSION_DIR}/extension_api.json" CACHE FILEPATH "Path to GDExtension API JSON file")

set(GODOT_PRECISION "SINGLE" CACHE STRING "Floating-point precision level (SINGLE, DOUBLE)")

set(GODOT_OPTIMIZE "AUTO" CACHE STRING "The desired optimization flags (NONE, CUSTOM, DEBUG, SPEED, SPEED_TRACE, SIZE)")

set(GODOT_SYMBOLS_VISIBILITY "AUTO" CACHE STRING "Symbols visibility on GNU platforms (AUTO, VISIBLE, HIDDEN)")

set(GODOT_BUILD_PROFILE "" CACHE FILEPATH "Path to a file containing a feature build profile")


option(GODOT_DEV_BUILD "Developer build with dev-only debugging code" OFF)

option(GODOT_DEBUG_SYMBOLS "Force build with debugging symbols" OFF)

set(DEFAULT_GODOT_USE_HOT_RELOAD ON)
if("${GODOT_TARGET}" STREQUAL "TEMPLATE_RELEASE")
	set(DEFAULT_GODOT_USE_HOT_RELOAD OFF)
endif()
option(GODOT_USE_HOT_RELOAD "Enable the extra accounting required to support hot reload" ${DEFAULT_GODOT_USE_HOT_RELOAD})

# Disable exception handling. Godot doesn't use exceptions anywhere, and this
# saves around 20% of binary size and very significant build time (GH-80513).
option(GODOT_DISABLE_EXCEPTIONS "Force disabling exception handling code" ON)

# Optionally mark headers as SYSTEM
option(GODOT_CPP_SYSTEM_HEADERS "Mark the header files as SYSTEM. This may be useful to suppress warnings in projects including this one" OFF)
set(GODOT_CPP_SYSTEM_HEADERS_ATTRIBUTE "")
if(GODOT_CPP_SYSTEM_HEADERS)
	set(GODOT_CPP_SYSTEM_HEADERS_ATTRIBUTE SYSTEM)
endif()

# Enable by default when building godot-cpp only
set(DEFAULT_WARNING_AS_ERROR OFF)
if(${CMAKE_PROJECT_NAME} STREQUAL ${PROJECT_NAME})
	set(DEFAULT_WARNING_AS_ERROR ON)
endif()
set(GODOT_CPP_WARNING_AS_ERROR "${DEFAULT_WARNING_AS_ERROR}" CACHE BOOL "Treat warnings as errors")

option(GODOT_GENERATE_TEMPLATE_GET_NODE "Generate a template version of the Node class's get_node" ON)

option(GODOT_THREADS "Enable threading support" ON)

###

# Compiler warnings and compiler check generators
include(GodotCompilerWarnings)

# Create the correct name (godot-cpp.platform.target)
# See more prefix appends in platform-specific configs
if(${GODOT_DEV_BUILD})
	string(APPEND LIBRARY_SUFFIX ".dev")
endif()

if("${GODOT_PRECISION}" STREQUAL "DOUBLE")
	string(APPEND LIBRARY_SUFFIX ".double")
endif()

# Workaround of $<CONFIG> expanding to "" when default build set
set(CONFIG "$<IF:$<STREQUAL:,$<CONFIG>>,${CMAKE_BUILD_TYPE},$<CONFIG>>")

string(TOLOWER ".${GODOT_PLATFORM}.${GODOT_TARGET}" platform_target)
string(PREPEND LIBRARY_SUFFIX ${platform_target})

# Default optimization levels if GODOT_OPTIMIZE=AUTO, for multi-config support
set(DEFAULT_OPTIMIZATION_DEBUG_FEATURES "$<OR:$<STREQUAL:${GODOT_TARGET},EDITOR>,$<STREQUAL:${GODOT_TARGET},TEMPLATE_DEBUG>>")
set(DEFAULT_OPTIMIZATION "$<NOT:${DEFAULT_OPTIMIZATION_DEBUG_FEATURES}>")

set(GODOT_DEBUG_SYMBOLS_ENABLED "$<OR:$<BOOL:${GODOT_DEBUG_SYMBOLS}>,$<IN_LIST:${CONFIG},${GODOT_CONFIGS_WITH_DEBUG}>>")

# Clear default options
set(CMAKE_CXX_FLAGS_DEBUG "")
set(CMAKE_CXX_FLAGS_RELEASE "")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "")
set(CMAKE_CXX_FLAGS_MINSIZEREL "")

list(APPEND GODOT_DEFINITIONS
	GDEXTENSION

	$<${compiler_is_msvc}:
		$<$<BOOL:${GODOT_DISABLE_EXCEPTIONS}>:
			_HAS_EXCEPTIONS=0
		>
	>

	$<$<STREQUAL:${GODOT_PRECISION},DOUBLE>:
		REAL_T_IS_DOUBLE
	>
	$<$<BOOL:${GODOT_USE_HOT_RELOAD}>:
		HOT_RELOAD_ENABLED
	>
	$<$<STREQUAL:${GODOT_TARGET},EDITOR>:
		TOOLS_ENABLED
	>

	$<$<BOOL:${GODOT_DEV_BUILD}>:
		DEV_ENABLED
	>
	$<$<NOT:$<BOOL:${GODOT_DEV_BUILD}>>:
		NDEBUG
	>

	$<$<NOT:$<STREQUAL:${GODOT_TARGET},TEMPLATE_RELEASE>>:
		DEBUG_ENABLED
		DEBUG_METHODS_ENABLED
	>
	$<$<BOOL:${GODOT_THREADS}>:
		THREADS_ENABLED
	>
)

list(APPEND GODOT_C_FLAGS
	$<${compiler_is_msvc}:
		$<${GODOT_DEBUG_SYMBOLS_ENABLED}:
			/Zi
			/FS
		>

		$<$<STREQUAL:${GODOT_OPTIMIZE},AUTO>:
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
		$<$<STREQUAL:${GODOT_OPTIMIZE},SPEED>:/O2>
		$<$<STREQUAL:${GODOT_OPTIMIZE},SPEED_TRACE>:/O2>
		$<$<STREQUAL:${GODOT_OPTIMIZE},SIZE>:/O1>
		$<$<STREQUAL:${GODOT_OPTIMIZE},DEBUG>:/Od>
		$<$<STREQUAL:${GODOT_OPTIMIZE},NONE>:/Od>

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

		$<$<STREQUAL:${GODOT_SYMBOLS_VISIBILITY},VISIBLE>:
			-fvisibility=default
		>
		$<$<STREQUAL:${GODOT_SYMBOLS_VISIBILITY},HIDDEN>:
			-fvisibility=hidden
		>

		$<$<STREQUAL:${GODOT_OPTIMIZE},AUTO>:
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
		$<$<STREQUAL:${GODOT_OPTIMIZE},SPEED>:-O3>
		$<$<STREQUAL:${GODOT_OPTIMIZE},SPEED_TRACE>:-O2>
		$<$<STREQUAL:${GODOT_OPTIMIZE},SIZE>:-Os>
		$<$<STREQUAL:${GODOT_OPTIMIZE},DEBUG>:-Og>
		$<$<STREQUAL:${GODOT_OPTIMIZE},NONE>:-O0>
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

		$<$<STREQUAL:${GODOT_OPTIMIZE},AUTO>:
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
		$<$<STREQUAL:${GODOT_OPTIMIZE},SPEED>:/OPT:REF>
		$<$<STREQUAL:${GODOT_OPTIMIZE},SPEED_TRACE>:/OPT:REF /OPT:NOICF>
		$<$<STREQUAL:${GODOT_OPTIMIZE},SIZE>:/OPT:REF>
	>
	$<$<NOT:${compiler_is_msvc}>:
		$<$<STREQUAL:${GODOT_SYMBOLS_VISIBILITY},VISIBLE>:
			-fvisibility=default
		>
		$<$<STREQUAL:${GODOT_SYMBOLS_VISIBILITY},HIDDEN>:
			-fvisibility=hidden
		>

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

# Platform-specific options
if("${GODOT_PLATFORM}" STREQUAL "LINUX")
	include(linux)
elseif("${GODOT_PLATFORM}" STREQUAL "MACOS")
	include(macos)
elseif("${GODOT_PLATFORM}" STREQUAL "WINDOWS")
	include(windows)
elseif("${GODOT_PLATFORM}" STREQUAL "ANDROID")
	include(android)
elseif("${GODOT_PLATFORM}" STREQUAL "IOS")
	include(ios)
elseif("${GODOT_PLATFORM}" STREQUAL "WEB")
	include(web)
else()
	message(FATAL_ERROR "Platform not supported: ${GODOT_PLATFORM}")
endif()

# Mac/IOS uses .framework directory structure and don't need arch suffix
if((NOT "${GODOT_PLATFORM}" STREQUAL "MACOS") AND (NOT "${GODOT_PLATFORM}" STREQUAL "IOS"))
	string(APPEND LIBRARY_SUFFIX ".${GODOT_ARCH}")
endif()

if(${IOS_SIMULATOR})
	string(APPEND LIBRARY_SUFFIX ".simulator")
endif()

if(NOT ${GODOT_THREADS})
	string(APPEND LIBRARY_SUFFIX ".nothreads")
endif()


# Write all flags to file for cmake configuration debug (CMake 3.19+)
#file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/flags-${CONFIG}.txt"
#	CONTENT
#	"C_FLAGS '${GODOT_C_FLAGS}'\nCXX_FLAGS '${GODOT_CXX_FLAGS}'\nLINK_FLAGS '${GODOT_LINK_FLAGS}'\nCOMPILE_WARNING_FLAGS '${GODOT_COMPILE_WARNING_FLAGS}'\nDEFINITIONS '${GODOT_DEFINITIONS}'"
#	GODOT_TARGET ${PROJECT_NAME}
#)
