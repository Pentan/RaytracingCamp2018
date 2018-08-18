#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class Scene {
    public var objectNodes = Array<ObjectNode>()
    public var camera:CameraNode
    
    public init() {
        //+++++
        /*
        camera = CameraNode(
            position: Vector3(0.0, 0.0, 10.0),
            look: Vector3(0.0, 0.0, 0.0),
            up: Vector3(0.0, 1.0, 0.0)
        )
        
        objectNodes.append(
            ObjectNode(
                Sphere(Vector3(0.0, 0.0, 0.0), 1.0),
                Material(
                    Vector3(0.8, 0.2, 0.2),
                    Vector3(0.0, 0.0, 0.0)
                )
            )
        )
        
        objectNodes.append(
            ObjectNode(
                Sphere(Vector3(0.0, -100.0, 0.0), 99.0),
                Material(
                    Vector3(0.8, 0.8, 0.8),
                    Vector3(0.0, 0.0, 0.0)
                )
            )
        )
        
        objectNodes.append(
            ObjectNode(
                Sphere(Vector3(1.0, 1.0, 1.0), 0.4),
                Material(
                    Vector3(0.0, 0.0, 0.0),
                    Vector3(2.0, 2.0, 2.0)
                )
            )
        )
        */
        
        // Cornel box
        camera = CameraNode(Vector3(50.0, 52.0, 295.6))
        camera.lookAt(
            look:Vector3(50.0, 52.0-0.042612, -1.0),
            up:Vector3(0.0, 1.0, 0.0)
        )
        camera.setFoculLengthWithFOV(30.0 * Double.pi / 180.0)
        
        objectNodes.append(ObjectNode(Sphere(Vector3( 1e5+1.0 , 40.8, 81.6),    1e5  ), Material(Vector3(0.75, 0.25, 0.25), Vector3(0.0, 0.0, 0.0), .kLambert)))
        objectNodes.append(ObjectNode(Sphere(Vector3(-1e5+99.0, 40.8, 81.6),    1e5  ), Material(Vector3(0.25, 0.25, 0.75), Vector3(0.0, 0.0, 0.0), .kLambert)))
        objectNodes.append(ObjectNode(Sphere(Vector3(50.0, 40.8, 1e5),          1e5  ), Material(Vector3(0.75, 0.75, 0.75), Vector3(0.0, 0.0, 0.0), .kLambert)))
        objectNodes.append(ObjectNode(Sphere(Vector3(50.0, 1e5 , 81.6),         1e5  ), Material(Vector3(0.75, 0.75, 0.75), Vector3(0.0, 0.0, 0.0), .kLambert)))
        objectNodes.append(ObjectNode(Sphere(Vector3(50.0, -1e5+81.6, 81.6),    1e5  ), Material(Vector3(0.75, 0.75, 0.75), Vector3(0.0, 0.0, 0.0), .kLambert)))
        objectNodes.append(ObjectNode(Sphere(Vector3(27.0, 16.5, 47.0),         16.5 ), Material(Vector3(0.99, 0.99, 0.99), Vector3(0.0, 0.0, 0.0), .kPerfectSpecular)))
        objectNodes.append(ObjectNode(Sphere(Vector3(73.0, 16.5, 78.0),         16.5 ), Material(Vector3(0.99, 0.99, 0.99), Vector3(0.0, 0.0, 0.0), .kFineGlass)))
        objectNodes.append(ObjectNode(Sphere(Vector3(50.0, 681.6-0.27, 81.6),   600.0), Material(Vector3(0.0 , 0.0 , 0.0 ), Vector3(12.0, 12.0, 12.0), .kLambert)))
        
        //+++++
    }
    
    public func raytrace(_ ray:Ray, _ near:Double=0.0, _ far:Double=kFarAway) -> (Bool, PathVertex) {
        var min_hit = Hit(false, far)
        
        for i in 0..<objectNodes.count {
            let hit = objectNodes[i].intersection(ray, near, min_hit.distance)
            if hit.isHit {
                min_hit = hit
                min_hit.objectIndex = i
            }
        }
        
        if min_hit.isHit {
            let obj = objectNodes[min_hit.objectIndex]
            let surf = obj.intersectionDetail(ray, min_hit)
            let pv = PathVertex(-ray.direction, min_hit, surf)
            return (true, pv)
        }
        
        return (false, PathVertex.kEmptyVertex)
    }
}
