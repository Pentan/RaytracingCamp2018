#if os(OSX)
    import Darwin
#else
    import Glibc
#endif

import LinearAlgebra

public class BVH {
    
    internal class Node {
        public var bounds:AABB = AABB()
        public var children:[Node] = []
        public var isLeaf:Bool = false
        public var dataId:Int = 0
        
        public init() {
        }
        
        public init(_ bounds:AABB, leaf:Bool, dataId:Int=0) {
            self.bounds = bounds
            isLeaf = leaf
            self.dataId = dataId
        }
    }
    
    //
    internal var leafNodes:[Node]
    internal var tree:Node
    
    //
    public init() {
        tree = Node()
        leafNodes = []
    }
    
    public func clear() {
        tree.children.removeAll()
        leafNodes.removeAll()
    }
    
    //
    public func appendLeaf(_ bounds:AABB, _ dataid:Int) {
        leafNodes.append(Node(bounds, leaf:true, dataId:dataid))
    }
    
    // build tree
    @discardableResult
    public func buildTree() -> Int {
        let (rootnode, maxdepth) = recurseBuildTree(leafNodes, 0)
        tree = rootnode
        return maxdepth
    }
    
    @discardableResult
    internal func recurseBuildTree(_ nodelist:[Node], _ depth:Int) -> (Node, Int) {
        var maxdepth = depth
        
        // Median split
        if nodelist.count < 2 {
            // Leaf node
            return (nodelist[0], depth + 1)
            
        } else {
            // tree
            let retnode = Node()
            retnode.isLeaf = false
            
            // Measure node bounding box
            retnode.bounds.clear()
            for node in nodelist {
                retnode.bounds.expand(node.bounds)
            }
            
            // Median count split
            let boundsSize = retnode.bounds.size()
            let axisid = boundsSize.maxMagnitudeAndIndex().index
            
            let sortedNodes = nodelist.sorted { (a, b) -> Bool in
                let aval = a.bounds.centroid.componentAt(axisid)
                let bval = b.bounds.centroid.componentAt(axisid)
                return aval < bval
            }
            
            let nodecount = sortedNodes.count
            let splitcount = nodecount / 2
            
            let nodelist0 = Array(sortedNodes[0..<splitcount])
            let nodelist1 = Array(sortedNodes[splitcount..<nodecount])
            
            let (node0, d0) = recurseBuildTree(nodelist0, depth + 1)
            let (node1, d1) = recurseBuildTree(nodelist1, depth + 1)
            
            retnode.children.append(node0)
            retnode.children.append(node1)
            maxdepth = max(d0, d1)
            
            return (retnode, maxdepth)
        }
    }
    
    // intersection test returns (is intersect, distance)
    public typealias intersectionTest = (_ dataId:Int, _ ray:Ray, _ near:Double, _ far:Double) -> (Bool, Double, Int)
    
    public func intersect(_ ray:Ray, _ near:Double, _ far:Double, _ leafIntersect:intersectionTest) -> (Bool, Double, Int, Int) {
        return intersectTree(tree, ray, near, far, leafIntersect)
    }
    
    internal func intersectTree(_ node:Node, _ ray:Ray, _ near:Double, _ far:Double, _ leafIntersect:intersectionTest) -> (Bool, Double, Int, Int) {
        if node.isLeaf {
            // Leaf node
            let (ishit, d, leafData) = leafIntersect(node.dataId, ray, near, far)
            return (ishit, d, node.dataId, leafData)
        } else {
            if node.bounds.isIntersect(ray, near, far) {
                var minFar = far
                var minNodeId = -1
                var minLeafData = -1
                for i in 0..<node.children.count {
                    let child = node.children[i]
                    let (ishit, d, nodeId, leafData) = intersectTree(child, ray, near, minFar, leafIntersect)
                    if ishit {
                        minFar = d
                        minNodeId = nodeId
                        minLeafData = leafData
                    }
                }
                
                if minFar < far {
                    return (true, minFar, minNodeId, minLeafData)
                }
            }
        }
        
        return (false, 0.0, -1, -1)
    }
}

