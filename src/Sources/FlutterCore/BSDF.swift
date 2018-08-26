#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

/////
public protocol BSDF {
    func typeFlags() -> Int
    func sampleAndEvaluate(_ pv:PathVertex, _ rng:Random) -> (ray:Ray, f:Double, pdf:Double, flag:Int)
    func evaluate(_ pv:PathVertex, _ ro:Ray) -> (f:Double, pdf:Double, flag:Int)
}
