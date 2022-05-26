const float pi = 3.14159265359;
const float tau = 2. * pi;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// External

////////////////////////////////////////////////////////////////////////////////
// 4D noise.
// Taken from 'https://www.shadertoy.com/view/wd3czs'.

float snoise(sampler3D channel, vec3 uvw, float time)
{
    vec4 p4 = uvw.x * vec4(-0.5,-0.5, 0.5, 0.5) +
              uvw.y * vec4( 0.5,-0.5,-0.5, 0.5) +
              uvw.z * vec4(-0.5, 0.5,-0.5, 0.5);
    
    p4 += time;
    
    vec4 ip = floor(p4);
    vec4 fp = p4 - ip;

   #if 0
    fp = (fp * fp * fp) * (10.0 + fp * (-15.0 + 6.0 * fp));
   #else
    fp = fp * fp * (3.0 - 2.0 * fp);
   #endif

	const float pi = 3.14159265359;
    const float texDim = 32.0;
    const float txlDim = 1.0 / texDim;
    const vec3 phi = vec3(27.0, 21.0, 17.0);
    const float o0 =        0.5  * txlDim;
    const vec3  o1 = (phi + 0.5) * txlDim;

    vec3 p3 = phi * ip.w + (ip.xyz + fp.xyz);
    
    vec4 n = mix(textureLod(channel, p3 * txlDim + o0, 0.0), 
                 textureLod(channel, p3 * txlDim + o1, 0.0), fp.w) * 2.0 - 1.0;

    return dot(n, sin(p4 * pi)) / pi;
}

////////////////////////////////////////////////////////////////////////////////
// Starfield.
// Taken from 'https://www.shadertoy.com/view/Md2SR3'.

// Return random noise in the range [0.0, 1.0], as a function of x.
float Noise2d( in vec2 x )
{
    float xhash = cos( x.x * 37.0 );
    float yhash = cos( x.y * 57.0 );
    return fract( 415.92653 * ( xhash + yhash ) );
}

// Convert Noise2d() into a "star field" by stomping everthing below fThreshhold to zero.
float NoisyStarField( in vec2 vSamplePos, float fThreshhold )
{
    float StarVal = Noise2d( vSamplePos );
    if ( StarVal >= fThreshhold )
        StarVal = pow( (StarVal - fThreshhold)/(1.0 - fThreshhold), 6.0 );
    else
        StarVal = 0.0;
    return StarVal;
}

// Stabilize NoisyStarField() by only sampling at integer values.
float StableStarField( in vec2 vSamplePos, float fThreshhold )
{
    // Linear interpolation between four samples.
    // Note: This approach has some visual artifacts.
    // There must be a better way to "anti alias" the star field.
    float fractX = fract( vSamplePos.x );
    float fractY = fract( vSamplePos.y );
    vec2 floorSample = floor( vSamplePos );    
    float v1 = NoisyStarField( floorSample, fThreshhold );
    float v2 = NoisyStarField( floorSample + vec2( 0.0, 1.0 ), fThreshhold );
    float v3 = NoisyStarField( floorSample + vec2( 1.0, 0.0 ), fThreshhold );
    float v4 = NoisyStarField( floorSample + vec2( 1.0, 1.0 ), fThreshhold );

    float StarVal =   v1 * ( 1.0 - fractX ) * ( 1.0 - fractY )
        			+ v2 * ( 1.0 - fractX ) * fractY
        			+ v3 * fractX * ( 1.0 - fractY )
        			+ v4 * fractX * fractY;
	return StarVal;
}

////////////////////////////////////////////////////////////////////////////////
// Trigonometric color palette.
// Taken from 'https://iquilezles.org/articles/palettes/'.

vec3 trig_palette(vec3 a, vec3 b, vec3 c, vec3 d, float t) {
    return a + b*cos( (tau*c*t+d) );
}
