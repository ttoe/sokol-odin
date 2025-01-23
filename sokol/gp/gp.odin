package sokol_gp

import sg "../gfx"
import "core:c"

SOKOL_DEBUG :: #config(SOKOL_DEBUG, ODIN_DEBUG)

DEBUG :: #config(SOKOL_GFX_DEBUG, SOKOL_DEBUG)
USE_GL :: #config(SOKOL_USE_GL, false)
USE_DLL :: #config(SOKOL_DLL, false)

when ODIN_OS == .Windows {
	when USE_DLL {
		when USE_GL {
			when DEBUG {foreign import sokol_gfx_clib "../gfx/sokol_dll_windows_x64_gl_debug.lib"} else {foreign import sokol_gfx_clib "../gfx/sokol_dll_windows_x64_gl_release.lib"}
		} else {
			when DEBUG {foreign import sokol_gfx_clib "../gfx/sokol_dll_windows_x64_d3d11_debug.lib"} else {foreign import sokol_gfx_clib "../gfx/sokol_dll_windows_x64_d3d11_release.lib"}
		}
	} else {
		when USE_GL {
			when DEBUG {foreign import sokol_gfx_clib "../gfx/sokol_gfx_windows_x64_gl_debug.lib"} else {foreign import sokol_gfx_clib "../gfx/sokol_gfx_windows_x64_gl_release.lib"}
		} else {
			when DEBUG {foreign import sokol_gfx_clib "../gfx/sokol_gfx_windows_x64_d3d11_debug.lib"} else {foreign import sokol_gfx_clib "../gfx/sokol_gfx_windows_x64_d3d11_release.lib"}
		}
	}
} else when ODIN_OS == .Darwin {
	when USE_DLL {
		when USE_GL && ODIN_ARCH ==
			.arm64 && DEBUG {foreign import sokol_gfx_clib "../dylib/sokol_dylib_macos_arm64_gl_debug.dylib"} else when USE_GL && ODIN_ARCH == .arm64 && !DEBUG {foreign import sokol_gfx_clib "../dylib/sokol_dylib_macos_arm64_gl_release.dylib"} else when USE_GL && ODIN_ARCH == .amd64 && DEBUG {foreign import sokol_gfx_clib "../dylib/sokol_dylib_macos_x64_gl_debug.dylib"} else when USE_GL && ODIN_ARCH == .amd64 && !DEBUG {foreign import sokol_gfx_clib "../dylib/sokol_dylib_macos_x64_gl_release.dylib"} else when !USE_GL && ODIN_ARCH == .arm64 && DEBUG {foreign import sokol_gfx_clib "../dylib/sokol_dylib_macos_arm64_metal_debug.dylib"} else when !USE_GL && ODIN_ARCH == .arm64 && !DEBUG {foreign import sokol_gfx_clib "../dylib/sokol_dylib_macos_arm64_metal_release.dylib"} else when !USE_GL && ODIN_ARCH == .amd64 && DEBUG {foreign import sokol_gfx_clib "../dylib/sokol_dylib_macos_x64_metal_debug.dylib"} else when !USE_GL && ODIN_ARCH == .amd64 && !DEBUG {foreign import sokol_gfx_clib "../dylib/sokol_dylib_macos_x64_metal_release.dylib"}
	} else {
		when USE_GL {
			when ODIN_ARCH == .arm64 {
				when DEBUG {foreign import sokol_gfx_clib {"../gfx/sokol_gfx_macos_arm64_gl_debug.a", "system:Cocoa.framework", "system:QuartzCore.framework", "system:OpenGL.framework"}} else {foreign import sokol_gfx_clib {"../gfx/sokol_gfx_macos_arm64_gl_release.a", "system:Cocoa.framework", "system:QuartzCore.framework", "system:OpenGL.framework"}}
			} else {
				when DEBUG {foreign import sokol_gfx_clib {"../gfx/sokol_gfx_macos_x64_gl_debug.a", "system:Cocoa.framework", "system:QuartzCore.framework", "system:OpenGL.framework"}} else {foreign import sokol_gfx_clib {"../gfx/sokol_gfx_macos_x64_gl_release.a", "system:Cocoa.framework", "system:QuartzCore.framework", "system:OpenGL.framework"}}
			}
		} else {
			when ODIN_ARCH == .arm64 {
				when DEBUG {foreign import sokol_gfx_clib {"../gfx/sokol_gfx_macos_arm64_metal_debug.a", "system:Cocoa.framework", "system:QuartzCore.framework", "system:Metal.framework", "system:MetalKit.framework"}} else {foreign import sokol_gfx_clib {"../gfx/sokol_gfx_macos_arm64_metal_release.a", "system:Cocoa.framework", "system:QuartzCore.framework", "system:Metal.framework", "system:MetalKit.framework"}}
			} else {
				when DEBUG {foreign import sokol_gfx_clib {"../gfx/sokol_gfx_macos_x64_metal_debug.a", "system:Cocoa.framework", "system:QuartzCore.framework", "system:Metal.framework", "system:MetalKit.framework"}} else {foreign import sokol_gfx_clib {"../gfx/sokol_gfx_macos_x64_metal_release.a", "system:Cocoa.framework", "system:QuartzCore.framework", "system:Metal.framework", "system:MetalKit.framework"}}
			}
		}
	}
} else when ODIN_OS == .Linux {
	when USE_DLL {
		when DEBUG {foreign import sokol_gfx_clib {"../gfx/sokol_gfx_linux_x64_gl_debug.so", "system:GL", "system:dl", "system:pthread"}} else {foreign import sokol_gfx_clib {"../gfx/sokol_gfx_linux_x64_gl_release.so", "system:GL", "system:dl", "system:pthread"}}
	} else {
		when DEBUG {foreign import sokol_gfx_clib {"../gfx/sokol_gfx_linux_x64_gl_debug.a", "system:GL", "system:dl", "system:pthread"}} else {foreign import sokol_gfx_clib {"../gfx/sokol_gfx_linux_x64_gl_release.a", "system:GL", "system:dl", "system:pthread"}}
	}
} else {
	#panic("This OS is currently not supported")
}

@(default_calling_convention = "c", link_prefix = "sgp_")
foreign sokol_gfx_clib {
	/* Initialization and de-initialization. */
	setup :: proc(#by_ptr desc: Desc) ---
	shutdown :: proc() ---
	is_valid :: proc() -> bool ---

	/* Error handling. */
	get_last_error :: proc() -> Error ---
	get_error_message :: proc(error: Error) -> cstring ---

	/* Custom pipeline creation. */
	make_pipeline :: proc(#by_ptr desc: Pipeline_Desc) -> sg.Pipeline ---

	/* Draw command queue management. */
	begin :: proc(width: c.int, height: c.int) ---
	flush :: proc() ---
	end :: proc() ---

	/* 2D coordinate space projection */
	project :: proc(left, right, top, bottom: f32) ---
	reset_project :: proc() ---

	/* 2D coordinate space transformation. */
	push_transform :: proc() ---
	pop_transform :: proc() ---
	reset_transform :: proc() ---
	translate :: proc(x, y: f32) ---
	rotate :: proc(theta: f32) ---
	rotate_at :: proc(theta, x, y: f32) ---
	scale :: proc(sx, sy: f32) ---
	scale_at :: proc(sx, sy, x, y: f32) ---

	/* State change for custom pipelines. */
	set_pipeline :: proc(pipeline: sg.Pipeline) ---
	reset_pipeline :: proc() ---
	set_uniform :: proc(vs_data: rawptr, vs_size: u32, fs_data: rawptr, fs_size: u32) ---
	reset_uniform :: proc() ---

	/* State change functions for the common pipelines. */
	set_blend_mode :: proc(blend_mode: Blend_Mode) ---
	reset_blend_mode :: proc() ---
	set_color :: proc(r, g, b, a: f32) ---
	reset_color :: proc() ---
	set_image :: proc(channel: c.int, image: sg.Image) ---
	unset_image :: proc(channel: c.int) ---
	reset_image :: proc(channel: c.int) ---
	set_sampler :: proc(channel: c.int, sampler: sg.Sampler) ---
	reset_sampler :: proc(channel: c.int) ---

	/* State change functions for all pipelines. */
	viewport :: proc(x, y, w, h: c.int) ---
	reset_viewport :: proc() ---
	scissor :: proc(x, y, w, h: c.int) ---
	reset_scissor :: proc() ---
	reset_state :: proc() ---

	/* Drawing functions. */
	clear :: proc() ---
	draw :: proc(primitive_type: sg.Primitive_Type, #by_ptr vertices: Vertex, count: u32) ---
	draw_points :: proc(#by_ptr points: Point, count: u32) ---
	draw_point :: proc(x, y: f32) ---
	draw_lines :: proc(#by_ptr lines: Line, count: u32) ---
	draw_line :: proc(ax, ay, bx, by, cx, cy: f32) ---
	draw_lines_strip :: proc(#by_ptr points: Point, count: u32) ---
	draw_filled_triangles :: proc(#by_ptr triangles: Triangle, count: u32) ---
	draw_filled_triangle :: proc(ax, ay, bx, by, cx, cy: f32) ---
	draw_filled_triangles_strip :: proc(#by_ptr points: Point, count: u32) ---
	draw_filled_rects :: proc(#by_ptr rects: Rect, count: u32) ---
	draw_filled_rect :: proc(x, y, w, h: f32) ---
	draw_textured_rects :: proc(channel: c.int, #by_ptr rects: Textured_Rect, count: u32) ---
	draw_textured_rect :: proc(channel: c.int, dest_rect, src_rect: Rect) ---

	/* Querying functions. */
	query_state :: proc() -> ^State ---
	query_desc :: proc() -> Desc ---
}

DEFAULT_MAX_VERTICES :: 65536
DEFAULT_MAX_COMMANDS :: 16384
MAX_MOVE_VERTICES :: 96
MAX_STACK_DEPTH :: 64

BATCH_OPTIMIZER_DEPTH :: 8
UNIFORM_CONTENT_SLOTS :: 4
TEXTURE_SLOTS :: 4

State :: struct {
	frame_size:    ISize,
	viewport:      IRect,
	scissor:       IRect,
	proj:          Mat2x3,
	transform:     Mat2x3,
	mvp:           Mat2x3,
	thickness:     f32,
	color:         Color_Ub4,
	textures:      Textures_Uniform,
	uniform:       Uniform,
	blend_mode:    Blend_Mode,
	pipeline:      sg.Pipeline,
	_base_vertex:  u32,
	_base_uniform: u32,
	_base_command: u32,
}

Desc :: struct {
	max_vertices: u32,
	max_commands: u32,
	color_format: sg.Pixel_Format,
	depth_format: sg.Pixel_Format,
	sample_count: c.int,
}

Error :: enum i32 {
	NO_ERROR = 0,
	SOKOL_INVALID,
	VERTICES_FULL,
	UNIFORMS_FULL,
	COMMANDS_FULL,
	VERTICES_OVERFLOW,
	TRANSFORM_STACK_OVERFLOW,
	TRANSFORM_STACK_UNDERFLOW,
	STATE_STACK_OVERFLOW,
	STATE_STACK_UNDERFLOW,
	ALLOC_FAILED,
	MAKE_VERTEX_BUFFER_FAILED,
	MAKE_WHITE_IMAGE_FAILED,
	MAKE_NEAREST_SAMPLER_FAILED,
	MAKE_COMMON_SHADER_FAILED,
	MAKE_COMMON_PIPELINE_FAILED,
}

Pipeline_Desc :: struct {
	shader:         sg.Shader,
	primitive_type: sg.Primitive_Type,
	blend_mode:     Blend_Mode,
	color_format:   sg.Pixel_Format,
	depth_format:   sg.Pixel_Format,
	sample_count:   c.int,
	has_vs_color:   bool,
}

Blend_Mode :: enum i32 {
	NONE = 0,
	BLEND,
	BLEND_PREMULTIPLIED,
	ADD,
	ADD_PREMULTIPLIED,
	MOD,
	MUL,
	_NUM,
}

ISize :: struct {
	w, h: c.int,
}

IRect :: struct {
	x, y, w, h: c.int,
}

Rect :: struct {
	x, y, w, h: f32,
}

Textured_Rect :: struct {
	dst, src: Rect,
}

Vec2 :: [2]f32
Point :: Vec2

Line :: struct {
	a, b: Point,
}

Triangle :: struct {
	a, b, c: Point,
}

Mat2x3 :: matrix[2, 3]f32

Color :: sg.Color

Color_Ub4 :: [4]u8

Vertex :: struct {
	position: Vec2,
	texcoord: Vec2,
	color:    Color_Ub4,
}

Uniform :: struct {
	size:    u32,
	content: [UNIFORM_CONTENT_SLOTS]f32,
}

Textures_Uniform :: struct {
	count:    u32,
	images:   [TEXTURE_SLOTS]sg.Image,
	samplers: [TEXTURE_SLOTS]sg.Sampler,
}

