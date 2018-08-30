import XCTest

@testable import FlutterCore
import LinearAlgebra

final class GLTFTests: XCTestCase {

    func testParseJSON() {
        let gltf0 = """
{
    "accessors" : [
        {
            "bufferView" : 0,
            "componentType" : 5121,
            "count" : 6,
            "max" : [
                3
            ],
            "min" : [
                0
            ],
            "type" : "SCALAR"
        },
        {
            "bufferView" : 1,
            "componentType" : 5126,
            "count" : 4,
            "max" : [
                1.0,
                0.0,
                1.0
            ],
            "min" : [
                -1.0,
                0.0,
                -1.0
            ],
            "type" : "VEC3"
        },
        {
            "bufferView" : 2,
            "componentType" : 5126,
            "count" : 4,
            "max" : [
                0.0,
                1.0,
                -0.0
            ],
            "min" : [
                0.0,
                1.0,
                -0.0
            ],
            "type" : "VEC3"
        }
    ],
    "asset" : {
        "generator" : "Khronos Blender glTF 2.0 exporter",
        "version" : "2.0"
    },
    "bufferViews" : [
        {
            "buffer" : 0,
            "byteLength" : 6,
            "byteOffset" : 0,
            "target" : 34963
        },
        {
            "buffer" : 0,
            "byteLength" : 48,
            "byteOffset" : 8,
            "target" : 34962
        },
        {
            "buffer" : 0,
            "byteLength" : 48,
            "byteOffset" : 56,
            "target" : 34962
        }
    ],
    "buffers" : [
        {
            "byteLength" : 104,
            "uri" : "untitled03.bin"
        }
    ],
    "materials" : [
        {
            "name" : "Material",
            "pbrMetallicRoughness" : {
                "baseColorFactor" : [
                    0.6400000190734865,
                    0.6400000190734865,
                    0.6400000190734865,
                    1.0
                ],
                "metallicFactor" : 0.0
            }
        }
    ],
    "meshes" : [
        {
            "name" : "Plane",
            "primitives" : [
                {
                    "attributes" : {
                        "NORMAL" : 2,
                        "POSITION" : 1
                    },
                    "indices" : 0,
                    "material" : 0
                }
            ]
        }
    ],
    "nodes" : [
        {
            "mesh" : 0,
            "name" : "Plane"
        }
    ],
    "scene" : 0,
    "scenes" : [
        {
            "name" : "Scene",
            "nodes" : [
                0
            ]
        }
    ]
}
"""
        let gltf = try! GLTF.parseGLTF(gltf0)
        XCTAssertEqual(gltf.asset.version, "2.0")
    }
    
    func testLoadGLTF() {
        let datadir = NSHomeDirectory() + "/RC2018TestData/"
        let path = datadir + "SPTest.gltf"
//        let path = datadir + "untitled02.gltf"
        let gltf = try! GLTF.load(path)
        XCTAssertEqual(gltf.asset.version, "2.0")
    }
    
    func testSceneBuild() {
        let datadir = NSHomeDirectory() + "/RC2018TestData/"
//        let path = datadir + "SPTest.gltf"
        let path = datadir + "untitled03.gltf"
        let scene = SceneBuilder.sceneFromGLTF(path)!
        
        XCTAssertEqual(scene.objectNodes.count, 1)
    }
    
    static var allTests = [
        ("testParseJSON", testParseJSON),
        ("testLoadGLTF", testLoadGLTF),
    ]
}
