#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public struct Hit {
    static public let kNoHitIndex = -1
    
    public var isHit = false
    public var distance = -1.0
    
    public var objectIndex = kNoHitIndex
    public var geometryIndex = kNoHitIndex
    public var primitiveIndex = kNoHitIndex
    
    public init(_ hit:Bool, _ d:Double=0.0,
                objectIndex:Int=kNoHitIndex,
                geometryIndex:Int=kNoHitIndex,
                primitiveIndex:Int=kNoHitIndex)
    {
        isHit = hit
        distance = d
        
        self.objectIndex = objectIndex
        self.geometryIndex = geometryIndex
        self.primitiveIndex = primitiveIndex
    }
}
