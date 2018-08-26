import XCTest

@testable import FlutterCore
import LinearAlgebra

final class TextureTests: XCTestCase {
    
    func testClampBorder() {
        var x0:Int
        var x1:Int
        var t:Double
        
        // clamp
        (x0, x1, t) = BufferTexture.edgeClamp(0.0, 256)
        XCTAssertEqual(x0, 0)
        XCTAssertEqual(x1, 1)
        XCTAssertEqual(t, 0.0)
        
        (x0, x1, t) = BufferTexture.edgeClamp(128.25, 256)
        XCTAssertEqual(x0, 128)
        XCTAssertEqual(x1, 129)
        XCTAssertEqual(t, 0.25)
        
        (x0, x1, t) = BufferTexture.edgeClamp(255.0, 256)
        XCTAssertEqual(x0, 255)
        XCTAssertEqual(x1, 255)
        //XCTAssertEqual(t, 1.0)
        
        (x0, x1, t) = BufferTexture.edgeClamp(-2.5, 256)
        XCTAssertEqual(x0, 0)
        XCTAssertEqual(x1, 0)
        //XCTAssertEqual(t, 0.0)
        
        (x0, x1, t) = BufferTexture.edgeClamp(258.25, 256)
        XCTAssertEqual(x0, 255)
        XCTAssertEqual(x1, 255)
        //XCTAssertEqual(t, 0.0)
    }
    
    func testRepeatBorder() {
        var x0:Int
        var x1:Int
        var t:Double
        
        // clamp
        (x0, x1, t) = BufferTexture.edgeRepeat(0.0, 256)
        XCTAssertEqual(x0, 0)
        XCTAssertEqual(x1, 1)
        XCTAssertEqual(t, 0.0)
        
        (x0, x1, t) = BufferTexture.edgeRepeat(128.25, 256)
        XCTAssertEqual(x0, 128)
        XCTAssertEqual(x1, 129)
        XCTAssertEqual(t, 0.25)
        
        (x0, x1, t) = BufferTexture.edgeRepeat(255.0, 256)
        XCTAssertEqual(x0, 255)
        XCTAssertEqual(x1, 0)
        XCTAssertEqual(t, 0.0)
        
        (x0, x1, t) = BufferTexture.edgeRepeat(-2.5, 256)
        XCTAssertEqual(x0, 253)
        XCTAssertEqual(x1, 254)
        XCTAssertEqual(t, 0.5)
        
        (x0, x1, t) = BufferTexture.edgeRepeat(258.25, 256)
        XCTAssertEqual(x0, 2)
        XCTAssertEqual(x1, 3)
        XCTAssertEqual(t, 0.25)
        
    }
    
    func testBufferSample() {
        let buf:[Double] = [
            0.0, 0.0, 0.0, 1.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0, 0.0, 1.0
        ]
        let tex = BufferTexture(2, 2, 3, buf)
        
        var c:Vector3
        
        // Test Repeat
        tex.setUWrapMode(.kRepeat)
        tex.setVWrapMode(.kRepeat)
        
        c = tex.sample(Vector3(0.0, 0.0, 0.0))
        XCTAssertEqual(c.x, 0.25, accuracy:1e-6)
        XCTAssertEqual(c.y, 0.25, accuracy:1e-6)
        XCTAssertEqual(c.z, 0.25, accuracy:1e-6)
        
        c = tex.sample(Vector3(0.25, 0.25, 0.0))
        XCTAssertEqual(c.x, 0.0, accuracy:1e-6)
        XCTAssertEqual(c.y, 0.0, accuracy:1e-6)
        XCTAssertEqual(c.z, 0.0, accuracy:1e-6)
        
        c = tex.sample(Vector3(0.5, 0.5, 0.0))
        XCTAssertEqual(c.x, 0.25, accuracy:1e-6)
        XCTAssertEqual(c.y, 0.25, accuracy:1e-6)
        XCTAssertEqual(c.z, 0.25, accuracy:1e-6)
        
        c = tex.sample(Vector3(0.75, 0.75, 0.0))
        XCTAssertEqual(c.x, 0.0, accuracy:1e-6)
        XCTAssertEqual(c.y, 0.0, accuracy:1e-6)
        XCTAssertEqual(c.z, 1.0, accuracy:1e-6)
        
        c = tex.sample(Vector3(1.0, 1.0, 0.0))
        XCTAssertEqual(c.x, 0.25, accuracy:1e-6)
        XCTAssertEqual(c.y, 0.25, accuracy:1e-6)
        XCTAssertEqual(c.z, 0.25, accuracy:1e-6)
        
        // Test Clamp
        tex.setUWrapMode(.kClamp)
        tex.setVWrapMode(.kClamp)
        
        c = tex.sample(Vector3(0.0, 0.0, 0.0))
        XCTAssertEqual(c.x, 0.0, accuracy:1e-6)
        XCTAssertEqual(c.y, 0.0, accuracy:1e-6)
        XCTAssertEqual(c.z, 0.0, accuracy:1e-6)
        
        c = tex.sample(Vector3(0.25, 0.25, 0.0))
        XCTAssertEqual(c.x, 0.0, accuracy:1e-6)
        XCTAssertEqual(c.y, 0.0, accuracy:1e-6)
        XCTAssertEqual(c.z, 0.0, accuracy:1e-6)
        
        c = tex.sample(Vector3(0.5, 0.5, 0.0))
        XCTAssertEqual(c.x, 0.25, accuracy:1e-6)
        XCTAssertEqual(c.y, 0.25, accuracy:1e-6)
        XCTAssertEqual(c.z, 0.25, accuracy:1e-6)
        
        c = tex.sample(Vector3(0.75, 0.75, 0.0))
        XCTAssertEqual(c.x, 0.0, accuracy:1e-6)
        XCTAssertEqual(c.y, 0.0, accuracy:1e-6)
        XCTAssertEqual(c.z, 1.0, accuracy:1e-6)
        
        c = tex.sample(Vector3(1.0, 1.0, 0.0))
        XCTAssertEqual(c.x, 0.0, accuracy:1e-6)
        XCTAssertEqual(c.y, 0.0, accuracy:1e-6)
        XCTAssertEqual(c.z, 1.0, accuracy:1e-6)
        
        c = tex.sample(Vector3(0.5, 0.0, 0.0))
        XCTAssertEqual(c.x, 0.5, accuracy:1e-6)
        XCTAssertEqual(c.y, 0.0, accuracy:1e-6)
        XCTAssertEqual(c.z, 0.0, accuracy:1e-6)
        
        c = tex.sample(Vector3(0.0, 0.5, 0.0))
        XCTAssertEqual(c.x, 0.0, accuracy:1e-6)
        XCTAssertEqual(c.y, 0.5, accuracy:1e-6)
        XCTAssertEqual(c.z, 0.0, accuracy:1e-6)
    }
    
    static var allTests = [
        ("testClampBorder", testClampBorder),
        ("testRepeatBorder", testRepeatBorder),
    ]
}
