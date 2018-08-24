#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public protocol Geometry {
    func transfomedAABB(_ transform:Matrix4) -> AABB
    func renderPreprocess(_ rng:Random)
    
    // return: (is hit, distance, primitive id(If multi primitive geometry like polygon mesh))
    func intersection(_ ray:Ray, _ near:Double, _ far:Double) -> (Bool, Double, Int)
    func intersectionDetail(_ ray:Ray, _ primId:Int, _ near:Double, _ far:Double) -> SurfaceSpec
}
