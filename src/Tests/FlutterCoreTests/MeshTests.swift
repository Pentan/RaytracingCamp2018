import XCTest

@testable import FlutterCore
import LinearAlgebra

final class MeshTests: XCTestCase {
    
    func testTriangleIntersection() {
        let mesh = Mesh()
        
        mesh.addVertexAndNormal(Vector3( 0.0,  1.0, 0.0), Vector3(0.0, 0.0, 1.0))
        mesh.addVertexAndNormal(Vector3(-0.866, -0.5, 0.0), Vector3(0.0, 0.0, 1.0))
        mesh.addVertexAndNormal(Vector3( 0.866, -0.5, 0.0), Vector3(0.0, 0.0, 1.0))
        mesh.addFace(0, 1, 2)
        mesh.renderPreprocess(Random())
        
        let tri = mesh.faces[0]
        
        let ray = Ray(Vector3(0.0, 0.0, 1.0), Vector3(0.0, 0.0, -1.0))
        var ishit:Bool
        
        ishit = tri.aabb.isIntersect(ray, 0.0, 1e10)
        XCTAssertTrue(ishit, "Triangle bounds test failed")
        
        (ishit, _, _, _) = tri.intersection(ray, 0.0, 1e10)
        XCTAssertTrue(ishit, "Triangle test failed")
    }
    
    func testMeshIntersection() {
        let mesh = Mesh()
        
        mesh.addVertexAndNormal(Vector3( 0.0,  1.0, 0.0), Vector3(0.0, 0.0, 1.0))
        mesh.addVertexAndNormal(Vector3( 0.866, -0.5, 0.0), Vector3(0.0, 0.0, 1.0))
        mesh.addVertexAndNormal(Vector3(-0.866, -0.5, 0.0), Vector3(0.0, 0.0, 1.0))
        mesh.addFace(0, 1, 2)
        mesh.renderPreprocess(Random())
        
        let ray = Ray(Vector3(0.0, 0.0, 1.0), Vector3(0.0, 0.0, -1.0))
        
        let (hit, d, i) = mesh.intersection(ray, 0.0, 1e10)
        XCTAssertTrue(hit)
    }
    
    static var allTests = [
        ("testTriangleIntersection", testTriangleIntersection),
        ("testMeshIntersection", testMeshIntersection),
    ]
}
