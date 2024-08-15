import { ImageEffectRenderer } from 'https://esm.sh/@mediamonks/image-effect-renderer@2.4.0'

const shader = `
// Adapted from https://www.shadertoy.com/view/l3BSRG

// #define shape 10

// Perspective or orthographic camera (0-1)
#define perspective 1
// Surface cloring modes (1-8)
#define colorMode 4
// Surface decoration pattern (0-8)
#define surfacePattern 0
// Background / environment (0-7)
#define background 0
// (0-1)
#define showBoundingCube 0
// (0-3)
#define shading 0

const float boundingBoxRadius = 1.01;
const vec2 initMouse = vec2(0.2, -0.1);

// Numerical solver settings
const int subdivisions = 100;
const int maxIter = 5;
const float EPS = 1e-5;
const float fEPS = 1e-6; // <- CHANGE THIS IF noisy surface / "swollen" singularity

////////////////////////////////////////////////////////////////////////////////

// Error codes / debug colors
// bright yellow
#define BINGO vec3(1.,1.,0.)
// black
#define NOBOUNDHIT vec3(0.,0.,0.)
// greenish blue
#define MAXITERREACHED vec3(0.,0.7,0.7)
// olive
#define MAXDISTREACHED vec3(0.7,0.7,0.)
// pink
#define ESCAPEDBOUNDS vec3(0.7,0.,0.7)
const vec3 NOHIT = vec3(0.2, 0., 0.6);

// Keyboard input
// #define checkKey(key) ( texture(i Channel1, vec2(key, 0.25)).x > 0.5 )
const float KEY_E     = 69.5/256.0;

// Utils
#define PI 3.14159265359
// #define cubemap(dir) ( texture(i Channel0, vec3(dir.x, dir.z, dir.y)).rgb )
float max3(float a, float b, float c) { return max(max(a,b),c); }
float smax(float a, float b) {
    float alpha = 20.0;
    return (a*exp(a*alpha) + b*exp(b*alpha)) / (exp(a*alpha)+exp(b*alpha));
}
float smax3(float a, float b, float c) { return smax(smax(a,b),c); }
float infinityNorm(vec3 v) { v = abs(v); return max3(v.x,v.y,v.z); }

////////////////////////////////////////////////////////////////////////////////

// Implicit equation of the surface
float f(vec3 pos) {
    float scale = 1.;
    vec3 center = vec3(0.);
    int shape = int(iTime) % 52;

    switch (shape) {
        case 20: scale = 7.; break;
        case 21: scale = 3.; break;
        case 22: scale = 1.5; break;
        case 26: scale = 0.8; center = vec3(0.,0.,-0.4); break;
        case 27: scale = 4.; break;
        case 28: scale = 1.5; break;
        case 29: scale = 1.5; center = vec3(0.,0.,1.); break;
        case 30: scale = 2.; break;
        case 31: scale = 2.; break;
        case 33: scale = 7.; break;
        case 35: scale = 2.; break;
        case 37: scale = 1.25; break;
        case 41: scale = 2.; break;
        case 42: scale = 3.; break;
        case 43: scale = 2.; break;
        case 46: scale = 3.2; break;
        case 50: scale = 3.; break;
        case 51: scale = 0.9; center = vec3(0.,0.3,0.); break;
    }
    float x = pos.x*scale + center.x;
    float y = pos.y*scale + center.y;
    float z = pos.z*scale + center.z;
    pos = vec3(x,y,z);
    float x2 = x*x;
    float x3 = x*x2;
    float x4 = x*x3;
    float y2 = y*y;
    float y3 = y*y2;
    float y4 = y*y3;
    float z2 = z*z;
    float z3 = z*z2;
    float z4 = z*z3;
    float R, R2, r, r2, term, v, v2, t, t2, t3;
    
    switch (shape) {
    case 1: return x; // plane
    case 2: return x*x + y*y + z*z - 1.; // sphere
    case 3: return -(x*x + y*y + z*z - 1.); // inside out sphere
    case 4: return infinityNorm(pos)-1.; // cube
    case 5: return x*y - z; // hyperbolic paraboloid
    case 6: return x*x-y*y*y; // cusp sheet
    case 7: return x*x-y*y*(y+1.); // nodal cubic sheet
    case 8: return x*x; // double plane
    case 9: return (x*x-z)*(y*y+z); // parabolic sheets tangent at 1 point
    case 10: return (x*x-z)*(x*x+z); // parabolic sheets tangent at 1 line
    case 11: return x*y*z; // coordinate planes
    case 12: return x*x+y*y-z*z; // cone
    case 13: return x*x+y*y-0.9*z*z-0.04; // one-sheet hyperboloid
    case 14: return x*x+y*y-0.9*z*z+0.04; // two-sheet hyperboloid
    case 15: return x*x-y*y*z; // Whitney umbrella
    case 16: return x*x+y*y*z; // Whitney umbrella upside down
    case 17: // swallowtail
        return -4.*x3*y2-27.*y4-16.*z*x4-128.*z2*x2-144.*z*y2*x-256.*z3;
    case 18: // torus
        R = 0.8; r = 0.45;
        term = (x2+y2+z2+R*R-r*r); return term*term - 4.*R*R*(x2+y2);
    case 19: // gyroid
        return sin(x*4.)*cos(y*4.)+sin(y*4.)*cos(z*4.)+sin(z*4.)*cos(x*4.);
    case 20: // mucube
        return smax3(sin(x)*sin(y),sin(y)*sin(z),sin(z)*sin(x));
    case 21: // tetrahedral surface
        return (x2+y2+z2)*(x2+y2+z2)+8.*x*y*z-10.*(x2+y2+z2)+25.;
    case 22: // Kummer surface
        v = 1.2; v2 = v*v;
        return (3.-v2)*(x2+y2+z2-v2)*(x2+y2+z2-v2)-
            (3.*v2-1.)*(1.-z-x*sqrt(2.))*(1.-z+x*sqrt(2.))*(1.+z+y*sqrt(2.))*
            (1.+z-y*sqrt(2.));
    case 23: return -x3-y2-z2; // A2 (--)
    case 24: return x3+y2-z2; // A2 (+-)
    case 25: return x2+x*z2+y2*z; // Hunt D5
    case 26: return -0.8*(2.*x3-6.*x*y2)+1.*z3+0.8*z2; // Cayley 2
    case 27: return 4.*(x2+y2+z2-13.)*(x2+y2+z2-13.)*(x2+y2+z2-13.)+27.*(3.*x2+y2-4.*z2-12.)*(3.*x2+y2-4.*z2-12.); // Hunt's surface
    case 28: return x2*y2+y2*z2+z2*x2-2.*x*y*z; // Steiner's roman surface
    case 29: // Boy's surface
        return 64.*(1.-z)*(1.-z)*(1.-z)*z3-
            48.*(1.-z)*(1.-z)*z2*(3.*x2+3.*y2+2.*z2)+
            12.*(1.-z)*z*(
                27.*(x2+y2)*(x2+y2)-
                24.*z2*(x2+y2)+
                36.*sqrt(2.)*y*z*(y2-3.*x2)+
                4.*z4)+
            (9.*x2+9.*y2-2.*z2)*(
                -81.*(x2+y2)*(x2+y2)-
                72.*z2*(x2+y2)+
                108.*sqrt(2.)*x*z*(x2-3.*y2)+4.*z4);
    case 30: // Bohemian star
        r = 1.; float r2 = r*r;
        return y4*((x2+y2+z2)*(x2+y2+z2)-4.*r2*(x2+z2))-16.*r2*x2*z2*(y2-r2);
    case 31: // Bohemian dome
        return 2.*x2*y2-2.*x2*z2+x4-4.*y2+2.*y2*z2+y4+z4;
    case 32: // Periodic rounded cubes
        return sin(x*4.)*sin(y*4.)+sin(y*4.)*sin(z*4.)+sin(z*4.)*sin(x*4.);
    case 33: // Periodic incomplete spheres
        return (0.5-mod(x,1.))*(0.5-mod(x,1.))+(0.5-mod(y,1.))*(0.5-mod(y,1.))+(0.5-mod(z,1.))*(0.5-mod(z,1.))-0.4;
    case 34: return z2*(-z+1.)-x2-y2; // revolution of nodal cubic
    case 35: // genus 2 surface
        return 2.*y*(y2-3.*x2)*(1.-z2) + (x2+y2)*(x2+y2) - (9.*z2-1.)*(1.-z2);
    case 36: // Equipotential surface of point charges
        vec3 p1 = vec3(-0.3,-0.3,-0.3);
        vec3 p2 = vec3(-0.3,+0.3,+0.3);
        vec3 p3 = vec3(+0.3,-0.3,+0.3);
        vec3 p4 = vec3(+0.3,+0.3,-0.3);
        v = 7.+3.*asin(0.9*asin(sin(iTime))/PI*2.)/PI*2.;
        return -v+1./distance(pos,p1)+1./distance(pos,p2)+1./distance(pos,p3)+1./distance(pos,p4);
    case 37: // 3 tori
        R = 1.; r = 0.2; R2 = R*R; v = 0.01;
        term = (x2+y2+z2+R*R-r*r); term = term*term;
        return (term-4.*R2*(x2+y2))*(term-4.*R2*(x2+z2))*(term-4.*R2*(y2+z2))-v;
    case 38: // 3d astroid v2
        r = 1.; r2 = r*r;
        return (x2+y2+z2-r2)*(x2+y2+z2-r2)*(x2+y2+z2-r2)+27.*r2*(x2*y2+y2*z2+z2*x2);
    case 39: // 3d astroid v2
        return pow(x2,1./3.)+pow(y2,1./3.)+pow(z2,1./3.)-1.;
    case 40: // blowup (compressed z)
        return x - 7.*y*z/(1.-z2);
    // https://www.imaginary.org/gallery/herwig-hauser-classic
    case 41: return (x2+y2)*(x2+y2)*(x2+y2)-x2*y2*(4.*z2+1.);
    case 42: return -6.*x2+2.*x4+y2*z2;
    case 43: return x2*z2+z4-y2-z3;
    case 44: return -x2+y2*z2+z3;
    case 45: return 1.*(x2+y2)*z4-(1.-x2-y2-z2)*(1.-x2-y2-z2)*(1.-x2-y2-z2);
    case 46: return x2*y*z+x2*z2+2.*y3*z+3.*y3;
    case 47: return 3.*(x2+z2)-(1.-y2)*(1.-y2)*(1.-y2);
    case 48: return z*y-x2;
    case 49: return y3*y2-x*z;
    case 50: return x2 - z4 + y*x2*z2;
    case 51: // deformation E7 into four A1's (Greuel, Lossen, Shustin, Introduction to Singularities and Deformations)
        t = 0.4*(1.+asin(sin(iTime))/PI*2.); t2=t*t; t3=t*t2;
        return x2 - (-z + sqrt(4.*t3/27.))*(z2-y2*(-y+t*1.2));
    }
    return 1.;
}

////////////////////////////////////////////////////////////////////////////////

struct Intersection {
  bool intersects;
  float start;
  float end;
};

// Ray intersection (only forward) with cube of "radius" b centered at origin
// Source: adapted from https://tavianator.com/2011/ray_box.html
Intersection boxIntersection(vec3 pos, vec3 dir, vec3 b) {
    vec3 invDir = 1./dir;
    
    float t1 = (-b.x - pos.x)*invDir.x;
    float t2 = (b.x - pos.x)*invDir.x;
    
    float tmin = min(t1, t2);
    float tmax = max(t1, t2);
    
    t1 = (-b.y - pos.y)*invDir.y;
    t2 = (b.y - pos.y)*invDir.y;
    
    tmin = max(tmin, min(t1, t2));
    tmax = min(tmax, max(t1, t2));
    
    t1 = (-b.z - pos.z)*invDir.z;
    t2 = (b.z - pos.z)*invDir.z;
    
    tmin = max(tmin, min(t1, t2));
    tmax = min(tmax, max(t1, t2));
    
    if (tmin > tmax || tmax < 0.) return Intersection(false, 0., 0.);
    tmin = max(tmin, 0.);
    tmax = max(tmax, 0.);
    return Intersection(true, tmin, tmax);
}

vec3 gradf(vec3 pos) {
    return vec3(f(pos+vec3(EPS,0.,0.)) - f(pos-vec3(EPS,0.,0.)),
                f(pos+vec3(0.,EPS,0.)) - f(pos-vec3(0.,EPS,0.)),
                f(pos+vec3(0.,0.,EPS)) - f(pos-vec3(0.,0.,EPS))
                )  / (2.*EPS);
}

vec3 raycast(vec3 pos, vec3 dir) {
    //float dist = 0.;
    float F;
    float dfdl;
    float dl;
    
    Intersection I = boxIntersection(pos, dir, vec3(boundingBoxRadius));
    if (!I.intersects) return NOBOUNDHIT;
    // move to intersection start point
    //dl = I.start;
    //pos += dir*dl;
    //dist += dl;
    
    vec3 left = pos + I.start * dir;
    vec3 right = pos + I.end * dir;
    
    float invdubdiv = 1./float(subdivisions);
    float substep = (I.end-I.start)/float(subdivisions);
    float q, l;
    for (int i=0; i < subdivisions; i++) {
        q = (float(i)+0.5)*invdubdiv;
        pos = mix(left, right, q);
        F = f(pos);
        if (abs(F) < fEPS) return pos;
        // Newton step
        dfdl = (f(pos+EPS*dir) - f(pos-EPS*dir)) / (2.*EPS);
        dl = -F/dfdl;
        l = dl;
        //if (F < 0.) return BINGO;
        pos += dl*dir;
        // try to find root in this interval
        for (int i=0; i < maxIter; i++) {
            if (infinityNorm(pos)>boundingBoxRadius) break;
            F = f(pos);
            if (abs(F) < fEPS) return pos;
            if (abs(l) > substep) break;
            // Newton step
            dfdl = (f(pos+EPS*dir) - f(pos-EPS*dir)) / (2.*EPS); // directional derivative along ray
            dl = -F/dfdl;
            l += dl;
            pos += dl*dir;

            //if (dl < -0.0 && (abs(F) > 0.01)) dl = 0.01;
            //dl = min(dl, 0.1);
        }
    }
    
    return NOHIT;
}

////////////////////////////////////////////////////////////////////////////////

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = 2.*(fragCoord-iResolution.xy/2.)/iResolution.y; // contains [-1,1]^2
    vec3 col = vec3(0.);
    
    // Camera rays
    vec3 camPos = vec3(4.,0.,0.);
    vec3 camDir = - normalize(camPos);
    vec3 rayPos, rayDir;
    float zoom = 1.5; // 1.8*cos(iTime);
    // if (checkKey(KEY_E)) zoom = 0.5;
    float fov = 0.4*zoom;
    float fov_ortho = 1.5*zoom;
    #if perspective
        // perspective cam
        rayPos = camPos;
        rayDir = normalize(camDir + fov*vec3(0., uv.x, uv.y));
    #else
        // orthographic cam
        rayPos = camPos + fov_ortho*vec3(0., uv.x, uv.y);
        rayDir = camDir;
    #endif
    // for perspective background in orthographic mode
    vec3 cubemapDir = normalize(camDir + fov*vec3(0., uv.x, uv.y));
    
    // Mouse-controlled rotation
    vec2 mouse = initMouse + vec2(0.015625*sin(iTime*PI), 0.0); // initMouse; // iMouse.xy == vec2(0.,0.) ? initMouse : (iMouse.xy/iResolution.xy - 0.5);
    float yaw = clamp(- mouse.x * 2.*PI * 1., -PI,PI);
    float pitch = clamp( mouse.y * PI * 1.2, -PI*0.5, PI*0.5);
    // pitch and yaw rotations (column-wise matrices)
    mat3 rot = mat3(cos(yaw), sin(yaw), 0., -sin(yaw), cos(yaw), 0., 0., 0., 1.);
    rot = rot * mat3(cos(pitch), 0., -sin(pitch), 0., 1., 0., sin(pitch), 0., cos(pitch));
    // apply
    camPos = rot*camPos;
    camDir = rot*camDir;
    rayPos = rot*rayPos;
    rayDir = rot*rayDir;
    cubemapDir = rot*cubemapDir;
    
    //cubemapDir = vec3(cubemapDir.x, cubemapDir.z, cubemapDir.y);
    
    vec3 hitPoint = raycast(rayPos, rayDir);
    
    if (hitPoint == BINGO) { fragColor = vec4(BINGO,1.0); return; }
    //if (hitPoint == NOHIT) { fragColor = vec4(NOHIT,1.0); return; }
    //if (hitPoint == NOBOUNDHIT) { fragColor = vec4(NOBOUNDHIT,1.0); return; }
    //if (hitPoint == ESCAPEDBOUNDS) { fragColor = vec4(ESCAPEDBOUNDS,1.0); return; }
    //if (hitPoint == MAXDISTREACHED) { fragColor = vec4(MAXDISTREACHED,1.0); return; }
    //if (hitPoint == MAXITERREACHED) { fragColor = vec4(MAXITERREACHED,1.0); return; }
    
    if (hitPoint == NOBOUNDHIT  || hitPoint == NOHIT || hitPoint == ESCAPEDBOUNDS || hitPoint == MAXITERREACHED) {
        //fragColor = vec4(vec3(0.2),1.0); return;
        
        #if background==1
        col = vec3(0.2);
        
        #elif background==2
        col = vec3(0.5);
        
        #elif background==3
        col = vec3(0.8);
        
        #elif background==4
        col = vec3(1.);
        
        #elif background==5
        // Real life environment
        col = 1.; // * cubemap(cubemapDir);
        
        #elif background==6
        // Stylized sky
        if (cubemapDir.z > 0.) {
            col = mix(vec3(0.7,1.,1.), vec3(0.5,0.7,0.9), sqrt(cubemapDir.z));
        } else {
            col = mix(vec3(0.5,0.6,0.7),vec3(0.3,0.3,0.3),asin(-cubemapDir.z));
        }
        
        #elif background==7
        // Sphere slices
        
        //col = mix(vec3(0.2), vec3(0.7,1.,1.), clamp(0.5+4.*dot(normalize(cubemapDir),normalize(vec3(0.,0.,1.))), 0., 1.));
        col = vec3(0.4);
        
        float linewidthSky = 0.003;
        float gridStepSky = 0.2;
        float gridAlpha = 0.3;
        col = mix(col,vec3(1.,0.,0.),gridAlpha*(1.-step(linewidthSky,mod(asin(cubemapDir.x)+linewidthSky/2.,gridStepSky))));
        col = mix(col,vec3(0.,1.,0.),gridAlpha*(1.-step(linewidthSky,mod(asin(cubemapDir.y)+linewidthSky/2.,gridStepSky))));
        col = mix(col,vec3(0.,0.,1.),gridAlpha*(1.-step(linewidthSky,mod(asin(cubemapDir.z)+linewidthSky/2.,gridStepSky))));
        
        #else
        col = vec3(0.);
        
        #endif
        
        #if showBoundingCube
        // darken bounding cube
        if (hitPoint != NOBOUNDHIT) { col *= vec3(0.7); }
        #endif

        fragColor = vec4(col,1.0); return;
    }
    
    
    vec3 grad = gradf(hitPoint+1.1*EPS*(-rayDir));
    float s = -sign(dot(grad,rayDir));
    
    // -- Color
    
    #if colorMode==1
    // one color per side
    col = mix(vec3(0.,0.7,1.),vec3(1.,0.5,0.),0.5+0.5*s);
    
    #elif colorMode==2
    // by distance to camera
    float hue = 3.*length(hitPoint - camPos);
    col = 0.5+0.5*vec3(cos(hue),cos(hue+2.*PI/3.),cos(hue+4.*PI/3.));
    col /= length(col)*0.7;
    
    #elif colorMode==3
    // by normal direction
    col = 0.65+0.35*grad/infinityNorm(grad);
    
    #elif colorMode==4
    // by normal direction per side
    col = 0.65+0.35*s*grad/infinityNorm(grad);
    
    #elif colorMode==5
    // by location in space
    col = 0.1 + 0.8*(boundingBoxRadius+hitPoint)/2.;
    
    #elif colorMode==6
    // by z coordinate
    float hue = 2.*PI*(0.5+0.5*(hitPoint.z/boundingBoxRadius));
    col = 0.5+0.5*vec3(cos(hue),cos(hue+2.*PI/3.),cos(hue+4.*PI/3.));
    //col = mix(vec3(0.,0.6,0.7),vec3(1.,0.5,0.),clamp(0.5+0.5*hitPoint.z,0.,1.));
    //col /= infinityNorm(col)*1.1;
    col /= length(col)*0.7;
    
    #elif colorMode==7
    // gray
    col = vec3(0.8);//vec3(0.5+0.1*dot(s*grad,vec3(0.,0.,1.)));
    
    #elif colorMode==8
    // white
    col = vec3(1.);
    
    #endif
    col = clamp(col, 0., 1.);
    
    // -- Surface pattern
    float gridStep = 0.081;
    float linewidth = 0.1*gridStep;
    
    #if surfacePattern==1
    // Colored coordinate planes
    col = mix(col,vec3(1.,0.,0.),0.2*(1.-step(linewidth,mod(hitPoint.x+linewidth/2.,gridStep))));
    col = mix(col,vec3(0.,1.,0.),0.2*(1.-step(linewidth,mod(hitPoint.y+linewidth/2.,gridStep))));
    col = mix(col,vec3(0.,0.,1.),0.2*(1.-step(linewidth,mod(hitPoint.z+linewidth/2.,gridStep))));
    
    #elif surfacePattern==2
    // additive transparent black coordinate planes
    col = mix(col,vec3(0.),0.2*(1.-step(linewidth,mod(hitPoint.x+linewidth/2.,gridStep))));
    col = mix(col,vec3(0.),0.2*(1.-step(linewidth,mod(hitPoint.y+linewidth/2.,gridStep))));
    col = mix(col,vec3(0.),0.2*(1.-step(linewidth,mod(hitPoint.z+linewidth/2.,gridStep))));
    
    #elif surfacePattern==3
    // combined transparent black displaced coordinate planes
    col = mix(col,vec3(0.),0.2*(1.-min(min(
                step(linewidth,mod(hitPoint.x+linewidth/2.+gridStep/2.,gridStep)),
                step(linewidth,mod(hitPoint.y+linewidth/2.+gridStep/2.,gridStep))),
                step(linewidth,mod(hitPoint.z+linewidth/2.+gridStep/2.,gridStep)))));
    
    #elif surfacePattern==4
    // gyroid
    gridStep *= 0.3;
    col = mix(col,vec3(0.),0.2*(1.-step(0.2,abs(
        sin(hitPoint.x/gridStep)*cos(hitPoint.y/gridStep)+
        sin(hitPoint.y/gridStep)*cos(hitPoint.z/gridStep)+
        sin(hitPoint.z/gridStep)*cos(hitPoint.x/gridStep)))));
    
    #elif surfacePattern==5
    // mucube (not as expected)
    col = mix(col,vec3(0.),0.2*(1.-step(0.1,abs(smax3(
        sin(hitPoint.x/gridStep)*sin(hitPoint.y/gridStep),
        sin(hitPoint.y/gridStep)*sin(hitPoint.z/gridStep),
        sin(hitPoint.z/gridStep)*sin(hitPoint.x/gridStep))))));
    
    #elif surfacePattern==6
    // spheres
    col = mix(col,vec3(0.),0.2*(1.-step(0.2,(0.5-mod(hitPoint.x/gridStep,1.))*(0.5-mod(hitPoint.x/gridStep,1.))+
        (0.5-mod(hitPoint.y/gridStep,1.))*(0.5-mod(hitPoint.y/gridStep,1.))+
        (0.5-mod(hitPoint.z/gridStep,1.))*(0.5-mod(hitPoint.z/gridStep,1.)))));
    
    #elif surfacePattern==7
    // 3D checkerboard
    col = mix(col,vec3(0.),0.1*mod(floor(hitPoint.x/gridStep)+floor(hitPoint.y/gridStep)+floor(hitPoint.z/gridStep),2.));
    
    #elif surfacePattern==8
    // 3D checkerboard shifted
    col = mix(col,vec3(0.),0.1*mod(floor(0.51+hitPoint.x/gridStep)+floor(0.51+hitPoint.y/gridStep)+floor(0.51+hitPoint.z/gridStep),2.));
    
    #endif
    
    // -- Shading
    
    float kAmbient = 0.6;
    float kDiffuse = 0.6;
    float kSpecular = 0.;
    float kEnvironment = 0.1;
    float shininess = 26.;
    vec3 iAmbient = vec3(1.);
    vec3 iDiffuse = vec3(1.);
    vec3 iSpecular = vec3(1.);
    vec3 L = normalize(vec3(0.,0.,1.)); // surface to light
    vec3 N = normalize(s*grad); // normal
    vec3 R = 2.*dot(L,N)*N - L; // reflected
    vec3 V = -rayDir; // viewer
    vec3 refl = 2.*dot(V,N)*N - V; // environment reflection
    
    #if shading==1||shading==2
    // Phong shading
    vec3 I = kAmbient*iAmbient*col +
          kDiffuse*col*iDiffuse*max(0.,dot(L,N)) +
          kSpecular*iSpecular*pow(max(0.,dot(R,V)),shininess);
    
        #if shading==2
        // Environment reflections
        //I += cubemap(refl);
        //I += col*cubemap(refl);
        I += kEnvironment; //*exp(5.*(cubemap(refl)-1.)); // exponential to simulate HDR environment
        #endif
    col = I;
    
    #elif shading==3
    // Light from camera only
    vec3 J = col*mix(0.2,1.,clamp(dot(-rayDir,N),0.,1.));
    col = J;
    
    #endif
    
    
    col = clamp(col, 0., 1.);
    fragColor = vec4(col,1.0);
}
`;

const options = { loop: true };

const glslWrapperElement = document.querySelector('#glsl-wrapper');

if(glslWrapperElement) {
    const renderer = ImageEffectRenderer.createTemporary(glslWrapperElement, shader, options);
}
