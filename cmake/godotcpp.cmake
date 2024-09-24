# This file contains variables needed by all platforms

# Helper functions
macro(godot_clear_default_flags)
	# Default options (including multi-config)
	set(CMAKE_EXE_LINKER_FLAGS "")
	set(CMAKE_EXE_LINKER_FLAGS_DEBUG "")
	set(CMAKE_EXE_LINKER_FLAGS_RELEASE "")
	set(CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO "")
	set(CMAKE_EXE_LINKER_FLAGS_MINSIZEREL "")

	set(CMAKE_STATIC_LINKER_FLAGS "")
	set(CMAKE_STATIC_LINKER_FLAGS_DEBUG "")
	set(CMAKE_STATIC_LINKER_FLAGS_RELEASE "")
	set(CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO "")
	set(CMAKE_STATIC_LINKER_FLAGS_MINSIZEREL "")

	set(CMAKE_SHARED_LINKER_FLAGS "")
	set(CMAKE_SHARED_LINKER_FLAGS_DEBUG "")
	set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "")
	set(CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO "")
	set(CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL "")

	set(CMAKE_MODULE_LINKER_FLAGS "")
	set(CMAKE_MODULE_LINKER_FLAGS_DEBUG "")
	set(CMAKE_MODULE_LINKER_FLAGS_RELEASE "")
	set(CMAKE_MODULE_LINKER_FLAGS_RELWITHDEBINFO "")
	set(CMAKE_MODULE_LINKER_FLAGS_MINSIZEREL "")

	set(CMAKE_C_FLAGS "")
	set(CMAKE_C_FLAGS_DEBUG "")
	set(CMAKE_C_FLAGS_RELEASE "")
	set(CMAKE_C_FLAGS_RELWITHDEBINFO "")
	set(CMAKE_C_FLAGS_MINSIZEREL "")

	set(CMAKE_CXX_FLAGS "")
	set(CMAKE_CXX_FLAGS_DEBUG "")
	set(CMAKE_CXX_FLAGS_RELEASE "")
	set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "")
	set(CMAKE_CXX_FLAGS_MINSIZEREL "")

	# (--sysroot= option removed to match SCons options, may return later)
	set(CMAKE_SYSROOT "")
	# TODO: remove `--sysroot=` and default `--target=` for android config
endmacro()

function(godot_make_doc)
	find_package(Python3 3.4 REQUIRED)
	set(options)
	set(oneValueArgs DESTINATION COMPRESSION)
	set(multiValueArgs SOURCES)
	cmake_parse_arguments(MAKE_DOC "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

	if("${MAKE_DOC_COMPRESSION}" STREQUAL "")
		set(MAKE_DOC_COMPRESSION "Z_BEST_COMPRESSION")
	endif()

	add_custom_command(OUTPUT ${MAKE_DOC_DESTINATION}
		COMMAND "${Python3_EXECUTABLE}"
			"${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../docs_generator.py"
			"${MAKE_DOC_COMPRESSION}"
			"${MAKE_DOC_DESTINATION}"
			 ${MAKE_DOC_SOURCES}
		VERBATIM
		DEPENDS "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../docs_generator.py"
		COMMENT "Generating docs..."
		COMMAND_EXPAND_LISTS
	)
endfunction()

### Options

set(GODOT_CONFIGS_WITH_DEBUG "Debug;RelWithDebInfo" CACHE STRING "Configurations that should have debug symbols (Modify if support for custom configurations is needed)")

# Default config
if("${CMAKE_BUILD_TYPE}" STREQUAL "")
	set(CMAKE_BUILD_TYPE "Debug")
endif()

set(GODOT_TARGET "template_debug" CACHE STRING "Target platform (editor, template_debug, template_release)")

# Auto-detect platform
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
	set(DEFAULT_GODOT_PLATFORM "linux")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
	set(DEFAULT_GODOT_PLATFORM "windows")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
	set(DEFAULT_GODOT_PLATFORM "macos")
elseif(CMAKE_SYSTEM_NAME STREQUAL "iOS")
	set(DEFAULT_GODOT_PLATFORM "ios")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Emscripten") # Set by providing Emscripten toolchain
	set(DEFAULT_GODOT_PLATFORM "web")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Android") # Set by providing Android toolchain
	set(DEFAULT_GODOT_PLATFORM "android")
else()
	set(DEFAULT_GODOT_PLATFORM "NOTFOUND")
endif()

set(GODOT_PLATFORM "${DEFAULT_GODOT_PLATFORM}" CACHE STRING "[Auto-detected] Target platform (linux, macos, windows, android, ios, web)")

if("${GODOT_PLATFORM}" STREQUAL "NOTFOUND")
       message(FATAL_ERROR "Could not auto-detect platform for \"${CMAKE_SYSTEM_NAME}\" automatically, please specify with -DGODOT_PLATFORM=<platform>")
endif()

message(STATUS "Platform detected: ${GODOT_PLATFORM}")

set(GODOT_GDEXTENSION_DIR "${CMAKE_CURRENT_SOURCE_DIR}/gdextension" CACHE PATH "Path to a directory containing GDExtension interface header")

set(GODOT_CUSTOM_API_FILE "${GODOT_GDEXTENSION_DIR}/extension_api.json" CACHE FILEPATH "Path to GDExtension API JSON file")

set(GODOT_PRECISION "single" CACHE STRING "Floating-point precision level (single, double)")

set(GODOT_OPTIMIZE "auto" CACHE STRING "The desired optimization flags (none, custom, debug, speed, speed_trace, size)")

set(GODOT_SYMBOLS_VISIBILITY "hidden" CACHE STRING "Symbols visibility on GNU platforms (default, visible, hidden)")

set(GODOT_BUILD_PROFILE "" CACHE FILEPATH "Path to a file containing a feature build profile")


option(GODOT_DEV_BUILD "Developer build with dev-only debugging code" OFF)

option(GODOT_DEBUG_SYMBOLS "Force build with debugging symbols" OFF)

set(DEFAULT_GODOT_USE_HOT_RELOAD ON)
if("${GODOT_TARGET}" STREQUAL "template_release")
	set(DEFAULT_GODOT_USE_HOT_RELOAD OFF)
endif()
option(GODOT_USE_HOT_RELOAD "Enable the extra accounting required to support hot reload" ${DEFAULT_GODOT_USE_HOT_RELOAD})

# Disable exception handling. Godot doesn't use exceptions anywhere, and this
# saves around 20% of binary size and very significant build time (GH-80513).
option(GODOT_DISABLE_EXCEPTIONS "Force disabling exception handling code" ON)

# Optionally mark headers as SYSTEM
option(GODOT_SYSTEM_HEADERS "Mark the header files as SYSTEM. This may be useful to suppress warnings in projects including this one" OFF)
set(GODOT_SYSTEM_HEADERS_ATTRIBUTE "")
if(GODOT_SYSTEM_HEADERS)
	set(GODOT_SYSTEM_HEADERS_ATTRIBUTE SYSTEM)
endif()

# Enable by default when building godot-cpp only
set(DEFAULT_WARNING_AS_ERROR OFF)
if(${CMAKE_PROJECT_NAME} STREQUAL ${PROJECT_NAME})
	set(DEFAULT_WARNING_AS_ERROR ON)
endif()
set(GODOT_WARNING_AS_ERROR "${DEFAULT_WARNING_AS_ERROR}" CACHE BOOL "Treat warnings as errors")

option(GODOT_GENERATE_TEMPLATE_GET_NODE "Generate a template version of the Node class's get_node" ON)

option(GODOT_THREADS "Enable threading support" ON)

###

# Common compiler options and compiler check generators
include(${CMAKE_CURRENT_LIST_DIR}/common_compiler_flags.cmake)

# Platform-specific options
include(${CMAKE_CURRENT_LIST_DIR}/${GODOT_PLATFORM}.cmake)

godot_clear_default_flags()

# Configuration of build targets:
    # - Editor or template
    # - Debug features (DEBUG_ENABLED code)
    # - Dev only code (DEV_ENABLED code)
    # - Optimization level
    # - Debug symbols for crash traces / debuggers
    # Keep this configuration in sync with SConstruct in upstream Godot.
list(APPEND GODOT_DEFINITIONS
	$<$<BOOL:${GODOT_THREADS}>:
		THREADS_ENABLED
	>

	$<$<BOOL:${GODOT_USE_HOT_RELOAD}>:
		HOT_RELOAD_ENABLED
	>

	$<$<STREQUAL:${GODOT_TARGET},editor>:
		TOOLS_ENABLED
	>

	$<$<NOT:$<STREQUAL:${GODOT_TARGET},template_release>>:
		# DEBUG_ENABLED enables debugging *features* and debug-only code, which is intended
		# to give *users* extra debugging information for their game development.
		DEBUG_ENABLED
		# In upstream Godot this is added in typedefs.h when DEBUG_ENABLED is set.
		DEBUG_METHODS_ENABLED
	>
	$<$<BOOL:${GODOT_DEV_BUILD}>:
        # DEV_ENABLED enables *engine developer* code which should only be compiled for those
        # working on the engine itself.
		DEV_ENABLED
	>

	$<$<NOT:$<BOOL:${GODOT_DEV_BUILD}>>:
	    # Disable assert() for production targets (only used in thirdparty code).
		NDEBUG
	>

	$<$<STREQUAL:${GODOT_PRECISION},double>:
		REAL_T_IS_DOUBLE
	>

    # Allow detecting when building as a GDExtension.
	GDEXTENSION
)

# Suffix
# See more prefix appends in platform-specific configs
string(PREPEND LIBRARY_SUFFIX ".${GODOT_PLATFORM}.${GODOT_TARGET}")

if(${GODOT_DEV_BUILD})
	string(APPEND LIBRARY_SUFFIX ".dev")
endif()

if("${GODOT_PRECISION}" STREQUAL "double")
	string(APPEND LIBRARY_SUFFIX ".double")
endif()

# Mac/IOS uses .framework directory structure and don't need arch suffix
if((NOT "${GODOT_PLATFORM}" STREQUAL "macos") AND (NOT "${GODOT_PLATFORM}" STREQUAL "ios"))
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
#	TARGET ${PROJECT_NAME}
#)
