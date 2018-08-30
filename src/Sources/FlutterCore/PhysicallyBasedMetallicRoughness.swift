#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class PhysicallyBasedMetallicRoughness : Material {
    
    public static let kDiffuseBSDF  = 0
    public static let kSpecularBSDF  = 1
    
    public var baseColorRGB:Vector3 = Vector3(1.0, 1.0, 1.0)
    public var baseColorAlpha:Double = 1.0
    public var baseColorTex:Texture = ConstantColor(Vector3(1.0, 1.0, 1.0))
    public var baseColorUV:Int = 0
    
    public var metallicFactor:Double = 1.0
    public var roughnessFactor:Double = 1.0
    public var metallicRoughnessTex:Texture = ConstantColor(Vector3(1.0, 1.0, 1.0))
    public var metallicRoughnessUV:Int = 0
    
    public var emissiveFactor:Vector3 = Vector3(0.0, 0.0, 0.0)
    public var emissiveTex:Texture = ConstantColor(Vector3(1.0, 1.0, 1.0))
    public var emissiveUV:Int = 0
    
    public var normalTex:Texture = ConstantColor(Vector3(0.5, 0.5, 1.0))
    public var normalUV:Int = 0
    public var normalScale:Double = 1.0
    
    public var occlusionTex:Texture = ConstantColor(Vector3(1.0, 1.0, 1.0))
    public var occlusionUV:Int = 0
    public var occlusionStrength:Double = 1.0
    
    // FIXME Not working
    public var alphaMode:Int = 0
    public var alphaCutoff:Double = 0.5
    public var doubleSided:Bool = false
    
    //
    internal var bsdfs:[BSDF] = []
    
    public init() {
        // FIXME
        bsdfs.append(LambertBSDF())
    }
    
    public func emittion(_ pv:PathVertex) -> Vector3 {
        let emit = emissiveTex.sample(pv.surface.uv)
        return Vector3.mul(emit, emissiveFactor)
    }
    
    public func isSpecularBSDF(_ i:Int) -> Bool {
        return (i == PhysicallyBasedMetallicRoughness.kSpecularBSDF) ? true : false
    }
    
    public func sampleNext(_ pv:PathVertex, _ rng:Random) -> (Ray, Vector3, Double, Int) {
        let surf = pv.surface
        let wi = pv.incident
        let ns = (Vector3.dot(wi, surf.shadingNormal) > 0.0) ? surf.shadingNormal : -surf.shadingNormal
        let ng = (Vector3.dot(wi, surf.geometryNormal) > 0.0) ? surf.geometryNormal : -surf.geometryNormal
        let uvs = [surf.uv, surf.uv] // FIXME
        
        let (wo, pdf) = cosineWeightedHemisphere(ns, rng)
        let oray = Ray(surf.location, wo)
        
        if !IsCorrectReflection(wi, wo, ng) {
            // Incorrect Reflection
            return (oray, Vector3(0.0, 0.0, 0.0), 1.0, PhysicallyBasedMetallicRoughness.kDiffuseBSDF)
        }
        
        let color = Vector3.mul(baseColorTex.sample(uvs[baseColorUV]), baseColorRGB)
        let alpha = baseColorTex.sample(uvs[baseColorUV], 3) * baseColorAlpha
        let mrtex = metallicRoughnessTex.sample(uvs[metallicRoughnessUV])
        let metalness = mrtex.z * metallicFactor
        let roughness = mrtex.y * roughnessFactor
        
        let occlusion = occlusionTex.sample(uvs[occlusionUV], 0) * occlusionStrength
        
        // Reference: glTF Specification Appendix B
        // https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#appendix-b-brdf-implementation
        let dielectricSpecular = Vector3(0.04, 0.04, 0.04)
        
        let Cdiff = Vector3.lerp(color * (1.0 - dielectricSpecular.x), Vector3(0.0, 0.0, 0.0), metalness)
        let F0 = Vector3.lerp(dielectricSpecular, color, metalness)
        let r2 = roughness * roughness
        
        let wh = (wi + wo) * 0.5
        let F = F0 + (Vector3(1.0, 1.0, 1.0) - F0) * pow(1.0 - Vector3.dot(wi, wh), 5.0)
        let Fmax = F.maxMagnitude()
        
        if rng.nextDoubleCO() < Fmax {
            // Specular
            let k = roughness * 0.7978845608028654 // (2.0 / Double.pi).squareRoot()
            
            func G(_ v:Vector3) -> Double {
                let vdoth = Vector3.dot(v, wh)
                return vdoth / (vdoth * (1.0 - k) + k)
            }
            func D() -> Double {
                let ndoth = Vector3.dot(ns, wh)
                let x = ndoth * ndoth * (r2 * r2 - 1.0) + 1
                return (r2 * r2) / (Double.pi * x * x)
            }
            
            let idotn = Vector3.dot(wi, ns)
            let odotn = Vector3.dot(wo, ns)
            
            let f = F * G(wo) * G(ns) * D() / (4.0 * odotn * idotn)
            let foF = Vector3.mul(f, F) * occlusion
            return (oray, foF, pdf * Fmax, PhysicallyBasedMetallicRoughness.kSpecularBSDF)
            
        } else {
            // Diffuse
            let f = 1.0 / Double.pi
            let fCF = Vector3.mul(f * Cdiff, (Vector3(1.0, 1.0, 1.0) - F))
            let fCFo = fCF * occlusion
            return (oray, fCFo, pdf * (1.0 - Fmax), PhysicallyBasedMetallicRoughness.kDiffuseBSDF)
        }
    }
    
    public func bsdf(_ bsdfId:Int, _ pv:PathVertex, _ ro:Ray) -> (Double, Double) {
        // FIXME
        let (f, pdf, _) = bsdfs[bsdfId].evaluate(pv, ro)
        return (f, pdf)
    }
}

