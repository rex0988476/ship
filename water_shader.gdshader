// Realistic Water Shader - Godot 4.x Updated Version
// Original by UnionBytes, Achim Menzel (alias AiYori)
// Upgraded to Godot 4.x by Gemini
shader_type spatial;
// G4 Change: 'diffuse_burley' and 'specular_schlick_ggx' are now default and no longer needed here.
render_mode cull_back, blend_mix;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Wave settings:
uniform float wave_speed = 0.5; // Speed scale for the waves
uniform vec4 wave_a = vec4(1.0, 1.0, 0.35, 3.0); // xy = Direction, z = Steepness, w = Length
uniform vec4 wave_b = vec4(1.0, 0.6, 0.30, 1.55); // xy = Direction, z = Steepness, w = Length
uniform vec4 wave_c = vec4(1.0, 1.3, 0.25, 0.9); // xy = Direction, z = Steepness, w = Length

// Surface settings:
uniform vec2 sampler_scale = vec2(0.25, 0.25); // Scale for the sampler
uniform vec2 sampler_direction= vec2(0.05, 0.04); // Direction and speed for the sampler offset

// G4 Change: 'hint_aniso' is deprecated. Set filtering on the texture import settings.
uniform sampler2D uv_sampler; // UV motion sampler for shifting the normalmap
uniform vec2 uv_sampler_scale = vec2(0.25, 0.25); // UV sampler scale
uniform float uv_sampler_strength = 0.04; // UV shifting strength

uniform sampler2D normalmap_a_sampler : hint_normal; // Normalmap sampler A
uniform sampler2D normalmap_b_sampler : hint_normal; // Normalmap sampler B

// G4 Change: 'hint_black' is deprecated, default is black anyway.
uniform sampler2D foam_sampler; // Foam sampler
uniform float foam_level = 0.5; // Foam level -> distance from the object (0.0 - 1.0)

// Volume settings:
uniform float refraction = 0.075; // Refraction of the water

// G4 Change: 'hint_color' is now 'source_color'.
//uniform vec4 color_deep : source_color; // Color for deep places in the water, medium to dark blue
//uniform vec4 color_shallow : source_color; // Color for lower places in the water, bright blue - green
uniform vec4 color_deep : source_color = vec4(0.0, 0.15, 0.3, 1.0);     // 深藍色
uniform vec4 color_shallow : source_color = vec4(0.0, 0.45, 0.5, 1.0);  // 淺藍綠色

uniform float beers_law = 2.0; // Beers law value, regulates the blending size to the deep water level
uniform float depth_offset = -0.75; // Offset for the blending

// Projector for the water caustics:
uniform mat4 projector; // Projector matrix, mostly the matrix of the sun / directlight
uniform sampler2DArray caustic_sampler; // Caustic sampler, (Texture array with 16 Textures for the animation)


// G4 Change: 'varying' is deprecated. Use 'out' in vertex shader and 'in' in fragment shader.
// Vertex -> Fragment:
varying float vertex_height; // Height of the water surface
varying vec3 vertex_normal; // Vertex normal -> Needed for refraction calculation
varying vec3 vertex_binormal; // Vertex binormal -> Needed for refraction calculation
varying vec3 vertex_tangent; // Vertex tangent -> Needed for refraction calculation
varying vec4 vertex_world_pos; // Vertex world position
varying mat4 inv_mv; // Inverse ModelView matrix -> Needed for caustic projection


// Wave function (no changes needed):
vec3 wave(vec4 parameter, vec2 position, float time, inout vec3 tangent, inout vec3 binormal)
{
    float wave_steepness = parameter.z;
    float wave_length = parameter.w;

    float k = 2.0 * 3.14159265359 / wave_length;
    float c = sqrt(9.8 / k);
    vec2 d = normalize(parameter.xy);
    float f = k * (dot(d, position) - c * time);
    float a = wave_steepness / k;

    tangent += normalize(vec3(1.0-d.x * d.x * (wave_steepness * sin(f)), d.x * (wave_steepness * cos(f)), -d.x * d.y * (wave_steepness * sin(f))));
    binormal += normalize(vec3(-d.x * d.y * (wave_steepness * sin(f)), d.y * (wave_steepness * cos(f)), 1.0-d.y * d.y * (wave_steepness * sin(f))));

    return vec3(d.x * (a * cos(f)), a * sin(f), d.y * (a * cos(f)));
}


// Vertex shader:
void vertex()
{
    float time = TIME * wave_speed;

    // G4 Change: Use MODEL_MATRIX instead of WORLD_MATRIX.
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    vec3 tang = vec3(0.0, 0.0, 0.0);
    vec3 bin = vec3(0.0, 0.0, 0.0);

    vec3 vertex_offset = vec3(0.0);
    vertex_offset += wave(wave_a, world_pos.xz, time, tang, bin);
    vertex_offset += wave(wave_b, world_pos.xz, time, tang, bin);
    vertex_offset += wave(wave_c, world_pos.xz, time, tang, bin);

    // Apply wave displacement to vertex
    VERTEX += vertex_offset;

    vertex_tangent = tang;
    vertex_binormal = bin;

    // G4 Change: MODELVIEW_MATRIX is now VIEW_MATRIX * MODEL_MATRIX
    mat4 model_view = VIEW_MATRIX * MODEL_MATRIX;
    // G4 Change: Calculate clip space z for refraction effect
    vertex_height = (PROJECTION_MATRIX * model_view * vec4(VERTEX, 1.0)).z;

    TANGENT = vertex_tangent;
    BINORMAL = vertex_binormal;
    vertex_normal = normalize(cross(vertex_binormal, vertex_tangent));
    // Don't assign to NORMAL directly, it will be overwritten by the normal map in fragment.
    // The calculated normal is passed via 'vertex_normal' varying.

    UV = VERTEX.xz * sampler_scale;

    // G4 Change: Pass necessary matrices and positions to fragment shader
    vertex_world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
    inv_mv = inverse(model_view);
}

// G4 Change: Add 'in' for variables coming from vertex shader
/*in float vertex_height;
in vec3 vertex_normal;
in vec3 vertex_binormal;
in vec3 vertex_tangent;
in vec4 vertex_world_pos;
in mat4 inv_mv;*/

// Fragment shader:
void fragment()
{
    // Calculation of the UV with the UV motion sampler
    vec2 uv_offset = sampler_direction * TIME;
    vec2 uv_sampler_uv = UV * uv_sampler_scale + uv_offset;
    // G4 Change: 'texture' is the modern function name.
    vec2 uv_sampler_uv_offset = uv_sampler_strength * texture(uv_sampler, uv_sampler_uv).rg * 2.0 - 1.0;
    vec2 uv = UV + uv_sampler_uv_offset;

    // Normalmap:
    vec3 normalmap_a_tex = texture(normalmap_a_sampler, uv - uv_offset * 2.0).rgb;
    vec3 normalmap_b_tex = texture(normalmap_b_sampler, uv + uv_offset).rgb;
    vec3 normalmap_tex = (normalmap_a_tex * 0.75) + (normalmap_b_tex * 0.25);

    // Refraction UV:
    vec3 ref_normalmap_local = normalmap_tex * 2.0 - 1.0;
    // Use the calculated TBN matrix from the vertex shader to transform the local normalmap to world space
    vec3 ref_normal_world = normalize(vertex_tangent * ref_normalmap_local.x + vertex_binormal * ref_normalmap_local.y + vertex_normal * ref_normalmap_local.z);
    vec2 ref_uv = SCREEN_UV + (ref_normal_world.xy * refraction) / vertex_height;

    // --- G4 Change: Major update to Depth Calculation ---
    // The old method is incompatible with Godot 4's depth buffer.
    // This new method correctly reconstructs positions from depth to get an accurate depth blend.
    float scene_depth_raw = texture(DEPTH_TEXTURE, ref_uv).r;
    vec3 ndc = vec3(ref_uv * 2.0 - 1.0, scene_depth_raw);
    vec4 scene_world_pos = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    scene_world_pos.xyz /= scene_world_pos.w;

    float depth_diff = distance(scene_world_pos.xyz, vertex_world_pos.xyz);
    float depth_blend = exp((depth_diff + depth_offset) * -beers_law);
    depth_blend = 1.0 - clamp(depth_blend, 0.0, 1.0);
    float depth_blend_pow = clamp(pow(depth_blend, 2.5), 0.0, 1.0);
    // --- End of Depth Calculation Update ---

    // Ground color:
    // G4 Change: textureLod is now texture_lod
    //vec3 screen_color = texture_lod(SCREEN_TEXTURE, ref_uv, depth_blend_pow * 2.5).rgb;
	vec3 screen_color = texture(SCREEN_TEXTURE, ref_uv).rgb;

    vec3 dye_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_pow);
    vec3 color = mix(screen_color * dye_color, dye_color * 0.25, depth_blend_pow * 0.5);

    // Caustic screen projection
    vec4 caustic_screenPos = vec4(ref_uv * 2.0 - 1.0, scene_depth_raw, 1.0);
    vec4 caustic_localPos = inv_mv * INV_PROJECTION_MATRIX * caustic_screenPos;
    caustic_localPos.xyz /= caustic_localPos.w;

    vec2 caustic_Uv = caustic_localPos.xz / vec2(1024.0) + 0.5;
    vec4 caustic_color = texture(caustic_sampler, vec3(caustic_Uv * 300.0, mod(TIME * 14.0, 16.0)));

    color *= 1.0 + pow(caustic_color.r, 1.50) * (1.0 - depth_blend) * 6.0;

    // --- G4 Change: Major update to Foam Calculation ---
    // The old logic was unclear and used mixed coordinate spaces.
    // This new logic generates foam in shallow areas based on the calculated depth_blend.
    float foam_cutoff = 1.0 - foam_level; // foam_level (0-1), higher value means foam in deeper water
    if (depth_blend > foam_cutoff) {
        //float foam_noise = pow(texture(foam_sampler, (uv * 4.0) - uv_offset).r, 10.0) * 40.0;
        //float foam_noise = pow(texture(foam_sampler, (uv * 4.0) - uv_offset).r, 2.0) * 2.0;
		float foam_noise = 0.05;
		float foam_blend_factor = smoothstep(foam_cutoff, foam_cutoff + 0.2, depth_blend);
        float foam_mix = clamp(foam_blend_factor * foam_noise, 0.0, 1.0);
        color = mix(color, vec3(0.7, 0.85, 1.0), foam_mix * 0.4);

    }
    // --- End of Foam Calculation Update ---

    // Set all values:
    ALBEDO = color;
    METALLIC = 0.1;
    ROUGHNESS = 0.2;
    SPECULAR = 0.2 + depth_blend_pow * 0.4;
    NORMAL_MAP = normalmap_tex;
    // G4 Change: NORMALMAP is now NORMAL_MAP
    NORMAL_MAP_DEPTH = 1.25;
}