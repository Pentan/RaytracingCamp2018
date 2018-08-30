#if os(OSX)
import Darwin
#else
import Glibc
#endif


public class JSON {
    
    //static internal let whiteSpaces = ["\t", "\r", "\n", " "]
    
    public enum ParseError : Error {
        case syntaxError
    }
    
    public init() {
        
    }
    
    internal func tokenize(_ src:String) -> [String] {
        let ws:[Character] = ["\t", "\r", "\n", " "]
        
        var tokens:[String] = []
        var tmptoken = ""
        var strnow = false
        var strq:Character = "\""
        var esc = false
        
        for c in src {
            if ws.contains(c) && !strnow {
                // Skip white space
                if tmptoken.count > 0 {
                    tokens.append(tmptoken)
                    tmptoken = ""
                }
            } else {
                if strnow {
                    // String mode
                    if c == "\"" || c == "'" {
                        // " or '
                        if c == strq {
                            if esc {
                                // escaped
                                esc = false
                                tmptoken.append(c)
                            } else {
                                // end
                                strnow = false
                                tmptoken.append(c)
                                tokens.append(tmptoken)
                                tmptoken = ""
                            }
                        } else {
                            tmptoken.append(c)
                        }
                    } else if c == "\\" && !esc {
                        // String escape
                        esc = true
                        tmptoken.append(c)
                        
                    } else {
                        // String contents char
                        tmptoken.append(c)
                        if esc {
                            esc = false
                        }
                    }
                } else {
                    // Non string mode
                    if c == "\"" || c == "'" {
                        // String begin
                        strnow = true
                        esc = false
                        strq = c
                        // update current token
                        tmptoken.append(c)
                        
                    } else if c == "{" || c == "}" || c == ":" {
                        // Object
                        if tmptoken.count > 0 {
                            // push token if exist
                            tokens.append(tmptoken)
                            tmptoken = ""
                        }
                        // push { , } or :
                        tokens.append(String(c))
                        tmptoken = ""
                        
                    } else if c == "[" || c == "]" {
                        // Array begin
                        if tmptoken.count > 0 {
                            // push token if exist
                            tokens.append(tmptoken)
                            tmptoken = ""
                        }
                        // push [ or ]
                        tokens.append(String(c))
                        
                    } else if c == "," {
                        // Array or Object
                        // push token
                        if tmptoken.count > 0 {
                            tokens.append(tmptoken)
                            tmptoken = ""
                        }
                        
                    } else {
                        // update current token
                        tmptoken.append(c)
                    }
                }
            }
        }
        if tmptoken.count > 0 {
            tokens.append(tmptoken)
        }
        
        return tokens
    }
    
    internal func parseObject(_ tokens:inout [String]) throws -> [String: Any] {
        var ret:[String: Any] = [:]
        // Drop "{"
        tokens.removeFirst()
        
        while 0 < tokens.count {
            let k = tokens[0]
            if k == "}" {
                // Object End
                tokens.removeFirst()
                return ret
            }
            
            let s = tokens[1]
            tokens.removeSubrange(0..<2)
            
            if s != ":" {
                assertionFailure("Invalid separater found between object and key")
                throw ParseError.syntaxError
            }
            
            let kv = try parseValue(k)
            guard let key = kv as? String else {
                assertionFailure("Invalid Object key found. key must be String")
                throw ParseError.syntaxError
            }
            
            let val = try parseToken(&tokens)
            ret.updateValue(val, forKey: key)
        }
        
        assertionFailure("Unclosed Object found")
        throw ParseError.syntaxError
    }
    
    internal func parseArray(_ tokens:inout [String]) throws -> [Any] {
        var ret:[Any] = []
        // Drop "["
        tokens.removeFirst()
        
        while 0 < tokens.count {
            let v = tokens[0]
            if v == "]" {
                // Array End
                tokens.removeFirst()
                return ret
            }
            
            let val = try parseToken(&tokens)
            ret.append(val)
        }
        
        assertionFailure("Unclosed Array found")
        throw ParseError.syntaxError
    }
    
    internal func parseValue(_ s:String) throws -> Any {
        // String, Number etc
        if s == "true" {
            // true
            return true

        } else if s == "false" {
            // false
            return false

        } else if s == "null" {
            // null
            return ""

        } else if let c = s.first {
            // s is not empty
            if c == "\"" || c == "'" {
                // String
                let unesctbl:[Character: Character] = [
                    "\"" : "\"",
                    "\\" : "\\",
                    "/" : "/",
                    //"b" : "\b",
                    //"f" : "\f",
                    "n" : "\n",
                    "r" : "\r"
                ]
                let inds = Array(s.indices)
                var tmpstr = ""
                var i = 1
                while i < (inds.count - 1) {
                    let c = s[inds[i]]
                    
                    if c != "\\" {
                        // Standard char
                        tmpstr.append(c)
                        
                    } else {
                        i += 1
                        let c1 = s[inds[i]]
                        if let uc = unesctbl[c1] {
                            tmpstr.append(uc)
                        } else if c1 == "u" {
                            var hexstr = ""
                            hexstr.append(s[inds[i + 1]])
                            hexstr.append(s[inds[i + 2]])
                            hexstr.append(s[inds[i + 3]])
                            hexstr.append(s[inds[i + 4]])
                            i += 4
                            guard let hex = Int(hexstr, radix:16) else {
                                assertionFailure("Hex parse failed in JSON")
                                throw ParseError.syntaxError
                            }
                            guard let us = Unicode.Scalar(hex) else {
                                assertionFailure("\(hex) convert to unicode failed in JSON")
                                throw ParseError.syntaxError
                            }
                            tmpstr.append(Character(us))
                        }
                    }
                    
                    // next
                    i += 1
                }
                return tmpstr
                
            } else {
                // Number?
                guard let n = Double(s) else {
                    assertionFailure("\(s) is not number in JSON")
                    throw ParseError.syntaxError
                }
                return n
            }
        }
        
        // Empty String token
        assertionFailure("Empty token is found")
        throw ParseError.syntaxError
    }
    
    internal func parseToken(_ tokens:inout [String]) throws -> Any {
        if tokens.count > 0 {
            let s = tokens[0]
            
            if s == "{" {
                // Begin Object
                let o = try parseObject(&tokens)
                return o
                
            } else if s == "[" {
                // Begin Array
                let a = try parseArray(&tokens)
                return a
                
            } else {
                // Value
                let v = try parseValue(s)
                tokens.removeFirst()
                return v
            }
        }
        
        assertionFailure("Empty token array")
        throw ParseError.syntaxError
    }
    
    public func parse(_ src:String) throws -> Any {
        var tokens = tokenize(src)
        let ret = try parseToken(&tokens)
        return ret
    }
    
}

