#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class ImageData {
    public var width:Int
    public var height:Int
    public var components:Int
    public var buffer:[Double]
    
    public init(_ w:Int, _ h:Int, _ c:Int) {
        width = w
        height = h
        components = c
        buffer = Array<Double>(repeating: 0.0, count: width * height * components)
    }
}
