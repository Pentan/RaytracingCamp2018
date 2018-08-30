#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class SceneBuilder {
    //
    static public func sceneFromGLTF(_ path:String) -> Scene? {
        print("Setup from glTF: \(path)")
        
        let gltf:GLTF.glTF
        do {
            gltf = try GLTF.load(path)
        } catch {
            print("glTF load failure: \(path) (\(error)")
            return nil
        }
        
        // Scene has some thing to render?
        if gltf.cameras == nil {
            print("glTF has no camera.")
            return nil
        }
        
        if gltf.meshes == nil {
            print("glTF has no Meshes")
            return nil
        }
        
        if gltf.nodes == nil {
            print("glTF has no Objects")
            return nil
        }
        
        // Extract
        guard let helper = GLTFHelper(gltf) else {
            return nil
        }
        
        //
        let scene = Scene()
        
        helper.buildScene(scene)
        
        return scene
    }
    
    // Helper
    internal class GLTFHelper {
        // glTF data
        internal var gltf:GLTF.glTF
        internal var primaryScene:GLTF.Scene
        internal var nodes:[GLTF.Node]
        
        // Application data
        internal var materialBank:[Material] = []
        internal var textureBank:[Texture] = []
        
        //
        public init?(_ gltf:GLTF.glTF) {
            self.gltf = gltf
            
            guard let gltf_scenes = gltf.scenes else {
                print("glTF has no scenes.")
                return nil
            }
            primaryScene = gltf_scenes[gltf.scene]
            
            guard let gltf_nodes = gltf.nodes else {
                print("glTF has no nodes.")
                return nil
            }
            nodes = gltf_nodes
        }
        
        public func buildScene(_ scene:Scene) {
            // Make data banks
            buildTextureBank()
            buildMaterialBank()
            
            // travers nodes
            if let scnNodes = primaryScene.nodes {
                let im = Matrix4()
                for i in scnNodes {
                    traverseNodes(i, im, scene)
                }
            }
            
            // Scene extra settings
            extractBackgroundExtras(scene)
        }
        
        internal func buildTextureBank() {
            guard let imgsrcs = gltf.images else {
                return
            }
            
            if let gltftexs = gltf.textures {
                for gltftex in gltftexs {
                    guard let imgid = gltftex.source else {
                        print("Source id undefined texture found")
                        continue
                    }
                    
                    let img = imgsrcs[imgid]
                    let tex:BufferTexture
                    
                    if let bvid = img.bufferView {
                        // GLB included image
                        // FIXME
                        print("GLB image texture is not supported now. make dummy. BufferView:\(bvid)")
                        let buffer = [0.8, 0.2, 0.2, 0.8, 0.2, 0.2, 0.8, 0.2, 0.2, 0.8, 0.2, 0.2]
                        tex = BufferTexture(2, 2, 3, buffer)
                        
                    } else if let uri = img.uri {
                        // uri
                        // FIXME
                        print("Image texture is not supported now. make dummy. \(uri)")
//                        let buffer = [0.2, 0.8, 0.2, 0.2, 0.8, 0.2, 0.2, 0.8, 0.2, 0.2, 0.8, 0.2]
                        let buffer = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
                        tex = BufferTexture(2, 2, 3, buffer)
                        
                    } else {
                        print("Unknown source image \(imgid)")
                        continue
                    }
                    
                    // Default wrap setting
                    tex.setUWrapMode(.kRepeat)
                    tex.setVWrapMode(.kRepeat)
                    
                    if let smplrid = gltftex.sampler {
                        if let smplrs = gltf.samplers {
                            let smplr = smplrs[smplrid]
                            
                            switch smplr.wrapS {
                            case .CLAMP_TO_EDGE:
                                tex.setUWrapMode(.kClamp)
                            case .MERRORED_REPEAT:
                                tex.setUWrapMode(.kRepeat)
                                print("WARNING Texture mirrored repeat \(smplr.wrapS.rawValue) is not supported")
                            case .REPEAT:
                                tex.setUWrapMode(.kRepeat)
                            }
                            
                            switch smplr.wrapT {
                            case .CLAMP_TO_EDGE:
                                tex.setVWrapMode(.kClamp)
                            case .MERRORED_REPEAT:
                                tex.setVWrapMode(.kRepeat)
                                print("WARNING Texture mirrored repeat \(smplr.wrapS.rawValue) is not supported")
                            case .REPEAT:
                                tex.setVWrapMode(.kRepeat)
                            }
                            
                            // Filter settings
//                            if let magf = smplr.magFilter {
//                                // FIXME
//                            }
//                            if let minf = smplr.minFilter {
//                                // FIXME
//                            }
                        }
                    }
                    textureBank.append(tex)
                }
            }
        }
        
        internal func buildMaterialBank() {
            if let gltfmats = gltf.materials {
                for gltfmat in gltfmats {
                    let mat = extractMaterial(gltfmat)
                    materialBank.append(mat)
                }
            } else {
                // Default material
                materialBank.append(PhysicallyBasedMetallicRoughness())
            }
        }
        
        internal func extractMaterial(_ gltfmat:GLTF.Material) -> Material {
            let mat = PhysicallyBasedMetallicRoughness()
            
            if let pbr = gltfmat.pbrMetallicRoughness {
                let bc = pbr.baseColorFactor
                mat.baseColorRGB.set(bc[0], bc[1], bc[2])
                mat.baseColorAlpha = bc[3]
                
                if let texinfo = pbr.baseColorTexture {
                    mat.baseColorTex = textureBank[texinfo.index]
                    mat.baseColorUV = texinfo.texCoord
                }
                
                mat.metallicFactor = pbr.metallicFactor
                mat.roughnessFactor = pbr.roughnessFactor
                if let texinfo = pbr.metallicRoughnessTexture {
                    mat.metallicRoughnessTex = textureBank[texinfo.index]
                    mat.metallicRoughnessUV = texinfo.texCoord
                }
            }
            
            if let texinfo = gltfmat.normalTexture {
                mat.normalTex = textureBank[texinfo.index]
                mat.normalUV = texinfo.texCoord
                mat.normalScale = texinfo.scale
            }
            
            if let texinfo = gltfmat.occlusionTexture {
                mat.occlusionTex = textureBank[texinfo.index]
                mat.occlusionUV = texinfo.texCoord
                mat.occlusionStrength = texinfo.strength
            }
            
            mat.emissiveFactor.setFromArray(gltfmat.emissiveFactor)
            if let texinfo = gltfmat.emissiveTexture {
                mat.emissiveTex = textureBank[texinfo.index]
                mat.emissiveUV = texinfo.texCoord
            }
            
            // FIXME
            switch gltfmat.alphaMode {
            case .BLEND:
                mat.alphaMode = 0
            case .MASK:
                mat.alphaMode = 1
            case .OPAQUE:
                mat.alphaMode = 2
            }
            mat.alphaCutoff = gltfmat.alphaCutOff
            mat.doubleSided = gltfmat.doubleSided
            
            return mat
        }
        
        internal func traverseNodes(_ nodeId:Int, _ inheritTransform:Matrix4, _ scn:Scene) {
            let node = nodes[nodeId]
            
            // Make local transform
            var lm = Matrix4()
            
            if let m = node.matrix {
                // has Matrix
                lm.set(m)
                
            } else {
                // Transform = T * R * S
                // Translate
                if let v = node.translation {
                    let m = Matrix4.makeTranslation(v[0], v[1], v[2])
                    lm = lm * m
                }
                // Rotation
                if let v = node.rotation {
                    let m = Matrix4.makeFromQuaternion(v[0], v[1], v[2], v[3])
                    lm = lm * m
                }
                // Scale
                if let v = node.scale {
                    let m = Matrix4.makeScale(v[0], v[1], v[2])
                    lm = lm * m
                }
                
                // Global transform
                let gm = inheritTransform * lm
                
                // Is Camera?
                if let camid = node.camera {
                    // Make Camera
                    if let cam = extractCamera(camid) {
                        cam.setTransform(gm)
                        scn.camera = cam
                    }
                }
                
                // Is Mesh?
                if let meshid = node.mesh {
                    // Make Object
                    if let obj = extractObject(meshid) {
                        obj.transform = gm
                        scn.addObject(obj)
                    }
                }
                
                // Traverse Next
                if let children = node.children {
                    for i in children {
                        traverseNodes(i, gm, scn)
                    }
                }
            }
        }
        
        internal func extractCamera(_ camid:Int) -> CameraNode? {
            let cam = gltf.cameras![camid]
            
            switch cam.type {
            case .Orthographic:
                print("Sorry! Orthographic camera is now support now.")
                assertionFailure()
                
            case .Perspevtive:
                guard let pers = cam.perspective else {
                    assertionFailure("perspective definition is not found")
                    return nil
                }
                
                let retcam = CameraNode()
                
                // Extra options
//                if let extras = pers.extras {
//                    if let exobj = extras as? [String: Any] {
//                        // sensor size
//                        // f number
//                        // forcus distance
//                        // etc...
//                    }
//                }
                
                // standard settings
                if let aspect = pers.aspectRatio {
                    let sw = retcam.sensorWidth
                    retcam.setSensorSizeWithAspectRatio(width: sw, aspect: aspect)
                }
                retcam.setFoculLengthWithFOV(pers.yfov)
                
                return retcam
            }
            
            return nil
        }
        
        internal func extractObject(_ meshId:Int) -> ObjectNode? {
            guard let gltfmesh = gltf.meshes?[meshId] else {
                return nil
            }
            guard let accessors = gltf.accessors else {
                return nil
            }
            
            let meshgeom = Mesh()
            
            var voffset = 0
            var noffset = 0
            var toffset = 0
            var uvoffset = 0
            var islight = false
            
            for prim in gltfmesh.primitives {
                var vcount = 0
                var ncount = 0
                var tcount = 0
                var uvcount = 0
                
                for (k, v) in prim.attributes {
                    switch k {
                    case GLTF.AttributeType.POSITION:
                        vcount = extractAndAddVertex(meshgeom, accessors[v])
                    case GLTF.AttributeType.NORMAL:
                        ncount = extractAndAddNormal(meshgeom, accessors[v])
                    case GLTF.AttributeType.TANGENT:
                        tcount = extractAndAddTangent(meshgeom, accessors[v])
                    case GLTF.AttributeType.TEXCOORD_0:
                        uvcount = extractAndAddTexcoord0(meshgeom, accessors[v])
                    case GLTF.AttributeType.TEXCOORD_1:
                        continue
                    case GLTF.AttributeType.COLOR_0:
                        continue
                    case GLTF.AttributeType.JOINTS_0:
                        continue
                    case GLTF.AttributeType.WEIGHTS_0:
                        continue
                    default:
                        continue
                    }
                }
                
                // Make indice array
                let indary:[Int]
                if let inds = prim.indices {
                    // DrawElement
                    indary = extractIndice(accessors[inds])
                    
                } else {
                    // DrawArray
                    var tmpary = Array<Int>(repeating: 0, count: vcount)
                    for i in 0..<vcount {
                        tmpary[i] = i
                    }
                    indary = tmpary
                }
                
                let matid = prim.material ?? 0
                
                if let pbrmat = materialBank[matid] as? PhysicallyBasedMetallicRoughness {
                    if pbrmat.emissiveFactor.maxMagnitude() > 0.0 {
                        // This is light!
                        islight = true
                    }
                }
                
                switch prim.mode {
                case .TRIANGLES:
                    for i in stride(from: 0, to: indary.count, by: 3) {
                        let i0 = indary[i] + voffset
                        let i1 = indary[i + 1] + voffset
                        let i2 = indary[i + 2] + voffset
                        meshgeom.addFace(i0, i1, i2, matid)
                    }
                case .TRIANGLE_FAN:
                    for i in 1..<(indary.count - 1) {
                        let i0 = indary[0] + voffset
                        let i1 = indary[i] + voffset
                        let i2 = indary[i + 1] + voffset
                        meshgeom.addFace(i0, i1, i2, matid)
                    }
                case .TRIANGLE_STRIP:
                    for i in 0..<(indary.count - 2) {
                        let i0 = indary[i] + voffset
                        let i1 = indary[i + 1] + voffset
                        let i2 = indary[i + 2] + voffset
                        meshgeom.addFace(i0, i1, i2, matid)
                    }
                default:
                    print("Sorry! Support only triangle series primitives.")
                }
                
                voffset += vcount
                noffset += ncount
                toffset += tcount
                uvoffset += uvcount
            }
            
            let obj = ObjectNode(meshgeom, islight)
            obj.materials = materialBank
            
            return obj
        }
        
        internal func extractAndAddVertex(_ mesh:Mesh, _ acc:GLTF.Accessor) -> Int {
            var dataCount = 0
            var dataStride = 0
            guard let fltptr:UnsafeMutablePointer<Float> = accesibleBufferPtr(acc, &dataCount, &dataStride) else {
                return 0
            }
            
            // VEC3
            if dataStride < 3 {
                dataStride = 3
            }
            for i in stride(from: 0, to: dataCount, by: dataStride) {
                let v = Vector3(Double(fltptr[i]), Double(fltptr[i + 1]), Double(fltptr[i + 2]))
                mesh.addVertex(v)
            }
            return acc.count
        }
        
        internal func extractAndAddNormal(_ mesh:Mesh, _ acc:GLTF.Accessor) -> Int {
            var dataCount = 0
            var dataStride = 0
            guard let fltptr:UnsafeMutablePointer<Float> = accesibleBufferPtr(acc, &dataCount, &dataStride) else {
                return 0
            }
            
            // VEC3
            if dataStride < 3 {
                dataStride = 3
            }
            for i in stride(from: 0, to: dataCount, by: dataStride) {
                let v = Vector3(Double(fltptr[i]), Double(fltptr[i + 1]), Double(fltptr[i + 2]))
                mesh.addNormal(v)
            }
            return acc.count
        }
        
        internal func extractAndAddTangent(_ mesh:Mesh, _ acc:GLTF.Accessor) -> Int {
            var dataCount = 0
            var dataStride = 0
            guard let fltptr:UnsafeMutablePointer<Float> = accesibleBufferPtr(acc, &dataCount, &dataStride) else {
                return 0
            }
            
            // VEC3
            if dataStride < 3 {
                dataStride = 3
            }
            for i in stride(from: 0, to: dataCount, by: dataStride) {
                let v = Vector3(Double(fltptr[i]), Double(fltptr[i + 1]), Double(fltptr[i + 2]))
                mesh.addTangent(v)
            }
            return acc.count
        }
        
        internal func extractAndAddTexcoord0(_ mesh:Mesh, _ acc:GLTF.Accessor) -> Int {
            var dataCount = 0
            var dataStride = 0
            
            switch acc.componentType {
            case .FLOAT:
                guard let fltptr:UnsafeMutablePointer<Float> = accesibleBufferPtr(acc, &dataCount, &dataStride) else {
                    return 0
                }
                // VEC2
                if dataStride < 2 {
                    dataStride = 2
                }
                for i in stride(from: 0, to: dataCount, by: dataStride) {
                    let v = Vector3(Double(fltptr[i]), Double(fltptr[i + 1]), Double(fltptr[i + 2]))
                    mesh.addVertex(v)
                }
                
            case .UNSIGNED_SHORT:
                guard let u16ptr:UnsafeMutablePointer<UInt16> = accesibleBufferPtr(acc, &dataCount, &dataStride) else {
                    return 0
                }
                // VEC2
                if dataStride < 2 {
                    dataStride = 2
                }
                let div = 1.0 / Double(UInt16.max)
                for i in stride(from: 0, to: dataCount, by: dataStride) {
                    let v = Vector3(Double(u16ptr[i]) * div, Double(u16ptr[i + 1]) * div, Double(u16ptr[i + 2]) * div)
                    mesh.addVertex(v)
                }
                
            case .UNSIGNED_BYTE:
                guard let u8ptr:UnsafeMutablePointer<UInt8> = accesibleBufferPtr(acc, &dataCount, &dataStride) else {
                    return 0
                }
                // VEC2
                if dataStride < 2 {
                    dataStride = 2
                }
                let div = 1.0 / Double(UInt8.max)
                for i in stride(from: 0, to: dataCount, by: dataStride) {
                    let v = Vector3(Double(u8ptr[i]) * div, Double(u8ptr[i + 1]) * div, Double(u8ptr[i + 2]) * div)
                    mesh.addVertex(v)
                }
                
            default:
                print("Invalid TEXCOORD_0 data type \(acc.componentType.rawValue)")
                return 0
            }
            
            return acc.count
        }
        
        internal func extractIndice(_ acc:GLTF.Accessor) -> [Int] {
            var ret:[Int] = []
            ret.reserveCapacity(acc.count)
            
            var dataCount = 0
            var dataStride = 0
            
            switch acc.componentType {
            case .UNSIGNED_BYTE:
                guard let tptr:UnsafeMutablePointer<UInt8> = accesibleBufferPtr(acc, &dataCount, &dataStride) else {
                    return []
                }
                for i in stride(from: 0, to: dataCount, by: dataStride) {
                    ret.append(Int(tptr[i]))
                }
                
            case .UNSIGNED_SHORT:
                guard let tptr:UnsafeMutablePointer<UInt16> = accesibleBufferPtr(acc, &dataCount, &dataStride) else {
                    return []
                }
                for i in stride(from: 0, to: dataCount, by: dataStride) {
                    ret.append(Int(tptr[i]))
                }
                
            case .UNSIGNED_INT:
                guard let tptr:UnsafeMutablePointer<UInt32> = accesibleBufferPtr(acc, &dataCount, &dataStride) else {
                    return []
                }
                for i in stride(from: 0, to: dataCount, by: dataStride) {
                    ret.append(Int(tptr[i]))
                }
                
            default:
                print("Invalid indice type \(acc.componentType)")
            }
            
            return ret
        }
        
        internal func accesibleBufferPtr<T>(_ acc:GLTF.Accessor, _ dataCount:inout Int, _ dataStride:inout Int) -> UnsafeMutablePointer<T>? {
            guard let bv = gltf.bufferViews?[acc.bufferView] else {
                print("BufferView not defined")
                return nil
            }
            
            guard let buf = gltf.buffers?[bv.buffer] else {
                print("Buffer not defined")
                return nil
            }
            
            guard let bufptr = buf.bufferPtr else {
                print("Buffer has no data")
                return nil
            }
            
            let typeSize = MemoryLayout<T>.size
            
            let byteOffset = bv.byteOffset
            let byteLength = bv.byteLength
            let byteStride = max(bv.byteStride, typeSize)
            
            //let datacount = acc.count
            dataCount = byteLength / typeSize
            dataStride = byteStride / typeSize
            let retptr = (bufptr + byteOffset).bindMemory(to: T.self, capacity: dataCount)
            
            return retptr
        }
        
        internal func extractBackgroundExtras(_ scn:Scene) {
            guard let gltfscn = gltf.scenes?[gltf.scene] else {
                return
            }
            guard let extras = gltfscn.extras as? [String: Any] else {
                return
            }
            guard let bg = extras["background"] as? [String: Any] else {
                return
            }
            
            if let color = bg["color"] as? [Double] {
                let tex = ConstantColor(Vector3(color[0], color[1], color[2]))
                scn.background.texture = tex
            }
            if let grad = bg["gradient"] as? [Double] {
                let tex = BufferTexture(1, grad.count / 3, 3, grad)
                scn.background.texture = tex
            }
        }
        
    }
}
