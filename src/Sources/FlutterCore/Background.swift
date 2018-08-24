#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class Background {
    public var texture:Texture
    public var transform:Matrix4
    
    public init() {
        texture = ConstantColor(Vector3(0.2, 0.2, 0.2))
        transform = Matrix4()
    }
    
    public init(_ tex:Texture, _ m:Matrix4=Matrix4()) {
        texture = tex
        transform = m
    }
    
    public func sample(_ ray:Ray) -> Vector3 {
        let dir = Vector3.normalized(Matrix4.mulV3(transform, ray.direction))
        let uv = Vector3(
            (atan2(dir.x, -dir.z) / Double.pi + 1.0) * 0.5,
            acos(max(min(dir.z, 1.0), -1.0)) / Double.pi * 0.5,
            0.0
        )
        return texture.sample(uv)
    }
}

