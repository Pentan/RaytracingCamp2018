import XCTest

@testable import FlutterCore
import LinearAlgebra

final class AABBTests: XCTestCase {
    
    func testIntersection() {
        let aabb = AABB(min:Vector3(-0.5, -0.5, -0.5), max:Vector3(0.5, 0.5, 0.5))
        
        func rayHitCheck(_ o:Vector3, _ d:Vector3) {
            let ray = Ray(o, d)
            let ishit = aabb.isIntersect(ray, 1e-4, 1e10)
            XCTAssert(ishit)
        }
        
        rayHitCheck(
            Vector3(0.0, 0.0, 5.0),
            Vector3(0.0, 0.0, -1.0)
        )
        rayHitCheck(
            Vector3(0.0, 0.0, 0.5),
            Vector3(0.0, 0.0, -1.0)
        )
        
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
