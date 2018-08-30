#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra

public class CameraNode {
    public var transform:Matrix4
    public var rayTransform:Matrix4
    
    public var sensorWidth:Double     = 36.0  // [mm]
    public var sensorHeight:Double    = 24.0  // [mm]
    public var foculLength:Double     = 28.0  // [mm]
    public var fNumber:Double         = 0.0
    public var focusDistance:Double   = 1.0   // [m]
    
    public var sensorAspectRatio:Double {
        return sensorWidth / sensorHeight
    }
    
    public init() {
        transform = Matrix4()
        rayTransform = Matrix4()
    }
    
    public init(position:Vector3, look:Vector3, up:Vector3=Vector3(0.0, 1.0, 0.0)) {
        transform = Matrix4()
        rayTransform = Matrix4()
        lookAt(eye:position, look:look, up:up)
    }
    
    public func lookAt(eye:Vector3, look:Vector3, up:Vector3=Vector3(0.0, 1.0, 0.0)) {
        transform = Matrix4.makeLookAt(eye, look, up)
        _ = transform.invert()
    }
    
    public func setTransform(_ m:Matrix4) {
        transform = m
    }
    
    public func setSensorSize(width:Double, height:Double) {
        sensorWidth = width
        sensorHeight = height
    }
    
    // aspect:=w/h
    public func setSensorSizeWithAspectRatio(width:Double, aspect:Double) {
        sensorWidth = width
        sensorHeight = width / aspect
    }
    
    public func resizeSensorWithAspectRatio(_ aspect:Double) {
        sensorHeight = sensorWidth / aspect
    }
    
    public func setFoculLength(_ fl:Double) {
        foculLength = fl
    }
    
    // fov : virtical angle [rad]
    public func setFoculLengthWithFOV(_ fov:Double) {
        foculLength = sensorHeight * 0.5 / tan(fov * 0.5)
    }
    
    public func setFNumber(_ fn:Double) {
        fNumber = fn
    }
    
    public func setFocusDistance(_ fd:Double) {
        focusDistance = fd
    }
    
//    public func ray(u:Double, v:Double, fov:Double, aspect:Double) -> Ray {
//        // u,v expects [-1,1]
//        // fov is vertical angle [rad]
//        // aspect is w/h
//        let z = -1.0 / tan(fov * 0.5)
//        let d = Vector3.normalized(Vector3(u * aspect, v, z))
//        let eye = Vector3(0.0, 0.0, 0.0)
//
//        return Ray(
//            Matrix4.transformV3(rayTransform, eye),
//            Matrix4.mulV3(rayTransform, d)
//        )
//    }
    
    public func renderPreprocess(_ rng:Random) {
//        rayTransform = Matrix4.inverted(transform).result
        rayTransform = transform
    }
    
    // u,v : [-1,1]
    public func ray(_ u:Double, _ v:Double, _ rng:Random) -> Ray {
        // A position on the sensor [mm]
        let sp = Vector3(
            sensorWidth * 0.5 * u,
            sensorHeight * 0.5 * v,
            foculLength
        )
        
        // aperture position [mm]
        let ap:Vector3
        if fNumber > 0.0 {
            // TODO
            ap = Vector3(0.0, 0.0, 0.0)
        } else {
            // Pinhole
            ap = Vector3(0.0, 0.0, 0.0)
        }
        
        // direction
        let d = Vector3.normalized(ap - sp)
        
        return Ray(
            Matrix4.transformV3(rayTransform, ap),
            Matrix4.mulV3(rayTransform, d)
        )
    }
    
}
