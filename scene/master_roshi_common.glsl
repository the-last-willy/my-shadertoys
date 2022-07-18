/*
    In this file:
    - Primitives and operators
    - Sdf tree
    - Material tree
*/

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// Primitives and operators.
// Credits to Inigo Quilez for most of it.

struct SdfAndMaterial {
    vec3 color;
    float distance;
};

float circle(float r, vec3 p) {
    vec2 q = vec2(length(p.xz)-r,p.y);
    return length(q);
}

float cone(in vec2 q, in vec3 p) {
    vec2 w = vec2( length(p.xz), p.y );
    vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
    vec2 b = w - q*vec2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
    float k = sign( q.y );
    float d = min(dot( a, a ),dot(b, b));
    float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
    return sqrt(d)*sign(s);
}

float corrected(float c, float d) {
    return d * c;
}

SdfAndMaterial corrected(float c, SdfAndMaterial sam) {
    return SdfAndMaterial(
        sam.color,
        corrected(c, sam.distance));
}

float cube(vec3 p) {
    p = abs(p);
    float exterior = length(max(p - vec3(.5), 0.));
    float interior = min(max(p.x, max(p.y, p.z)) - .5, 0.);
    return exterior + interior;
}

float difference(float d0, float d1) {
    return max(d0, -d1);
}

SdfAndMaterial difference(in SdfAndMaterial sam0, in SdfAndMaterial sam1) {
    return SdfAndMaterial(
        sam0.color,
        difference(sam0.distance, sam1.distance));
}

float dilated(float radius, float d) {
    return d - radius;
}

SdfAndMaterial dilated(float radius, SdfAndMaterial sam) {
    sam.distance = dilated(radius, sam.distance);
    return sam;
}

float inverted(float d) {
    return -d;
}

SdfAndMaterial inverted(in SdfAndMaterial sam) {
    return SdfAndMaterial(
        sam.color,
        inverted(sam.distance));
}

float onion(in float f) {
    return abs(f);
}

SdfAndMaterial onion(in SdfAndMaterial sam) {
    return SdfAndMaterial(
        sam.color,
        onion(sam.distance));
}

float point(in vec3 position) {
    return length(position);
}

vec3 reflected_x(vec3 p) {
    return vec3(abs(p.x), p.yz);
}

vec3 reflected_y(in vec3 p) {
    p.y = abs(p.y);
    return p;
}

vec3 reflected_z(vec3 p) {
    p.z = abs(p.z);
    return p;
}

vec3 rotated_x(float a, vec3 p) {
    float sa=sin(a);
    float ca=cos(a);
    return vec3(
        p.x,
        ca * p.y - sa * p.z,
        sa * p.y + ca * p.z);
}

vec3 rotated_y(float a, vec3 p) {
    float sa=sin(a);
    float ca=cos(a);
    return vec3(ca*p.x+sa*p.z,p.y,-sa*p.x+ca*p.z);
}

vec3 rotated_z(float a, vec3 p) {
    float sa=sin(a);
    float ca=cos(a);
    return vec3(ca*p.x+sa*p.y,-sa*p.x+ca*p.y,p.z);
}

vec3 scaled(float s, vec3 position) {
    return position / s;
}

vec3 scaled(vec3 s, vec3 position) {
    return position / s;
}

float ellipsoid(in vec3 r, in vec3 p) {
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float intersection(in float d0, in float d1) {
    return max(d0, d1);
}

SdfAndMaterial intersection(in SdfAndMaterial sam0, in SdfAndMaterial sam1) {
    if(sam0.distance < sam1.distance) {
        return sam1;
    } else {
        return sam0;
    }
}

float line_segment(vec3 a, vec3 b, vec3 p) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float plane(vec3 position) {
    return abs(position.x);
}

float unionn(in float d0, in float d1) {
    return min(d0, d1);
}

SdfAndMaterial unionn(in SdfAndMaterial sam0, in SdfAndMaterial sam1) {
    if(sam0.distance < sam1.distance) {
        return sam0;
    } else {
        return sam1;
    }
}

float smooth_union(float k, float d1, float d2) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

SdfAndMaterial smooth_union(float k, in SdfAndMaterial sam0, in SdfAndMaterial sam1) {
    float d1 = sam0.distance;
    float d2 = sam1.distance;
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return SdfAndMaterial(
        mix(sam1.color, sam0.color, h),
        mix(d2, d1, h) - k*h*(1.0-h));
}

vec3 translated(vec3 translation, vec3 position) {
    return position - translation;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//  SDF tree.

float roshi_rod_sdf(vec3 position) {
  return smooth_union(0.2,
    dilated(0.05,
      corrected(0.23,
        corrected(0.1,
          cube(
            scaled(vec3(0.1, 0.1, 0.1),
              scaled(vec3(0.23, 0.24, 0.58),
                rotated_z(-0.73,
                  rotated_y(-0.21,
                    rotated_x(-1.01,
                      translated(vec3(0.33, 1.01, -0.5),
                        position)))))))))),
    smooth_union(0.2,
      dilated(0.05,
        corrected(1.59,
          corrected(0.1,
            cube(
              scaled(vec3(0.1, 0.1, 0.1),
                scaled(vec3(1.76, 1.59, 1.66),
                  rotated_y(-0.46,
                    rotated_x(-0.92,
                      translated(vec3(0.33, 1.19, -0.5),
                        position))))))))),
      smooth_union(0.2,
        dilated(0.05,
          corrected(1.,
            corrected(0.1,
              cube(
                scaled(vec3(0.1, 0.1, 0.1),
                  scaled(vec3(1.11, 1, 1.55),
                    rotated_z(-0.73,
                      rotated_y(-0.21,
                        rotated_x(-1.01,
                          translated(vec3(0.33, 1.43, -0.5),
                            position)))))))))),
        corrected(1.,
          dilated(0.05,
            line_segment(vec3(0, -1, 0), vec3(0, 1, 0), scaled(vec3(1, 1.08, 1),
              translated(vec3(0.36, -0.02, -0.46),
                position))))))));
}

float roshi_shirt_sdf(vec3 position) {
  return unionn(
    intersection(
      inverted(
        translated(vec3(0.1, 0, 0),
          position).x),
      corrected(0.46,
        intersection(
          inverted(
            scaled(vec3(1.14, 1.16, 0.46),
              translated(vec3(-0.06, 0, 0),
                position)).y),
          ellipsoid(vec3(0.65, 2, 1),
            scaled(vec3(1.14, 1.16, 0.46),
              translated(vec3(-0.06, 0, 0),
                position)))))),
    unionn(
      corrected(0.1,
        unionn(
          corrected(0.34,
            dilated(1.,
              point(scaled(vec3(0.86, 0.34, 0.94),
                translated(vec3(6.2, 1.88, 0),
                  scaled(vec3(0.1, 0.1, 0.1),
                    position)))))),
          unionn(
            corrected(0.39,
              dilated(1.,
                point(scaled(vec3(0.62, 0.39, 1),
                  translated(vec3(6.15, 4.54, 0),
                    scaled(vec3(0.1, 0.1, 0.1),
                      position)))))),
            unionn(
              corrected(0.39,
                dilated(1.,
                  point(scaled(vec3(0.62, 0.39, 1),
                    translated(vec3(5.95, 7.06, 0),
                      scaled(vec3(0.1, 0.1, 0.1),
                        position)))))),
              corrected(0.39,
                dilated(1.,
                  point(scaled(vec3(0.62, 0.39, 1),
                    translated(vec3(5.73, 9.51, 0),
                      scaled(vec3(0.1, 0.1, 0.1),
                        position)))))))))),
      smooth_union(0.1,
        corrected(0.4,
          dilated(1.,
            point(scaled(vec3(0.4, 0.4, 0.4),
              translated(vec3(0, 1.16, 0.58),
                reflected_z(
                  position)))))),
        intersection(
          inverted(
            position.y),
          ellipsoid(vec3(0.65, 2, 1),
            position)))));
}

float roshi_left_arm_sdf(vec3 position) {
  return unionn(
    dilated(0.1,
      corrected(0.125,
        cube(
          scaled(vec3(0.125, 0.13, 0.15),
            translated(vec3(0, 0.2, 0.92),
              position))))),
    unionn(
      corrected(0.36,
        dilated(0.2,
          circle(1.,
            scaled(vec3(0.38, 0.96, 0.36),
              translated(vec3(0, 0.33, 0.86),
                position))))),
      unionn(
        dilated(0.1,
          corrected(0.125,
            cube(
              scaled(vec3(0.125, 0.13, 0.15),
                translated(vec3(0, 0.2, 0.92),
                  position))))),
        intersection(
          inverted(
            translated(vec3(0, 0.2, 0),
              position).y),
          dilated(0.4,
            line_segment(vec3(0, 1.16, 0.58), vec3(0, 0.27, 0.87), position))))));
}

float roshi_right_arm_sdf(vec3 position) {
  return unionn(
    corrected(0.36,
      dilated(0.2,
        circle(1.,
          scaled(vec3(0.36, 1.26, 0.36),
            rotated_z(-1.68,
              translated(vec3(0.36, 0.62, -0.94),
                position)))))),
    unionn(
      smooth_union(0.2,
        dilated(0.1,
          corrected(0.125,
            cube(
              scaled(vec3(0.125, 0.13, 0.15),
                translated(vec3(0.73, 0.61, -0.9),
                  position))))),
        dilated(0.1,
          line_segment(vec3(0, 0.65, -0.98), vec3(0.67, 0.63, -0.94), position))),
      intersection(
        corrected(1.,
          scaled(vec3(1, 1, 1),
            translated(vec3(0.47, 0, 0),
              position)).x),
        dilated(0.01,
          onion(
            unionn(
              dilated(0.39,
                line_segment(vec3(0, 0.65, -0.98), vec3(0.37, 0.63, -0.94), position)),
              dilated(0.39,
                line_segment(vec3(0, 1.16, -0.58), vec3(0, 0.65, -0.98), position))))))));
}

float roshi_head_sdf(vec3 position) {
  return unionn(
    corrected(0.4,
      smooth_union(0.2,
        corrected(0.1,
          corrected(1.,
            dilated(1.,
              point(scaled(vec3(1, 1, 1),
                translated(vec3(9.34, -4.26, 0.25),
                  reflected_z(
                    scaled(vec3(0.1, 0.1, 0.1),
                      scaled(vec3(0.4, 0.4, 0.4),
                        translated(vec3(0.29, 1.92, 0),
                          position)))))))))),
        smooth_union(0.2,
          corrected(0.1,
            dilated(1.,
              line_segment(vec3(10.07, 0.08, 0), vec3(10.59, -4.16, 0), scaled(vec3(0.1, 0.1, 0.1),
                scaled(vec3(0.4, 0.4, 0.4),
                  translated(vec3(0.29, 1.92, 0),
                    position)))))),
          smooth_union(0.2,
            corrected(0.7,
              dilated(0.2,
                cube(
                  scaled(vec3(1, 1.05, 0.7),
                    translated(vec3(0.05, -0.49, 0),
                      scaled(vec3(0.4, 0.4, 0.4),
                        translated(vec3(0.29, 1.92, 0),
                          position))))))),
            smooth_union(0.2,
              corrected(0.56,
                dilated(0.2,
                  cube(
                    scaled(vec3(0.9, 0.56, 0.91),
                      translated(vec3(0.06, -0.13, 0),
                        scaled(vec3(0.4, 0.4, 0.4),
                          translated(vec3(0.29, 1.92, 0),
                            position))))))),
              smooth_union(0.2,
                corrected(0.3,
                  ellipsoid(vec3(1, 1, 0.5),
                    scaled(vec3(0.3, 0.3, 0.3),
                      rotated_y(-0.93,
                        translated(vec3(0, -0.21, 1.07),
                          reflected_z(
                            scaled(vec3(0.4, 0.4, 0.4),
                              translated(vec3(0.29, 1.92, 0),
                                position)))))))),
                dilated(1.,
                  point(scaled(vec3(0.4, 0.4, 0.4),
                    translated(vec3(0.29, 1.92, 0),
                      position)))))))))),
    corrected(0.1,
      dilated(0.1,
        unionn(
          difference(corrected(1.19,
            dilated(1.,
              point(scaled(vec3(1.19, 1.24, 1.21),
                translated(vec3(5.52, 22.04, 1.29),
                  reflected_z(
                    scaled(vec3(0.1, 0.1, 0.1),
                      translated(vec3(0, -0.1, 0),
                        position)))))))), corrected(1.78,
            dilated(1.,
              point(scaled(vec3(2.38, 4.93, 1.78),
                translated(vec3(7.46, 20.27, 1.28),
                  reflected_z(
                    scaled(vec3(0.1, 0.1, 0.1),
                      translated(vec3(0, -0.1, 0),
                        position))))))))),
          unionn(
            smooth_union(0.3,
              corrected(0.71,
                dilated(1.,
                  point(scaled(vec3(0.71, 1.04, 1.55),
                    translated(vec3(6.77, 17.21, 0),
                      scaled(vec3(0.1, 0.1, 0.1),
                        translated(vec3(0, -0.1, 0),
                          position))))))),
              corrected(0.75,
                cone(vec2(1., 1.),
                  scaled(vec3(0.75, 3.51, 1.35),
                    rotated_x(0.64,
                      translated(vec3(6.81, 13.67, 2.86),
                        reflected_z(
                          scaled(vec3(0.1, 0.1, 0.1),
                            translated(vec3(0, -0.1, 0),
                              position))))))))),
            corrected(0.83,
              cone(vec2(1., 1.),
                scaled(vec3(0.83, 5.2, 2),
                  translated(vec3(6.46, 10.32, -0.14),
                    scaled(vec3(0.1, 0.1, 0.1),
                      translated(vec3(0, -0.1, 0),
                        position)))))))))));
}

float roshi_glasses_sdf(vec3 position) {
  return unionn(
    corrected(0.1,
      corrected(0.24,
        dilated(1.,
          point(scaled(vec3(0.24, 0.97, 1.24),
            translated(vec3(7.3, 19.17, 1.83),
              reflected_z(
                scaled(vec3(0.1, 0.1, 0.1),
                  position)))))))),
    corrected(0.1,
      smooth_union(0.1,
        dilated(0.2,
          line_segment(vec3(2.34, 19.72, 4.31), vec3(7.08, 19.52, 3.26), reflected_z(
            scaled(vec3(0.1, 0.1, 0.1),
              position)))),
        smooth_union(0.1,
          corrected(0.58,
            dilated(0.1,
              line_segment(vec3(0, 0, -1), vec3(0, 0, 1), scaled(vec3(0.58, 2.3, 1.57),
                translated(vec3(7.3, 19.75, 0),
                  scaled(vec3(0.1, 0.1, 0.1),
                    position)))))),
          corrected(0.23,
            dilated(1.,
              point(scaled(vec3(0.23, 1.23, 1.57),
                translated(vec3(7.18, 19.21, 1.87),
                  reflected_z(
                    scaled(vec3(0.1, 0.1, 0.1),
                      position)))))))))));
}

// Alright, I got lazy for that one.
float roshi_lower_half_sdf(vec3 position) {
  return smooth_union(0.2,
    corrected(0.32,
      dilated(1.,
        point(scaled(vec3(0.331, 0.32, 0.36),
          translated(vec3(-0.03, -0.26, -0.31),
            position))))),
    smooth_union(0.2,
      corrected(0.31,
        dilated(1.,
          point(scaled(vec3(0.31, 0.32, 0.36),
            translated(vec3(0.1, -0.11, 0.36),
              position))))),
      unionn(
        corrected(0.24,
          intersection(
            inverted(
              scaled(vec3(0.51, 0.26, 0.24),
                rotated_y(0.37,
                  translated(vec3(0.17, -1.25, 0.3),
                    reflected_z(
                      position)))).y),
            unionn(
              corrected(0.74,
                dilated(1.,
                  point(scaled(vec3(1.29, 0.74, 1.21),
                    translated(vec3(-0.08, 0.12, 0),
                      scaled(vec3(0.51, 0.26, 0.24),
                        rotated_y(0.37,
                          translated(vec3(0.17, -1.25, 0.3),
                            reflected_z(
                              position))))))))),
              dilated(1.,
                point(scaled(vec3(0.51, 0.26, 0.24),
                  rotated_y(0.37,
                    translated(vec3(0.17, -1.25, 0.3),
                      reflected_z(
                        position))))))))),
        corrected(0.49,
          dilated(0.2,
            cone(vec2(1., 1.),
              scaled(vec3(0.49, 0.94, 0.53),
                translated(vec3(0.01, -0.88, 0.24),
                  reflected_z(
                    position)))))))));
}

float roshi_sdf(vec3 position) {
  return unionn(
    roshi_lower_half_sdf(
      position),
    unionn(
      roshi_glasses_sdf(
        position),
      unionn(
        roshi_head_sdf(
          position),
        unionn(
          roshi_right_arm_sdf(
            position),
          unionn(
            roshi_left_arm_sdf(
              position),
            unionn(
              roshi_shirt_sdf(
                position),
              corrected(1.,
                roshi_rod_sdf(
                  scaled(vec3(1, 1.08, 1),
                    translated(vec3(0.36, -0.02, -0.46),
                      position))))))))));
}

float scene_sdf(vec3 position) {
  return roshi_sdf(
    vec3(position.y, position.z, -position.x));
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// Material tree.

SdfAndMaterial roshi_rod_material(vec3 position) {
  return SdfAndMaterial(vec3(0.356863, 0.160784, 0.152941),
    smooth_union(0.2,
      dilated(0.05,
        corrected(0.23,
          corrected(0.1,
            cube(
              scaled(vec3(0.1, 0.1, 0.1),
                scaled(vec3(0.23, 0.24, 0.58),
                  rotated_z(-0.73,
                    rotated_y(-0.21,
                      rotated_x(-1.01,
                        translated(vec3(0.33, 1.01, -0.5),
                          position)))))))))),
      smooth_union(0.2,
        dilated(0.05,
          corrected(1.59,
            corrected(0.1,
              cube(
                scaled(vec3(0.1, 0.1, 0.1),
                  scaled(vec3(1.76, 1.59, 1.66),
                    rotated_y(-0.46,
                      rotated_x(-0.92,
                        translated(vec3(0.33, 1.19, -0.5),
                          position))))))))),
        smooth_union(0.2,
          dilated(0.05,
            corrected(1.,
              corrected(0.1,
                cube(
                  scaled(vec3(0.1, 0.1, 0.1),
                    scaled(vec3(1.11, 1, 1.55),
                      rotated_z(-0.73,
                        rotated_y(-0.21,
                          rotated_x(-1.01,
                            translated(vec3(0.33, 1.43, -0.5),
                              position)))))))))),
          corrected(1.,
            dilated(0.05,
              line_segment(vec3(0, -1, 0), vec3(0, 1, 0), scaled(vec3(1, 1.08, 1),
                translated(vec3(0.36, -0.02, -0.46),
                  position)))))))));
}

SdfAndMaterial roshi_shirt_material(vec3 position) {
  return unionn(
    SdfAndMaterial(vec3(0.870588, 0.780392, 0.780392),
      intersection(
        inverted(
          translated(vec3(0.1, 0, 0),
            position).x),
        corrected(0.46,
          intersection(
            inverted(
              scaled(vec3(1.14, 1.16, 0.46),
                translated(vec3(-0.06, 0, 0),
                  position)).y),
            ellipsoid(vec3(0.65, 2, 1),
              scaled(vec3(1.14, 1.16, 0.46),
                translated(vec3(-0.06, 0, 0),
                  position))))))),
    unionn(
      SdfAndMaterial(vec3(0.227451, 0.145098, 0.262745),
        corrected(0.1,
          unionn(
            corrected(0.34,
              dilated(1.,
                point(scaled(vec3(0.86, 0.34, 0.94),
                  translated(vec3(6.2, 1.88, 0),
                    scaled(vec3(0.1, 0.1, 0.1),
                      position)))))),
            unionn(
              corrected(0.39,
                dilated(1.,
                  point(scaled(vec3(0.62, 0.39, 1),
                    translated(vec3(6.15, 4.54, 0),
                      scaled(vec3(0.1, 0.1, 0.1),
                        position)))))),
              unionn(
                corrected(0.39,
                  dilated(1.,
                    point(scaled(vec3(0.62, 0.39, 1),
                      translated(vec3(5.95, 7.06, 0),
                        scaled(vec3(0.1, 0.1, 0.1),
                          position)))))),
                corrected(0.39,
                  dilated(1.,
                    point(scaled(vec3(0.62, 0.39, 1),
                      translated(vec3(5.73, 9.51, 0),
                        scaled(vec3(0.1, 0.1, 0.1),
                          position))))))))))),
      SdfAndMaterial(vec3(0.8, 0.443137, 0.239216),
        smooth_union(0.1,
          corrected(0.4,
            dilated(1.,
              point(scaled(vec3(0.4, 0.4, 0.4),
                translated(vec3(0, 1.16, 0.58),
                  reflected_z(
                    position)))))),
          intersection(
            inverted(
              position.y),
            ellipsoid(vec3(0.65, 2, 1),
              position))))));
}

SdfAndMaterial roshi_left_arm_material(vec3 position) {
  return unionn(
    SdfAndMaterial(vec3(0.819608, 0.560784, 0.498039),
      dilated(0.1,
        corrected(0.125,
          cube(
            scaled(vec3(0.125, 0.13, 0.15),
              translated(vec3(0, 0.2, 0.92),
                position)))))),
    unionn(
      SdfAndMaterial(vec3(0.870588, 0.780392, 0.780392),
        corrected(0.36,
          dilated(0.2,
            circle(1.,
              scaled(vec3(0.38, 0.96, 0.36),
                translated(vec3(0, 0.33, 0.86),
                  position)))))),
      unionn(
        SdfAndMaterial(vec3(0.819608, 0.560784, 0.498039),
          dilated(0.1,
            corrected(0.125,
              cube(
                scaled(vec3(0.125, 0.13, 0.15),
                  translated(vec3(0, 0.2, 0.92),
                    position)))))),
        SdfAndMaterial(vec3(0.8, 0.443137, 0.239216),
          intersection(
            inverted(
              translated(vec3(0, 0.2, 0),
                position).y),
            dilated(0.4,
              line_segment(vec3(0, 1.16, 0.58), vec3(0, 0.27, 0.87), position)))))));
}

SdfAndMaterial roshi_right_arm_material(vec3 position) {
  return unionn(
    SdfAndMaterial(vec3(0.870588, 0.780392, 0.780392),
      corrected(0.36,
        dilated(0.2,
          circle(1.,
            scaled(vec3(0.36, 1.26, 0.36),
              rotated_z(-1.68,
                translated(vec3(0.36, 0.62, -0.94),
                  position))))))),
    unionn(
      SdfAndMaterial(vec3(0.819608, 0.560784, 0.498039),
        smooth_union(0.2,
          dilated(0.1,
            corrected(0.125,
              cube(
                scaled(vec3(0.125, 0.13, 0.15),
                  translated(vec3(0.73, 0.61, -0.9),
                    position))))),
          dilated(0.1,
            line_segment(vec3(0, 0.65, -0.98), vec3(0.67, 0.63, -0.94), position)))),
      SdfAndMaterial(vec3(0.8, 0.443137, 0.239216),
        intersection(
          corrected(1.,
            scaled(vec3(1, 1, 1),
              translated(vec3(0.47, 0, 0),
                position)).x),
          dilated(0.01,
            onion(
              unionn(
                dilated(0.39,
                  line_segment(vec3(0, 0.65, -0.98), vec3(0.37, 0.63, -0.94), position)),
                dilated(0.39,
                  line_segment(vec3(0, 1.16, -0.58), vec3(0, 0.65, -0.98), position)))))))));
}

SdfAndMaterial roshi_head_material(vec3 position) {
  return unionn(
    SdfAndMaterial(vec3(0.819608, 0.560784, 0.498039),
      corrected(0.4,
        smooth_union(0.2,
          corrected(0.1,
            corrected(1.,
              dilated(1.,
                point(scaled(vec3(1, 1, 1),
                  translated(vec3(9.34, -4.26, 0.25),
                    reflected_z(
                      scaled(vec3(0.1, 0.1, 0.1),
                        scaled(vec3(0.4, 0.4, 0.4),
                          translated(vec3(0.29, 1.92, 0),
                            position)))))))))),
          smooth_union(0.2,
            corrected(0.1,
              dilated(1.,
                line_segment(vec3(10.07, 0.08, 0), vec3(10.59, -4.16, 0), scaled(vec3(0.1, 0.1, 0.1),
                  scaled(vec3(0.4, 0.4, 0.4),
                    translated(vec3(0.29, 1.92, 0),
                      position)))))),
            smooth_union(0.2,
              corrected(0.7,
                dilated(0.2,
                  cube(
                    scaled(vec3(1, 1.05, 0.7),
                      translated(vec3(0.05, -0.49, 0),
                        scaled(vec3(0.4, 0.4, 0.4),
                          translated(vec3(0.29, 1.92, 0),
                            position))))))),
              smooth_union(0.2,
                corrected(0.56,
                  dilated(0.2,
                    cube(
                      scaled(vec3(0.9, 0.56, 0.91),
                        translated(vec3(0.06, -0.13, 0),
                          scaled(vec3(0.4, 0.4, 0.4),
                            translated(vec3(0.29, 1.92, 0),
                              position))))))),
                smooth_union(0.2,
                  corrected(0.3,
                    ellipsoid(vec3(1, 1, 0.5),
                      scaled(vec3(0.3, 0.3, 0.3),
                        rotated_y(-0.93,
                          translated(vec3(0, -0.21, 1.07),
                            reflected_z(
                              scaled(vec3(0.4, 0.4, 0.4),
                                translated(vec3(0.29, 1.92, 0),
                                  position)))))))),
                  dilated(1.,
                    point(scaled(vec3(0.4, 0.4, 0.4),
                      translated(vec3(0.29, 1.92, 0),
                        position))))))))))),
    SdfAndMaterial(vec3(0.870588, 0.780392, 0.780392),
      corrected(0.1,
        dilated(0.1,
          unionn(
            difference(corrected(1.19,
              dilated(1.,
                point(scaled(vec3(1.19, 1.24, 1.21),
                  translated(vec3(5.52, 22.04, 1.29),
                    reflected_z(
                      scaled(vec3(0.1, 0.1, 0.1),
                        translated(vec3(0, -0.1, 0),
                          position)))))))), corrected(1.78,
              dilated(1.,
                point(scaled(vec3(2.38, 4.93, 1.78),
                  translated(vec3(7.46, 20.27, 1.28),
                    reflected_z(
                      scaled(vec3(0.1, 0.1, 0.1),
                        translated(vec3(0, -0.1, 0),
                          position))))))))),
            unionn(
              smooth_union(0.3,
                corrected(0.71,
                  dilated(1.,
                    point(scaled(vec3(0.71, 1.04, 1.55),
                      translated(vec3(6.77, 17.21, 0),
                        scaled(vec3(0.1, 0.1, 0.1),
                          translated(vec3(0, -0.1, 0),
                            position))))))),
                corrected(0.75,
                  cone(vec2(1., 1.),
                    scaled(vec3(0.75, 3.51, 1.35),
                      rotated_x(0.64,
                        translated(vec3(6.81, 13.67, 2.86),
                          reflected_z(
                            scaled(vec3(0.1, 0.1, 0.1),
                              translated(vec3(0, -0.1, 0),
                                position))))))))),
              corrected(0.83,
                cone(vec2(1., 1.),
                  scaled(vec3(0.83, 5.2, 2),
                    translated(vec3(6.46, 10.32, -0.14),
                      scaled(vec3(0.1, 0.1, 0.1),
                        translated(vec3(0, -0.1, 0),
                          position))))))))))));
}

SdfAndMaterial roshi_glasses_material(vec3 position) {
  return unionn(
    SdfAndMaterial(vec3(0.0470588, 0.2, 0.0666667),
      corrected(0.1,
        corrected(0.24,
          dilated(1.,
            point(scaled(vec3(0.24, 0.97, 1.24),
              translated(vec3(7.3, 19.17, 1.83),
                reflected_z(
                  scaled(vec3(0.1, 0.1, 0.1),
                    position))))))))),
    SdfAndMaterial(vec3(0.490196, 0.12549, 0.0745098),
      corrected(0.1,
        smooth_union(0.1,
          dilated(0.2,
            line_segment(vec3(2.34, 19.72, 4.31), vec3(7.08, 19.52, 3.26), reflected_z(
              scaled(vec3(0.1, 0.1, 0.1),
                position)))),
          smooth_union(0.1,
            corrected(0.58,
              dilated(0.1,
                line_segment(vec3(0, 0, -1), vec3(0, 0, 1), scaled(vec3(0.58, 2.3, 1.57),
                  translated(vec3(7.3, 19.75, 0),
                    scaled(vec3(0.1, 0.1, 0.1),
                      position)))))),
            corrected(0.23,
              dilated(1.,
                point(scaled(vec3(0.23, 1.23, 1.57),
                  translated(vec3(7.18, 19.21, 1.87),
                    reflected_z(
                      scaled(vec3(0.1, 0.1, 0.1),
                        position))))))))))));
}

SdfAndMaterial roshi_lower_half_material(vec3 position) {
  return smooth_union(0.2,
    SdfAndMaterial(vec3(0.219608, 0.203922, 0.494118),
      corrected(0.32,
        dilated(1.,
          point(scaled(vec3(0.331, 0.32, 0.36),
            translated(vec3(-0.03, -0.26, -0.31),
              position)))))),
    smooth_union(0.2,
      SdfAndMaterial(vec3(0.219608, 0.203922, 0.494118),
        corrected(0.31,
          dilated(1.,
            point(scaled(vec3(0.31, 0.32, 0.36),
              translated(vec3(0.1, -0.11, 0.36),
                position)))))),
      unionn(
        corrected(0.24,
          intersection(
            SdfAndMaterial(vec3(0.819608, 0.560784, 0.498039),
              inverted(
                scaled(vec3(0.51, 0.26, 0.24),
                  rotated_y(0.37,
                    translated(vec3(0.17, -1.25, 0.3),
                      reflected_z(
                        position)))).y)),
            unionn(
              SdfAndMaterial(vec3(0.227451, 0.145098, 0.262745),
                corrected(0.74,
                  dilated(1.,
                    point(scaled(vec3(1.29, 0.74, 1.21),
                      translated(vec3(-0.08, 0.12, 0),
                        scaled(vec3(0.51, 0.26, 0.24),
                          rotated_y(0.37,
                            translated(vec3(0.17, -1.25, 0.3),
                              reflected_z(
                                position)))))))))),
              SdfAndMaterial(vec3(0.819608, 0.560784, 0.498039),
                dilated(1.,
                  point(scaled(vec3(0.51, 0.26, 0.24),
                    rotated_y(0.37,
                      translated(vec3(0.17, -1.25, 0.3),
                        reflected_z(
                          position)))))))))),
        SdfAndMaterial(vec3(0.219608, 0.203922, 0.494118),
          corrected(0.49,
            dilated(0.2,
              cone(vec2(1., 1.),
                scaled(vec3(0.49, 0.94, 0.53),
                  translated(vec3(0.01, -0.88, 0.24),
                    reflected_z(
                      position))))))))));
}

SdfAndMaterial roshi_material(vec3 position) {
  return unionn(
    roshi_lower_half_material(
      position),
    unionn(
      roshi_glasses_material(
        position),
      unionn(
        roshi_head_material(
          position),
        unionn(
          roshi_right_arm_material(
            position),
          unionn(
            roshi_left_arm_material(
              position),
            unionn(
              roshi_shirt_material(
                position),
              corrected(1.,
                roshi_rod_material(
                  scaled(vec3(1, 1.08, 1),
                    translated(vec3(0.36, -0.02, -0.46),
                      position))))))))));
}

SdfAndMaterial scene_material(vec3 position) {
  return roshi_material(
    vec3(position.y, position.z, -position.x));
}

vec3 scene_normal( in vec3 p) {
  float e = .01;
  float v = scene_sdf(p);
  return normalize(vec3(
    scene_sdf(vec3(p.x + e, p.y, p.z)) - v,
    scene_sdf(vec3(p.x, p.y + e, p.z)) - v,
    scene_sdf(vec3(p.x, p.y, p.z + e)) - v));
}
