#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public protocol Material {
    func emittion(_ pv:PathVertex) -> Vector3
    func isSpecularBSDF(_ i:Int) -> Bool
    
    func sampleNext(_ pv:PathVertex, _ rng:Random) -> (Ray, Vector3, Double, Int)
    func bsdf(_ bsdfId:Int, _ pv:PathVertex, _ ro:Ray) -> (Double, Double)
}
