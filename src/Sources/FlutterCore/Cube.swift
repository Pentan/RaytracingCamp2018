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
        
        var i0 = 0
        var i1 = 0
        var i2 = 0
        var i3 = 0
        
        // front
        i0 = mesh.addVertexAndNormal(Vector3(maxp.x, maxp.y, maxp.z), Vector3(0.0, 0.0, 1.0))
        i1 = mesh.addVertexAndNormal(Vector3(minp.x, maxp.y, maxp.z), Vector3(0.0, 0.0, 1.0))
        i2 = mesh.addVertexAndNormal(Vector3(minp.x, minp.y, maxp.z), Vector3(0.0, 0.0, 1.0))
        i3 = mesh.addVertexAndNormal(Vector3(maxp.x, minp.y, maxp.z), Vector3(0.0, 0.0, 1.0))
        mesh.addFace(i0, i1, i2)
        mesh.addFace(i2, i3, i0)
        
        // back
        i0 = mesh.addVertexAndNormal(Vector3(minp.x, maxp.y, minp.z), Vector3(0.0, 0.0, -1.0))
        i1 = mesh.addVertexAndNormal(Vector3(maxp.x, maxp.y, minp.z), Vector3(0.0, 0.0, -1.0))
        i2 = mesh.addVertexAndNormal(Vector3(maxp.x, minp.y, minp.z), Vector3(0.0, 0.0, -1.0))
        i3 = mesh.addVertexAndNormal(Vector3(minp.x, minp.y, minp.z), Vector3(0.0, 0.0, -1.0))
        mesh.addFace(i0, i1, i2)
        mesh.addFace(i2, i3, i0)

        // right
        i0 = mesh.addVertexAndNormal(Vector3(maxp.x, maxp.y, minp.z), Vector3(1.0, 0.0, 0.0))
        i1 = mesh.addVertexAndNormal(Vector3(maxp.x, maxp.y, maxp.z), Vector3(1.0, 0.0, 0.0))
        i2 = mesh.addVertexAndNormal(Vector3(maxp.x, minp.y, maxp.z), Vector3(1.0, 0.0, 0.0))
        i3 = mesh.addVertexAndNormal(Vector3(maxp.x, minp.y, minp.z), Vector3(1.0, 0.0, 0.0))
        mesh.addFace(i0, i1, i2)
        mesh.addFace(i2, i3, i0)

        // left
        i0 = mesh.addVertexAndNormal(Vector3(minp.x, maxp.y, maxp.z), Vector3(-1.0, 0.0, 0.0))
        i1 = mesh.addVertexAndNormal(Vector3(minp.x, maxp.y, minp.z), Vector3(-1.0, 0.0, 0.0))
        i2 = mesh.addVertexAndNormal(Vector3(minp.x, minp.y, minp.z), Vector3(-1.0, 0.0, 0.0))
        i3 = mesh.addVertexAndNormal(Vector3(minp.x, minp.y, maxp.z), Vector3(-1.0, 0.0, 0.0))
        mesh.addFace(i0, i1, i2)
        mesh.addFace(i2, i3, i0)

        // top
        i0 = mesh.addVertexAndNormal(Vector3(maxp.x, maxp.y, minp.z), Vector3(0.0, 1.0, 0.0))
        i1 = mesh.addVertexAndNormal(Vector3(minp.x, maxp.y, minp.z), Vector3(0.0, 1.0, 0.0))
        i2 = mesh.addVertexAndNormal(Vector3(minp.x, maxp.y, maxp.z), Vector3(0.0, 1.0, 0.0))
        i3 = mesh.addVertexAndNormal(Vector3(maxp.x, maxp.y, maxp.z), Vector3(0.0, 1.0, 0.0))
        mesh.addFace(i0, i1, i2)
        mesh.addFace(i2, i3, i0)

        // bottom
        i0 = mesh.addVertexAndNormal(Vector3(maxp.x, minp.y, maxp.z), Vector3(0.0, -1.0, 0.0))
        i1 = mesh.addVertexAndNormal(Vector3(minp.x, minp.y, maxp.z), Vector3(0.0, -1.0, 0.0))
        i2 = mesh.addVertexAndNormal(Vector3(minp.x, minp.y, minp.z), Vector3(0.0, -1.0, 0.0))
        i3 = mesh.addVertexAndNormal(Vector3(maxp.x, minp.y, minp.z), Vector3(0.0, -1.0, 0.0))
        mesh.addFace(i0, i1, i2)
        mesh.addFace(i2, i3, i0)
        
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

