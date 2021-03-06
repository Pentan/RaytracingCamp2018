#if os(OSX)
import Darwin
#else
import Glibc
#endif

public class ImageFragments {
    public enum State {
        case kStandBy
        case kProcessing
        case kDone
    }
    
    public struct Index2D {
        public var x:Int
        public var y:Int
        
        public init(_ x:Int=0, _ y:Int=0) {
            self.x = x
            self.y = y
        }
    }
    
    public var pixelIndices:[Index2D]
    public var state:State
    
    public init() {
        pixelIndices = Array<Index2D>()
        state = .kStandBy
    }
    
    public init(startX:Int, startY:Int, tileWidth:Int, tileHeight:Int, imageWidth:Int, imageHeight:Int) {
        pixelIndices = Array<Index2D>()
        for ix in 0..<tileWidth {
            let x = ix + startX
            if x >= imageWidth {
                break
            }
            
            for iy in 0..<tileHeight {
                let y = iy + startY
                if y >= imageHeight {
                    break;
                }
                
                pixelIndices.append(Index2D(x, y))
            }
        }
        state = .kStandBy
    }
    
    static public func makeTileArray(_ w:Int, _ h:Int, _ tileW:Int, _ tileH:Int) -> [ImageFragments] {
        var ret = Array<ImageFragments>()
        for ty in stride(from: 0, to: h, by: tileH) {
            for tx in stride(from: 0, to: w, by: tileW) {
                ret.append(
                    ImageFragments(
                        startX: tx, startY: ty,
                        tileWidth: tileW,
                        tileHeight: tileH,
                        imageWidth: w,
                        imageHeight: h
                    )
                )
            }
        }
        return ret
    }
    
    static public func makeScranbledArray(_ w:Int, _ h:Int, _ tileW:Int, _ tileH:Int, _ rng:Random) -> [ImageFragments] {
        let numFrags = w * h
        
        var i2dary = Array<Index2D>()
        i2dary.reserveCapacity(numFrags)
        for y in 0..<h {
            for x in 0..<w {
                i2dary.append(Index2D(x, y))
            }
        }
        
        for i in 0..<(numFrags - 1) {
            let k = i + Int(rng.nextDoubleCO() * Double(numFrags - i))
            i2dary.swapAt(i, k)
        }
        
        let numBuckets = ((w - 1) / tileW + 1) * ((h - 1) / tileH + 1)
        var ret = Array<ImageFragments>()
        ret.reserveCapacity(numBuckets)
        
        let fragPerBucket = numFrags / numBuckets
        for ibkt in 0..<numBuckets {
            let frag = ImageFragments()
            for ifpb in 0..<fragPerBucket {
                let i2d = fragPerBucket * ibkt + ifpb
                frag.pixelIndices.append(i2dary[i2d])
            }
            ret.append(frag)
        }
        
        let numUsed = fragPerBucket * numBuckets
        for i in 0..<(numFrags - numUsed) {
            ret[i].pixelIndices.append(i2dary[i + numUsed])
        }
        
        return ret
    }
}

