#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class SimpleMaterial : Material {
    public enum MaterialType {
        case kLambert
        case kPerfectSpecular
        case kFineGlass
    }
    
    static internal let kColorTexture       = 0
    static internal let kEmissionTexture    = 1
    static internal let kIorTexture         = 2
    
    //
    public var textures:[Texture] = []
    internal var bsdfs:[BSDF] = []
    
    internal let materialType:MaterialType
    
    //
    public init(_ color:Vector3, _ emit:Vector3, _ mtype:MaterialType) {
        textures.append(ConstantColor(color))
        textures.append(ConstantColor(emit))
        materialType = mtype
        
        switch materialType {
        case .kLambert:
            bsdfs.append(LambertBSDF())
        case .kPerfectSpecular:
            bsdfs.append(PerfectSpecular())
        case .kFineGlass:
            // Specular
            bsdfs.append(PerfectSpecular())
            // Transmit
            let iortex = ConstantColor(Vector3(1.5, 1.5, 1.5))
            textures.append(iortex)
            bsdfs.append(PerfectRefraction(iortex, 0))
            // Full reflected case Specular
            bsdfs.append(PerfectSpecular())
        }
    }
    
    public func setEmissionTexture(_ tex:Texture) {
        textures[SimpleMaterial.kEmissionTexture] = tex
    }
    
    public func setColorTexture(_ tex:Texture) {
        textures[SimpleMaterial.kColorTexture] = tex
    }
    
    //
    public func emittion(_ pv:PathVertex) -> Vector3 {
        let tex = textures[SimpleMaterial.kEmissionTexture]
        let uv = pv.surface.uv
        return tex.sample(uv)
    }
    
    public func isSpecularBSDF(_ i: Int) -> Bool {
        return (bsdfs[i].typeFlags() & BSDFTypeFlag.kSpecular) != 0
    }
    
    public func sampleNext(_ pv: PathVertex, _ rng: Random) -> (Ray, Vector3, Double, Int) {
        let uv = pv.surface.uv
        let coltex = textures[SimpleMaterial.kColorTexture]
        let color = coltex.sample(uv)
        
        switch materialType {
        case .kFineGlass:
            let rbsdf = bsdfs[0]
            let tbsdf = bsdfs[1]
            
            let wi = pv.incident
            let n = pv.surface.shadingNormal
            
            let (tray, tf, tpdf, flag) = tbsdf.sampleAndEvaluate(pv, rng)
            if flag == 1 {
                // Critical angle reflection case
                return (tray, tf * color, tpdf, 2)
            }
            
            let iortex = textures[SimpleMaterial.kIorTexture]
            let ior = iortex.sample(uv).x
            let Fr = fresnel(wi, tray.direction, n, ior)
            
            if rng.nextDoubleCO() < Fr {
                // Reflection
                let (rray, rf, rpdf, _) = rbsdf.sampleAndEvaluate(pv, rng)
                return (rray, rf * Fr * color, rpdf * Fr, 0)
            } else {
                // Transmit
                return (tray, tf * (1.0 - Fr) * color, tpdf * (1.0 - Fr), 1)
            }
            
        default:
            let (ray, f, pdf, _) = bsdfs[0].sampleAndEvaluate(pv, rng)
            return (ray, f * color, pdf, 0)
        }
    }
    
    public func bsdf(_ bsdfId: Int, _ pv: PathVertex, _ ro: Ray) -> (Double, Double) {
        switch materialType {
        case .kFineGlass:
            if bsdfId == 2 {
                // Full reflection case
                let (f, pdf, _) = bsdfs[0].evaluate(pv, ro)
                return (f, pdf)
            } else {
                // Fresnel
                let uv = pv.surface.uv
                let iortex = textures[SimpleMaterial.kIorTexture]
                let ior = iortex.sample(uv).x
                
                let wi = pv.incident
                let n = pv.surface.shadingNormal
                var F = fresnel(wi, ro.direction, n, ior)
                if bsdfId == 1 {
                    // Transmit
                    F = 1.0 - F
                }
                let (f, pdf, _) = bsdfs[bsdfId].evaluate(pv, ro)
                return (f * F, pdf * F)
            }
        default:
            let (f, pdf, _) = bsdfs[bsdfId].evaluate(pv, ro)
            return (f, pdf)
        }
    }
    
    
    
    
}

