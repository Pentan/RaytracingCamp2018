import XCTest
@testable import FlutterCore

final class RandomTests: XCTestCase {
    func testGenrand() {
        let rng = Random(seed:12345)
        
        //----- UInt64 -----
        func testNext() {
            //print("1000 outputs of next()");
            var ui64_res = Array<UInt64>(repeating: 0, count: 1000)
            for i in 0..<1000 {
                ui64_res[i] = rng.next()
            }
            
            // reference result values
            let ui0_4:[UInt64] = [5703686706282124394, 15181128508879479020, 11713703072819584576, 2395620858144650628, 8055391375587558944]
            for (i, n) in ui0_4.enumerated() {
                XCTAssertEqual(ui64_res[i], n)
            }
            let ui995_999:[UInt64] = [15725985882330549063, 13197276392818897239, 9059476223836260773, 9869062834391525109, 9417523957422165086]
            for (i, n) in ui995_999.enumerated() {
                XCTAssertEqual(ui64_res[i + 995], n)
            }
        }
        testNext()
        
        //
        
        //----- double [0,1] -----
        func testNextDoubleCC() {
            //print("\n1000 outputs of genrand64_real1()");
            var double_res = Array<Double>(repeating: 0.0, count: 1000)
            for i in 0..<1000 {
                double_res[i] = rng.nextDoubleCC()
            }
            
            // reference result values
            let dcc0_4:[Double] = [0.7603329164, 0.7838647734, 0.9644285831, 0.5164214185, 0.6161801959]
            for (i, d) in dcc0_4.enumerated() {
                XCTAssertEqual(double_res[i], d, accuracy:0.00000001)
            }
            let dcc995_999:[Double] = [0.9609498653, 0.5790692986, 0.8827585395, 0.1805802401, 0.4181343838]
            for (i, d) in dcc995_999.enumerated() {
                XCTAssertEqual(double_res[i + 995], d, accuracy:0.00000001)
            }
        }
        testNextDoubleCC()
        
        //----- double [0,1) -----
        func testNextDoubleCO() {
            //print("\n1000 outputs of genrand64_real2()");
            var double_res = Array<Double>(repeating: 0.0, count: 1000)
            for i in 0..<1000 {
                double_res[i] = rng.nextDoubleCO()
            }
            
            // reference result values
            let dco0_4:[Double] = [0.6300652232, 0.3583074017, 0.0953219725, 0.9275866285, 0.9666566778]
            for (i, d) in dco0_4.enumerated() {
                XCTAssertEqual(double_res[i], d, accuracy:0.00000001)
            }
            let dco995_999:[Double] = [0.4433375034, 0.2248244788, 0.7058694284, 0.4917691750, 0.8453423833]
            for (i, d) in dco995_999.enumerated() {
                XCTAssertEqual(double_res[i + 995], d, accuracy:0.00000001)
            }
        }
        testNextDoubleCO();
        
        //----- double (0,1) -----
        func testNextDoubleOO() {
            //print("\n1000 outputs of genrand64_real1()");
            var double_res = Array<Double>(repeating: 0.0, count: 1000)
            for i in 0..<1000 {
                double_res[i] = rng.nextDoubleOO()
            }
            
            // reference result values
            let doo0_4:[Double] = [0.7206864319, 0.0218513383, 0.3476395708, 0.5563547780, 0.3984949740]
            for (i, d) in doo0_4.enumerated() {
                XCTAssertEqual(double_res[i], d, accuracy:0.00000001)
            }
            let doo995_999:[Double] = [0.5360179693, 0.0271825268, 0.8990601664, 0.1320639635, 0.7645244386]
            for (i, d) in doo995_999.enumerated() {
                XCTAssertEqual(double_res[i + 995], d, accuracy:0.00000001)
            }
        }
        testNextDoubleOO();
        
    }
    
    static var allTests = [
        ("testGenrand", testGenrand),
    ]
}
