/* ----- Original credits of http://xoshiro.di.unimi.it/xoshiro256plus.c ----- */
/*  Written in 2018 by David Blackman and Sebastiano Vigna (vigna@acm.org)
 
 To the extent possible under law, the author has dedicated all copyright
 and related and neighboring rights to this software to the public domain
 worldwide. This software is distributed without any warranty.
 
 See <http://creativecommons.org/publicdomain/zero/1.0/>. */

/* This is xoshiro256+ 1.0, our best and fastest generator for floating-point
 numbers. We suggest to use its upper bits for floating-point
 generation, as it is slightly faster than xoshiro256**. It passes all
 tests we are aware of except for the lowest three bits, which might
 fail linearity tests (and just those), so if low linear complexity is
 not considered an issue (as it is usually the case) it can be used to
 generate 64-bit outputs, too.
 
 We suggest to use a sign test to extract a random Boolean value, and
 right shifts to extract subsets of bits.
 
 The state must be seeded so that it is not everywhere zero. If you have
 a 64-bit seed, we suggest to seed a splitmix64 generator and use its
 output to fill s. */
/* -----  ----- */

/*
 port to swift : Satoru NAKAJIMA
 */

#if os(OSX)
import Darwin
#else
import Glibc
#endif

public class Random {
    static private let kDoubleMultiplyC0C1:Double = 1.0 / 9007199254740991.0
    static private let kDoubleMultiplyC0O1:Double = 1.0 / 9007199254740992.0
    static private let kDoubleMultiplyO0O1:Double = 1.0 / 4503599627370496.0
    
    private var s = Array<UInt64>(repeating: 0, count: 4)
    
    public init(seed:UInt64=1234567890) {
        setSeed(seed: seed)
    }
    
    public func setSeed(seed:UInt64) {
        /* splitmix64 http://xoshiro.di.unimi.it/splitmix64.c */
        /* The state can be seeded with any value. */
        var x:UInt64 = seed
        func splitmix64_next() -> UInt64 {
            x = x &+ 0x9e3779b97f4a7c15
            var z = x
            z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
            z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
            return z ^ (z >> 31)
        }
        
        // Init seeds
        for i in 0..<s.count {
            s[i] = splitmix64_next()
        }
    }
    
    // Don't use this directory. see original comments.
    internal func next() -> UInt64 {
        
        func rotl(_ x:UInt64, _ k:UInt) -> UInt64 {
            return (x << k) | (x >> (64 &- k))
        }
        
        let result_plus = s[0] &+ s[3]
        
        let t = s[1] << 17
    
        s[2] ^= s[0]
        s[3] ^= s[1]
        s[1] ^= s[2]
        s[0] ^= s[3]
    
        s[2] ^= t
    
        s[3] = rotl(s[3], 45)
    
        return result_plus
    }
    
    //
    public func next32() -> Int {
        return Int(next() >> 32)
    }
    
    // [0,1]
    public func nextDoubleCC() -> Double {
        return Double(next() >> 11) * Random.kDoubleMultiplyC0C1
    }
    
    // [0,1)
    public func nextDoubleCO() -> Double {
        return Double(next() >> 11) * Random.kDoubleMultiplyC0O1
    }
    
    // (0,1)
    public func nextDoubleOO() -> Double {
        return Double(next() >> 12) * Random.kDoubleMultiplyO0O1
    }
    
    // [-1,1]
    public func nextDoubleNPCC() -> Double {
        return nextDoubleCC() * 2.0 - 1.0
    }
    
    // (-1,1)
    public func nextDoubleNPOO() -> Double {
        return (nextDoubleCO() * 2.0 + Random.kDoubleMultiplyC0O1) - 1.0
    }
    
    /* This is the jump function for the generator. It is equivalent
     to 2^128 calls to next(); it can be used to generate 2^128
     non-overlapping subsequences for parallel computations. */
    
    public func jump() {
        let JUMP:[UInt64] = [ 0x180ec6d33cfd0aba, 0xd5a61266f0c9392c, 0xa9582618e03fc9aa, 0x39abdc4529b1661c ]
        
        var s0:UInt64 = 0
        var s1:UInt64 = 0
        var s2:UInt64 = 0
        var s3:UInt64 = 0
        for i in 0..<JUMP.count {
            for b in 0..<64 {
                if (JUMP[i] & (1 << b)) != 0 {
                    s0 ^= s[0]
                    s1 ^= s[1]
                    s2 ^= s[2]
                    s3 ^= s[3]
                }
                _ = next()
            }
        }
        
        s[0] = s0
        s[1] = s1
        s[2] = s2
        s[3] = s3
    }
    
    /* This is the long-jump function for the generator. It is equivalent to
     2^192 calls to next(); it can be used to generate 2^64 starting points,
     from each of which jump() will generate 2^64 non-overlapping
     subsequences for parallel distributed computations. */
    
    public func long_jump() {
        let LONG_JUMP:[UInt64] = [ 0x76e15d3efefdcbbf, 0xc5004e441c522fb3, 0x77710069854ee241, 0x39109bb02acbe635 ]
        
        var s0:UInt64 = 0
        var s1:UInt64 = 0
        var s2:UInt64 = 0
        var s3:UInt64 = 0
        for i in 0..<LONG_JUMP.count {
            for b in 0..<64 {
                if (LONG_JUMP[i] & (1 << b)) != 0 {
                    s0 ^= s[0]
                    s1 ^= s[1]
                    s2 ^= s[2]
                    s3 ^= s[3]
                }
                _ = next()
            }
        }
        
        s[0] = s0
        s[1] = s1
        s[2] = s2
        s[3] = s3
    }
}

