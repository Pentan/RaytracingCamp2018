import XCTest
import class Foundation.Bundle

import STB

final class stb_image_Tests: XCTestCase {
    
//    func testExample() throws {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct
//        // results.
//
//        // Some of the APIs that we use below are available in macOS 10.13 and above.
//        guard #available(macOS 10.13, *) else {
//            return
//        }
//
//        let fooBinary = productsDirectory.appendingPathComponent("STBTest")
//
//        let process = Process()
//        process.executableURL = fooBinary
//
//        let pipe = Pipe()
//        process.standardOutput = pipe
//
//        try process.run()
//        process.waitUntilExit()
//
//        let data = pipe.fileHandleForReading.readDataToEndOfFile()
//        let output = String(data: data, encoding: .utf8)
//
//        XCTAssertEqual(output, "Hello, world!\n")
//    }
//
//    /// Returns path to the built products directory.
//    var productsDirectory: URL {
//      #if os(macOS)
//        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
//            return bundle.bundleURL.deletingLastPathComponent()
//        }
//        fatalError("couldn't find the products directory")
//      #else
//        return Bundle.main.bundleURL
//      #endif
//    }

    func testLoadPNG32() {
        let path = testDataDir() + "png32.png"
        let prms = UnsafeMutablePointer<Int32>.allocate(capacity: 4)
        if let img = stbi_load(path, prms, prms + 1, prms + 2, 4) {
            XCTAssertEqual(prms[0], 16)
            XCTAssertEqual(prms[1], 16)
            XCTAssertEqual(prms[2], 4)
            
            var tmp:UnsafeMutablePointer<stbi_uc>
            
            tmp = img
            XCTAssertEqual(tmp[0], 0)
            XCTAssertEqual(tmp[1], 0)
            XCTAssertEqual(tmp[2], 0)
            XCTAssertEqual(tmp[3], 255)
            
            tmp = img + 4 * 4
            XCTAssertEqual(tmp[0], 64)
            XCTAssertEqual(tmp[1], 64)
            XCTAssertEqual(tmp[2], 64)
            XCTAssertEqual(tmp[3], 255)
            
            tmp = img + 8 * 4
            XCTAssertEqual(tmp[0], 128)
            XCTAssertEqual(tmp[1], 128)
            XCTAssertEqual(tmp[2], 128)
            XCTAssertEqual(tmp[3], 255)
            
            tmp = img + 12 * 4
            XCTAssertEqual(tmp[0], 192)
            XCTAssertEqual(tmp[1], 192)
            XCTAssertEqual(tmp[2], 192)
            XCTAssertEqual(tmp[3], 255)
            
            tmp = img + 16 * 4 * 4
            XCTAssertEqual(tmp[0], 255)
            XCTAssertEqual(tmp[1], 0)
            XCTAssertEqual(tmp[2], 0)
            XCTAssertEqual(tmp[3], 255)
            
            tmp = img + (16 * 16 + 0) * 4
            XCTAssertEqual(tmp[3], 0)
            
            tmp = img + (16 * 16 + 4) * 4
            XCTAssertEqual(tmp[3], 0)
            
            tmp = img + (16 * 16 + 8) * 4
            XCTAssertEqual(tmp[3], 0)
            
            tmp = img + (16 * 16 + 12) * 4
            XCTAssertEqual(tmp[3], 0)
            
            img.deallocate()
        }
        prms.deallocate()
    }
    
    func testLoadPNG24() {
        let path = testDataDir() + "png24.png"
        let prms = UnsafeMutablePointer<Int32>.allocate(capacity: 4)
        if let img = stbi_load(path, prms, prms + 1, prms + 2, 3) {
            XCTAssertEqual(prms[0], 16)
            XCTAssertEqual(prms[1], 16)
            XCTAssertEqual(prms[2], 3)
            
            var tmp:UnsafeMutablePointer<stbi_uc>
            
            tmp = img
            XCTAssertEqual(tmp[0], 0)
            XCTAssertEqual(tmp[1], 0)
            XCTAssertEqual(tmp[2], 0)
            
            tmp = img + 4 * 3
            XCTAssertEqual(tmp[0], 64)
            XCTAssertEqual(tmp[1], 64)
            XCTAssertEqual(tmp[2], 64)
            
            tmp = img + 8 * 3
            XCTAssertEqual(tmp[0], 128)
            XCTAssertEqual(tmp[1], 128)
            XCTAssertEqual(tmp[2], 128)
            
            tmp = img + 12 * 3
            XCTAssertEqual(tmp[0], 192)
            XCTAssertEqual(tmp[1], 192)
            XCTAssertEqual(tmp[2], 192)
            
            tmp = img + 16 * 4 * 3
            XCTAssertEqual(tmp[0], 255)
            XCTAssertEqual(tmp[1], 0)
            XCTAssertEqual(tmp[2], 0)
            
            img.deallocate()
        }
        prms.deallocate()
    }
    
    internal func testDataDir() -> String {
        return NSHomeDirectory() + "/RC2018TestData/"
    }
    
    static var allTests = [
//        ("testExample", testExample),
        ("testLoadPNG32", testLoadPNG32),
        ("testLoadPNG24", testLoadPNG24)
    ]
}
