vec2 hash( vec2 x )  // replace this by something better
{
    const vec2 k = vec2( 0.3483099, 0.4688794 );
    x = x*k + k.yx;
    return fract( 16.0 * k*fract( x.x*x.y*(x.x+x.y)) );
}

vec2 voronoi(vec2 v) {
    vec2 d = vec2(1., 1.);
    vec2 i = floor(v);
    for(float j = -1.; j <= 1.; j += 1.f)
    for(float k = -1.; k <= 1.; k += 1.f) {
        vec2 seed = i + vec2(j, k) + hash(i + vec2(j, k));
        vec2 diff = seed - v;
        if(dot(diff, diff) < dot(d, d)) {
            d = diff;
        }
    }
    return d;
}

void mainImage( out vec4 col, in vec2 cs ) {
    cs = (2. * cs - iResolution.xy) / iResolution.y * 4.f;
    vec2 v = voronoi(cs);
    
    if(cs.x < 0.) {
        col = vec4(vec3(length(v) / sqrt(2.)), 1.);
    } else {
        if(dot(v, v) > 0.) v = normalize(v); 
        vec3 n = normalize(vec3(-v.x, -v.y, 1.));
        col = vec4(vec3(n / 2. + 0.5), 1.);
    }
}
