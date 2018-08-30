#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class PathTracer {
    public var minDepth = 2
    public var minRRCutOff = 5e-3
    
    public init() {
        //
    }
    
    public func pathtrace(_ nx:Double, _ ny:Double, _ scene:Scene, _ rng:Random) -> (Vector3, Int) {
        // Start ray tracing
        //var ray = scene.camera.ray(u: nx, v: ny, fov: kFOV, aspect: kAspect)
        var ray = scene.camera.ray(nx, ny, rng)
        
        var throughput = Vector3(1.0, 1.0, 1.0)
        var radiance = Vector3(0.0, 0.0, 0.0)
        var fromSpecular = false
        
        var depth = 0
        while true {
            // Get next intersection point
            let (ishit, pv) = scene.raytrace(ray, kRayOffset, kFarAway)
            if !ishit {
                // sample env using ray direction
                let bgcol = scene.background.sample(ray)
                radiance += Vector3.mul(throughput, bgcol)
                break
            }
            
            // get radiance from next intersection point
            let obj = scene.objectNodes[pv.hit.objectIndex]
            let mat = obj.materials[pv.surface.materialIndex]
            
            // and accumulate it with throughput
            // if (not light) || depth < 1 || specular bounce
            radiance += Vector3.mul(throughput, mat.emittion(pv))
            
            // current point can do light sample?
            if depth > 0 {
                // do light sample
            }
            
            // normal
//            radiance = pv.surface.geometryNormal * 0.5 + Vector3(0.5, 0.5, 0.5)
//            break
            
            // Update from next material infomation
            // Sample next direction
            let (nxtRay, fr, pdf, bsdfId) = mat.sampleNext(pv, rng)
            
            // Update throughput
            let ndotl = Vector3.dot(pv.surface.shadingNormal, nxtRay.direction)
            throughput = Vector3.mul(throughput, fr * abs(ndotl) / pdf)
            
            // Update specular bounce flag
            fromSpecular = mat.isSpecularBSDF(bsdfId)
            
            // Update ray
            ray = nxtRay
            
            // Russian roulette
            if depth > minDepth {
                //let c = throughput.maxMagnitude()
                let c = (throughput.x + throughput.y + throughput.z) / 3.0
                let q = max(minRRCutOff, 1.0 - c)
                if rng.nextDoubleCO() < q {
                    break
                }
                throughput = throughput / (1.0 - q)
            }
            
            // Update depth
            depth += 1
//            if depth > kMaxDepth {
//                // Biased Kill!
//                break
//            }

            //+++++
            //radiance = Vector3(1.0, 1.0, 1.0)
            // normal
//            radiance = pv.surface.geometryNormal * 0.5 + Vector3(0.5, 0.5, 0.5)
//            break
            //radiance = mat.Kd
            //break
            //+++++
        }
        
        return (radiance, depth)
    }
}
