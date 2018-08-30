import XCTest

@testable import FlutterCore
import LinearAlgebra

final class AABBTests: XCTestCase {
    
    func testIntersection() {
        let aabb = AABB(min:Vector3(-1.0, -1.0, -1.0), max:Vector3(1.0, 1.0, 1.0))
        
        func rayHitCheck(_ o:Vector3, _ d:Vector3) -> Bool {
            let ray = Ray(o, Vector3.normalized(d))
            return aabb.isIntersect(ray, 1e-4, 1e10)
        }
        
        var b:Bool
        
        b = rayHitCheck(
            Vector3(0.0, 0.0, 5.0),
            Vector3(0.0, 0.0, -1.0)
        )
        XCTAssertEqual(b, true)
        
        b = rayHitCheck(
            Vector3(0.0, 0.0, 0.5),
            Vector3(0.0, 0.0, -1.0)
        )
        XCTAssertEqual(b, true)
        
        
        b = rayHitCheck(
            Vector3(0.0, 0.0, 10.0),
            Vector3(1.0, 1.0, 1.0 - 10.0)
        )
        XCTAssertEqual(b, true)
        
        b = rayHitCheck(
            Vector3(0.0, 0.0, 5.0),
            Vector3(0.0, 0.0, 1.0)
        )
        XCTAssertEqual(b, false)
        
        b = rayHitCheck(
            Vector3(0.0, 0.0, 5.0),
            Vector3(0.0, 0.5, 0.5)
        )
        XCTAssertEqual(b, false)
        
    }
    
    func testThinIntersection() {
        let aabb = AABB(min:Vector3(-0.5, -0.5, 0.5), max:Vector3(0.5, 0.5, 0.5))
        
        var ishit:Bool
        var ray:Ray
        
        ray = Ray(Vector3(0.0, 0.0, 5.0), Vector3(0.0, 0.0, -1.0))
        ishit = aabb.isIntersect(ray, 1e-4, 1e10)
        XCTAssertTrue(ishit)
    }
    
    static var allTests = [
        ("testIntersection", testIntersection),
        ("testThinIntersection", testThinIntersection),
    ]
}
