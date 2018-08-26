#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class LegacyMaterial : Material {
    public enum MaterialType {
        case kLambert
        case kPerfectSpecular
        case kFineGlass
    }
    
    public struct BSDFType {
        static public var kLambert              = 1
        static public var kPerfectSpecular      = 2
        static public var kFresnelSpecular      = 3
        static public var kFresnelRefraction    = 4
        
        private init() {
        }
    }
    
    public var Kd:Vector3
    public var Ke:Vector3
    public var matType:MaterialType
    
    public var ior:Double = 1.5
    
    public init(_ color:Vector3, _ emit:Vector3, _ mtype:MaterialType) {
        Kd = color
        Ke = emit
        matType = mtype
    }
    
    public func emittion(_ pv:PathVertex) -> Vector3 {
        return Ke
    }
    
    public func isSpecularBSDF(_ i:Int) -> Bool {
        return (i == BSDFType.kPerfectSpecular) || (i == BSDFType.kFresnelSpecular)
    }
    
    public func sampleNext(_ pv:PathVertex, _ rng:Random) -> (Ray, Vector3, Double, Int) {
        let surf = pv.surface
        
        switch matType {
        case .kLambert:
            let n = (Vector3.dot(pv.incident, surf.shadingNormal) > 0.0) ? surf.shadingNormal : -surf.shadingNormal
            let (dir, pdf) = cosineWeightedHemisphere(n, rng)
            let f = Kd / Double.pi
            return (Ray(surf.location, dir), f, pdf, BSDFType.kLambert)
            
        case .kPerfectSpecular:
            let dir = reflect(pv.incident, surf.shadingNormal)
            let f = Kd / abs(Vector3.dot(surf.shadingNormal, dir))
            return (Ray(surf.location, dir), f, 1.0, BSDFType.kPerfectSpecular)
            
        case .kFineGlass:
            // Refrect
            let wi = pv.incident
            let n = surf.shadingNormal
            let dr = reflect(wi, n)
            let (refracted, dt, pwt) = refract(wi, n, ior)
            if !refracted {
                // Critical angle
                let f = Kd / abs(Vector3.dot(dr, n))
                return (Ray(surf.location, dr), f, 1.0, BSDFType.kPerfectSpecular)
            }
            
            // Fresnel
            let Fr = fresnel(wi, dt, n, ior)
            
            //return (Ray(surf.location, refractDir), 1.0, BSDFType.kPerfectRefraction)
            if rng.nextDoubleCO() < Fr {
                // Reflection case
                let f = Kd * Fr / abs(Vector3.dot(dr, n))
                return (Ray(surf.location, dr), f, Fr, BSDFType.kFresnelSpecular)
            } else {
                // Refraction case
                let f = Kd * (1.0 - Fr) * pwt / abs(Vector3.dot(dt, n))
                return (Ray(surf.location, dt), f, 1.0 - Fr, BSDFType.kFresnelRefraction)
            }
            
        }
    }
    
    public func bsdf(_ bsdfId:Int, _ pv:PathVertex, _ ro:Ray) -> (Double, Double) {
        
        switch bsdfId {
        case BSDFType.kLambert:
            return (1.0 / Double.pi, 1.0)
            
        case BSDFType.kPerfectSpecular:
            let wi = pv.incident
            let wo = ro.direction
            let n = pv.surface.shadingNormal
            
            let idotn = Vector3.dot(wi, n)
            let odotn = Vector3.dot(wo, n)
            if abs(idotn - odotn) <= kEPS {
                return (1.0 / abs(odotn), 1.0)
            }
            return (0.0, 1.0)
            
        case BSDFType.kFresnelSpecular:
            let wi = pv.incident
            let wo = ro.direction
            let n = pv.surface.shadingNormal
            //let (_, wr, _) = refract(wi, n, ior)
            let Fr = fresnel(wi, wo, n, ior)
            
            let (f, pdf) = self.bsdf(BSDFType.kPerfectSpecular, pv, ro)
            return (f * Fr, pdf)
            
        case BSDFType.kFresnelRefraction:
            let wi = pv.incident
            let wo = ro.direction
            let n = pv.surface.shadingNormal
            
            let idotn = Vector3.dot(wi, n)
            let odotn = Vector3.dot(wo, n)
            let eta = (idotn > 0.0) ? (1.0 / ior) : ior
            let Fr = fresnel(wi, wo, n, ior)
            
            if abs((1.0 - odotn * odotn) / (1.0 - idotn * idotn) - eta * eta) < kEPS {
                return (eta * eta * (1.0 - Fr) / abs(odotn), 1.0)
            }
            return (0.0, 1.0)
            
        default:
            assertionFailure("Unknown BSDF:\(bsdfId)")
        }
        
        return (0.0, 1.0)
    }
}

