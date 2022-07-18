vec3 hash( vec3 x )  // replace this by something better
{
    x = vec3( dot(x,vec3(127.1,311.7, 74.7)),
			  dot(x,vec3(269.5,183.3,246.1)),
			  dot(x,vec3(113.5,271.9,124.6)));

	return fract(sin(x)*43758.5453123);
}

vec3 voronoi(vec3 v) {
    vec3 d = vec3(1., 1., 1.);
    vec3 i = floor(v);
    for(float j = -1.; j <= 1.; j += 1.f)
    for(float k = -1.; k <= 1.; k += 1.f)
    for(float l = -1.; l <= 1.; l += 1.f) {
        vec3 seed = i + vec3(j, k, l) + hash(i + vec3(j, k, l));
        vec3 diff = seed - v;
        if(dot(diff, diff) < dot(d, d)) {
            d = diff;
        }
    }
    return d;
}

float worley_noise_edge(vec3 v) {
    // Minimum distance to seed vector.
    vec3 md = vec3(1., 1., 1.);
    // Minimum squared radius to seed.
    float mr = 3.f;
    vec3 i = floor(v);
    for(float j = -1.; j <= 1.; j += 1.)
    for(float k = -1.; k <= 1.; k += 1.)
    for(float l = -1.; l <= 1.; l += 1.) {
        vec3 seed = i + vec3(j, k, l) + hash(i + vec3(j, k, l));
        vec3 d = seed - v;
        float r = dot(d, d);
        if(r < mr) {
            md = d;
            mr = r;
        }
    }
    // Minimum distance seed.
    vec3 s1 = v + md;
    // Minimum cell coordinates.
    vec3 mc = floor(s1);
    // Minimum edge distance.
    float me = 3.;
    for(float j = -2.; j <= 2.; j += 1.)
    for(float k = -2.; k <= 2.; k += 1.)
    for(float l = -2.; l <= 2.; l += 1.) {
        if(j == 0. && k == 0. && l == 0.) continue;
        vec3 s2 = mc + vec3(j, k, l) + hash(mc + vec3(j, k, l));
        vec3 d = s1 - v;
        float e = (dot(v - (s1 + s2) / 2., normalize(s1 - s2)));
        if(e < me) {
            me = e;
        }
    }
    return me;
}

void mainImage( out vec4 col, in vec2 cs ) {
    cs = (2. * cs - iResolution.xy) / iResolution.y * 4.f;
   
    
    if(cs.x < 0.) {
        vec3 v = voronoi(vec3(cs, iTime/ 4.));
        col = vec4(vec3(length(v) / sqrt(2.)), 1.);
    } else {
        col = vec4(vec3(worley_noise_edge(vec3(cs, iTime/ 4.))), 1.);
    }
}
