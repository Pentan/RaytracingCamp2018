#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class PathVertex {
    static public let kEmptyVertex = PathVertex(Vector3(), Hit(false), SurfaceSpec())
    
    public var incident:Vector3
    public var hit:Hit
    public var surface:SurfaceSpec
    
    public init(_ incident:Vector3, _ hit:Hit, _ surface:SurfaceSpec) {
        self.hit = hit
        self.incident = incident
        self.surface = surface
    }
}
