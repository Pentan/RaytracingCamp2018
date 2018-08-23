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
    public var shadingTangent = Vector3()
    public var uv = Vector3()
    
    public var varycentricCoord = Vector3()
    
    public var materialIndex = 0
    
    public func applyTransform(_ tm:Matrix4, _ ittm:Matrix4) {
        location = Matrix4.transformV3(tm, location)
        geometryNormal = Matrix4.mulV3(ittm, geometryNormal)
        geometryNormal.normalize()
        shadingNormal = Matrix4.mulV3(ittm, shadingNormal)
        shadingNormal.normalize()
    }
    
}
