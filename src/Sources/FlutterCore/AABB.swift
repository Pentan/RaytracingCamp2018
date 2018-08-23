#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class AABB {
    public var min:Vector3
    public var max:Vector3
//    public var dataId:Int
    
    public var centroid:Vector3 {
        return (min + max) * 0.5
    }
    
    public init() {
        let gfm = Double.greatestFiniteMagnitude
        min = Vector3(gfm, gfm, gfm)
        max = Vector3(-gfm, -gfm, gfm)
//        centroid = Vector3(0.0, 0.0, 0.0)
//        dataId = 0
    }
    
    public init(min:Vector3, max:Vector3) {
        self.min = min
        self.max = max
        if self.min.x > self.max.x {
            swap(&self.min.x, &self.max.x)
        }
        if self.min.y > self.max.y {
            swap(&self.min.y, &self.max.y)
        }
        if self.min.z > self.max.z {
            swap(&self.min.z, &self.max.z)
        }
//        centroid = (self.min + self.max) * 0.5
//        dataId = 0
    }
    
    public func clear() {
        let gfm = Double.greatestFiniteMagnitude
        min = Vector3(gfm, gfm, gfm)
        max = Vector3(-gfm, -gfm, -gfm)
//        centroid = Vector3(0.0, 0.0, 0.0)
//        dataId = 0
    }
    
    public func copy(_ a:AABB) {
        min = a.min
        max = a.max
    }
    
    public func size() -> Vector3 {
        return max - min
    }
    
    public func surfaceArea() -> Double {
        let d = max - min
        return 2.0 * (d.x * d.y + d.y * d.z + d.z * d.x)
    }
    
    public func expand(_ p:Vector3) {
        if p.x < min.x { min.x = p.x }
        if p.y < min.y { min.y = p.y }
        if p.z < min.z { min.z = p.z }
        
        if p.x > max.x { max.x = p.x }
        if p.y > max.y { max.y = p.y }
        if p.z > max.z { max.z = p.z }
        
//        centroid = (min + max) * 0.5
    }
    
    public func expand(_ aabb:AABB) {
        if aabb.min.x < min.x { min.x = aabb.min.x }
        if aabb.min.y < min.y { min.y = aabb.min.y }
        if aabb.min.z < min.z { min.z = aabb.min.z }
        
        if aabb.max.x > max.x { max.x = aabb.max.x }
        if aabb.max.y > max.y { max.y = aabb.max.y }
        if aabb.max.z > max.z { max.z = aabb.max.z }
        
//        centroid = (min + max) * 0.5
    }
    
    public func isInside(_ p:Vector3) -> Bool {
        return (
            (p.x > min.x && p.y > min.y && p.z > min.z) &&
            (p.x < max.x && p.y < max.y && p.z < max.z)
        )
    }
    
    public func isIntersect(_ ray:Ray, _ near:Double, _ far:Double) -> Bool {
        var largest_min = near
        var smallest_max = far
        
        for i in 0..<3 {
            let invD = 1.0 / ray.direction.componentAt(i)
            var tmin = (min.componentAt(i) - ray.origin.componentAt(i)) * invD
            var tmax = (max.componentAt(i) - ray.origin.componentAt(i)) * invD
            if invD < 0.0 {
                swap(&tmin, &tmax)
            }
            
            largest_min = Double.minimum(largest_min, tmin)
            smallest_max = Double.minimum(smallest_max, tmax)
            
            if smallest_max < largest_min {
                return false
            }
        }
        
        return true
    }
}
