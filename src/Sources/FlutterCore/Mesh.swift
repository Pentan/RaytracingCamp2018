#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class Mesh : Geometry {
    public struct FaceIndice {
        public var a:Int = 0
        public var b:Int = 0
        public var c:Int = 0
        
        public init(_ a:Int=0, _ b:Int=0, _ c:Int=0) {
            self.a = a
            self.b = b
            self.c = c
        }
    }
    
    public class Triangle {
        public var vid:FaceIndice
        public var nid:FaceIndice
        public var uvid:FaceIndice
        public var materialId = 0
        
        public var p0 = Vector3()
        public var edge01 = Vector3()
        public var edge02 = Vector3()
        public var normal = Vector3()
        public var area = 0.0
        public var areaSampleBorder = 0.0
        public var bounds = AABB()
        
        
        public init(_ a:Int, _ b:Int, _ c:Int, _ matid:Int=0) {
            self.vid = FaceIndice(a, b, c)
            self.nid = FaceIndice(a, b, c)
            self.uvid = FaceIndice(a, b, c)
            materialId = matid
        }
        
        public init(_ vid:FaceIndice, _ nid:FaceIndice, _ uvid:FaceIndice, _ matid:Int=0) {
            self.vid = vid
            self.nid = nid
            self.uvid = uvid
            materialId = matid
        }
        
        public func intersection(_ ray:Ray, _ near:Double, _ far:Double) -> (Bool, Double, Double, Double) {
            let r = ray.origin - p0
            let u = Vector3.cross(ray.direction, edge02)
            let v = Vector3.cross(r, edge01)
            
            let div = 1.0 / Vector3.dot(u, edge01)
            let t = Vector3.dot(v, edge02) * div
            let b = Vector3.dot(u, r) * div
            let c = Vector3.dot(v, ray.direction) * div
            
            if (b < 0.0) || (c < 0.0) || (b + c > 1.0) || (t < near) || (t > far) {
                return (false, -1.0, 0.0, 0.0)
            }
            return (true, t, b, c)
        }
    }
    
    public var vertices:[Vector3] = []
    public var normals:[Vector3] = []
    public var tangents:[Vector3] = []
    public var texcoords:[Vector3] = []
    public var vertexAttrs:[[Vector3]] = []
    
    public var faces:[Triangle] = []
    
    public var bounds:AABB = AABB()
    public var faceBVH = BVH()
    
    /////
    
    public init(_ vcapa:Int=0, _ fcapa:Int=0, _ vattrnum:Int=0) {
        if vcapa > 0 {
            vertices.reserveCapacity(vcapa)
            normals.reserveCapacity(vcapa)
            tangents.reserveCapacity(vcapa)
            texcoords.reserveCapacity(vcapa)
            if vattrnum > 0 {
                vertexAttrs.reserveCapacity(vattrnum)
                for _ in 0..<vattrnum {
                    var vattr = Array<Vector3>()
                    vattr.reserveCapacity(vcapa)
                    vertexAttrs.append(vattr)
                }
            }
        }
        if fcapa > 0 {
            faces.reserveCapacity(fcapa)
        }
    }
    
    @discardableResult
    public func addVertexAndNormal(_ v:Vector3, _ n:Vector3) -> Int {
        let ret = vertices.count
        vertices.append(v)
        normals.append(n)
        return ret
    }
    
    @discardableResult
    public func addVertex(_ v:Vector3) -> Int {
        vertices.append(v)
        return vertices.count - 1
    }
    
    @discardableResult
    public func addNormal(_ v:Vector3) -> Int {
        normals.append(v)
        return normals.count - 1
    }
    
    @discardableResult
    public func addTangent(_ v:Vector3) -> Int {
        tangents.append(v)
        return tangents.count - 1
    }
    
    @discardableResult
    public func addTexCoord(_ v:Vector3) -> Int {
        texcoords.append(v)
        return texcoords.count - 1
    }
    
    @discardableResult
    public func addVertexAttribute(_ i:Int, _ v:Vector3) -> Int {
        assert(i < vertexAttrs.count, "Vertex attribute out of inces")
        if i < vertexAttrs.count {
            vertexAttrs[i].append(v)
            return vertexAttrs[i].count
        }
        return -1
    }
    
    @discardableResult
    public func addFace(_ a:Int, _ b:Int, _ c:Int, _ matid:Int=0) -> Int {
        let f = Triangle(a, b, c, matid)
        faces.append(f)
        return faces.count - 1
    }
    
    @discardableResult
    public func addFace(_ vid:FaceIndice, _ nid:FaceIndice, _ uvid:FaceIndice, _ matid:Int=0) -> Int {
        let f = Triangle(vid, nid, uvid, matid)
        faces.append(f)
        return faces.count - 1
    }
    
    public func assignFaceMaterial(_ faceId:Int, _ matId:Int) {
        let f = faces[faceId]
        f.materialId = matId
    }
    
    /////
    public func transfomedAABB(_ transform:Matrix4) -> AABB {
        let ret = AABB()
        for v in vertices {
            ret.expand(Matrix4.transformV3(transform, v))
        }
        return ret
    }
    
    public func renderPreprocess(_ rng:Random) {
        // Face preprocess
        faceBVH.clear()
        bounds.clear()
        var totalArea = 0.0
        for i in 0..<faces.count {
            let tri = faces[i]
            let p0 = vertices[tri.vid.a]
            let p1 = vertices[tri.vid.b]
            let p2 = vertices[tri.vid.c]
            
            tri.p0 = p0
            tri.edge01 = p1 - p0
            tri.edge02 = p2 - p0
            let n = Vector3.cross(tri.edge01, tri.edge02)
            let nl = n.length()
            tri.normal = n / nl
            tri.area = nl
            tri.areaSampleBorder = totalArea + tri.area
            tri.bounds.clear()
            tri.bounds.expand(p0)
            tri.bounds.expand(p1)
            tri.bounds.expand(p2)
            
            bounds.expand(tri.bounds)
            
            totalArea += tri.area
            
            // Add face to BVH
            faceBVH.appendLeaf(tri.bounds, i)
        }
        
        // Build BVH
        faceBVH.buildTree()
    }
    
    /////
    public func intersection(_ ray: Ray, _ near: Double, _ far: Double) -> (Bool, Double, Int) {
        // Blute force
//        var minD = far
//        var hitId = -1
//        var isHit = false
//        for i in 0..<faces.count {
//            let tri = faces[i]
//            let (h, d, _, _) = tri.intersection(ray, near, minD)
//            if h {
//                minD = d
//                hitId = i
//                isHit = true
//            }
//        }
        
        // BVH
        let (isHit, minD, hitId, _) = faceBVH.intersect(ray, near, far) { (faceId, ray, near, far) -> (Bool, Double, Int) in
            let tri = faces[faceId]
            let (ishit, d, _, _) = tri.intersection(ray, near, far)
            return (ishit, d, 0) // leafData is don't mind
        }
        
        //
        if isHit {
            return (true, minD, hitId)
        }
        
        return (false, -1.0, 0)
    }
    
    public func intersectionDetail(_ ray: Ray, _ primId: Int, _ near: Double, _ far: Double) -> SurfaceSpec {
        let tri = faces[primId]
        let (_, _, vb, vc) = tri.intersection(ray, near, far)
        let va = 1.0 - vb - vc
        
        let surf = SurfaceSpec()
        surf.location = vertices[tri.vid.a] * va + vertices[tri.vid.b] * vb + vertices[tri.vid.c] * vc
        surf.geometryNormal = tri.normal
        surf.shadingNormal = normals[tri.nid.a] * va + normals[tri.nid.b] * vb + normals[tri.nid.c] * vc
        if tangents.count > 0 {
            surf.shadingTangent = tangents[tri.nid.a] * va + tangents[tri.nid.b] * vb + tangents[tri.nid.c] * vc
            // TODO
            // eval normal map
        }
        if texcoords.count > 0 {
            surf.uv = texcoords[tri.uvid.a] * va + texcoords[tri.uvid.b] * vb + texcoords[tri.uvid.c] * vc
        }
        surf.varycentricCoord = Vector3(va, vb, vc)
        surf.materialIndex = tri.materialId
        
        return surf
    }
    
    
}
