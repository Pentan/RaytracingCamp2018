#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public struct Ray {
    public var origin:Vector3
    public var direction:Vector3
    
    public init() {
        origin = Vector3()
        direction = Vector3(0.0, 0.0, -1.0)
    }
    
    public init(_ o:Vector3, _ d:Vector3) {
        origin = o
        direction = d
    }
}
