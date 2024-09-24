# Used with Emscripted toolchain at *toolchain_dir*/cmake/Modules/Platform/Emscripten.cmake

set(GODOT_ARCH "wasm32" CACHE STRING "Target architecture (wasm32, custom)")

string(REGEX MATCH "32$|64$" DEFAULT_GODOT_BITS "${GODOT_ARCH}")
set(GODOT_BITS "${DEFAULT_GODOT_BITS}" CACHE STRING "Architecture bits. Needs to be set manually for custom architecture")


list(APPEND GODOT_DEFINITIONS
	WEB_ENABLED
	UNIX_ENABLED
)

list(APPEND GODOT_C_FLAGS
	$<$<BOOL:${GODOT_THREADS}>:
		# Thread support (via SharedArrayBuffer).
		-sUSE_PTHREADS=1
	>
	# Build as side module (shared library)
	-sSIDE_MODULE=1

	# Force wasm longjmp mode.
	-sSUPPORT_LONGJMP='wasm'
)

list(APPEND GODOT_CXX_FLAGS
)

list(APPEND GODOT_LINK_FLAGS
	$<$<BOOL:${GODOT_THREADS}>:
		-sUSE_PTHREADS=1
	>
	-sSIDE_MODULE=1

	# Enable WebAssembly BigInt <-> i64 conversion.
    # This must match the flag used to build Godot (true in official builds since 4.3)
	-sWASM_BIGINT

	-sSUPPORT_LONGJMP='wasm'

)
