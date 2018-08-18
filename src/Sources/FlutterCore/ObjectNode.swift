#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class ObjectNode {
    public var geometrys:[Sphere] = []
    public var materials:[Material] = []
    
    public init(_ geom:Sphere, _ mat:Material) {
        geometrys.append(geom)
        materials.append(mat)
    }
    
    public func intersection(_ ray:Ray, _ near:Double, _ far:Double) -> Hit {
        var min_hit = Hit(false, far)
        var min_hitp = Vector3()
        
        // TODO transform ray global to local
        
        for i in 0..<geometrys.count {
            let (hitp, primId) = geometrys[i].intersection(ray, near, min_hit.distance)
            if primId != Hit.kNoHitIndex {
                min_hitp = hitp
                min_hit.isHit = true
                min_hit.primitiveIndex = primId
                min_hit.geometryIndex = i
            }
        }
        
        if min_hit.isHit {
            // TODO transform hit point local to global
            min_hit.distance = (ray.origin - min_hitp).length()
            
            return min_hit
        }
        
        return Hit(false)
    }
    
    public func intersectionDetail(_ ray:Ray, _ hit:Hit) -> SurfaceSpec {
        let geom = geometrys[hit.geometryIndex]
        
        // TODO transform ray global to local
        
        let surf = geom.intersectionDetail(ray, hit)
        
        // TODO needs transform location and normals to local to global
        
        return surf
    }
}
