#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public protocol Geometry {
    func transfomedAABB(_ transform:Matrix4) -> AABB
    func renderPreprocess(_ rng:Random)
    func intersection(_ ray:Ray, _ near:Double, _ far:Double) -> (Bool, Double, Int)
    func intersectionDetail(_ ray:Ray, _ primId:Int, _ near:Double, _ far:Double) -> SurfaceSpec
}
