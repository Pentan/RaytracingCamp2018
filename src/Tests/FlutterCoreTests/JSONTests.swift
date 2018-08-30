import XCTest

@testable import FlutterCore
import LinearAlgebra

final class JSONTests: XCTestCase {
    
    func testTokenize() {
        let jp = JSON()
        
        var r:[String]
        
        r = jp.tokenize("123.45")
        XCTAssertEqual(r[0], "123.45")
        r = jp.tokenize("\"string with spaces\"")
        XCTAssertEqual(r[0], "\"string with spaces\"")
        r = jp.tokenize("\"str 'str' str\"")
        XCTAssertEqual(r[0], "\"str 'str' str\"")
        r = jp.tokenize("'str \"str\" str'")
        XCTAssertEqual(r[0], "'str \"str\" str'")
        r = jp.tokenize("\"str \\\"str\\\" \"")
        XCTAssertEqual(r[0], "\"str \\\"str\\\" \"")
        r = jp.tokenize("'str \\'str\\' str'")
        XCTAssertEqual(r[0], "'str \\'str\\' str'")
        
        let json0 = "[1, -2, 3.5, 1e-3, \"string 0\", 'string 1']"
        r = jp.tokenize(json0)
        XCTAssertEqual(r[0], "[")
        XCTAssertEqual(r[1], "1")
        XCTAssertEqual(r[2], "-2")
        XCTAssertEqual(r[3], "3.5")
        XCTAssertEqual(r[4], "1e-3")
        XCTAssertEqual(r[5], "\"string 0\"")
        XCTAssertEqual(r[6], "'string 1'")
        
        let json1 = """
        {
            "key0" : "value 0",
            "key1" : [1],
            "key2" : {"key" : 123}
        }
        """
        r = jp.tokenize(json1)
        XCTAssertEqual(r[0], "{")
        XCTAssertEqual(r[1], "\"key0\"")
        XCTAssertEqual(r[2], ":")
        XCTAssertEqual(r[3], "\"value 0\"")
        XCTAssertEqual(r[4], "\"key1\"")
        XCTAssertEqual(r[5], ":")
        XCTAssertEqual(r[6], "[")
        XCTAssertEqual(r[7], "1")
        XCTAssertEqual(r[8], "]")
        XCTAssertEqual(r[9], "\"key2\"")
        XCTAssertEqual(r[10], ":")
        XCTAssertEqual(r[11], "{")
        XCTAssertEqual(r[12], "\"key\"")
        XCTAssertEqual(r[13], ":")
        XCTAssertEqual(r[14], "123")
        XCTAssertEqual(r[15], "}")
        XCTAssertEqual(r[16], "}")
    }
    
    func testParseValue() {
        let jp = JSON()
        
        var s:String
        var n:Double
        var b:Bool
        
        s = try! jp.parseValue("\"string 0\"") as! String
        XCTAssertEqual(s, "string 0")
        
        s = try! jp.parseValue("\"string \\\" \\\\ \\/ \\n \\r\"") as! String
        XCTAssertEqual(s, "string \" \\ / \n \r")
        
        n = try! jp.parseValue("123.45") as! Double
        XCTAssertEqual(n, 123.45)
        
        n = try! jp.parseValue("-1e-2") as! Double
        XCTAssertEqual(n, -1e-2)
        
        b = try! jp.parseValue("true") as! Bool
        XCTAssertEqual(b, true)
        
        b = try! jp.parseValue("false") as! Bool
        XCTAssertEqual(b, false)
        
        s = try! jp.parseValue("\"true\"") as! String
        XCTAssertEqual(s, "true")
        
        s = try! jp.parseValue("\"false\"") as! String
        XCTAssertEqual(s, "false")
        
        s = try! jp.parseValue("null") as! String
        XCTAssertEqual(s, "")
        
        s = try! jp.parseValue("\"null\"") as! String
        XCTAssertEqual(s, "null")
    }
    
    func testParseArray() {
        let jp = JSON()
        var a:[Any]
        
        var token0 = ["[", "]"]
        a = try! jp.parseArray(&token0)
        XCTAssertEqual(a.count, 0)
        
        var token1 = ["[", "1", "\"string\"", "]"]
        a = try! jp.parseArray(&token1)
        XCTAssertEqual(a.count, 2)
        XCTAssertEqual(a[0] as! Double , 1.0)
        XCTAssertEqual(a[1] as! String, "string")
        
        var token2 = ["[", "5", "[", "10", "]", "]"]
        a = try! jp.parseArray(&token2)
        XCTAssertEqual(a.count, 2)
        XCTAssertEqual(a[0] as! Double , 5.0)
        XCTAssertEqual((a[1] as! [Any])[0] as! Double, 10.0)
    }
    
    func testParseObject() {
        let jp = JSON()
        var o:[String: Any]
        
        var token0 = ["{", "}"]
        o = try! jp.parseObject(&token0)
        XCTAssertEqual(o.count, 0)
        
        var token1 = ["{",
                      "\"key0\"", ":", "1",
                      "\"key1\"", ":", "\"string\"",
                      "}"]
        o = try! jp.parseObject(&token1)
        XCTAssertEqual(o.count, 2)
        XCTAssertEqual(o["key0"] as! Double , 1.0)
        XCTAssertEqual(o["key1"] as! String, "string")
        
        var token2 = ["{",
                      "\"key0\"", ":", "[", "1", "2", "]",
                      "\"key1\"", ":", "{",
                          "\"key1_0\"", ":", "1.0",
                          "\"key1_1\"", ":", "1.1",
                          "\"key1_2\"", ":", "1.2",
                      "}",
                      "}"]
        o = try! jp.parseObject(&token2)
        XCTAssertEqual(o.count, 2)
        XCTAssertEqual((o["key0"] as! [Any]).count, 2)
        XCTAssertEqual((o["key0"] as! [Any])[0] as! Double, 1.0)
        XCTAssertEqual((o["key1"] as! [String: Any]).count, 3)
        XCTAssertEqual((o["key1"] as! [String: Any])["key1_1"] as! Double, 1.1)
    }
    
    func testParseJSON() {
        let json = """
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
        let jp = JSON()
        let r = try! jp.parse(json)
        let jo = r as! [String: Any]
        XCTAssertEqual(jo.count, 9)
        
        let scene = jo["scene"] as! Double
        XCTAssertEqual(scene, 0.0)
        
        let mats = jo["materials"] as! [[String: Any]]
        XCTAssertEqual(mats[0]["name"] as! String, "Material")
        
        let pbr = mats[0]["pbrMetallicRoughness"] as! [String: Any]
        let bcf = pbr["baseColorFactor"] as! [Double]
        XCTAssertEqual(bcf[0], 0.6400000190734865)
        XCTAssertEqual(bcf[1], 0.6400000190734865)
        XCTAssertEqual(bcf[2], 0.6400000190734865)
        XCTAssertEqual(bcf[3], 1.0)
    }
    
    static var allTests = [
        ("testTokenize", testTokenize),
        ("testParseValue", testParseValue),
        ("testParseArray", testParseArray),
        ("testParseObject", testParseObject),
        ("testParseJSON", testParseJSON),
    ]
}
