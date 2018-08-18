#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

/////
internal func tangentSpace(_ n:Vector3) -> (Vector3, Vector3) {
    //let s = Double((n.z.bitPattern & 0x8000000000000000) | 0x3ff0000000000000)
    let s = copysign(1.0, n.z)
    let a = -1.0 / (s + n.z)
    let b = n.x * n.y * a
    return (
        Vector3(1.0 + s * n.x * n.x * a, s * b, -s * n.x),
        Vector3(b, s + n.y * n.y * a, -n.y)
    )
}

internal func cosineWeightedHemisphere(_ n:Vector3, _ rng:Random) -> (Vector3, Double) {
    let (u, v) = tangentSpace(n)
    let r = rng.nextDoubleCO().squareRoot()
    let t = 2.0 * Double.pi * rng.nextDoubleCO()
    let x = r * cos(t)
    let y = r * sin(t)
    let d = Vector3(x, y, max(0.0, 1.0 - x * x - y * y).squareRoot())
    
    let wo = u * d.x + v * d.y + n * d.z
    let pdf = abs(Vector3.dot(n, wo)) / Double.pi
    
    return (wo, pdf)
}

internal func fresnel(_ wi:Vector3, _ wo:Vector3, _ n:Vector3, _ ior:Double) -> Double {
    let F0 = ((1.0 - ior) * (1.0 - ior)) / ((1.0 + ior) * (1.0 + ior))
    let idotn = Vector3.dot(wi, n)
    let rdotn = (idotn > 0) ? idotn : Vector3.dot(wo, n)
    return F0 + (1.0 - F0) * pow(1.0 - rdotn, 5.0)
}

internal func reflect(_ wi:Vector3, _ n:Vector3) -> Vector3 {
    return 2.0 * Vector3.dot(wi, n) * n - wi
}

internal func refract(_ wi:Vector3, _ n:Vector3, _ ior:Double) -> (Bool, Vector3) {
    let idotn = Vector3.dot(wi, n)
    let isInto = idotn > 0.0
    // Refract
    let eta:Double
    let absn:Vector3
    if isInto {
        eta = 1.0 / ior
        absn = n
    } else {
        eta = ior
        absn = -n
    }
    let cos2t = 1.0 - eta * eta * (1.0 - idotn * idotn)
    if cos2t < 0.0 {
        return (false, Vector3())
    }
    let wr = (eta * abs(idotn) - cos2t.squareRoot()) * absn - eta * wi
    return (true, wr)
}

public class Material {
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
    
    public func sampleNext(_ pv:PathVertex, _ rng:Random) -> (Ray, Double, Int) {
        let surf = pv.surface
        
        switch matType {
        case .kLambert:
            let n = (Vector3.dot(pv.incident, surf.shadingNormal) > 0.0) ? surf.shadingNormal : -surf.shadingNormal
            let (dir, pdf) = cosineWeightedHemisphere(n, rng)
            return (Ray(surf.location, dir), pdf, BSDFType.kLambert)
            
        case .kPerfectSpecular:
//            let n = surf.shadingNormal
//            let idotn = Vector3.dot(pv.incident, n)
//            let dir = 2.0 * idotn * n - pv.incident
            let dir = reflect(pv.incident, surf.shadingNormal)
            return (Ray(surf.location, dir), 1.0, BSDFType.kPerfectSpecular)
            
        case .kFineGlass:
            // Refrect
            let wi = pv.incident
            let n = surf.shadingNormal
//            let idotn = Vector3.dot(wi, n)
//            let isInto = idotn > 0.0
//            let reflectDir = 2.0 * idotn * n - wi
//            // Refract
//            let eta:Double
//            let absn:Vector3
//            if isInto {
//                eta = 1.0 / ior
//                absn = n
//            } else {
//                eta = ior
//                absn = -n
//            }
//            let cos2t = 1.0 - eta * eta * (1.0 - idotn * idotn)
//            if cos2t < 0.0 {
//                // Critical angle
//                return (Ray(surf.location, reflectDir), 1.0, BSDFType.kPerfectSpecular)
//            }
//            let refractDir = (eta * abs(idotn) - cos2t.squareRoot()) * absn - eta * wi
            let reflectDir = reflect(wi, n)
            let (isRefract, refractDir) = refract(wi, n, ior)
            if !isRefract {
                // Critical angle
                return (Ray(surf.location, reflectDir), 1.0, BSDFType.kPerfectSpecular)
            }
            
            // Fresnel
//            let F0 = ((1.0 - ior) * (1.0 - ior)) / ((1.0 + ior) * (1.0 + ior))
//            let rdotn = isInto ? Vector3.dot(wi, n) : Vector3.dot(refractDir, n)
//            let Fr = F0 + (1.0 - F0) * pow(1.0 - rdotn, 5.0)
            let Fr = fresnel(wi, refractDir, n, ior)
            
            //return (Ray(surf.location, refractDir), 1.0, BSDFType.kPerfectRefraction)
            if rng.nextDoubleCO() < Fr {
                // Reflection case
                return (Ray(surf.location, reflectDir), Fr, BSDFType.kFresnelSpecular)
                //return (Ray(surf.location, reflectDir), 1.0, BSDFType.kFresnelSpecular)
            } else {
                // Refraction case
                return (Ray(surf.location, refractDir), 1.0 - Fr, BSDFType.kFresnelRefraction)
                //return (Ray(surf.location, refractDir), 1.0, BSDFType.kFresnelRefraction)
            }
            
//        default:
//            assertionFailure("Unknown BSDF type:\(matType)")
//            let n = (Vector3.dot(pv.incident, surf.shadingNormal) > 0.0) ? surf.shadingNormal : -surf.shadingNormal
//            let (dir, pdf) = cosineWeightedHemisphere(n, rng)
//            return (Ray(surf.location, dir), pdf, BSDFType.kLambert)
        }
        //return (Ray(), 1.0)
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
            //let wo = ro.direction
            let n = pv.surface.shadingNormal
//            let idotn = Vector3.dot(wi, n)
//            let eta:Double
//            let absn:Vector3
//            if idotn > 0.0 {
//                eta = 1.0 / ior
//                absn = n
//            } else {
//                eta = ior
//                absn = -n
//            }
//            let cos2t = 1.0 - eta * eta * (1.0 - idotn * idotn)
//            let wr = (eta * abs(idotn) - cos2t.squareRoot()) * absn - eta * wi
            let (_, wr) = refract(wi, n, ior)
            let Fr = fresnel(wi, wr, n, ior)
            
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

