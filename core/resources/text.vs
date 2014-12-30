#ifdef GL_ES
precision mediump float;
#endif

attribute lowp float a_fsid;
attribute vec2 a_position;
attribute vec2 a_texCoord;

uniform sampler2D u_transforms;
uniform lowp vec2 u_tresolution;
uniform lowp vec2 u_resolution;
uniform mat4 u_proj;

varying vec2 f_uv;
varying float f_alpha;

#define PI 3.14159

#define alpha   tdata.a
#define tx      tdata.x
#define ty      tdata.y
#define theta   tdata.z
#define txp     tdataPrecision.x
#define typ     tdataPrecision.y

/*
 * Converts (i, j) pixel coordinates to the corresponding (u, v) in
 * texture space. The (u,v) targets the center of pixel
 */
vec2 ij2uv(float i, float j, float w, float h) {
    return vec2(
        (2.0*i+1.0) / (2.0*w),
        (2.0*j+1.0) / (2.0*h)
    );
}

/*
 * Decodes the id and find its place for its transform inside the texture
 * Returns the (i,j) position inside texture
 */
vec2 id2ij(int fsid, float w) {
    float i = mod(float(fsid * 2), w);
    float j = floor(float(fsid * 2) / w);
    return vec2(i, j);
}

void main() {
    // decode the uv from a text id
    vec2 ij = id2ij(int(a_fsid), u_tresolution.x);
    vec2 uv1 = ij2uv(ij.x, ij.y, u_tresolution.x, u_tresolution.y);
    vec2 uv2 = ij2uv(ij.x+1.0, ij.y, u_tresolution.x, u_tresolution.y);

    // reads the transform data and its precision
    vec4 tdata = texture2D(u_transforms, uv1);
    vec4 tdataPrecision = texture2D(u_transforms, uv2);

    float precisionScale = 1.0/255.0;

    // transforms from [0..1] to [0..resolution] and add lost precision
    tx = u_resolution.x * (tx + txp * precisionScale);
    ty = u_resolution.y * (ty + typ * precisionScale);

    // scale from [0..1] to [0..2pi]
    theta = theta * 2.0 * PI;

    float st = sin(theta);
    float ct = cos(theta);

    // rotates first around +z-axis (0,0,1) and then translates by (tx,ty,0)
    vec4 p = vec4(
        a_position.x * ct - a_position.y * st + tx,
        a_position.x * st + a_position.y * ct + ty,
        0.0,
        1.0
    );

    gl_Position = u_proj * p;

    f_uv = a_texCoord;
    f_alpha = alpha;
}
