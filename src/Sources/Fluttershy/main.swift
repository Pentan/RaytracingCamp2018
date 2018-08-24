#if os(OSX)
import Darwin
#else
import Glibc
#endif

import Dispatch
import LinearAlgebra
import FlutterCore

print("=== Fluttershy ===")

public func getTimeInSeconds() -> Double {
    let timeval = UnsafeMutablePointer<timeval>.allocate(capacity: 1)
    gettimeofday(timeval, nil)
    return Double(timeval.pointee.tv_sec) + Double(timeval.pointee.tv_usec) * 1e-6
}

// Render settings
struct RenderConfig {
    public var width    = 320
    public var height   = 240
    public var aspect:Double {
        return Double(width) / Double(height)
    }
    
    public var pixelSubSamples  = 1
    public var samplesPerPixel   = 32
    
    public var minDepth = 1
    public var maxDepth = 4
    public var minRRCutOff = 0.005
    
    public var tileSize = 64
    
    public var outputImage = "output.ppm"
    
    public mutating func parseCommandlineOptions() {
        var i = 1
        while i < CommandLine.argc {
            let arg:String = CommandLine.arguments[i]
            
            if arg == "-s" {
                let s = CommandLine.arguments[i + 1].split(separator: ":")
                width = Int(s[0])!
                height = Int(s[1])!
                i += 1
            } else if arg == "-ss" {
                pixelSubSamples = Int(CommandLine.arguments[i + 1])!
                i += 1
            } else if arg == "-spp" {
                samplesPerPixel = Int(CommandLine.arguments[i + 1])!
                i += 1
            } else if arg == "-mind" {
                minDepth = Int(CommandLine.arguments[i + 1])!
                i += 1
            } else if arg == "-maxd" {
                maxDepth = Int(CommandLine.arguments[i + 1])!
                i += 1
            } else if arg == "-ts" {
                tileSize = Int(CommandLine.arguments[i + 1])!
                i += 1
            } else if arg == "-o" {
                outputImage = CommandLine.arguments[i + 1]
                i += 1
            }
            
            i += 1
        }
    }
    
    public func printCommandlineOptionInfo() {
        print("options:")
        print(" -s w:h : render size")
        print(" -ss N : sub samples")
        print(" -spp N : samples per (sub)pixel")
        print(" -mind N : min depth")
        print(" -maxd N : max depth")
        print(" -ts N : tile size")
        print(" -o String : output file name. If given empty string, not save file.")
    }
}
var rndrconf = RenderConfig()

// Parse command line options
if CommandLine.argc > 1 {
    rndrconf.parseCommandlineOptions()
} else {
    rndrconf.printCommandlineOptionInfo()
}

//
print("\n--- render settings ---")

// Image settings
print("render size:\(rndrconf.width),\(rndrconf.height)")
print("tile size:\(rndrconf.tileSize)")
print("save as:\(rndrconf.outputImage)")

// Sampling settings
print("Sub samples:\(rndrconf.pixelSubSamples)")
print("Samples per pixel:\(rndrconf.samplesPerPixel)")
print("Total samples per pixel:\(rndrconf.pixelSubSamples * rndrconf.pixelSubSamples * rndrconf.samplesPerPixel)")

print("Trace depth min:\(rndrconf.minDepth) max:\(rndrconf.maxDepth)(Max is not work now)")

// Setup scene
let scene = Scene()
// scene load ...

//+++++
//BuildCornelBoxScene(scene)
//BuildMeshCornelBoxScene(scene)
BuildTestScene01(scene)
//+++++

// Preprocess
scene.renderPreprocess(Random(seed:UInt64(time(nil))))

// override camera settings
scene.camera.resizeSensorWithAspectRatio(rndrconf.aspect)
print("camera sensor size:(\(scene.camera.sensorWidth), \(scene.camera.sensorHeight))")
print("camera focul length:\(scene.camera.foculLength)")

//
var imageBuffer = Array<Pixel>()
imageBuffer.reserveCapacity(rndrconf.width * rndrconf.height)
for _ in 0..<(rndrconf.width * rndrconf.height) {
    imageBuffer.append(Pixel())
}

//
func pathtrace(_ nx:Double, _ ny:Double, _ scene:Scene, _ rng:Random) -> (Vector3, Int) {
    // Start ray tracing
    //var ray = scene.camera.ray(u: nx, v: ny, fov: kFOV, aspect: kAspect)
    var ray = scene.camera.ray(nx, ny, rng)
    
    var throughput = Vector3(1.0, 1.0, 1.0)
    var radiance = Vector3(0.0, 0.0, 0.0)
    
    var depth = 0
    while true {
        // Get next intersection point
        let (ishit, pv) = scene.raytrace(ray, 1e-4, kFarAway)
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
        // if (not light) || depth < 1
        radiance += Vector3.mul(throughput, mat.Ke)
        
        // current point can do light sample?
        if depth > 0 {
            // do light sample
        }
        
        // update from next material infomation
        
        // Sample next direction
        //let normal = (Vector3.dot(-ray.direction, pv.surface.shadingNormal) > 0.0) ? pv.surface.shadingNormal : -pv.surface.shadingNormal
        let (nxtRay, rayPdf, bsdfId) = mat.sampleNext(pv, rng)
        
        // throughput
        let ndotl = Vector3.dot(pv.surface.shadingNormal, nxtRay.direction)
        let (bsdf, bsdfPdf) = mat.bsdf(bsdfId, pv, nxtRay)
        throughput = Vector3.mul(throughput, mat.Kd * bsdf * abs(ndotl) / (rayPdf * bsdfPdf))
        
        // new ray
        ray = nxtRay
        
        // Russian roulette
        if depth > rndrconf.minDepth {
            //let c = throughput.maxMagnitude()
            let c = (throughput.x + throughput.y + throughput.z) / 3.0
            let q = max(rndrconf.minRRCutOff, 1.0 - c)
            if rng.nextDoubleCO() < q {
                break
            }
            throughput = throughput / (1.0 - q)
        }
        
        // Update depth
        depth += 1
//        if depth > kMaxDepth {
//            // Biased Kill!
//            break
//        }
        
        //+++++
        //radiance = Vector3(1.0, 1.0, 1.0)
        // normal
//        radiance = pv.surface.geometryNormal * 0.5 + Vector3(0.5, 0.5, 0.5)
//        break
        //radiance = mat.Kd
        //break
        //+++++
    }
    
    return (radiance, depth)
}

// Image buckets array
let imageTiles = ImageFragments.makeTileArray(rndrconf.width, rndrconf.height, rndrconf.tileSize, rndrconf.tileSize)
print("tiles:\(imageTiles.count)")

// Render
let startTime = getTimeInSeconds()
print("Start rendering")

let dq = DispatchQueue.global()
let dg = DispatchGroup()

dq.async(group: dg) {
    
    let seedBase = UInt64(time(nil))
    
    DispatchQueue.concurrentPerform(iterations: imageTiles.count) { (itile) in
    //for itile in 0..<tiles.count {
        let tile = imageTiles[itile]
        let rng = Random(seed:seedBase + UInt64(itile))
        var maxDepth = 0
        var minDepth = Int.max
        var avrDepth = 0
        var avrCount = 0

        for ipi in 0..<tile.pixelIndices.count {
            let findx = tile.pixelIndices[ipi]
            let pixel = imageBuffer[findx.x + findx.y * rndrconf.width]
            let px = Double(findx.x)
            let py = Double(findx.y)
            
            for suby in 0..<rndrconf.pixelSubSamples {
                for subx in 0..<rndrconf.pixelSubSamples {
                    for _ in 0..<rndrconf.samplesPerPixel {
                        let sx = px + (Double(subx) + rng.nextDoubleCO()) / Double(rndrconf.pixelSubSamples)
                        let sy = py + (Double(suby) + rng.nextDoubleCO()) / Double(rndrconf.pixelSubSamples)
                        
                        // ([0,w),[0,h)) -> ([-1,1),[-1,1))
                        let nx = sx / Double(rndrconf.width) * 2.0 - 1.0
                        let ny = sy / Double(rndrconf.height) * 2.0 - 1.0
                        
                        let (radiance, depth) = pathtrace(nx, ny, scene, rng)
                        
                        // Depth info
                        if depth > 0 {
                            maxDepth = max(maxDepth, depth)
                            minDepth = min(minDepth, depth)
                            avrDepth += depth
                            avrCount += 1
                        }
                        
                        // Accumulate
                        pixel.accumulate(radiance)
                    }
                }
            }
        }
        
        var msg = "tile \(itile) done."
        msg += " fragments:\(tile.pixelIndices.count)"
        if avrCount > 0 {
            msg += " depth:{min:\(minDepth), max:\(maxDepth), average:\(Double(avrDepth)/Double(avrCount))}"
        } else {
            msg += " no valid depth."
        }
        print(msg)
    }
}

print("wait to finish...")
dg.wait()

print("finish render")
let endTime = getTimeInSeconds()
print("render time:\(endTime - startTime)[sec]")

// Output
if rndrconf.outputImage.count > 0 {
    print("save image")
    let f = fopen(rndrconf.outputImage, "wb")
    fputs("P3\n", f)
    fputs("\(rndrconf.width) \(rndrconf.height)\n", f)
    fputs("255\n", f)
    
    func tosRGB8(_ c:Double) -> Int {
        let kGamma = 2.2
        if c < 0.0 {
            print("! negative radiance:\(c)")
            return 0
        }
        let gc = pow(c, 1.0 / kGamma)
        return Int(max(min(gc * 255.0, 255.0), 0.0))
    }
    
    // rendered image is 180 degree rotated
    for y in 0..<rndrconf.height {
        //let h = (kHeight - y - 1) * kWidth
        for x in 0..<rndrconf.width {
            //let i = x + h
            let i = (rndrconf.width - x - 1) + y * rndrconf.width
            let (r, g, b) = imageBuffer[i].rgb()
            fputs("\(tosRGB8(r)) \(tosRGB8(g)) \(tosRGB8(b))\n", f)
        }
    }
    fclose(f)
}
