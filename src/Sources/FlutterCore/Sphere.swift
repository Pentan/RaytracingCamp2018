#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class Sphere : Geometry {
    public var position:Vector3
    public var radius:Double
    
    public init(_ p:Vector3, _ r:Double) {
        position = p
        radius = r
    }
    
    internal func intersectDistance(_ ray:Ray, _ near:Double=0.0, _ far:Double=kFarAway) -> Double {
        let op = position - ray.origin
        let b = Vector3.dot(op, ray.direction)
        let det = b * b - Vector3.dot(op, op) + radius * radius
        if det >= 0.0 {
            let detsqrt = det.squareRoot()
            
            var t:Double
            t = b - detsqrt
            if (near < t) && (t < far) {
                return t
            }
            t = b + detsqrt
            if (near < t) && (t < far) {
                return t
            }
        }
        return -1.0
    }
    
    public func intersection(_ ray:Ray, _ near:Double=0.0, _ far:Double=kFarAway) -> (Vector3, Int) {
        let d = intersectDistance(ray, near, far)
        if d >= 0.0 {
            let p = ray.origin + ray.direction * d
            return (p, 0)
        } else {
            return (Vector3(), Hit.kNoHitIndex)
        }
    }
    
    public func intersectionDetail(_ ray:Ray, _ hit:Hit) -> SurfaceSpec {
        let surf = SurfaceSpec()
        let d = intersectDistance(ray)
        let hitp = ray.origin + ray.direction * d
        let n = Vector3.normalized(hitp - position)
        surf.location = hitp
        surf.geometryNormal = n
        surf.shadingNormal = n
        surf.uv0 = Vector3(
            atan2(n.x, n.z) / Double.pi * 0.5 + 0.5,
            acos(n.z) / Double.pi * 0.5 + 0.5,
            0.0
        )
        surf.materialIndex = 0
        
        return surf
    }
}
