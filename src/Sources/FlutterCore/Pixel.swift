#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class Pixel {
    public var color = Vector3()
    public var sampleCount = 0
    
    public init() {
    }
    
    public func clear() {
        color.set(0.0, 0.0, 0.0)
        sampleCount = 0
    }
    
    public func accumulate(_ c:Vector3) {
        color = color + c
        sampleCount += 1
    }
    
    public func rgb() -> (Double, Double, Double) {
        if sampleCount > 0 {
            let sc = Double(sampleCount)
            return (color.x / sc, color.y / sc, color.z / sc)
        }
        return (0.0, 0.0, 0.0)
//        return (1.0, 0.0, 0.0)
    }
}
