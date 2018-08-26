#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

/////
public protocol Texture {
    func sample(_ uv:Vector3) -> Vector3
}

/////
public class ConstantColor : Texture {
    public var color:Vector3
    
    public init(_ col:Vector3) {
        color = col
    }
    
    public func sample(_ uv: Vector3) -> Vector3 {
        return color
    }
}

/////
public class LinearGradient : Texture {
    public enum Direction : Int {
        case kX
        case kY
        case kZ
    }
    
    public var color0:Vector3
    public var color1:Vector3
    internal var dirComp:Int
    
    public init(_ col0:Vector3, _ col1:Vector3, direction:Direction = .kX) {
        color0 = col0
        color1 = col1
        dirComp = direction.rawValue
    }
    
    public func sample(_ uv: Vector3) -> Vector3 {
        let t = max(min(uv.componentAt(dirComp), 1.0), -1.0)
        return color0 * (1.0 - t) + color1 * t
    }
}

/////
/* buffer coordinate
  [0]+---+[w-1]
     |   |
     +---+ [w*h*N-1]
 uv(0,0)
 */
public class BufferTexture : Texture {
    public var width:Int
    public var height:Int
    public var stride:Int
    public let buffer:[Double]
    
    
    /////
    public enum WrapMode : Int {
        case kClamp
        case kRepeat
    }
    internal var wrapU:(Double,Int) -> (Int, Int, Double)
    internal var wrapV:(Double,Int) -> (Int, Int, Double)
    
    static internal let edgeClamp = {(x:Double, n:Int) -> (Int, Int, Double) in
        let f = floor(x)
        let t = x - f
        var i = Int(f)
        var j = i + 1
        i = max(0, min(n - 1, i))
        j = max(0, min(n - 1, j))
        return (i, j, t)
    }
    
    static internal let edgeRepeat = {(x:Double, n:Int) -> (Int, Int, Double) in
        let f = floor(x)
        let t = x - f
        var i = Int(f) % n
        if i < 0 {
            i += n
        }
        let j = (i + 1) % n
        return (i, j, t)
    }
    
    /////
    public init(_ w:Int, _ h:Int, _ comps:Int, _ buf:[Double]) {
        width = w
        height = h
        buffer = buf
        wrapU = BufferTexture.edgeRepeat
        wrapV = BufferTexture.edgeRepeat
        stride = comps
    }
    
    public init(_ w:Int, _ h:Int, _ comps:Int, _ filler:(Int,Int) -> (Double, Double, Double)) {
        width = w
        height = h
        stride = comps
        
        var tmpbuf = Array<Double>(repeating: 0.0, count: w * h * stride)
        for y in 0..<height {
            for x in 0..<width {
                let i = (x + y * width) * stride
                let (r, g, b) = filler(x, y)
                tmpbuf[i] = r
                tmpbuf[i + 1] = g
                tmpbuf[i + 2] = b
            }
        }
        buffer = tmpbuf
        
        wrapU = BufferTexture.edgeRepeat
        wrapV = BufferTexture.edgeRepeat
    }
    
    public func setUWrapMode(_ b:WrapMode) {
        switch b {
        case .kClamp:
            wrapU = BufferTexture.edgeClamp
        case .kRepeat:
            wrapU = BufferTexture.edgeRepeat
        }
    }
    
    public func setVWrapMode(_ b:WrapMode) {
        switch b {
        case .kClamp:
            wrapV = BufferTexture.edgeClamp
        case .kRepeat:
            wrapV = BufferTexture.edgeRepeat
        }
    }
    
    // Sample [0,1,2] components as Vector3
    public func sample(_ uv: Vector3) -> Vector3 {
        // Bilinear
        let (x0, x1, xt) = wrapU(uv.x * Double(width) - 0.5, width)
        let (y0, y1, yt) = wrapV((1.0 - uv.y) * Double(height) - 0.5, height)
        
        let i00 = (x0 + y0 * width) * stride
        let i01 = (x0 + y1 * width) * stride
        let i10 = (x1 + y0 * width) * stride
        let i11 = (x1 + y1 * width) * stride
        
        let v00 = Vector3(buffer[i00], buffer[i00 + 1], buffer[i00 + 2])
        let v01 = Vector3(buffer[i01], buffer[i01 + 1], buffer[i01 + 2])
        let v10 = Vector3(buffer[i10], buffer[i10 + 1], buffer[i10 + 2])
        let v11 = Vector3(buffer[i11], buffer[i11 + 1], buffer[i11 + 2])
        
        let vy0 = (v00 * (1.0 - xt) + v10 * xt)
        let vy1 = (v01 * (1.0 - xt) + v11 * xt)
        
        return vy0 * (1.0 - yt) + vy1 * yt
    }
    
    // Sample one component
    public func sample(_ uv: Vector3, comp:Int) -> Double {
        // Bilinear
        let (x0, x1, xt) = wrapU(uv.x * Double(width) - 0.5, width)
        let (y0, y1, yt) = wrapV((1.0 - uv.y) * Double(height) - 0.5, height)
        
        let i00 = (x0 + y0 * width) * stride
        let i01 = (x0 + y1 * width) * stride
        let i10 = (x1 + y0 * width) * stride
        let i11 = (x1 + y1 * width) * stride
        
        let c00 = buffer[i00 + comp]
        let c01 = buffer[i01 + comp]
        let c10 = buffer[i10 + comp]
        let c11 = buffer[i11 + comp]
        
        let cy0 = (c00 * (1.0 - xt) + c10 * xt)
        let cy1 = (c01 * (1.0 - xt) + c11 * xt)
        
        return cy0 * (1.0 - yt) + cy1 * yt
    }
}
