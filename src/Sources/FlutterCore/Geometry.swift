#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public protocol Geometry {
    func intersection(_ ray:Ray, _ near:Double, _ far:Double) -> (Vector3, Int)
    func intersectionDetail(_ ray:Ray, _ hit:Hit) -> SurfaceSpec
}
