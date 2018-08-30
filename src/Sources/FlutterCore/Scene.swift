#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class Scene {
    
    public var camera = CameraNode()
    public var background = Background()
    
    public var objectNodes = Array<ObjectNode>()
    public var lightNodes = Array<ObjectNode>()
    
    internal let objectBVH = BVH()
    
    public init() {
    }
    
    public func addObject(_ obj:ObjectNode) {
        objectNodes.append(obj)
        if obj.isLight {
            lightNodes.append(obj)
        }
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
        // Blute force
//        var min_hit = Hit(false, far)
//        for i in 0..<objectNodes.count {
//            let (ishit, dist, primid) = objectNodes[i].intersection(ray, near, min_hit.distance)
//            if ishit {
//                min_hit.isHit = true
//                min_hit.distance = dist
//                min_hit.objectIndex = i
//                min_hit.primitiveIndex = primid
//            }
//        }
//
//        if min_hit.isHit {
//            let obj = objectNodes[min_hit.objectIndex]
//            let surf = obj.intersectionDetail(ray, min_hit, near, far)
//            let pv = PathVertex(-ray.direction, min_hit, surf)
//            return (true, pv)
//        }
        
        // BVH
        let (ishit, dist, objId, primId) = objectBVH.intersect(ray, near, far) { (objId, ray, near, far) -> (Bool, Double, Int) in
            return objectNodes[objId].intersection(ray, near, far)
        }
        
        if ishit {
            let hit = Hit(true, dist, objectIndex:objId, primitiveIndex:primId)
            let obj = objectNodes[objId]
            let surf = obj.intersectionDetail(ray, hit, near, far)
            let pv = PathVertex(-ray.direction, hit, surf)
            return (true, pv)
        }
        
//        assert(bfhit.primitiveIndex == min_hit.primitiveIndex)
        
        
        return (false, PathVertex.kEmptyVertex)
    }
}
