// Transforms
vec3 rotateX(vec3 p, float a) {
    float sa = sin(a);
    float ca = cos(a);
    return vec3(p.x, ca * p.y - sa * p.z, sa * p.y + ca * p.z);
}

vec3 rotateY(vec3 p, float a) {
    float sa = sin(a);
    float ca = cos(a);
    return vec3(ca * p.x + sa * p.z, p.y, -sa * p.x + ca * p.z);
}

vec3 rotateZ(vec3 p, float a) {
    float sa = sin(a);
    float ca = cos(a);
    return vec3(ca * p.x + sa * p.y, -sa * p.x + ca * p.y, p.z);
}

vec3 sdf_color_closest(
    in float distance0, in vec3 color0,
    in float distance1, in vec3 color1)
{
    return distance0 < distance1 ? color0 : color1;
}


float circle_sdf(vec2 v) {
    return length(v - normalize(v));
}

// XY circle.
float circle_sdf(vec3 v) {
    return length(v - vec3(normalize(v.xy), 0.));
}

float sdf_cube(in vec3 position) {
    vec3 ap = abs(position);
    float exterior = length(max(ap - vec3(.5), 0.));
    float interior = min(max(ap.x, max(ap.y, ap.z)) - .5, 0.);
    return exterior + interior;
}

// float sdf_plane(vec3 p) {
//     return p.z;
// }

float sdf_point(in vec3 position) {
    return length(position);
}

float sdf_square_toroid(float r, vec3 v) {
    // XY circle.
    float d = length(v.xy - normalize(v.xy)) - r;;
    // Extrusion.
    vec2 w = vec2(d, abs(v.z) - r);
    return min(max(w.x,w.y),0.) + length(max(w, 0.));
}

float sdf_square_toroid(float r, float h, vec3 v) {
    // XY circle.
    float d = length(v.xy - normalize(v.xy)) - r;;
    // Extrusion.
    vec2 w = vec2(d, abs(v.z) - h);
    return min(max(w.x,w.y),0.) + length(max(w, 0.));
}


float square_sdf(vec2 p) {
    p = abs(p);
    float exterior = length(max(p - vec2(.5), 0.));
    float interior = min(max(p.x, p.y) - .5, 0.);
    return exterior + interior;
}

float cube_sdf(vec3 p) {
    p = abs(p);
    float exterior = length(max(p - vec3(.5), 0.));
    float interior = min(max(p.x, max(p.y, p.z)) - .5, 0.);
    return exterior + interior;
}

float line_sdf(vec3 a, vec3 b, vec3 p) {
    vec3 ab = b - a, ap = p - a;
    vec3 q = a + dot(ap, ab) / dot(ab, ab) * ab;
    return length(q - ap);
}

float plane_sdf(vec3 p) {
    return p.z;
}

float point_sdf(vec2 v) {
    return length(v);
}

float point_sdf(vec3 v) {
    return length(v);
}

float point_sdf(vec3 p, vec3 q) {
    return length(p - q);
}

float segment_sdf(vec3 p) {
	return 0.;
}

float segment_sdf(vec3 a, vec3 b, vec3 p) {
    vec3 ab = b - a, ap = p - a;
	float h = clamp(dot(ab, ap) / dot(ab, ab), 0., 1.);
	return length(ap - h * ab);
}


float cylinder_sdf(vec3 p) {
    vec2 q = vec2(length(p.xy), p.z);
    return square_sdf(q);
}


float sdf_difference(float a, float b) {
    return max(a, -b);
}

float sdf_intersection(float a, float b) {
    return max(a, b);
}

float sdf_union(float a, float b) {
    return min(a, b);
}


// subroutine vec3 RenderMode();

// subroutine(RenderMode) vec3 render_albedo() {
//     return vec3(0.);
// }

// subroutine uniform RenderMode render_mode;

// Common

// Hashing function
// Returns a random number in [-1,1]
float Hash(float seed) {
    return fract(sin(seed) * 43758.5453);
}

// Cosine direction
vec3 Cosine(in float seed, in vec3 nor) {
    float u = Hash(78.233 + seed);
    float v = Hash(10.873 + seed);

    // method 3 by fizzer: http://www.amietia.com/lambertnotangent.html
    float a = 6.2831853 * v;
    u = 2. * u - 1.;
    return normalize(nor + vec3(sqrt(1. - u * u) * vec2(cos(a), sin(a)), u));
}

// Rotation matrix around z axis
// a : Angle
mat3 rotate_z(float a) {
    float sa = sin(a);
    float ca = cos(a);
    return mat3(
         ca, sa, 0.,
        -sa, ca, 0., 
         0., 0., 1.);
}

// Compute the ray
// m : Mouse position
// p : Pixel
// ro, rd : Ray origin and direction
void Ray(in vec2 m, in vec2 p, out vec3 ro, out vec3 rd) {
    float a = 3. * 3.14 * m.x;
    float le = 3.8;

    ro = vec3(70., 0., 20.);
    ro *= rotate_z(3. * 3.14 * m.x);

    vec3 ta = vec3(0., 0., 1.);
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0., 0., 1.)));
    vec3 vv = normalize(cross(uu, ww));
    rd = normalize(p.x * uu + p.y * vv + le * ww);
}

// Main

const int Steps = 1000;
const float Epsilon = .03; // Marching epsilon

const float T = .5;

const float rA = 0.1; // Maximum and minimum ray marching or sphere tracing distance from origin
const float rB = 100.;


// Props.

float base(in vec3 p) {
    p -= vec3(0., -4., 0.);
    float d = sdf_intersection(point_sdf(p) - 25.f, plane_sdf(p.xzy));
    float s = 3.;
    d = sdf_difference(d, sdf_square_toroid(0.2 / s, 0.1 / s, p.xzy / s) * s);
    s = 6.;
    d = sdf_difference(d, sdf_square_toroid(0.2 / s, 0.1 / s, p.xzy / s) * s);
    s = 9.;
    d = sdf_difference(d, sdf_square_toroid(0.2 / s, 0.1 / s, p.xzy / s) * s);
    s = 12.;
    d = sdf_difference(d, sdf_square_toroid(0.2 / s, 0.1 / s, p.xzy / s) * s);
    s = 15.;
    d = sdf_difference(d, sdf_square_toroid(0.2 / s, 0.1 / s, p.xzy / s) * s);
    s = 18.;
    d = sdf_difference(d, sdf_square_toroid(0.2 / s, 0.1 / s, p.xzy / s) * s);
    s = 21.;
    d = sdf_difference(d, sdf_square_toroid(0.2 / s, 0.1 / s, p.xzy / s) * s);
    s = 24.;
    d = sdf_difference(d, sdf_square_toroid(0.2 / s, 0.1 / s, p.xzy / s) * s);
    return d;
}

// Planets.

vec3 sun_position() {
    return vec3(0., 0., 0.);
}

float sun_disc(in vec3 p) {
    float d = point_sdf(p) - 1.;
    d = sdf_union(d, segment_sdf(vec3(0., -5., 0.), vec3(0., 0., 0.), p) - .2);
    return d;
}

float mercury_disc(in vec3 p) {
    p = rotateY(p, -1.7 * iTime);
    p -= vec3(3., 0., 0.);

    float d = point_sdf(p) - 1.;
    d = sdf_union(d, segment_sdf(vec3(0., -5., 0.), vec3(0., 0., 0.), p) - .2);
    return d;
}

float venus_disc(in vec3 p) {
    p = rotateY(p, -1.6 * iTime);
    p -= vec3(6., 0., 0.);

    float d = point_sdf(p) - 1.;
    d = sdf_union(d, segment_sdf(vec3(0., -5., 0.), vec3(0., 0., 0.), p) - .2);
    return d;
}

float moon_distance(in vec3 p) {
    p -= rotateY(vec3(1.5, 0., 0.), 0.);
    float d = point_sdf(p) - 0.25;
    d = sdf_union(d, segment_sdf(vec3(0., -2., 0.), vec3(0., 0., 0.), p) - .05);
    d = sdf_union(d, segment_sdf(vec3(0., -2., 0.), vec3(-1.5, -2., 0.), p) - .05);
    return d;
}

float earth_disc(in vec3 p) {
    p = rotateY(p, -1.5 * iTime);
    p -= vec3(9., 0., 0.);
    p = rotateY(p, -10.f * iTime);

    float d = point_sdf(p) - 1.;
    d = sdf_union(d, segment_sdf(vec3(0., -5., 0.), vec3(0., 0., 0.), p) - .2);
    
    d = sdf_union(d, moon_distance(p));
    
    return d;
}

float mars_disc(in vec3 p) {
    p = rotateY(p, -1.4 * iTime);
    p -= vec3(12., 0., 0.);

    float d = point_sdf(p) - 1.;
    d = sdf_union(d, segment_sdf(vec3(0., -5., 0.), vec3(0., 0., 0.), p) - .2);
    return d;
}

float jupiter_disc(in vec3 p) {
    p = rotateY(p, -1.3 * iTime);
    p -= vec3(15., 0., 0.);

    float d = point_sdf(p) - 1.;
    d = sdf_union(d, segment_sdf(vec3(0., -5., 0.), vec3(0., 0., 0.), p) - .2);
    return d;
}

float saturn_disc(in vec3 p) {
    p = rotateY(p, -1.2 * iTime);
    p -= vec3(18., 0., 0.);
    p = rotateY(p, -1.2 * iTime);

    float d = point_sdf(p) - 1.;
    d = sdf_union(d, segment_sdf(vec3(0., -5., 0.), vec3(0., 0., 0.), p) - .2);

    vec3 q = p / 1.5;
    q = rotateX(q, 1.);
    d = sdf_union(d, sdf_square_toroid(0.2, 0.02, q) / 1.5);
    d = sdf_union(d, segment_sdf(vec3(0.), vec3(0., -1., 0.), q) - 0.05);
    return d;
}

float neptune_disc(in vec3 p) {
    p = rotateY(p, -1.1 * iTime);
    p -= vec3(21., 0., 0.);

    float d = point_sdf(p) - 1.;
    d = sdf_union(d, segment_sdf(vec3(0., -5., 0.), vec3(0., 0., 0.), p) - .2);
    return d;
}

float uranus_disc(in vec3 p) {
    p = rotateY(p, -1. * iTime);
    p -= vec3(24., 0., 0.);

    float d = point_sdf(p) - 1.;
    d = sdf_union(d, segment_sdf(vec3(0., -5., 0.), vec3(0., 0., 0.), p) - .2);
    return d;
}

float orrery_distance(in vec3 p) {
    p = p.xzy;
    float d = 1000.;
    d = sdf_union(d, sun_disc(p));
    d = sdf_union(d, mercury_disc(p));
    d = sdf_union(d, venus_disc(p));
    d = sdf_union(d, earth_disc(p));
    d = sdf_union(d, mars_disc(p));
    d = sdf_union(d, jupiter_disc(p));
    d = sdf_union(d, saturn_disc(p));
    d = sdf_union(d, neptune_disc(p));
    d = sdf_union(d, uranus_disc(p));

    d = sdf_union(d, base(p));
    return d;
}

vec3 orrery_normal(in vec3 p) {
    float e = .0001;
    vec3 n;
    float v = orrery_distance(p);
    n.x = orrery_distance(vec3(p.x + e, p.y, p.z)) - v;
    n.y = orrery_distance(vec3(p.x, p.y + e, p.z)) - v;
    n.z = orrery_distance(vec3(p.x, p.y, p.z + e)) - v;
    return normalize(n);
}

// Trace ray using ray marching
// o : ray origin
// u : ray direction
// h : hit
// s : Number of steps
float SphereTrace(vec3 o,vec3 u,float rB,out bool h,out int s)
{
  h=false;
  
  // Don't start at the origin, instead move a little bit forward
  float t=rA;
  
  // Overstepping [Keinert2014].
  float os_d = 1000.; // Overstepping distance.
  float os_k = 0.2; // Overstepping coef.
  
  for(int i=0;i<Steps;i++)
  {
    s=i;
    
    vec3 p=o+t*u;
    float v=orrery_distance(p);
    
    
    if(v < os_d) {
        // Overstepped, go back and redo this iteration.
        t -= os_d;
        p=o+t*u;
        v=orrery_distance(p);
    }
    

    // Hit object
    if(v<0.)
    {
      s=i;
      h=true;
      break;
    }
    
    
    // Move along ray and overstep.
    t+=max(Epsilon, (1. + os_k) * abs(v));
    // Compute overstepped distance.
    os_d = os_k * abs(v);
   
    // Escape marched far away
    if(t>(1. + os_k) * rB)
    {
      break;
    }
  }
  return t;
}

// Ambient occlusion
// p : Point
// n : Normal
// a : Number of samples
float AmbientOcclusion(vec3 p,vec3 n,int a)
{
  if(a==0){return 1.;}
  
  float ao=0.;
  
  for(int i=0;i<a;i++)
  {
    vec3 d=Cosine(581.123*float(i),n);
    
    int s = 0;
    bool h = false;
    float t=SphereTrace(p,d,10.,h,s);
    if(!h){ao+=1.;}
    else if(t>5.)
    {
      ao+=1.;
    }
  }
  
  ao/=float(a);
  return ao;
}

// Background color
vec3 background(vec3 rd)
{
  return mix(vec3(.652,.451,.995),vec3(.552,.897,.995),rd.z*.5+.5);
}

float Light(vec3 p,vec3 n)
{
  // point light
  const vec3 lp=vec3(5.,10.,25.);
  
  vec3 l=normalize(lp-p);
  
  // Not even Phong shading, use weighted cosine instead for smooth transitions
  float diff=pow(.5*(1.+dot(n,l)),2.);
  
  bool h = false;
  int s = 0;
  float t=SphereTrace(p+.1*n,l,100.,h,s);
  if(!h)
  {
    return diff;
  }
  return 0.;
}

float SmoothLight(vec3 p,vec3 n,int a)
{
  if(a==0)
  return 1.;
  
  // point light
  const vec3 lp=vec3(5.,10.,25.);
  
  vec3 l=normalize(lp-p);
  
  float lo=0.;
  
  for(int i=0;i<a;i++)
  {
    vec3 d=Cosine(581.123*float(i),n);
    d=normalize(l+d*.15);
    int s;
    bool h;
    float t=SphereTrace(p,d,10.,h,s);
    if(!h){lo+=1.;}
    else if(t>100.)
    {
      lo+=1.;
    }
  }
  
  lo/=float(a);
  return lo;
  
}

// Shading and lighting
// p : point,
// n : normal at point
vec3 Shade(vec3 p,vec3 n)
{
  vec3 c=.25+.25*background(n);
  c+=.15*AmbientOcclusion(p+.1*n,n,0)*vec3(1.,1.,1.);
  c+=.35*Light(p,n);
  return c;
}

// Shading with number of steps
vec3 ShadeSteps(int n)
{
  float t=float(n)/(float(Steps-1));
  return .5+mix(vec3(.05,.05,.5),vec3(.65,.39,.65),t);
}

// Picture in picture
// pixel : Pixel
// pip : Boolean, true if pixel was in sub-picture zone
vec2 Pip(in vec2 pixel,out bool pip)
{
  // Pixel coordinates
  vec2 p=(-iResolution.xy+2.*pixel)/iResolution.y;
  if(pip==true)
  {
    const float fraction=1./3.;
    // Recompute pixel coordinates in sub-picture
    if((pixel.x<iResolution.x*fraction)&&(pixel.y<iResolution.y*fraction))
    {
      p=(-iResolution.xy*fraction+2.*pixel)/(iResolution.y*fraction);
      pip=true;
    }
    else
    {
      pip=false;
    }
  }
  return p;
}

// Image
void mainImage(out vec4 color,in vec2 pxy)
{
  // Picture in picture on
  bool pip=false;
  
  // Pixel
  vec2 pixel=Pip(pxy,pip);
  
  // Mouse
  vec2 m=iMouse.xy/iResolution.xy;
  
  // Camera
  vec3 ro = vec3(0.), rd = vec3(0.);
  Ray(m,pixel,ro,rd);
  
  // Trace ray
  
  // Hit and number of steps
  bool hit = false;
  int s = 0;
  
  float t=SphereTrace(ro,rd,100.,hit,s);
  
  // Position
  vec3 pt=ro+t*rd;
  
  // Shade background
  vec3 rgb=background(rd);
  
  if(hit)
  {
    // Compute normal
    vec3 n=orrery_normal(pt);

    float lambertian = max(dot(-rd, n), 0.);
    float brightness = .5 + lambertian * .5;
    
    // Shade object with light
    rgb= n * .5 + .5;
  }
  
  // Uncomment this line to shade image with false colors representing the number of steps
  if(pip==true)
  {
    rgb=ShadeSteps(s);
  }
  
  color=vec4(rgb,1.);
}
