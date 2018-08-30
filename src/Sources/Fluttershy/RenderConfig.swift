#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra
import FlutterCore

public class RenderConfig {
    public var width    = 320
    public var height   = 240
    public var aspect:Double {
        return Double(width) / Double(height)
    }
    
    public var pixelSubSamples  = 1
    public var samplesPerPixel   = 8
    
    public var minDepth = 1
    public var maxDepth = 4
    public var minRRCutOff = 0.005
    
    public var tileSize = 64
    
    public var timeLimit = 121.0
    public var progressInterval = 15.0
    
    public var quietProgress = false
    public var waitToFinish = false
    
    public var inputFile = ""
    public var outputImage = "output.bmp"
    
    public func parseCommandlineOptions() {
        let opts = Array(CommandLine.arguments.dropFirst())
        parseOptionArray(opts)
    }
    
    public func loadOptionFile(_ path:String) {
        guard let (optptr, optlen) = try? LoadAllBytes(path) else {
            print("option: \(path) load failed")
            return
        }
        let u8ptr = optptr.bindMemory(to: UInt8.self, capacity: optlen)
        let optjson = String(cString: u8ptr)
        
        let jp = JSON()
        guard let json = try? jp.parse(optjson) else {
            print("option JSON: \(path) parse failed")
            optptr.deallocate()
            return
        }
        optptr.deallocate()
        
        guard let opts = json as? [String] else {
            print("option JSON format error: \(path)")
            return
        }
        parseOptionArray(opts)
    }
    
    internal func parseOptionArray(_ options:[String]) {
        var i = 0
        while i < options.count {
            let arg:String = options[i]
            
            if arg == "-s" {
                let s = options[i + 1].split(separator: ":")
                width = Int(s[0])!
                height = Int(s[1])!
                i += 1
            } else if arg == "-ss" {
                pixelSubSamples = Int(options[i + 1])!
                i += 1
            } else if arg == "-spp" {
                samplesPerPixel = Int(options[i + 1])!
                i += 1
            } else if arg == "-mind" {
                minDepth = Int(options[i + 1])!
                i += 1
            } else if arg == "-maxd" {
                maxDepth = Int(options[i + 1])!
                i += 1
            } else if arg == "-ts" {
                tileSize = Int(options[i + 1])!
                i += 1
            } else if arg == "-q" {
                quietProgress = true
            } else if arg == "-w" {
                waitToFinish = true
            } else if arg == "-i" {
                inputFile = options[i + 1]
                i += 1
            } else if arg == "-o" {
                outputImage = options[i + 1]
                i += 1
            }
            
            i += 1
        }
    }
    
    public func printCommandlineOptionInfo() {
        print("options:")
        print(" -s w:h : render size")
        print(" -ss N : sub samples")
        print(" -spp N : samples per (sub)pixel")
        print(" -mind N : min depth")
        print(" -maxd N : max depth")
        print(" -ts N : tile size")
        print(" -q : no progress image output")
        print(" -w : wait to finish")
        print(" -i String : input file glTF")
        print(" -o String : output file name. If given empty string, not save file.")
    }
}

