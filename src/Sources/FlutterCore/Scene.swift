#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class Scene {
    public var objectNodes = Array<ObjectNode>()
    public var camera = CameraNode()
    
    internal let objectBVH = BVH()
    
    public init() {
    }
    
    public func addObject(_ obj:ObjectNode) {
        objectNodes.append(obj)
    }
    
    public func renderPreprocess(_ rng:Random) {
        // Camera
        camera.renderPreprocess(rng)
        
        // Background
        // TODO
        
        // BVH
        objectBVH.clear()
        
        // Objects
        for i in 0..<objectNodes.count {
            let obj = objectNodes[i]
            obj.renderPreprocess(rng)
            
            // Register BVH
            objectBVH.appendLeaf(obj.aabb, i)
        }
        
        // Lights
        // TODO
        
        // BVH
        let bvhdepth = objectBVH.buildTree()
        print("object bvh max depth:\(bvhdepth)")
    }
    
    public func raytrace(_ ray:Ray, _ near:Double=0.0, _ far:Double=kFarAway) -> (Bool, PathVertex) {
        var min_hit = Hit(false, far)
        
        // Blute force
//        for i in 0..<objectNodes.count {
//            let hit = objectNodes[i].intersection(ray, near, min_hit.distance)
//            if hit.isHit {
//                min_hit = hit
//                min_hit.objectIndex = i
//            }
//        }
//        let bfhit = min_hit
        
        // BVH
        var tmphit = Hit(false, 0.0)
        let (bvhhit, bvhd, oid) = objectBVH.intersect(ray, near, far) { (objId, ray, near, far) -> (Bool, Double) in
            let hit = objectNodes[objId].intersection(ray, near, far)
            if hit.isHit {
                tmphit = hit
            }
            return (hit.isHit, hit.distance)
        }
        if bvhhit {
            min_hit = tmphit
            min_hit.distance = bvhd //++++++
            min_hit.objectIndex = oid
        }
        
//        assert(bfhit.primitiveIndex == min_hit.primitiveIndex)
        
        if min_hit.isHit {
            let obj = objectNodes[min_hit.objectIndex]
            let surf = obj.intersectionDetail(ray, min_hit, near, far)
            let pv = PathVertex(-ray.direction, min_hit, surf)
            return (true, pv)
        }
        
        return (false, PathVertex.kEmptyVertex)
    }
}
