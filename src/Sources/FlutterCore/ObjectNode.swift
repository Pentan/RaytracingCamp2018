#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class ObjectNode {
    public var geometry:Geometry
    public var materials:[Material] = []
    public var isLight:Bool
    
    public var aabb = AABB()
    
    public var transform = Matrix4()
    public var invTransform = Matrix4()
    public var invTransTransform = Matrix4()
    
    public init(_ geom:Geometry, _ isL:Bool=false) {
        geometry = geom
        isLight = isL
    }
    
    public init(_ geom:Geometry, _ mat:Material, _ isL:Bool=false) {
        geometry = geom
        materials.append(mat)
        isLight = isL
    }
    
    @discardableResult
    public func addMaterial(_ mat:Material) -> Int {
        materials.append(mat)
        return materials.count - 1
    }
    
    internal func makeLocalRay(_ ray:Ray) -> (Ray, Double) {
        let lorg = Matrix4.transformV3(invTransform, ray.origin)
        let ldir = Matrix4.mulV3(invTransform, ray.direction)
        let ldlen = ldir.length()
        return (Ray(lorg, ldir / ldlen), ldlen)
    }
    
    public func renderPreprocess(_ rng:Random) {
        geometry.renderPreprocess(rng)
        // Update AABB
        aabb = geometry.transfomedAABB(transform)
        
        (invTransform, _) = Matrix4.inverted(transform)
        invTransTransform = Matrix4.transposed(invTransform)
    }
    
    public func intersection(_ ray:Ray, _ near:Double, _ far:Double) -> (Bool, Double, Int) {
        // Transform ray global to local
        let (lray, lscale) = makeLocalRay(ray)
        
        //
        let (ishit, hitd, primId) = geometry.intersection(lray, near * lscale, far * lscale)
        if ishit {
            // Transform hit distance local to global
            return (true, hitd / lscale, primId)
        }
        
        return (false, -1.0, -1)
    }
    
    public func intersectionDetail(_ ray:Ray, _ hit:Hit, _ near:Double, _ far:Double) -> SurfaceSpec {
        // Transform ray global to local
        let (lray, _) = makeLocalRay(ray)
        
        let surf = geometry.intersectionDetail(lray, hit.primitiveIndex, near, far)
        
        // Transform location and normals local to global
        surf.applyTransform(transform, invTransTransform)
        
        return surf
    }
}
