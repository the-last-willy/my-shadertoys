// MIT License
// Copyright (c) 2022 Willy Jacquet
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// `https://github.com/the-last-willy/shadertoy/tree/main/volumetric_cosmos`

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// Common functions.

float sphere_distance(vec3 p) {
    return length(p);
}

vec3 rotated_x(float a, vec3 p) {
    float ca = cos(a);
    float sa = sin(a);
    return vec3(p.x, ca * p.y + sa * p.z, -sa * p.y + ca * p.z);
}

vec3 rotated_y(float a, vec3 p) {
    float ca = cos(a);
    float sa = sin(a);
    return vec3(ca * p.x - sa * p.z, p.y, sa * p.x + ca * p.z);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// Spheres.
// Defining all three objects properties here.

// 4D noise (3D + time) is used as a texture for the sphere
// as well as a sort of density of matter going outward of the spheres.

vec3 sphere_0_position() {
    return vec3(0.);
}

float sphere_0_radius() {
    return 1.;
}

vec3 sphere_0_color(vec3 p) {
    vec2 xy = p.xy - sphere_0_position().xy;
    float ang = atan(xy.y, xy.x);
    vec3 pal = trig_palette(vec3(.8, .2, .2), vec3(.2, .2, .2), vec3(1., 1., 1.),vec3(.0,.33,.67), ang / tau);
    return mix(vec3(1., 0., 0.), pal, min(length(xy), 1.));
    
}

float sphere_0_density(vec3 p) {
    vec3 d = sphere_0_position() - p;
    float l = length(d);
    vec3 q = sphere_0_radius() * normalize(d);
    return abs(snoise(iChannel0, q * 2., iTime / 5. - l));
}

float sphere_0_distance(vec3 p) {
    return sphere_distance(p - sphere_0_position()) - 1.;
}

vec3 sphere_1_position() {
    return rotated_y(iTime, vec3(3, 0., 0.));
}

float sphere_1_radius() {
    return 1.;
}

vec3 sphere_1_color(vec3 p) {
    vec2 xy = p.xy - sphere_1_position().xy;
    float ang = atan(xy.y, xy.x);
    vec3 pal = trig_palette(vec3(.2, .6, .3), vec3(.2, .2, .3), vec3(1., 1., 1.),vec3(.0,.33,.67), ang / tau);
    return mix(vec3(0., 1., 0.), pal, min(length(xy), 1.));
}

float sphere_1_density(vec3 p) {
    vec3 d = sphere_1_position() - p;
    float l = length(d);
    vec3 q = sphere_1_radius() * normalize(d);
    return abs(snoise(iChannel0, q * 1.5, iTime / 5. - l));
}

float sphere_1_distance(vec3 p) {
    return sphere_distance(p - sphere_1_position()) - 1.f;
}

vec3 sphere_2_position() {
    return rotated_y(iTime / 1.7, vec3(6., 0., 0.));
}

float sphere_2_radius() {
    return 1.;
}

vec3 sphere_2_color(vec3 p) {
    vec2 xy = p.xy - sphere_2_position().xy;
    float ang = atan(xy.y, xy.x);
    vec3 pal = trig_palette(vec3(.4, .2, .7), vec3(.2, .2, .3), vec3(1., 1., 1.),vec3(.0,.33,.67), ang / tau);
    return mix(vec3(0., 0., 1.), pal, min(length(xy), 1.));
}

float sphere_2_density(vec3 p) {
    vec3 d = sphere_2_position() - p;
    float l = length(d);
    vec3 q = sphere_2_radius() * normalize(d);
    return abs(snoise(iChannel0, q, iTime / 5. - l));
}

float sphere_2_distance(vec3 p) {
    return sphere_distance(p - sphere_2_position()) - 1.f;
}

////////////////////////////////////////////////////////////////////////////////
// Scene.

float scene_distance(vec3 p) {
    float s0 = sphere_0_distance(p);
    float s1 = sphere_1_distance(p);
    float s2 = sphere_2_distance(p);
    return min(s0, min(s1, s2));
}

vec3 scene_color(vec3 p) {
    // Returns the color of the closest object.

    float s0 = sphere_0_distance(p);
    float s1 = sphere_1_distance(p);
    float s2 = sphere_2_distance(p);
    
    if(s0 < s1) {
        if(s0 < s2) {
            return sphere_0_color(p);
        } else {
            return sphere_2_color(p);
        }
    } else {
        if(s1 < s2) {
            return sphere_1_color(p);
        } else {
            return sphere_2_color(p);
        }
    }
}

float scene_density(vec3 p) {
    // This function is discontinuous.
    // This causes some artifacts.
    // A bit too much stuff to rewrite to fix it...

    float s0 = sphere_0_distance(p);
    float s1 = sphere_1_distance(p);
    float s2 = sphere_2_distance(p);
    
    if(s0 < s1) {
        if(s0 < s2) {
            return sphere_0_density(p);
        } else {
            return sphere_2_density(p);
        }
    } else {
        if(s1 < s2) {
            return sphere_1_density(p);
        } else {
            return sphere_2_density(p);
        }
    }
}

vec4 scene_halo(vec3 p, vec3 d) {
    // Bunch of magic constants here that wre chosen empirically to look good.
    // Could use some factoring as well...

    float sd0 = 2. * sphere_0_distance(p) / 1.8;
    vec3 v0 = p - sphere_0_position();
    float a0 = 2. / (1. + sd0 * sd0 * sd0);
    
    float sd1 = 2. * sphere_1_distance(p) / 1.8;
    vec3 v1 = p - sphere_1_position();
    float a1 = 2. / (1. + sd1 * sd1 * sd1);
    
    float sd2 = 2. * sphere_2_distance(p) / 1.8;
    vec3 v2 = p - sphere_2_position();
    float a2 = 2. / (1. + sd2 * sd2 * sd2);
    
    float sum_a = a0 + a1 + a2;
    vec3 rgb = (a0 * sphere_0_color(p) + a1 * sphere_1_color(p) + a2 * sphere_2_color(p)) / sum_a;
    float a = 1. - (1. - a0) * (1. - a1) * (1. - a2);
    
    float density = .2 + .8 * scene_density(p);
    
    return vec4(rgb, density * a);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void mainImage(out vec4 rgba, in vec2 coords) {
    // Normalized device coordinates and aspect ratio (FOV 90).
    coords = (2. * coords.xy - iResolution.xy) / iResolution.x;
    
    vec3 ro = vec3(0., 3., -10.); // Ray origin.
    vec3 rd = rotated_x(-0.2, normalize(vec3(coords.xy, 1.))); // Ray direction.
    
    vec4 halo = vec4(0.);
    
    for(int i = 0; i < 150; ++i) {
        // The step distance is upper bounded to ensure visual continuity in the halo.
        float sd = min(scene_distance(ro), 0.25);
        
        // Advances the ray.
        ro += sd * rd;
        
        if(sd < 0.01) {
            break;
        } else {
            // Integrates the density as the ray marches.
            // The result is accumulated with regular blending.
            // Aplha is premultiplied in the halo color.
            vec4 halo_i = scene_halo(ro, rd);
            halo += (1. - halo.a) * sd * vec4(halo_i.rgb * halo_i.a, halo_i.a);
        }
    }
    
    // Took some stars from another shader to have a less boring background.
    vec3 rgb = vec3(StableStarField(1000. * (coords + vec2(1.)), .97));
    
    // That doesn't make much sense but it somehow checks that we're before the far plane or smth.
    float d = length(ro);
    if(d < 20.) {
        // Adds texture to the object, overriding the backgroud. 
        float noi =  scene_density(ro);
        noi = pow(noi, 1. / 5.);
        rgb = mix(scene_color(ro), vec3(1.), noi);
    }
    
    // Composites the halo into the image.
    rgba = vec4(halo.rgb + (1. - halo.a) * rgb, 1.);
}
