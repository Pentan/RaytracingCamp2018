#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

/////
public class BSDFTypeFlag {
    static let kDiffuse     = 1
    static let kSpecular    = 1 << 1
    static let kTransmit    = 1 << 2
}

/////
public class LambertBSDF : BSDF {
    
    public func typeFlags() -> Int {
        return BSDFTypeFlag.kDiffuse
    }
    
    public func sampleAndEvaluate(_ pv:PathVertex, _ rng:Random) -> (ray:Ray, f:Double, pdf:Double, flag:Int) {
        let surf = pv.surface
        let n = (Vector3.dot(pv.incident, surf.shadingNormal) > 0.0) ? surf.shadingNormal : -surf.shadingNormal
        
        let (dir, pdf) = cosineWeightedHemisphere(n, rng)
        let f = 1.0 / Double.pi
        return (Ray(surf.location, dir), f, pdf, 0)
    }
    
    public func evaluate(_ pv:PathVertex, _ ro:Ray) -> (f:Double, pdf:Double, flag:Int) {
        return (1.0 / Double.pi, 1.0, 0)
    }
}

/////
public class PerfectSpecular : BSDF {
    
    public func typeFlags() -> Int {
        return BSDFTypeFlag.kSpecular
    }
    
    public func sampleAndEvaluate(_ pv: PathVertex, _ rng: Random) -> (ray: Ray, f: Double, pdf: Double, flag:Int) {
        let surf = pv.surface
        let n = surf.shadingNormal
        let dir = reflect(pv.incident, n)
        let f = 1.0 / abs(Vector3.dot(n, dir))
        return (Ray(surf.location, dir), f, 1.0, 0)
    }
    
    public func evaluate(_ pv: PathVertex, _ ro: Ray) -> (f: Double, pdf: Double, flag:Int) {
        let wi = pv.incident
        let wo = ro.direction
        let n = pv.surface.shadingNormal
        
        let idotn = Vector3.dot(wi, n)
        let odotn = Vector3.dot(wo, n)
        if abs(idotn - odotn) <= kEPS {
            return (1.0 / abs(odotn), 1.0, 0)
        }
        return (0.0, 1.0, 0)
    }
}

/////
public class PerfectRefraction : BSDF {
    
    public var iorTex:Texture
    public var iorComponent:Int = 0
    
    public init(_ ior:Double=1.5) {
        iorTex = ConstantColor(Vector3(ior, ior, ior))
    }
    
    public init(_ iorTex:Texture, _ comp:Int=0) {
        self.iorTex = iorTex
        iorComponent = comp
    }
    
    public func typeFlags() -> Int {
        return BSDFTypeFlag.kSpecular | BSDFTypeFlag.kTransmit
    }
    
    // If reflected, flag returns 1.
    public func sampleAndEvaluate(_ pv: PathVertex, _ rng: Random) -> (ray: Ray, f: Double, pdf: Double, flag: Int) {
        let surf = pv.surface
        let wi = pv.incident
        let n = surf.shadingNormal
        let ior = iorTex.sample(surf.uv).componentAt(iorComponent)
        
        let dr = reflect(wi, n)
        let (refracted, dt, pwt) = refract(wi, n, ior)
        
        if !refracted {
            // Critical angle. perfect reflection
            let f = 1.0 / abs(Vector3.dot(dr, n))
            return (Ray(surf.location, dr), f, 1.0, 1)
        }
        
        // Refraction case
        let f = pwt / abs(Vector3.dot(dt, n))
        return (Ray(surf.location, dt), f, 1.0, 0)
    }
    
    public func evaluate(_ pv: PathVertex, _ ro: Ray) -> (f: Double, pdf: Double, flag: Int) {
        let surf = pv.surface
        let wi = pv.incident
        let wo = ro.direction
        let n = pv.surface.shadingNormal
        let ior = iorTex.sample(surf.uv).componentAt(iorComponent)
        
        let idotn = Vector3.dot(wi, n)
        let odotn = Vector3.dot(wo, n)
        let eta = (idotn > 0.0) ? (1.0 / ior) : ior
        
        if abs((1.0 - odotn * odotn) / (1.0 - idotn * idotn) - eta * eta) < kEPS {
            return (eta * eta / abs(odotn), 1.0, 0)
        }
        return (0.0, 1.0, 0)
    }
}

/*
/////
public class FineGlass : BSDF {
    
    public var iorTex:Texture = ConstantColor(Vector3(1.5, 1.5, 1.5))
    public var iorCompId:Int = 0
    
    public func sampleAndEvaluate(_ pv: PathVertex, _ rng: Random) -> (ray: Ray, f: Double, pdf: Double) {
        let surf = pv.surface
        let wi = pv.incident
        let n = surf.shadingNormal
        
        let uv = surf.uv
        let ior = iorTex.sample(uv).componentAt(iorCompId)
        
        // Reflect
        let dr = reflect(wi, n)
        let (isRefract, dt, pwt) = refract(wi, n, ior)
        if !isRefract {
            // Critical angle
            let f = 1.0 / abs(Vector3.dot(dr, n))
            return (Ray(surf.location, dr), f, 1.0)
        }
        
        // Fresnel
        let Fr = fresnel(wi, dt, n, ior)
        
        if rng.nextDoubleCO() < Fr {
            // Reflection case
            let f = 1.0 * Fr / abs(Vector3.dot(dr, n))
            return (Ray(surf.location, dr), f, Fr)
        } else {
            // Refraction case
            let f = (1.0 - Fr) * pwt / abs(Vector3.dot(dt, n))
            return (Ray(surf.location, dt), f, 1.0 - Fr)
        }
    }
    
    public func evaluate(_ pv: PathVertex, _ ro: Ray) -> (f: Double, pdf: Double) {
        let surf = pv.surface
        let wi = pv.incident
        let wo = ro.direction
        let n = pv.surface.shadingNormal
        
        let uv = surf.uv
        let ior = iorTex.sample(uv).componentAt(iorCompId)
        
        let idotn = Vector3.dot(wi, n)
        let odotn = Vector3.dot(wo, n)
        
        let eta = (idotn > 0.0) ? (1.0 / ior) : ior
        let Fr = fresnel(wi, wo, n, ior)
        
        if abs(idotn - odotn) < kEPS {
            // Reflected case
            var f = 1.0 / abs(odotn)
            let (refracted, _, _) = refract(wi, n, ior)
            if refracted {
                // Fresnel affected case
                f *= Fr
            }
            return (f, 1.0)
        } else {
            // Transmited case
            if abs((1.0 - odotn * odotn) / (1.0 - idotn * idotn) - eta * eta) < kEPS {
                return (eta * eta * (1.0 - Fr) / abs(odotn), 1.0)
            }
        }
        return (0.0, 1.0)
    }
}
*/
