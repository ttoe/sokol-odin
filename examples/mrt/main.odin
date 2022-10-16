//------------------------------------------------------------------------------
//  mrt/main.odin
//
//  Rendering with multi-rendertargets, and recreating render targets
//  when window size changes.
//------------------------------------------------------------------------------
package main

import "core:runtime"
import "core:math"
import sg "../../sokol/gfx"
import sapp "../../sokol/app"
import sglue "../../sokol/glue"
import m "../math"

OFFSCREEN_SAMPLE_COUNT :: 4

state: struct {
    offscreen: struct {
        pass_action: sg.Pass_Action,
        pass_desc: sg.Pass_Desc,
        pass: sg.Pass,
        pip: sg.Pipeline,
        bind: sg.Bindings,
    },
    fsq: struct {
        pip: sg.Pipeline,
        bind: sg.Bindings,
    },
    dbg: struct {
        pip: sg.Pipeline,
        bind: sg.Bindings,
    },
    pass_action: sg.Pass_Action,
    rx, ry: f32,
}

Vertex :: struct {
    x, y, z, b : f32,
}

// called initially and when window size changes
create_offscreen_pass :: proc (width, height: i32) {
    // destroy previous resource (can be called for invalid id)
    sg.destroy_pass(state.offscreen.pass)
    for i in 0..<3 {
        sg.destroy_image(state.offscreen.pass_desc.color_attachments[i].image)
    }
    sg.destroy_image(state.offscreen.pass_desc.depth_stencil_attachment.image)

    // create offscreen rendertarget images and pass
    color_img_desc := sg.Image_Desc {
        render_target = true,
        width = width,
        height = height,
        min_filter = .LINEAR,
        mag_filter = .LINEAR,
        wrap_u = .CLAMP_TO_EDGE,
        wrap_v = .CLAMP_TO_EDGE,
        sample_count = sg.query_features().msaa_render_targets ? OFFSCREEN_SAMPLE_COUNT : 1,
    }
    depth_img_desc := color_img_desc
    depth_img_desc.pixel_format = .DEPTH;
    state.offscreen.pass_desc = {
        color_attachments = {
            0 = { image = sg.make_image(color_img_desc) },
            1 = { image = sg.make_image(color_img_desc) },
            2 = { image = sg.make_image(color_img_desc) }
        },
        depth_stencil_attachment = {
            image = sg.make_image(depth_img_desc)
        }
    }
    state.offscreen.pass = sg.make_pass(state.offscreen.pass_desc)

    // also need to update the fullscreen-quad texture bindings
    for i in 0..<3 {
        state.fsq.bind.fs_images[i] = state.offscreen.pass_desc.color_attachments[i].image
    }
}

// listen for window-resize events and recreate offscreen rendertargets
event :: proc "c" (ev: ^sapp.Event) {
    context = runtime.default_context()
    if ev.type == .RESIZED {
        create_offscreen_pass(ev.framebuffer_width, ev.framebuffer_height)
    }
}

init :: proc "c" () {
    context = runtime.default_context()
    sg.setup({ ctx = sglue.ctx() })

    // a pass action for the default render pass (don't clear the frame buffer
    // since it will be completely overwritten anyway)
    state.pass_action = {
        colors = { 0 = { action = .DONTCARE} },
        depth = { action = .DONTCARE },
        stencil = { action = .DONTCARE }
    }

    // a render pass with 3 color attachment images, and a depth attachment image
    create_offscreen_pass(sapp.width(), sapp.height())

    // cube vertex buffer
    cube_vertices := [?]Vertex {
        // pos + brightness
        { -1.0, -1.0, -1.0,   1.0 },
        {  1.0, -1.0, -1.0,   1.0 },
        {  1.0,  1.0, -1.0,   1.0 },
        { -1.0,  1.0, -1.0,   1.0 },

        { -1.0, -1.0,  1.0,   0.8 },
        {  1.0, -1.0,  1.0,   0.8 },
        {  1.0,  1.0,  1.0,   0.8 },
        { -1.0,  1.0,  1.0,   0.8 },

        { -1.0, -1.0, -1.0,   0.6 },
        { -1.0,  1.0, -1.0,   0.6 },
        { -1.0,  1.0,  1.0,   0.6 },
        { -1.0, -1.0,  1.0,   0.6 },

        {  1.0, -1.0, -1.0,    0.4 },
        {  1.0,  1.0, -1.0,    0.4 },
        {  1.0,  1.0,  1.0,    0.4 },
        {  1.0, -1.0,  1.0,    0.4 },

        { -1.0, -1.0, -1.0,   0.5 },
        { -1.0, -1.0,  1.0,   0.5 },
        {  1.0, -1.0,  1.0,   0.5 },
        {  1.0, -1.0, -1.0,   0.5 },

        { -1.0,  1.0, -1.0,   0.7 },
        { -1.0,  1.0,  1.0,   0.7 },
        {  1.0,  1.0,  1.0,   0.7 },
        {  1.0,  1.0, -1.0,   0.7 },
    }
    cube_vbuf := sg.make_buffer({
        data = { ptr = &cube_vertices, size = size_of(cube_vertices) }
    })

    // index buffer for the cube
    cube_indices := [?]u16 {
        0, 1, 2,  0, 2, 3,
        6, 5, 4,  7, 6, 4,
        8, 9, 10,  8, 10, 11,
        14, 13, 12,  15, 14, 12,
        16, 17, 18,  16, 18, 19,
        22, 21, 20,  23, 22, 20
    }
    cube_ibuf := sg.make_buffer({
        type = .INDEXBUFFER,
        data = { ptr = &cube_indices, size = size_of(cube_indices) }
    })

    // pass action for offscreen pass
    state.offscreen.pass_action = {
        colors = {
            0 = { action = .CLEAR, value = { 0.25, 0.0, 0.0, 1.0 } },
            1 = { action = .CLEAR, value = { 0.0, 0.25, 0.0, 1.0 } },
            2 = { action = .CLEAR, value = { 0.0, 0.0, 0.25, 1.0 } }
        },
    }

    // shader and pipeline object for offscreen-renderer cube
    state.offscreen.pip = sg.make_pipeline({
        shader = sg.make_shader(offscreen_shader_desc(sg.query_backend())),
        layout = {
            buffers = { 0 = { stride = size_of(Vertex) } },
            attrs = {
                ATTR_vs_offscreen_pos     = { offset = i32(offset_of(Vertex, x)), format = .FLOAT3 },
                ATTR_vs_offscreen_bright0 = { offset = i32(offset_of(Vertex, b)), format = .FLOAT }
            }
        },
        index_type = .UINT16,
        cull_mode = .BACK,
        sample_count = sg.query_features().msaa_render_targets ? OFFSCREEN_SAMPLE_COUNT : 1,
        depth = {
            pixel_format = .DEPTH,
            compare = .LESS_EQUAL,
            write_enabled = true,
        },
        color_count = 3
    })

    // resource bindings for offscreen rendering
    state.offscreen.bind = {
        vertex_buffers = {
            0 = cube_vbuf
        },
        index_buffer = cube_ibuf,
    }

    // a vertex buffer to render a fullscreen rectangle
    quad_vertices := [?]f32 { 0.0, 0.0,  1.0, 0.0,  0.0, 1.0,  1.0, 1.0 }
    quad_vbuf := sg.make_buffer({
        data = { ptr = &quad_vertices, size = size_of(quad_vertices) }
    })

    // shader and pipeline object to render the fullscreen quad
    state.fsq.pip = sg.make_pipeline({
        shader = sg.make_shader(fsq_shader_desc(sg.query_backend())),
        layout = {
            attrs = {
                ATTR_vs_fsq_pos = { format = .FLOAT2 }
            }
        },
        primitive_type = .TRIANGLE_STRIP,
    })

    // resource bindings to render the fullscreen quad
    state.fsq.bind = {
        vertex_buffers = {
            0 = quad_vbuf,
        },
        fs_images = {
            SLOT_tex0 = state.offscreen.pass_desc.color_attachments[0].image,
            SLOT_tex1 = state.offscreen.pass_desc.color_attachments[1].image,
            SLOT_tex2 = state.offscreen.pass_desc.color_attachments[2].image,
        }
    }

    // pipeline and resource bindings to render debug-visualization quads
    state.dbg.pip = sg.make_pipeline({
        shader = sg.make_shader(dbg_shader_desc(sg.query_backend())),
        layout = {
            attrs = {
                ATTR_vs_dbg_pos = { format = .FLOAT2 }
            }
        },
        primitive_type = .TRIANGLE_STRIP,
    })
    state.dbg.bind.vertex_buffers[0] = quad_vbuf
}

frame :: proc "c" () {
    context = runtime.default_context()

    // view-projection matrix
    proj := m.persp(fov = 60.0, aspect = sapp.widthf() / sapp.heightf(), near = 0.01, far = 10.0)
    view := m.lookat(eye = {0.0, 1.5, 6.0}, center = {}, up = m.up())
    view_proj := m.mul(proj, view)

    // shader parameters
    t := f32(sapp.frame_duration() * 60.0)
    state.rx += 1.0 * t;
    state.ry += 2.0 * t;
    fsq_params := Fsq_Params {
        offset = { math.sin(state.rx * 0.01) * 0.1, math.sin(state.ry * 0.01) * 0.1 }
    }
    rxm := m.rotate(state.rx, { 1.0, 0.0, 0.0 })
    rym := m.rotate(state.ry, { 0.0, 1.0, 0.0 })
    model := m.mul(rxm, rym)
    offscreen_params := Offscreen_Params {
        mvp = m.mul(view_proj, model)
    }

    // render cube into MRT offscreen render targets
    sg.begin_pass(state.offscreen.pass, state.offscreen.pass_action)
    sg.apply_pipeline(state.offscreen.pip)
    sg.apply_bindings(state.offscreen.bind)
    sg.apply_uniforms(.VS, SLOT_offscreen_params, { ptr = &offscreen_params, size = size_of(offscreen_params) })
    sg.draw(0, 36, 1)
    sg.end_pass()

    // render fullscreen quad with the 'composed image', plus 3 small debug-view quads
    sg.begin_default_pass(state.pass_action, sapp.width(), sapp.height())
    sg.apply_pipeline(state.fsq.pip)
    sg.apply_bindings(state.fsq.bind)
    sg.apply_uniforms(.VS, SLOT_fsq_params, { ptr = &fsq_params, size = size_of(fsq_params) })
    sg.draw(0, 4, 1)
    sg.apply_pipeline(state.dbg.pip)
    for i in 0..<3 {
        sg.apply_viewport(i * 100, 0, 100, 100, false)
        state.dbg.bind.fs_images[SLOT_tex] = state.offscreen.pass_desc.color_attachments[i].image
        sg.apply_bindings(state.dbg.bind)
        sg.draw(0, 4, 1)
    }
    sg.apply_viewport(0, 0, sapp.width(), sapp.height(), false)
    sg.end_pass()
    sg.commit()
}

cleanup :: proc "c" () {
    context = runtime.default_context()
    sg.shutdown()
}

main :: proc () {
    sapp.run({
        init_cb = init,
        frame_cb = frame,
        event_cb = event,
        cleanup_cb = cleanup,
        width = 800,
        height = 600,
        sample_count = 4,
        window_title = "mrt",
        icon = { sokol_default = true }
    })
}
