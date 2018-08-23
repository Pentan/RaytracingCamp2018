#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class Sphere : Geometry {
    public var position:Vector3
    public var radius:Double
    //public var aabb:AABB
    
    public init(_ p:Vector3, _ r:Double) {
        position = p
        radius = r
        //aabb = AABB(min: p - Vector3(r, r, r), max: p + Vector3(r, r, r))
    }
    
    public func transfomedAABB(_ transform:Matrix4) -> AABB {
        // FIXME ?
        let minp = position - Vector3(radius, radius, radius)
        let maxp = position + Vector3(radius, radius, radius)
        let verts = [
            Vector3(minp.x, minp.y, minp.z),
            Vector3(minp.x, minp.y, maxp.z),
            Vector3(minp.x, maxp.y, minp.z),
            Vector3(minp.x, maxp.y, maxp.z),
            Vector3(maxp.x, minp.y, minp.z),
            Vector3(maxp.x, minp.y, maxp.z),
            Vector3(maxp.x, maxp.y, minp.z),
            Vector3(maxp.x, maxp.y, maxp.z)
        ]
        let ret = AABB()
        for v in verts {
            ret.expand(Matrix4.transformV3(transform, v))
        }
        return ret
    }
    
    public func renderPreprocess(_ rng:Random) {
        // TODO
        // AABB
    }
    
    internal func intersectDistance(_ ray:Ray, _ near:Double, _ far:Double) -> Double {
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
    
    public func intersection(_ ray:Ray, _ near:Double, _ far:Double) -> (Bool, Double, Int) {
        let d = intersectDistance(ray, near, far)
        if d >= 0.0 {
            //let p = ray.origin + ray.direction * d
            return (true, d, 0)
        } else {
            return (false, -1.0, Hit.kNoHitIndex)
        }
    }
    
    public func intersectionDetail(_ ray:Ray, _ primId:Int, _ near:Double, _ far:Double) -> SurfaceSpec {
        let surf = SurfaceSpec()
        let d = intersectDistance(ray, near, far)
        let hitp = ray.pointAt(d)
        let n = Vector3.normalized(hitp - position)
        surf.location = hitp
        surf.geometryNormal = n
        surf.shadingNormal = n
        surf.uv = Vector3(
            atan2(n.x, n.z) / Double.pi * 0.5 + 0.5,
            acos(n.z) / Double.pi * 0.5 + 0.5,
            0.0
        )
        surf.materialIndex = 0
        
        return surf
    }
}
