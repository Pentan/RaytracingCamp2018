#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class Cube : Geometry {
    public var position:Vector3
    public var mesh:Mesh
    public var aabb:AABB
    
    public init(_ p:Vector3, _ s:Vector3) {
        position = p
        mesh = Mesh(24, 12)
        
        let minp = p - s * 0.5
        let maxp = p + s * 0.5
        aabb = AABB(min: minp, max: maxp)
        
        // Vertex
        // Bottom
        mesh.addVertex(Vector3(minp.x, minp.y, minp.z)) // 0
        mesh.addVertex(Vector3(minp.x, minp.y, maxp.z)) // 1
        mesh.addVertex(Vector3(maxp.x, minp.y, maxp.z)) // 2
        mesh.addVertex(Vector3(maxp.x, minp.y, minp.z)) // 3
        // Top
        mesh.addVertex(Vector3(minp.x, maxp.y, minp.z)) // 4
        mesh.addVertex(Vector3(minp.x, maxp.y, maxp.z)) // 5
        mesh.addVertex(Vector3(maxp.x, maxp.y, maxp.z)) // 6
        mesh.addVertex(Vector3(maxp.x, maxp.y, minp.z)) // 7
        
        // Normal
        mesh.addNormal(Vector3( 1.0, 0.0, 0.0)) // 0
        mesh.addNormal(Vector3(-1.0, 0.0, 0.0)) // 1
        mesh.addNormal(Vector3(0.0,  1.0, 0.0)) // 2
        mesh.addNormal(Vector3(0.0, -1.0, 0.0)) // 3
        mesh.addNormal(Vector3(0.0, 0.0,  1.0)) // 4
        mesh.addNormal(Vector3(0.0, 0.0, -1.0)) // 5
        
        // Texcoord
        mesh.addTexCoord(Vector3(0.0, 0.0, 0.0))
        mesh.addTexCoord(Vector3(1.0, 0.0, 0.0))
        mesh.addTexCoord(Vector3(1.0, 1.0, 0.0))
        mesh.addTexCoord(Vector3(0.0, 1.0, 0.0))
        
        // Right
        mesh.addFace(Mesh.FaceIndice(6, 2, 3), Mesh.FaceIndice(0, 0, 0), Mesh.FaceIndice(0, 1, 2))
        mesh.addFace(Mesh.FaceIndice(3, 7, 6), Mesh.FaceIndice(0, 0, 0), Mesh.FaceIndice(2, 3, 0))
        // Left
        mesh.addFace(Mesh.FaceIndice(4, 0, 1), Mesh.FaceIndice(1, 1, 1), Mesh.FaceIndice(0, 1, 2))
        mesh.addFace(Mesh.FaceIndice(1, 5, 4), Mesh.FaceIndice(1, 1, 1), Mesh.FaceIndice(2, 3, 0))
        // Top
        mesh.addFace(Mesh.FaceIndice(4, 5, 6), Mesh.FaceIndice(2, 2, 2), Mesh.FaceIndice(0, 1, 2))
        mesh.addFace(Mesh.FaceIndice(6, 7, 4), Mesh.FaceIndice(2, 2, 2), Mesh.FaceIndice(2, 3, 0))
        // Bottom
        mesh.addFace(Mesh.FaceIndice(2, 1, 0), Mesh.FaceIndice(3, 3, 3), Mesh.FaceIndice(0, 1, 2))
        mesh.addFace(Mesh.FaceIndice(0, 3, 2), Mesh.FaceIndice(3, 3, 3), Mesh.FaceIndice(2, 3, 0))
        // Front
        mesh.addFace(Mesh.FaceIndice(1, 2, 6), Mesh.FaceIndice(4, 4, 4), Mesh.FaceIndice(0, 1, 2))
        mesh.addFace(Mesh.FaceIndice(6, 5, 1), Mesh.FaceIndice(4, 4, 4), Mesh.FaceIndice(2, 3, 0))
        // Back
        mesh.addFace(Mesh.FaceIndice(3, 0, 4), Mesh.FaceIndice(5, 5, 5), Mesh.FaceIndice(0, 1, 2))
        mesh.addFace(Mesh.FaceIndice(4, 7, 3), Mesh.FaceIndice(5, 5, 5), Mesh.FaceIndice(2, 3, 0))
    }
    
    public func transfomedAABB(_ transform:Matrix4) -> AABB {
        let verts = [
            Vector3(aabb.min.x, aabb.min.y, aabb.min.z),
            Vector3(aabb.min.x, aabb.min.y, aabb.max.z),
            Vector3(aabb.min.x, aabb.max.y, aabb.min.z),
            Vector3(aabb.min.x, aabb.max.y, aabb.max.z),
            Vector3(aabb.max.x, aabb.min.y, aabb.min.z),
            Vector3(aabb.max.x, aabb.min.y, aabb.max.z),
            Vector3(aabb.max.x, aabb.max.y, aabb.min.z),
            Vector3(aabb.max.x, aabb.max.y, aabb.max.z)
        ]
        let ret = AABB()
        for v in verts {
            ret.expand(Matrix4.transformV3(transform, v))
        }
        return ret
    }
    
    public func renderPreprocess(_ rng:Random) {
        // Mesh preprocess
        mesh.renderPreprocess(rng)
    }
    
    public func intersection(_ ray: Ray, _ near: Double, _ far: Double) -> (Bool, Double, Int) {
        return mesh.intersection(ray, near, far)
    }
    
    public func intersectionDetail(_ ray: Ray, _ primId: Int, _ near:Double, _ far:Double) -> SurfaceSpec {
        return mesh.intersectionDetail(ray, primId, near, far)
    }
    
    
}

