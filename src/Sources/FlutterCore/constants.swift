#if os(OSX)
import Darwin
#else
import Glibc
#endif

/////
public let kRayOffset = 1e-4
public let kFarAway = 1e10
public let kEPS     = 1e-6

