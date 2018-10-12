#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra
import STB

public class STBImageTexture : BufferTexture {
    public let sourcePath:String
    
    public init(filepath:String, flip:Bool=true) throws {
        let imgparams = UnsafeMutablePointer<Int32>.allocate(capacity: 4)
        if flip {
            stbi_set_flip_vertically_on_load(1)
        }
        guard let rawbuf = STB.stbi_loadf(filepath, imgparams, imgparams + 1, imgparams + 2, 0) else {
            print("ImageTexture \(filepath) load failed.")
            throw ImageTextureError.loadFailed
        }
        
        let srcW = Int(imgparams[0])
        let srcH = Int(imgparams[1])
        let srcCh = Int(imgparams[2])
        let srcLength = srcW * srcH * srcCh
        
        var buf = Array<Double>(repeating: 0.0, count: srcLength)
        for i in 0..<srcLength {
            buf[i] = Double(rawbuf[i])
        }
        
        imgparams.deallocate()
        rawbuf.deallocate()
        
        sourcePath = filepath
        
        super.init(srcW, srcH, srcCh, buf)
    }
}
