#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class SurfaceSpec {
    public var location = Vector3()
    public var geometryNormal = Vector3()
    public var shadingNormal = Vector3()
    public var uv0 = Vector3()
    
    public var varycentricCoord = Vector3()
    
    public var materialIndex = 0
}
