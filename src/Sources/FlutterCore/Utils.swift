#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

/////
public func basisFromNormal(_ n:Vector3) -> (Vector3, Vector3) {
    //let s = Double((n.z.bitPattern & 0x8000000000000000) | 0x3ff0000000000000)
    let s = copysign(1.0, n.z)
    let a = -1.0 / (s + n.z)
    let b = n.x * n.y * a
    return (
        Vector3(1.0 + s * n.x * n.x * a, s * b, -s * n.x),
        Vector3(b, s + n.y * n.y * a, -n.y)
    )
}

public func cosineWeightedHemisphere(_ n:Vector3, _ rng:Random) -> (Vector3, Double) {
    let (u, v) = basisFromNormal(n)
    let r = rng.nextDoubleCO().squareRoot()
    let t = 2.0 * Double.pi * rng.nextDoubleCO()
    let x = r * cos(t)
    let y = r * sin(t)
    let d = Vector3(x, y, max(0.0, 1.0 - x * x - y * y).squareRoot())
    
    let wo = u * d.x + v * d.y + n * d.z
    let pdf = abs(Vector3.dot(n, wo)) / Double.pi
    
    return (wo, pdf)
}

public func fresnel(_ wi:Vector3, _ wo:Vector3, _ n:Vector3, _ ior:Double) -> Double {
    let F0 = ((1.0 - ior) * (1.0 - ior)) / ((1.0 + ior) * (1.0 + ior))
    let idotn = Vector3.dot(wi, n)
    let rdotn = (idotn > 0) ? idotn : Vector3.dot(wo, n)
    return F0 + (1.0 - F0) * pow(1.0 - rdotn, 5.0)
}

public func reflect(_ wi:Vector3, _ n:Vector3) -> Vector3 {
    return 2.0 * Vector3.dot(wi, n) * n - wi
}

public func refract(_ wi:Vector3, _ n:Vector3, _ ior:Double) -> (Bool, Vector3, Double) {
    let idotn = Vector3.dot(wi, n)
    let isInto = idotn > 0.0
    // Refract
    let eta:Double
    let absn:Vector3
    if isInto {
        eta = 1.0 / ior
        absn = n
    } else {
        eta = ior
        absn = -n
    }
    let cos2t = 1.0 - eta * eta * (1.0 - idotn * idotn)
    if cos2t < 0.0 {
        return (false, Vector3(), 0.0)
    }
    let wr = (eta * abs(idotn) - cos2t.squareRoot()) * absn - eta * wi
    return (true, wr, eta * eta)
}
