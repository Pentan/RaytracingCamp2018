#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

internal func makeBasePath(_ path:String) -> String {
    if path == "" {
        return ""
    }
    
    let splited = path.split(separator: "/")
    let droped = splited.dropLast().joined(separator: "/")
    
    if path.index(of: "/") == path.startIndex {
        return "/" + droped + "/"
    }
    
    return droped + "/"
}

public class GLTF {
    //
    public enum GLTFError : Error {
        case FileLoadFailure
        case JSONParseError
        case GLTFParseError
        case BufferDataLoadError
    }
    
    //
    internal init() {
        //
    }
    
    static public func load(_ filepath:String) throws -> glTF {
        let (fileptr, filesize) = try GLTF.loadAllBytes(filepath)
        let u8ptr = fileptr.bindMemory(to: UInt8.self, capacity: filesize)
        
        let gltf:glTF
        
        // "glTF" = [0x67, 0x6c, 0x54, 0x46]
        if u8ptr[0] == 0x67 && u8ptr[1] == 0x6c && u8ptr[2] == 0x54 && u8ptr[3] == 0x46 {
            // .glb
            gltf = try loadGLB(fileptr, filesize)
        } else {
            // .gltf
            let srcstr = String(cString: u8ptr)
            gltf = try parseGLTF(srcstr)
        }
        
        gltf.srcPath = filepath
        gltf.basePath = makeBasePath(filepath)
        
        // Load buffer binaries
        if let bufs = gltf.buffers {
            for buf in bufs {
                if let uri = buf.uri {
                    let (bufptr, bufsz) = try loadAllBytes(gltf.basePath + uri)
                    if buf.byteLength != bufsz {
                        throw GLTFError.BufferDataLoadError
                    }
                    buf.bufferPtr = bufptr
                }
            }
        }
        
        // clean
        fileptr.deallocate()
        
        return gltf
    }
    
    static public func parseGLTF(_ srcstr:String) throws -> glTF {
        let parser = JSON()
        let json = try parser.parse(srcstr)
        guard let srcjson = json as? [String: Any] else {
            throw GLTFError.JSONParseError
        }
        guard let ret = glTF(json:srcjson) else {
            throw GLTFError.GLTFParseError
        }
        return ret
    }
    
    static internal func loadGLB(_ ptr:UnsafeRawPointer, _ size:Int) throws -> glTF {
        // FIXME
        return glTF(asset:Asset(version: ""))
    }
    
    static internal func loadAllBytes(_ path:String) throws -> (UnsafeMutableRawPointer, Int) {
        let fd = open(path, O_RDONLY)
        let fp = fdopen(fd, "rb")
        
        if fp == nil {
            throw GLTFError.FileLoadFailure
        }
        
        let stat = UnsafeMutablePointer<stat>.allocate(capacity: 1)
        fstat(fd, stat)
        
        let fsize = Int(stat[0].st_size)
        stat.deallocate()
        
        let buf = UnsafeMutableRawPointer.allocate(byteCount: fsize, alignment: MemoryLayout<UInt8>.alignment)
        let readed = fread(buf, 1, fsize, fp)
        fclose(fp)
        
        if readed < fsize {
            buf.deallocate()
            throw GLTFError.FileLoadFailure
        }
        
        return (buf, fsize)
    }
    
    // Constants
    public enum ValueType : String {
        case SCALAR     = "SCALAR"
        case VEC2       = "VEC2"
        case VEC3       = "VEC3"
        case VEC4       = "VEC4"
        case MAT2       = "MAT2"
        case MAT3       = "MAT3"
        case MAT4       = "MAT4"
    }
    
    public enum ComponentType : Int {
        case BYTE           = 5120
        case UNSIGNED_BYTE  = 5121
        case SHORT          = 5122
        case UNSIGNED_SHORT = 5123
        case UNSIGNED_INT   = 5125
        case FLOAT          = 5126
    }
    
    public enum InterpolationType : String {
        case LINEAR         = "LINEAR"
        case STEP           = "STEP"
        case CUBICSPLINE    = "CUBICSPLINE"
    }
    
    public enum ChannelTarget : String {
        case Translation    = "translation"
        case Rotation       = "rotation"
        case Scale          = "scale"
        case Weights        = "weights"
    }
    
    public enum BufferType : Int {
        case ARRAY_BUFFER           = 34962
        case ELEMENT_ARRAY_BUFFER   = 34963
    }
    
    public enum CameraType : String {
        case Perspevtive    = "perspective"
        case Orthographic   = "orthographic"
    }
    
    public enum AlphaMode : String {
        case OPAQUE     = "OPAQUE"
        case MASK       = "MASK"
        case BLEND      = "BLEND"
    }
    
    public class AttributeType {
        static public let POSITION       = "POSITION"
        static public let NORMAL         = "NORMAL"
        static public let TANGENT        = "TANGENT"
        static public let TEXCOORD_0     = "TEXCOORD_0"
        static public let TEXCOORD_1     = "TEXCOORD_1"
        static public let COLOR_0        = "COLOR_0"
        static public let JOINTS_0       = "JOINTS_0"
        static public let WEIGHTS_0      = "WEIGHTS_0"
        
        internal init() {}
    }
    
    public enum PrimitiveMode : Int {
        case POINT
        case LINE
        case LINE_LOOP
        case LINE_STRIP
        case TRIANGLES
        case TRIANGLE_STRIP
        case TRIANGLE_FAN
    }
    
    public enum FilterMode : Int {
        case NEAREST                = 9728
        case LINEAR                 = 9729
        case NEARESR_MIPMAP_NEAREST = 9984
        case LINEAR_MIPMAP_NEAREST  = 9985
        case NEARESR_MIPMAP_LINEAR  = 9986
        case LINEAR_MIPMAP_LINEAR   = 9987
    }
    
    public enum WrapMode : Int {
        case CLAMP_TO_EDGE      = 33071
        case MERRORED_REPEAT    = 33648
        case REPEAT             = 10497
    }
    
    // Classes
    // base class
    public class glTFObject {
        public var extensions:[String: Any]?
        public var extras:Any?
        public var additionalProperties:[String: Any]?
        
        internal func handleUnknownProperty(_ value:Any, forKey key:String) {
            switch key {
            case "extensions":
                extensions = value as? [String: Any]
            case "extras":
                extras = value
            default:
                if additionalProperties == nil {
                    additionalProperties = [:]
                }
                additionalProperties?.updateValue(value, forKey: key)
            }
        }
    }
    
    public class Accessor : glTFObject {
        //
        public var bufferView:Int       = 0
        public var byteOffset:Int       = 0
        public var componentType:ComponentType
        public var normalized:Bool      = false
        public var count:Int            = 0
        public var type:ValueType
        public var max:[Double]?
        public var min:[Double]?
        public var sparce:Sparce?
        public var name:String?
        
        //
        public init(componentType:ComponentType, valueType:ValueType) {
            self.componentType = componentType
            self.type = valueType
        }
        
        public init?(json:[String: Any]) {
            // Required properties
            // componentType
            guard let rawct = json["componentType"] as? Double else {
                assertionFailure("Accessor requires componentType")
                return nil
            }
            guard let ct = ComponentType.init(rawValue: Int(rawct)) else {
                assertionFailure("Accessor invalid componentType: \(rawct)")
                return nil
            }
            componentType = ct
            
            // valueType
            guard let rawt = json["type"] as? String else {
                assertionFailure("Accessor requires type")
                return nil
            }
            guard let vt = ValueType.init(rawValue: rawt) else {
                assertionFailure("Accessor invalid type: \(rawt)")
                return nil
            }
            type = vt
            
            //
            super.init()
            
            // Remaining properties
            for (k, v) in json {
                switch k {
                case "bufferView":
                    guard let bv = v as? Double else {
                        assertionFailure("Accessor invalid bufferView: \(v)")
                        continue
                    }
                    bufferView = Int(bv)
                    
                case "byteOffset":
                    guard let bo = v as? Double else {
                        assertionFailure("Accessor invalid byteOffset: \(v)")
                        continue
                    }
                    byteOffset = Int(bo)
                    
                case "componentType":
                    break
                    
                case "normalized":
                    guard let nd = v as? Bool else {
                        assertionFailure("Accessor invalid normalized: \(v)")
                        continue
                    }
                    normalized = nd
                    
                case "count":
                    guard let c = v as? Double else {
                        assertionFailure("Accessor invalid count: \(v)")
                        continue
                    }
                    count = Int(c)
                    
                case "type":
                    break
                    
                case "max":
                    guard let m = v as? [Double] else {
                        assertionFailure("Accessor invalid max: \(v)")
                        continue
                    }
                    max = m
                    
                case "min":
                    guard let m = v as? [Double] else {
                        assertionFailure("Accessor invalid min: \(v)")
                        continue
                    }
                    min = m
                    
                case "sparce":
                    guard let spcjson = v as? [String: Any] else {
                        assertionFailure("Accessor invalid space: \(v)")
                        continue
                    }
                    guard let s = Sparce(json:spcjson) else {
                        continue
                    }
                    sparce = s
                    
                case "name":
                    guard let nm = v as? String else {
                        assertionFailure("Accessor invalid name: \(v)")
                        continue
                    }
                    name = nm
                    
                default:
                    handleUnknownProperty(v, forKey: k)
                }
            }
        }
        
        // Child classes
        public class Sparce : glTFObject {
            
            public var count:Int
            public var indices:Indices
            public var values:Values
            
            public init(count:Int, indices:Indices, values:Values) {
                self.count = count
                self.indices = indices
                self.values = values
            }
            
            public init?(json:[String: Any]) {
                // Required properties
                // count
                guard let c = json["count"] as? Double else {
                    assertionFailure("Accessor.Sparce requires count")
                    return nil
                }
                count = Int(c)
                
                // indices
                guard let indjson = json["indices"] as? [String: Any] else {
                    assertionFailure("Accessor.Sparce requires indices")
                    return nil
                }
                guard let ind = Indices(json:indjson) else {
                    return nil
                }
                indices = ind
                
                // values
                guard let valsjson = json["values"] as? [String: Any] else {
                    assertionFailure("Accessor.Sparce requires values")
                    return nil
                }
                guard let vals = Values(json:valsjson) else {
                    return nil
                }
                values = vals
                
                //
                super.init()
                
                // Remaining properties
                for (k, v) in json {
                    switch k {
                    case "count":
                        break
                    case "indices":
                        break;
                    case "values":
                        break
                    default:
                        handleUnknownProperty(v, forKey: k)
                    }
                }
            }
            
            // Child classes
            public class Indices : glTFObject {
                public var bufferView:Int
                public var byteOffset:Int       = 0
                public var componentType:ComponentType
                
                public init(bufferView:Int, componentType:ComponentType) {
                    self.bufferView = bufferView
                    self.componentType = componentType
                }
                
                public init?(json:[String: Any]) {
                    // Required properties
                    // bufferView
                    guard let bv = json["bufferView"] as? Double else {
                        assertionFailure("Accessor.Sparce.Indices requires bufferView")
                        return nil
                    }
                    bufferView = Int(bv)
                    
                    // componentType
                    guard let rawct = json["componentType"] as? Double else {
                        assertionFailure("Accessor.Sparce.Indices requires componentType")
                        return nil
                    }
                    guard let ct = ComponentType.init(rawValue: Int(rawct)) else {
                        assertionFailure("Accessor.Sparce.Indices invalid componentType: \(rawct)")
                        return nil
                    }
                    componentType = ct
                    
                    // super init
                    super.init()
                    
                    // Remaining properties
                    for (k, v) in json {
                        switch k {
                        case "byteOffset":
                            guard let bo = v as? Double else {
                                assertionFailure("Accessor.Sparce.Indices invalid byteOffset value: \(v)")
                                continue
                            }
                            byteOffset = Int(bo)
                            
                        case "componentType":
                            break
                        case "bufferView":
                            break;
                        default:
                            handleUnknownProperty(v, forKey: k)
                        }
                    }
                }
            }
            
            //
            public class Values : glTFObject {
                public var bufferView:Int
                public var byteOffset:Int       = 0
                
                public init(bufferView:Int) {
                    self.bufferView = bufferView
                }
                
                public init?(json:[String: Any]) {
                    // Required properties
                    guard let bv = json["bufferView"] as? Double else {
                        assertionFailure("Accessor.Sparce.Values requires bufferView")
                        return nil
                    }
                    bufferView = Int(bv)
                    
                    //
                    super.init()
                    
                    // Remaining properties
                    for (k, v) in json {
                        switch k {
                        case "byteOffset":
                            guard let bo = v as? Double else {
                                assertionFailure("Accessor.Sparce.Values invalid byteOffset value: \(v)")
                                continue
                            }
                            byteOffset = Int(bo)
                            
                        case "bufferView":
                            break;
                        default:
                            handleUnknownProperty(v, forKey: k)
                        }
                    }
                }
            }
        }
    }
    
    public class Animation : glTFObject {
        public var channels:[Channel]            = []
        public var samplers:[AnimationSampler]  = []
        public var name:String?
        
        public init?(json:[String: Any]) {
            super.init()
            
            // Remaining properties
            for (k, v) in json {
                switch k {
                case "channels":
                    guard let tmpjsons = json["channels"] as? [[String:Any]] else {
                        assertionFailure("Animation invalid channels")
                        continue
                    }
                    for srcjson in tmpjsons {
                        guard let tmp = Channel(json: srcjson) else {
                            continue
                        }
                        channels.append(tmp)
                    }
                    
                case "samplers":
                    guard let tmpjsons = json["samplers"] as? [[String:Any]] else {
                        assertionFailure("Animation invalid samplers")
                        continue
                    }
                    for srcjson in tmpjsons {
                        guard let tmp = AnimationSampler(json: srcjson) else {
                            continue
                        }
                        samplers.append(tmp)
                    }
                    
                case "name":
                    guard let tmp = json["name"] as? String else {
                        assertionFailure("Animation invalid name")
                        continue
                    }
                    name = tmp
                    
                default:
                    handleUnknownProperty(v, forKey: k)
                }
            }
        }
        
        // Child Classes
        public class AnimationSampler : glTFObject {
            public var input:Int
            public var interpolation:InterpolationType = .LINEAR
            public var output:Int
            
            public init(input:Int, output:Int) {
                self.input = input
                self.output = output
            }
            
            public init?(json:[String: Any]) {
                // Required properties
                // input
                guard let ip = json["input"] as? Double else {
                    assertionFailure("Animation.AnimationSampler requires input")
                    return nil
                }
                input = Int(ip)
                
                // output
                guard let op = json["output"] as? Double else {
                    assertionFailure("Animation.AnimationSampler requires output")
                    return nil
                }
                output = Int(op)
                
                //
                super.init()
                
                // Remaining properties
                for (k, v) in json {
                    switch k {
                    case "input":
                        break;
                        
                    case "interpolation":
                        guard let rawtmp = json["interpolation"] as? String else {
                            assertionFailure("Animation.AnimationSampler invalid interpolation")
                            continue
                        }
                        guard let tmp = InterpolationType(rawValue: rawtmp) else {
                            assertionFailure("Animation.AnimationSampler invalid interpolation \(rawtmp)")
                            continue
                        }
                        interpolation = tmp
                        
                    case "output":
                        break
                        
                    default:
                        handleUnknownProperty(v, forKey: k)
                    }
                }
            }
        }
        
        public class Channel : glTFObject {
            public var sampler:Int
            public var target:Target
            
            public init(sampler:Int, target:Target) {
                self.sampler = sampler
                self.target = target
            }
            
            public init?(json:[String: Any]) {
                // Required properties
                // sampler
                guard let smp = json["sampler"] as? Double else {
                    assertionFailure("Animation.Channel requires sampler")
                    return nil
                }
                sampler = Int(smp)
                
                // target
                guard let tgjson = json["target"] as? [String: Any] else {
                    assertionFailure("Animation.Channel requires target")
                    return nil
                }
                guard let tg = Target(json: tgjson) else {
                    return nil
                }
                target = tg
                
                //
                super.init()
                
                // Remaining properties
                for (k, v) in json {
                    switch k {
                    case "sampler":
                        break;
                    case "target":
                        break
                    default:
                        handleUnknownProperty(v, forKey: k)
                    }
                }
            }
            
            // Child Classes
            public class Target : glTFObject {
                public var node:Int     = 0
                public var path:ChannelTarget
                
                public init(path:ChannelTarget) {
                    self.path = path
                }
                
                public init?(json:[String: Any]) {
                    // Required properties
                    guard let rawp = json["path"] as? String else {
                        assertionFailure("Animation.Channel.Target requires path")
                        return nil
                    }
                    guard let p = ChannelTarget(rawValue: rawp) else {
                        assertionFailure("Animation.Channel.Target invalid path \(rawp)")
                        return nil
                    }
                    path = p
                    
                    //
                    super.init()
                    
                    // Remaining properties
                    for (k, v) in json {
                        switch k {
                        case "path":
                            break;
                            
                        case "node":
                            guard let n = json["node"] as? Double else {
                                assertionFailure("Animation.Channel.Target invalid node")
                                continue
                            }
                            node = Int(n)
                            
                        default:
                            handleUnknownProperty(v, forKey: k)
                        }
                    }
                }
            }
        }
    }
    
    public class Asset : glTFObject {
        public var copyright:String?
        public var generator:String?
        public var version:String
        public var minVersion:String?
        
        public init(version:String) {
            self.version = version
        }
        
        public init?(json:[String: Any]) {
            // Required properties
            guard let v = json["version"] as? String else {
                assertionFailure("Asset requires version")
                return nil
            }
            version = v
            
            //
            super.init()
            
            // Remaining properties
            for (k, v) in json {
                switch k {
                case "copyright":
                    guard let cr = json["copyright"] as? String else {
                        assertionFailure("Asset invalid copyright")
                        continue
                    }
                    copyright = cr
                    
                case "generator":
                    guard let g = json["generator"] as? String else {
                        assertionFailure("Asset invalid generator")
                        continue
                    }
                    generator = g
                    
                case "version":
                    break;
                    
                case "minVersion":
                    guard let mv = json["minVersion"] as? String else {
                        assertionFailure("Asset invalid minVersion")
                        continue
                    }
                    minVersion = mv
                    
                default:
                    handleUnknownProperty(v, forKey: k)
                }
            }
        }
    }
    
    public class Buffer : glTFObject {
        public var uri:String?
        public var byteLength:Int
        public var name:String?
        
        // Application data
        public var bufferPtr:UnsafeMutableRawPointer?
        deinit {
            if let bp = bufferPtr {
                bp.deallocate()
            }
        }
        
        public init(byteLength:Int) {
            self.byteLength = byteLength
        }
        
        public init?(json:[String: Any]) {
            // Required properties
            guard let bl = json["byteLength"] as? Double else {
                assertionFailure("Buffer requires byteLength")
                return nil
            }
            byteLength = Int(bl)
            
            //
            super.init()
            
            // Remaining properties
            for (k, v) in json {
                switch k {
                case "uri":
                    guard let u = json["uri"] as? String else {
                        assertionFailure("Buffer invalid uri")
                        continue
                    }
                    uri = u
                    
                case "version":
                    break;
                    
                case "name":
                    guard let nm = json["name"] as? String else {
                        assertionFailure("Buffer invalid name")
                        continue
                    }
                    name = nm
                    
                default:
                    handleUnknownProperty(v, forKey: k)
                }
            }
        }
    }
    
    public class BufferView : glTFObject {
        public var buffer:Int
        public var byteOffset:Int   = 0
        public var byteLength:Int
        public var byteStride:Int   = 0
        public var target:BufferType?
        public var name:String?
        
        public init(buffer:Int, byteLength:Int) {
            self.buffer = buffer
            self.byteLength = byteLength
        }
        
        public init?(json:[String: Any]) {
            // Required properties
            // buffer
            guard let bf = json["buffer"] as? Double else {
                assertionFailure("BufferView requires buffer")
                return nil
            }
            buffer = Int(bf)
            
            // byteLength
            guard let bl = json["byteLength"] as? Double else {
                assertionFailure("BufferView requires byteLength")
                return nil
            }
            byteLength = Int(bl)
            
            //
            super.init()
            
            // Remaining properties
            for (k, v) in json {
                switch k {
                case "buffer":
                    break
                    
                case "byteOffset":
                    guard let bo = json["byteOffset"] as? Double else {
                        assertionFailure("BufferView invalid byteOffset")
                        continue
                    }
                    byteOffset = Int(bo)
                    
                case "byteLength":
                    break;
                    
                case "byteStride":
                    guard let bs = json["byteStride"] as? Double else {
                        assertionFailure("BufferView invalid byteStride")
                        continue
                    }
                    byteStride = Int(bs)
                    
                case "target":
                    guard let rawtg = json["target"] as? Double else {
                        assertionFailure("BufferView invalid target")
                        continue
                    }
                    guard let tg = BufferType(rawValue: Int(rawtg)) else {
                        assertionFailure("BufferView invalid target: \(rawtg)")
                        continue
                    }
                    target = tg
                    
                case "name":
                    guard let nm = json["name"] as? String else {
                        assertionFailure("BufferView invalid name")
                        continue
                    }
                    name = nm
                    
                default:
                    handleUnknownProperty(v, forKey: k)
                }
            }
        }
    }
    
    public class Camera : glTFObject {
        public var orthographic:Orthographic?
        public var perspective:Perspective?
        public var type:CameraType
        public var name:String?
        
        public init(type:CameraType) {
            self.type = type
        }
        
        public init?(json:[String: Any]) {
            // Required properties
            // type
            guard let rawt = json["type"] as? String else {
                assertionFailure("Camera requires type")
                return nil
            }
            guard let t = CameraType(rawValue: rawt) else {
                assertionFailure("Camera invlalid type: \(rawt)")
                return nil
            }
            type = t
            
            //
            super.init()
            
            // Remaining properties
            for (k, v) in json {
                switch k {
                case "orthographic":
                    guard let orthjson = json["orthographic"] as? [String: Any] else {
                        assertionFailure("Camera invalid orthographic")
                        continue
                    }
                    guard let orth = Orthographic(json:orthjson) else {
                        continue
                    }
                    orthographic = orth
                    
                case "perspective":
                    guard let prsjson = json["perspective"] as? [String: Any] else {
                        assertionFailure("Camera invalid perspective")
                        continue
                    }
                    guard let prs = Perspective(json:prsjson) else {
                        continue
                    }
                    perspective = prs
                    
                case "type":
                    break;
                    
                case "name":
                    guard let nm = json["name"] as? String else {
                        assertionFailure("Camera invalid name")
                        continue
                    }
                    name = nm
                    
                default:
                    handleUnknownProperty(v, forKey: k)
                }
            }
        }
        
        // Child classes
        public class Orthographic : glTFObject {
            public var xmag:Double
            public var ymag:Double
            public var zfar:Double
            public var znear:Double
            
            public init(xmag:Double, ymag:Double, znear:Double, zfar:Double) {
                self.xmag = xmag
                self.ymag = ymag
                self.znear = znear
                self.zfar = zfar
            }
            
            public init?(json:[String: Any]) {
                // Required properties
                // xmag
                guard let xm = json["xmag"] as? Double else {
                    assertionFailure("Orthographic requires xmag")
                    return nil
                }
                xmag = xm
                
                // ymag
                guard let ym = json["ymag"] as? Double else {
                    assertionFailure("Orthographic requires ymag")
                    return nil
                }
                ymag = ym
                
                // zfar
                guard let zf = json["zfar"] as? Double else {
                    assertionFailure("Orthographic requires zfar")
                    return nil
                }
                zfar = zf
                
                // znear
                guard let zn = json["znear"] as? Double else {
                    assertionFailure("Orthographic requires znear")
                    return nil
                }
                znear = zn
                
                //
                super.init()
                
                // Remaining properties
                for (k, v) in json {
                    switch k {
                    case "xmag":
                        break
                    case "ymag":
                        break
                    case "zfar":
                        break;
                    case "znear":
                        break
                    default:
                        handleUnknownProperty(v, forKey: k)
                    }
                }
            }
        }
        
        public class Perspective : glTFObject {
            public var aspectRatio:Double?
            public var yfov:Double
            public var zfar:Double?
            public var znear:Double
            
            public init(yfov:Double, znear:Double) {
                self.yfov = yfov
                self.znear = znear
            }
            
            public init?(json:[String: Any]) {
                // Required properties
                // yfov
                guard let yf = json["yfov"] as? Double else {
                    assertionFailure("Perspective requires yfov")
                    return nil
                }
                yfov = yf
                
                // znear
                guard let zn = json["znear"] as? Double else {
                    assertionFailure("Perspective requires znear")
                    return nil
                }
                znear = zn
                
                //
                super.init()
                
                // Remaining properties
                for (k, v) in json {
                    switch k {
                    case "aspectRatio":
                        guard let ar = json["aspectRatio"] as? Double else {
                            assertionFailure("Perspective invalid aspectRatio")
                            continue
                        }
                        aspectRatio = ar
                        
                    case "yfov":
                        break
                    case "zfar":
                        guard let zf = json["zfar"] as? Double else {
                            assertionFailure("Perspective invalid zfar")
                            continue
                        }
                        zfar = zf
                        
                    case "znear":
                        break
                    default:
                        handleUnknownProperty(v, forKey: k)
                    }
                }
            }
        }
    }
    
    public class glTF : glTFObject {
        public var extensionUsed:[String]?
        public var extensionRequired:[String]?
        public var accessors:[Accessor]?
        public var animations:[Animation]?
        public var asset:Asset
        public var buffers:[Buffer]?
        public var bufferViews:[BufferView]?
        public var cameras:[Camera]?
        public var images:[Image]?
        public var materials:[Material]?
        public var meshes:[Mesh]?
        public var nodes:[Node]?
        public var samplers:[Sampler]?
        public var scene:Int = 0
        public var scenes:[Scene]?
        public var skins:[Skin]?
        public var textures:[Texture]?
        
        // Application data
        public var srcPath:String = ""
        public var basePath:String = ""
        
        public init(asset:Asset) {
            self.asset = asset
        }
        public init?(json:[String: Any]) {
            // Required properties
            guard let astjson = json["asset"] as? [String: Any] else {
                assertionFailure("glTF requires asset")
                return nil
            }
            guard let ast = Asset(json: astjson) else {
                return nil
            }
            asset = ast
            
            //
            super.init()
            
            // Remaining properties
            for (k, v) in json {
                switch k {
                case "extensionUsed":
                    guard let tmp = json["extensionUsed"] as? [String] else {
                        assertionFailure("glTF invalid extensionUsed")
                        continue
                    }
                    extensionUsed = tmp
                    
                case "extensionRequired":
                    guard let tmp = json["extensionRequired"] as? [String] else {
                        assertionFailure("glTF invalid extensionRequired")
                        continue
                    }
                    extensionRequired = tmp
                    
                case "accessors":
                    guard let tmpjsons = json["accessors"] as? [[String: Any]] else {
                        assertionFailure("glTF invalid accessors")
                        continue
                    }
                    var tmpary:[Accessor] = []
                    for srcjson in tmpjsons {
                        guard let tmp = Accessor(json: srcjson) else {
                            continue
                        }
                        tmpary.append(tmp)
                    }
                    accessors = tmpary
                    
                case "animations":
                    guard let tmpjsons = json["animations"] as? [[String: Any]] else {
                        assertionFailure("glTF invalid animations")
                        continue
                    }
                    var tmpary:[Animation] = []
                    for srcjson in tmpjsons {
                        guard let tmp = Animation(json: srcjson) else {
                            continue
                        }
                        tmpary.append(tmp)
                    }
                    animations = tmpary
                    
                case "asset":
                    break
                    
                case "buffers":
                    guard let tmpjsons = json["buffers"] as? [[String: Any]] else {
                        assertionFailure("glTF invalid buffers")
                        continue
                    }
                    var tmpary:[Buffer] = []
                    for srcjson in tmpjsons {
                        guard let tmp = Buffer(json: srcjson) else {
                            continue
                        }
                        tmpary.append(tmp)
                    }
                    buffers = tmpary
                    
                case "bufferViews":
                    guard let tmpjsons = json["bufferViews"] as? [[String: Any]] else {
                        assertionFailure("glTF invalid bufferViews")
                        continue
                    }
                    var tmpary:[BufferView] = []
                    for srcjson in tmpjsons {
                        guard let tmp = BufferView(json: srcjson) else {
                            continue
                        }
                        tmpary.append(tmp)
                    }
                    bufferViews = tmpary
                    
                case "cameras":
                    guard let tmpjsons = json["cameras"] as? [[String: Any]] else {
                        assertionFailure("glTF invalid cameras")
                        continue
                    }
                    var tmpary:[Camera] = []
                    for srcjson in tmpjsons {
                        guard let tmp = Camera(json: srcjson) else {
                            continue
                        }
                        tmpary.append(tmp)
                    }
                    cameras = tmpary
                    
                case "images":
                    guard let tmpjsons = json["images"] as? [[String: Any]] else {
                        assertionFailure("glTF invalid images")
                        continue
                    }
                    var tmpary:[Image] = []
                    for srcjson in tmpjsons {
                        guard let tmp = Image(json: srcjson) else {
                            continue
                        }
                        tmpary.append(tmp)
                    }
                    images = tmpary
                    
                case "materials":
                    guard let tmpjsons = json["materials"] as? [[String: Any]] else {
                        assertionFailure("glTF invalid materials")
                        continue
                    }
                    var tmpary:[Material] = []
                    for srcjson in tmpjsons {
                        guard let tmp = Material(json: srcjson) else {
                            continue
                        }
                        tmpary.append(tmp)
                    }
                    materials = tmpary
                    
                case "meshes":
                    guard let tmpjsons = json["meshes"] as? [[String: Any]] else {
                        assertionFailure("glTF invalid meshs")
                        continue
                    }
                    var tmpary:[Mesh] = []
                    for srcjson in tmpjsons {
                        guard let tmp = Mesh(json: srcjson) else {
                            continue
                        }
                        tmpary.append(tmp)
                    }
                    meshes = tmpary
                    
                case "nodes":
                    guard let tmpjsons = json["nodes"] as? [[String: Any]] else {
                        assertionFailure("glTF invalid nodes")
                        continue
                    }
                    var tmpary:[Node] = []
                    for srcjson in tmpjsons {
                        guard let tmp = Node(json: srcjson) else {
                            continue
                        }
                        tmpary.append(tmp)
                    }
                    nodes = tmpary
                    
                case "samplers":
                    guard let tmpjsons = json["samplers"] as? [[String: Any]] else {
                        assertionFailure("glTF invalid samplers")
                        continue
                    }
                    var tmpary:[Sampler] = []
                    for srcjson in tmpjsons {
                        guard let tmp = Sampler(json: srcjson) else {
                            continue
                        }
                        tmpary.append(tmp)
                    }
                    samplers = tmpary
                    
                case "scene":
                    guard let tmp = json["scene"] as? Double else {
                        assertionFailure("glTF invalid scene")
                        continue
                    }
                    scene = Int(tmp)
                    
                case "scenes":
                    guard let tmpjsons = json["scenes"] as? [[String: Any]] else {
                        assertionFailure("glTF invalid scenes")
                        continue
                    }
                    var tmpary:[Scene] = []
                    for srcjson in tmpjsons {
                        guard let tmp = Scene(json: srcjson) else {
                            continue
                        }
                        tmpary.append(tmp)
                    }
                    scenes = tmpary
                    
                case "skins":
                    guard let tmpjsons = json["skins"] as? [[String: Any]] else {
                        assertionFailure("glTF invalid skins")
                        continue
                    }
                    var tmpary:[Skin] = []
                    for srcjson in tmpjsons {
                        guard let tmp = Skin(json: srcjson) else {
                            continue
                        }
                        tmpary.append(tmp)
                    }
                    skins = tmpary
                    
                case "textures":
                    guard let tmpjsons = json["textures"] as? [[String: Any]] else {
                        assertionFailure("glTF invalid textures")
                        continue
                    }
                    var tmpary:[Texture] = []
                    for srcjson in tmpjsons {
                        guard let tmp = Texture(json: srcjson) else {
                            continue
                        }
                        tmpary.append(tmp)
                    }
                    textures = tmpary
                    
                default:
                    handleUnknownProperty(v, forKey: k)
                }
            }
        }
    }
    
    public class Image : glTFObject {
        public var uri:String?
        public var mimeType:String?
        public var bufferView:Int?
        public var name:String?
        
        public init?(json:[String: Any]) {
            super.init()
            
            // Remaining properties
            for (k, v) in json {
                switch k {
                case "uri":
                    guard let tmp = json["uri"] as? String else {
                        assertionFailure("Image invalid uri")
                        continue
                    }
                    uri = tmp
                    
                case mimeType:
                    guard let tmp = json["mimeType"] as? String else {
                        assertionFailure("Image invalid mimeType")
                        continue
                    }
                    mimeType = tmp
                    
                case "bufferView":
                    guard let tmp = json["bufferView"] as? Double else {
                        assertionFailure("Image invalid bufferView")
                        continue
                    }
                    bufferView = Int(tmp)
                    
                case "name":
                    guard let tmp = json["name"] as? String else {
                        assertionFailure("Image invalid name")
                        continue
                    }
                    name = tmp
                    
                default:
                    handleUnknownProperty(v, forKey: k)
                }
            }
        }
    }
    
    public class Material : glTFObject {
        public var name:String?
        public var pbrMetallicRoughness:PbrMetallicRoughness?
        public var normalTexture:NormalTextureInfo?
        public var occlusionTexture:OcclusionTextureInfo?
        public var emissiveTexture:TextureInfo?
        public var emissiveFactor:[Double]  = [0.0, 0.0, 0.0]
        public var alphaMode:AlphaMode      = .OPAQUE
        public var alphaCutOff:Double       = 0.5
        public var doubleSided:Bool         = false
        
        public init?(json:[String: Any]) {
            super.init()
            
            // Remaining properties
            for (k, v) in json {
                switch k {
                case "name":
                    guard let tmp = json["name"] as? String else {
                        assertionFailure("Material invalid name")
                        continue
                    }
                    name = tmp
                    
                case "pbrMetallicRoughness":
                    guard let tmpjson = json["pbrMetallicRoughness"] as? [String: Any] else {
                        assertionFailure("Material invalid pbrMetallicRoughness")
                        continue
                    }
                    guard let tmp = PbrMetallicRoughness(json:tmpjson) else {
                        continue
                    }
                    pbrMetallicRoughness = tmp
                    
                case "normalTexture":
                    guard let tmpjson = json["normalTexture"] as? [String: Any] else {
                        assertionFailure("Material invalid normalTexture")
                        continue
                    }
                    guard let tmp = NormalTextureInfo(json:tmpjson) else {
                        continue
                    }
                    normalTexture = tmp
                    
                case "occlusionTexture":
                    guard let tmpjson = json["occlusionTexture"] as? [String: Any] else {
                        assertionFailure("Material invalid occlusionTexture")
                        continue
                    }
                    guard let tmp = OcclusionTextureInfo(json:tmpjson) else {
                        continue
                    }
                    occlusionTexture = tmp
                    
                case "emissiveTexture":
                    guard let tmpjson = json["emissiveTexture"] as? [String: Any] else {
                        assertionFailure("Material invalid emissiveTexture")
                        continue
                    }
                    guard let tmp = TextureInfo(json:tmpjson) else {
                        continue
                    }
                    emissiveTexture = tmp
                    
                case "emissiveFactor":
                    guard let tmp = json["emissiveFactor"] as? [Double] else {
                        assertionFailure("Material invalid emissiveFactor")
                        continue
                    }
                    emissiveFactor = tmp
                    
                case "alphaMode":
                    guard let rawtmp = json["alphaMode"] as? String else {
                        assertionFailure("Material invalid alphaMode")
                        continue
                    }
                    guard let tmp = AlphaMode(rawValue: rawtmp) else {
                        continue
                    }
                    alphaMode = tmp
                    
                case "alphaCutOff":
                    guard let tmp = json["alphaCutOff"] as? Double else {
                        assertionFailure("Material invalid alphaCutOff")
                        continue
                    }
                    alphaCutOff = tmp
                    
                case "doubleSided":
                    guard let tmp = json["doubleSided"] as? Bool else {
                        assertionFailure("Material invalid doubleSided")
                        continue
                    }
                    doubleSided = tmp
                    
                default:
                    handleUnknownProperty(v, forKey: k)
                }
            }
        }
        
        // Child Classes
        public class NormalTextureInfo : glTFObject {
            public var index:Int
            public var texCoord:Int = 0
            public var scale:Double = 1.0
            
            public init(index:Int) {
                self.index = index
            }
            
            public init?(json:[String: Any]) {
                // Required properties
                guard let ind = json["index"] as? Double else {
                    assertionFailure("NormalTextureInfo requires index")
                    return nil
                }
                index = Int(ind)
                
                //
                super.init()
                
                // Remaining properties
                for (k, v) in json {
                    switch k {
                    case "index":
                        break;
                        
                    case "texCoord":
                        guard let tc = json["texCoord"] as? Double else {
                            assertionFailure("NormalTextureInfo invalid texCoord")
                            continue
                        }
                        texCoord = Int(tc)
                        
                    case "scale":
                        guard let s = json["scale"] as? Double else {
                            assertionFailure("NormalTextureInfo invalid scale")
                            continue
                        }
                        scale = s
                        
                    default:
                        handleUnknownProperty(v, forKey: k)
                    }
                }
            }
        }
        
        public class OcclusionTextureInfo : glTFObject {
            public var index:Int
            public var texCoord:Int     = 0
            public var strength:Double  = 1.0
            
            public init(index:Int) {
                self.index = index
            }
            
            public init?(json:[String: Any]) {
                // Required properties
                guard let ind = json["index"] as? Double else {
                    assertionFailure("OcclusionTextureInfo requires index")
                    return nil
                }
                index = Int(ind)
                
                //
                super.init()
                
                // Remaining properties
                for (k, v) in json {
                    switch k {
                    case "index":
                        break;
                        
                    case "texCoord":
                        guard let tc = json["texCoord"] as? Double else {
                            assertionFailure("OcclusionTextureInfo invalid texCoord")
                            continue
                        }
                        texCoord = Int(tc)
                        
                    case "strength":
                        guard let s = json["strength"] as? Double else {
                            assertionFailure("OcclusionTextureInfo invalid strength")
                            continue
                        }
                        strength = s
                        
                    default:
                        handleUnknownProperty(v, forKey: k)
                    }
                }
            }
        }
        
        public class PbrMetallicRoughness : glTFObject {
            public var baseColorFactor:[Double]     = [1.0, 1.0, 1.0, 1.0]
            public var baseColorTexture:TextureInfo?
            public var metallicFactor:Double        = 1.0
            public var roughnessFactor:Double       = 1.0
            public var metallicRoughnessTexture:TextureInfo?
            
            public init?(json:[String: Any]) {
                //
                super.init()
                
                // Remaining properties
                for (k, v) in json {
                    switch k {
                    case "baseColorFactor":
                        guard let tmp = json["baseColorFactor"] as? [Double] else {
                            assertionFailure("pbrMetallicRoughness invalid baseColorFactor")
                            continue
                        }
                        baseColorFactor = tmp
                        
                    case "baseColorTexture":
                        guard let tmpjson = json["baseColorTexture"] as? [String: Any] else {
                            assertionFailure("pbrMetallicRoughness invalid baseColorTexture")
                            continue
                        }
                        guard let tmp = TextureInfo(json:tmpjson) else {
                            continue
                        }
                        baseColorTexture = tmp
                        
                    case "metallicFactor":
                        guard let tmp = json["metallicFactor"] as? Double else {
                            assertionFailure("pbrMetallicRoughness invalid metallicFactor")
                            continue
                        }
                        metallicFactor = tmp
                        
                    case "roughnessFactor":
                        guard let tmp = json["roughnessFactor"] as? Double else {
                            assertionFailure("pbrMetallicRoughness invalid roughnessFactor")
                            continue
                        }
                        roughnessFactor = tmp
                        
                    case "metallicRoughnessTexture":
                        guard let tmpjson = json["metallicRoughnessTexture"] as? [String: Any] else {
                            assertionFailure("pbrMetallicRoughness invalid metallicRoughnessTexture")
                            continue
                        }
                        guard let tmp = TextureInfo(json:tmpjson) else {
                            continue
                        }
                        metallicRoughnessTexture = tmp
                        
                    default:
                        handleUnknownProperty(v, forKey: k)
                    }
                }
            }
        }
    }
    
    public class Mesh : glTFObject {
        public var primitives:[Primitive]   = []
        public var weights:[Double]         = []
        public var name:String?
        
        public init?(json:[String: Any]) {
            super.init()
            
            // Remaining properties
            for (k, v) in json {
                switch k {
                case "primitives":
                    guard let primjsons = json["primitives"] as? [[String: Any]] else {
                        assertionFailure("Mesh invalid primitives")
                        continue
                    }
                    for tmpjson in primjsons {
                        guard let tmp = Primitive(json: tmpjson) else {
                            assertionFailure("Mesh invalid primitives entry")
                            continue
                        }
                        primitives.append(tmp)
                    }
                    
                case "weights":
                    guard let tmp = json["weights"] as? [Double] else {
                        assertionFailure("Mesh invalid weights")
                        continue
                    }
                    weights = tmp
                    
                case "name":
                    guard let tmp = json["name"] as? String else {
                        assertionFailure("Mesh invalid name")
                        continue
                    }
                    name = tmp
                    
                default:
                    handleUnknownProperty(v, forKey: k)
                }
            }
        }
        
        // Child classes
        public class Primitive : glTFObject {
            public var attributes:[String: Int] = [:]
            public var indices:Int?
            public var material:Int?
            public var mode:PrimitiveMode   = .TRIANGLES
            public var targets:[String: Int]?
            
            public init?(json:[String: Any]) {
                super.init()
                
                // Remaining properties
                for (k, v) in json {
                    switch k {
                    case "attributes":
                        guard let tmp = json["attributes"] as? [String: Double] else {
                            assertionFailure("Primitive invalid attributes")
                            continue
                        }
                        attributes = tmp.mapValues({ Int($0) })
                        
                    case "indices":
                        guard let tmp = json["indices"] as? Double else {
                            assertionFailure("Primitive invalid pbrMetallicRoughness")
                            continue
                        }
                        indices = Int(tmp)
                        
                    case "material":
                        guard let tmp = json["material"] as? Double else {
                            assertionFailure("Primitive invalid material")
                            continue
                        }
                        material = Int(tmp)
                        
                    case "mode":
                        guard let rawtmp = json["mode"] as? Double else {
                            assertionFailure("Primitive invalid mode")
                            continue
                        }
                        guard let tmp = PrimitiveMode(rawValue: Int(rawtmp)) else {
                            continue
                        }
                        mode = tmp
                        
                    case "targets":
                        guard let tmp = json["targets"] as? [String: Int] else {
                            assertionFailure("Primitive invalid targets")
                            continue
                        }
                        targets = tmp
                        
                    default:
                        handleUnknownProperty(v, forKey: k)
                    }
                }
            }
        }
    }
    
    public class Node : glTFObject {
        public var camera:Int?
        public var children:[Int]?
        public var skin:Int?
        public var matrix:[Double]?      // default:Identity
        public var mesh:Int?
        public var rotation:[Double]?    // default:[0.0, 0.0, 0.0, 1.0]
        public var scale:[Double]?       // default:[1.0, 1.0, 1.0]
        public var translation:[Double]? // default:[0.0, 0.0, 0.0]
        public var weights:[Double]?
        public var name:String?
        
        public init?(json:[String: Any]) {
            super.init()
            
            // Remaining properties
            for (k, v) in json {
                switch k {
                case "camera":
                    guard let tmp = json["camera"] as? Double else {
                        assertionFailure("Node invalid camera")
                        continue
                    }
                    camera = Int(tmp)
                    
                case "children":
                    guard let tmp = json["children"] as? [Double] else {
                        assertionFailure("Node invalid children")
                        continue
                    }
                    children = tmp.map({ Int($0) })
                    
                case "skin":
                    guard let tmp = json["skin"] as? Double else {
                        assertionFailure("Node invalid skin")
                        continue
                    }
                    skin = Int(tmp)
                    
                case "matrix":
                    guard let tmp = json["matrix"] as? [Double] else {
                        assertionFailure("Node invalid matrix")
                        continue
                    }
                    matrix = tmp
                    
                case "mesh":
                    guard let tmp = json["mesh"] as? Double else {
                        assertionFailure("Node invalid mesh")
                        continue
                    }
                    mesh = Int(tmp)
                    
                case "rotation":
                    guard let tmp = json["rotation"] as? [Double] else {
                        assertionFailure("Node invalid rotation")
                        continue
                    }
                    rotation = tmp
                    
                case "scale":
                    guard let tmp = json["scale"] as? [Double] else {
                        assertionFailure("Node invalid scale")
                        continue
                    }
                    scale = tmp
                    
                case "translation":
                    guard let tmp = json["translation"] as? [Double] else {
                        assertionFailure("Node invalid translation")
                        continue
                    }
                    translation = tmp
                    
                case "weights":
                    guard let tmp = json["weights"] as? [Double] else {
                        assertionFailure("Node invalid weights")
                        continue
                    }
                    weights = tmp
                    
                case "name":
                    guard let tmp = json["name"] as? String else {
                        assertionFailure("Node invalid name")
                        continue
                    }
                    name = tmp
                    
                default:
                    handleUnknownProperty(v, forKey: k)
                }
            }
        }
    }
    
    public class Sampler : glTFObject {
        public var magFilter:FilterMode?
        public var minFilter:FilterMode?
        public var wrapS:WrapMode   = .REPEAT
        public var wrapT:WrapMode   = .REPEAT
        public var name:String?
        
        public init?(json:[String: Any]) {
            super.init()
            
            // Remaining properties
            for (k, v) in json {
                switch k {
                case "magFilter":
                    guard let rawtmp = json["magFilter"] as? Double else {
                        assertionFailure("Sampler invalid magFilter")
                        continue
                    }
                    guard let tmp = FilterMode(rawValue: Int(rawtmp)) else {
                        assertionFailure("Sampler invalid magFilter value \(rawtmp)")
                        continue
                    }
                    magFilter = tmp
                    
                case "minFilter":
                    guard let rawtmp = json["minFilter"] as? Double else {
                        assertionFailure("Sampler invalid minFilter")
                        continue
                    }
                    guard let tmp = FilterMode(rawValue: Int(rawtmp)) else {
                        assertionFailure("Sampler invalid minFilter value \(rawtmp)")
                        continue
                    }
                    minFilter = tmp
                    
                case "wrapS":
                    guard let rawtmp = json["wrapS"] as? Double else {
                        assertionFailure("Sampler invalid wrapS")
                        continue
                    }
                    guard let tmp = WrapMode(rawValue: Int(rawtmp)) else {
                        assertionFailure("Sampler invalid wrapS value \(rawtmp)")
                        continue
                    }
                    wrapS = tmp
                    
                case "wrapT":
                    guard let rawtmp = json["wrapT"] as? Double else {
                        assertionFailure("Sampler invalid wrapT")
                        continue
                    }
                    guard let tmp = WrapMode(rawValue: Int(rawtmp)) else {
                        assertionFailure("Sampler invalid wrapT value \(rawtmp)")
                        continue
                    }
                    wrapT = tmp
                    
                case "name":
                    guard let tmp = json["name"] as? String else {
                        assertionFailure("Sampler invalid name")
                        continue
                    }
                    name = tmp
                    
                default:
                    handleUnknownProperty(v, forKey: k)
                }
            }
        }
    }
    
    public class Scene : glTFObject {
        public var nodes:[Int]?
        public var name:String?
        
        public init?(json:[String: Any]) {
            super.init()
            
            // Remaining properties
            for (k, v) in json {
                switch k {
                case "nodes":
                    guard let tmp = json["nodes"] as? [Double] else {
                        assertionFailure("Scene invalid nodes")
                        continue
                    }
                    nodes = tmp.map({ Int($0) })
                    
                case "name":
                    guard let tmp = json["name"] as? String else {
                        assertionFailure("Scene invalid name")
                        continue
                    }
                    name = tmp
                    
                default:
                    handleUnknownProperty(v, forKey: k)
                }
            }
        }
    }
    
    public class Skin : glTFObject {
        public var inverseBindMatrices:Int?
        public var skeleton:Int?
        public var joints:[Int]     = []
        public var name:String?
        
        public init?(json:[String: Any]) {
            super.init()
            
            // Remaining properties
            for (k, v) in json {
                switch k {
                case "inverseBindMatrices":
                    guard let tmp = json["inverseBindMatrices"] as? Double else {
                        assertionFailure("Skin invalid inverseBindMatrices")
                        continue
                    }
                    inverseBindMatrices = Int(tmp)
                    
                case "skeleton":
                    guard let tmp = json["skeleton"] as? Double else {
                        assertionFailure("Skin invalid skeleton")
                        continue
                    }
                    skeleton = Int(tmp)
                    
                case "joints":
                    guard let tmp = json["joints"] as? [Double] else {
                        assertionFailure("Skin invalid joints")
                        continue
                    }
                    joints = tmp.map({ Int($0) })
                    
                case "name":
                    guard let tmp = json["name"] as? String else {
                        assertionFailure("Skin invalid name")
                        continue
                    }
                    name = tmp
                    
                default:
                    handleUnknownProperty(v, forKey: k)
                }
            }
        }
    }
    
    public class Texture : glTFObject {
        public var sampler:Int?
        public var source:Int?
        public var name:String?
        
        public init?(json:[String: Any]) {
            super.init()
            
            // Remaining properties
            for (k, v) in json {
                switch k {
                case "sampler":
                    guard let tmp = json["sampler"] as? Double else {
                        assertionFailure("Texture invalid camera")
                        continue
                    }
                    sampler = Int(tmp)
                    
                case "source":
                    guard let tmp = json["source"] as? Double else {
                        assertionFailure("Texture invalid source")
                        continue
                    }
                    source = Int(tmp)
                    
                case "name":
                    guard let tmp = json["name"] as? String else {
                        assertionFailure("Texture invalid name")
                        continue
                    }
                    name = tmp
                    
                default:
                    handleUnknownProperty(v, forKey: k)
                }
            }
        }
    }
    
    public class TextureInfo : glTFObject {
        public var index:Int
        public var texCoord:Int     = 0
        
        public init(index:Int) {
            self.index = index
        }
        
        public init?(json:[String: Any]) {
            // Required properties
            guard let i = json["index"] as? Double else {
                assertionFailure("TextureInfo requires index")
                return nil
            }
            index = Int(i)
            
            //
            super.init()
            
            // Remaining properties
            for (k, v) in json {
                switch k {
                case "index":
                    break
                    
                case "texCoord":
                    guard let tc = json["texCoord"] as? Double else {
                        assertionFailure("TextureInfo invalid texCoord")
                        continue
                    }
                    texCoord = Int(tc)
                    
                default:
                    handleUnknownProperty(v, forKey: k)
                }
            }
        }
    }
}
