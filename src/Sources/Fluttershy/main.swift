#if os(OSX)
import Darwin
#else
import Glibc
#endif

import Dispatch
import LinearAlgebra
import FlutterCore

// Utility
public func getTimeInSeconds() -> Double {
    let timeval = UnsafeMutablePointer<timeval>.allocate(capacity: 1)
    gettimeofday(timeval, nil)
    return Double(timeval.pointee.tv_sec) + Double(timeval.pointee.tv_usec) * 1e-6
}

// Main Routine
print("=== Fluttershy ===")
let startTime = getTimeInSeconds()

// Render settings
var rndrconf = RenderConfig()
rndrconf.loadOptionFile("data/options.json")

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
//+++++
//let scene = Scene()
////BuildCornelBoxScene(scene)
////BuildMeshCornelBoxScene(scene)
////BuildTestScene01(scene)
//BuildTestScene02(scene)
//+++++

// scene load ...
//let sceneFilePath = "/Users/satoru/Documents/_Working/GitRepos/RaytracingCamp2018/local_datas/Model/Blender/export/test02.gltf"
//guard let scene = SceneBuilder.sceneFromGLTF(sceneFilePath) else {
//    print("Scene load failure")
//    exit(0)
//}

let scene:Scene
if rndrconf.inputFile.isEmpty {
    print("No input file. render default scene.")
    scene = Scene()
    BuildMeshCornelBoxScene(scene)
    
} else {
    guard let scn = SceneBuilder.sceneFromGLTF(rndrconf.inputFile) else {
        print("Scene load failure")
        exit(0)
    }
    scene = scn
}

// Preprocess
scene.renderPreprocess(Random(seed:UInt64(time(nil))))

// override camera settings
if abs(rndrconf.aspect - scene.camera.sensorAspectRatio) > 1e-6 {
    print("!WARNING! Aspect ratio is different.")
    print(" camera:\(scene.camera.sensorAspectRatio)")
    print(" config:\(rndrconf.aspect)")
    print("camera aspect ratio changed.")
    
    scene.camera.resizeSensorWithAspectRatio(rndrconf.aspect)
    print("camera sensor size:(\(scene.camera.sensorWidth), \(scene.camera.sensorHeight))")
    print("camera focul length:\(scene.camera.foculLength)")
}

//
func makePixelArray(_ len:Int) -> [Pixel] {
    var ary = Array<Pixel>()
    ary.reserveCapacity(len)
    for _ in 0..<len {
        ary.append(Pixel())
    }
    return ary
}
let imageBuffer = makePixelArray(rndrconf.width * rndrconf.height)

//
func saveImage(_ path:String) {
    var snapshot = Array<Vector3>()
    snapshot.reserveCapacity(rndrconf.width * rndrconf.height)
    
    for y in (0..<rndrconf.height).reversed() {
        for x in (0..<rndrconf.width).reversed() {
            let i = x + y * rndrconf.width
            let (r, g, b) = imageBuffer[i].rgb()
            snapshot.append(Vector3(r, g, b))
        }
    }
    
    let w = Int32(rndrconf.width)
    let h = Int32(rndrconf.height)
    ImageWriter.writeBMP(filepath: path, width: w, height: h, data: snapshot, gamma: 2.2)
}

//
let render = PathTracer()
render.minDepth = rndrconf.minDepth
render.minRRCutOff = rndrconf.minRRCutOff

// Image buckets array
let imageTiles = ImageFragments.makeTileArray(rndrconf.width, rndrconf.height, rndrconf.tileSize, rndrconf.tileSize)
print("Tiles:\(imageTiles.count)")

// Render
print("Setup done: \(getTimeInSeconds() - startTime) [sec]")
print("Start rendering")

let dq = DispatchQueue.global()
let dg = DispatchGroup()

var progTimer:DispatchSourceTimer?
if !rndrconf.quietProgress {
    progTimer = DispatchSource.makeTimerSource()
    
    let interval = rndrconf.progressInterval
    let microleeway = DispatchTimeInterval.microseconds(Int(1000000.0))
    let deadline = DispatchTime.now() + interval
    
    progTimer?.schedule(deadline: deadline, repeating: interval, leeway: microleeway)
    
    var outputCount = 0
    progTimer?.setEventHandler(handler: DispatchWorkItem(block: {
        let cntstr = String(outputCount)
        var namebase = "00000"
        namebase.removeLast(cntstr.count)
        let outname = "\(namebase)\(cntstr).bmp"
        
        print("save progress image \(outname)")
        saveImage(outname)
        outputCount += 1
    }))
    progTimer?.resume()
}

var vorbTimer = DispatchSource.makeTimerSource()
vorbTimer.schedule(deadline: DispatchTime.now() + 1.0, repeating: 1.0)
vorbTimer.setEventHandler {
    let total = imageTiles.count
    var standby = 0
    var processing = 0
    var done = 0
    for i in 0..<total {
        let tile = imageTiles[i]
        switch tile.state {
        case .kStandBy:
            standby += 1
        case .kProcessing:
            processing += 1
        case .kDone:
            done += 1
        }
    }
    print("\rstandby:\(standby),processing:\(processing),done:\(done)/\(total)     ", terminator:"")
    fflush(stdout)
}
vorbTimer.resume()

let timeoutTime = DispatchWallTime.now() + rndrconf.timeLimit
var pastTime:Double = 0.0
repeat {
    dq.async(group: dg) {
        
        let seedBase = UInt64(time(nil))
        
        DispatchQueue.concurrentPerform(iterations: imageTiles.count) { (itile) in
//        for itile in 0..<imageTiles.count {
            let tile = imageTiles[itile]
            tile.state = .kProcessing
            
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
                            
                            let (radiance, depth) = render.pathtrace(nx, ny, scene, rng)
                            
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
            tile.state = .kDone
            
            //+++++
//            var msg = "tile \(itile) done."
//            msg += " fragments:\(tile.pixelIndices.count)"
//            if avrCount > 0 {
//                msg += " depth:{min:\(minDepth), max:\(maxDepth), average:\(Double(avrDepth)/Double(avrCount))}"
//            } else {
//                msg += " no valid depth."
//            }
//            print(msg)
            //+++++
        }
    }

    if rndrconf.waitToFinish {
        print("wait to finish...")
        dg.wait()
        pastTime = rndrconf.timeLimit
        
    } else {
        print("remain \(rndrconf.timeLimit - pastTime) seconds...")
        let waitResult = dg.wait(wallTimeout: timeoutTime)
        if waitResult == .success {
//            print("time remaining? rewind.")
            for i in 0..<imageTiles.count {
                imageTiles[i].state = .kStandBy
            }
        }
        pastTime = getTimeInSeconds() - startTime
    }
} while(pastTime < rndrconf.timeLimit)

if let tmr = progTimer {
    tmr.cancel()
}
vorbTimer.cancel()

print("finish render")
let endTime = getTimeInSeconds()
print("render time:\(endTime - startTime)[sec]")

// Output
if rndrconf.outputImage.count > 0 {
    print("save final image: \(rndrconf.outputImage)")
    saveImage(rndrconf.outputImage)
}
