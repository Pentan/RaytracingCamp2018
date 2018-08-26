#if os(OSX)
import Darwin
#else
import Glibc
#endif

import LinearAlgebra
import FlutterCore

// Cornel box
public func BuildCornelBoxScene(_ scene:Scene) {
    print("Build simple cornel box scene")
    let camera = scene.camera
    camera.position = Vector3(50.0, 52.0, 295.6)
    camera.lookAt(
        look:camera.position + Vector3(0.0, -0.042612, -1.0),
        up:Vector3(0.0, 1.0, 0.0)
    )
    camera.setFoculLengthWithFOV(30.0 * Double.pi / 180.0)
    
    scene.background.texture = ConstantColor(Vector3(0.02, 0.02, 0.02))
    
    scene.addObject(ObjectNode(Sphere(Vector3( 1e5+1.0 , 40.8, 81.6),    1e5  ), LegacyMaterial(Vector3(0.75, 0.25, 0.25), Vector3(0.0, 0.0, 0.0), .kLambert)))
    scene.addObject(ObjectNode(Sphere(Vector3(-1e5+99.0, 40.8, 81.6),    1e5  ), LegacyMaterial(Vector3(0.25, 0.25, 0.75), Vector3(0.0, 0.0, 0.0), .kLambert)))
    scene.addObject(ObjectNode(Sphere(Vector3(50.0, 40.8, 1e5),          1e5  ), LegacyMaterial(Vector3(0.75, 0.75, 0.75), Vector3(0.0, 0.0, 0.0), .kLambert)))
    scene.addObject(ObjectNode(Sphere(Vector3(50.0, 1e5 , 81.6),         1e5  ), LegacyMaterial(Vector3(0.75, 0.75, 0.75), Vector3(0.0, 0.0, 0.0), .kLambert)))
    scene.addObject(ObjectNode(Sphere(Vector3(50.0, -1e5+81.6, 81.6),    1e5  ), LegacyMaterial(Vector3(0.75, 0.75, 0.75), Vector3(0.0, 0.0, 0.0), .kLambert)))
    scene.addObject(ObjectNode(Sphere(Vector3(27.0, 16.5, 47.0),         16.5 ), LegacyMaterial(Vector3(0.99, 0.99, 0.99), Vector3(0.0, 0.0, 0.0), .kPerfectSpecular)))
    scene.addObject(ObjectNode(Sphere(Vector3(73.0, 16.5, 78.0),         16.5 ), LegacyMaterial(Vector3(0.99, 0.99, 0.99), Vector3(0.0, 0.0, 0.0), .kFineGlass)))
    scene.addObject(ObjectNode(Sphere(Vector3(50.0, 681.6-0.27, 81.6),   600.0), LegacyMaterial(Vector3(0.0 , 0.0 , 0.0 ), Vector3(12.0, 12.0, 12.0), .kLambert)))
}

// Cornel box 2
public func BuildMeshCornelBoxScene(_ scene:Scene) {
    print("Build mesh cornel box scene")
    let camera = scene.camera
    camera.position = Vector3(50.0, 52.0, 295.6)
    camera.lookAt(
        look:camera.position + Vector3(0.0, -0.042612, -1.0),
        up:Vector3(0.0, 1.0, 0.0)
    )
    camera.setFoculLengthWithFOV(30.0 * Double.pi / 180.0)
    
    scene.background.texture = ConstantColor(Vector3(0.02, 0.02, 0.02))
    
    // Walls
    let wallgeom = Mesh(8, 6, 0)
    // Bottom verts
    wallgeom.addVertex(Vector3(  0.0, 0.0, 0.0))    // 0
    wallgeom.addVertex(Vector3(  0.0, 0.0, 300.0))  // 1
    wallgeom.addVertex(Vector3(100.0, 0.0, 300.0))  // 2
    wallgeom.addVertex(Vector3(100.0, 0.0, 0.0))    // 3
    // Top verts
    wallgeom.addVertex(Vector3(  0.0, 80.0, 0.0))   // 4
    wallgeom.addVertex(Vector3(  0.0, 80.0, 300.0)) // 5
    wallgeom.addVertex(Vector3(100.0, 80.0, 300.0)) // 6
    wallgeom.addVertex(Vector3(100.0, 80.0, 0.0))   // 7
    // Normals
    wallgeom.addNormal(Vector3( 1.0, 0.0, 0.0)) // 0
    wallgeom.addNormal(Vector3(-1.0, 0.0, 0.0)) // 1
    wallgeom.addNormal(Vector3(0.0,  1.0, 0.0)) // 2
    wallgeom.addNormal(Vector3(0.0, -1.0, 0.0)) // 3
    wallgeom.addNormal(Vector3(0.0, 0.0,  1.0)) // 4
    wallgeom.addNormal(Vector3(0.0, 0.0, -1.0)) // 5
    
    // +x
    wallgeom.addFace(Mesh.FaceIndice(6, 7, 3), Mesh.FaceIndice(1, 1, 1), Mesh.FaceIndice(), 0)
    wallgeom.addFace(Mesh.FaceIndice(3, 2, 6), Mesh.FaceIndice(1, 1, 1), Mesh.FaceIndice(), 0)
    // -x
    wallgeom.addFace(Mesh.FaceIndice(4, 5, 1), Mesh.FaceIndice(0, 0, 0), Mesh.FaceIndice(), 1)
    wallgeom.addFace(Mesh.FaceIndice(1, 0, 4), Mesh.FaceIndice(0, 0, 0), Mesh.FaceIndice(), 1)
    // +y
    wallgeom.addFace(Mesh.FaceIndice(4, 7, 6), Mesh.FaceIndice(3, 3, 3), Mesh.FaceIndice(), 2)
    wallgeom.addFace(Mesh.FaceIndice(6, 5, 4), Mesh.FaceIndice(3, 3, 3), Mesh.FaceIndice(), 2)
    // -y
    wallgeom.addFace(Mesh.FaceIndice(0, 1, 2), Mesh.FaceIndice(2, 2, 2), Mesh.FaceIndice(), 2)
    wallgeom.addFace(Mesh.FaceIndice(2, 3, 0), Mesh.FaceIndice(2, 2, 2), Mesh.FaceIndice(), 2)
    // +z : Open
    // -z
    wallgeom.addFace(Mesh.FaceIndice(7, 4, 0), Mesh.FaceIndice(4, 4, 4), Mesh.FaceIndice(), 2)
    wallgeom.addFace(Mesh.FaceIndice(0, 3, 7), Mesh.FaceIndice(4, 4, 4), Mesh.FaceIndice(), 2)
    
    let wallobj = ObjectNode(wallgeom)
//    wallobj.addMaterial(LegacyMaterial(Vector3(0.75, 0.25, 0.25), Vector3(0.0, 0.0, 0.0), .kLambert))
//    wallobj.addMaterial(LegacyMaterial(Vector3(0.25, 0.25, 0.75), Vector3(0.0, 0.0, 0.0), .kLambert))
//    wallobj.addMaterial(LegacyMaterial(Vector3(0.75, 0.75, 0.75), Vector3(0.0, 0.0, 0.0), .kLambert))
    wallobj.addMaterial(SimpleMaterial(Vector3(0.75, 0.25, 0.25), Vector3(0.0, 0.0, 0.0), .kLambert))
    wallobj.addMaterial(SimpleMaterial(Vector3(0.25, 0.25, 0.75), Vector3(0.0, 0.0, 0.0), .kLambert))
    wallobj.addMaterial(SimpleMaterial(Vector3(0.75, 0.75, 0.75), Vector3(0.0, 0.0, 0.0), .kLambert))

    scene.addObject(wallobj)
    
    // Light
    let litgeom = Mesh()
    litgeom.addVertex(Vector3(50.0, 79.5, 80.0) + Vector3(-20.0, 0.0, -20.0))
    litgeom.addVertex(Vector3(50.0, 79.5, 80.0) + Vector3(-20.0, 0.0,  20.0))
    litgeom.addVertex(Vector3(50.0, 79.5, 80.0) + Vector3( 20.0, 0.0,  20.0))
    litgeom.addVertex(Vector3(50.0, 79.5, 80.0) + Vector3( 20.0, 0.0, -20.0))
    
    litgeom.addNormal(Vector3(0.0, -1.0, 0.0))
    litgeom.addFace(Mesh.FaceIndice(0, 1, 2), Mesh.FaceIndice(0, 0, 0), Mesh.FaceIndice(), 0)
    litgeom.addFace(Mesh.FaceIndice(2, 3, 0), Mesh.FaceIndice(0, 0, 0), Mesh.FaceIndice(), 0)
    
    let litobj = ObjectNode(litgeom)
//    litobj.addMaterial(LegacyMaterial(Vector3(0.0 , 0.0 , 0.0 ), Vector3(12.0, 12.0, 12.0), .kLambert))
    litobj.addMaterial(SimpleMaterial(Vector3(0.0 , 0.0 , 0.0 ), Vector3(12.0, 12.0, 12.0), .kLambert))
    
    scene.addObject(litobj)
    
    // Cubes
    let cubegeom = Cube(Vector3(0.0, 0.0, 0.0), Vector3(33.0, 33.0, 33.0))
    
//    let mirrormat = LegacyMaterial(Vector3(0.99, 0.99, 0.99), Vector3(0.0, 0.0, 0.0), .kPerfectSpecular)
    let mirrormat = SimpleMaterial(Vector3(0.99, 0.99, 0.99), Vector3(0.0, 0.0, 0.0), .kPerfectSpecular)
    let mirrorobj = ObjectNode(cubegeom, mirrormat)
    mirrorobj.transform.setTranslation(27.0, 16.5, 47.0)
    mirrorobj.transform.rotate(20.0 * Double.pi / 180.0, Vector3(0.0, 1.0, 0.0))
    scene.addObject(mirrorobj)
    
//    let glassmat = LegacyMaterial(Vector3(0.99, 0.99, 0.99), Vector3(0.0, 0.0, 0.0), .kFineGlass)
    let glassmat = SimpleMaterial(Vector3(0.99, 0.99, 0.99), Vector3(0.0, 0.0, 0.0), .kFineGlass)
    let glassobj = ObjectNode(cubegeom, glassmat)
    glassobj.transform.setTranslation(73.0, 16.5, 78.0)
    glassobj.transform.rotate(-25.0 * Double.pi / 180.0, Vector3(0.0, 1.0, 0.0))
    scene.addObject(glassobj)
}

// Test scene
public func BuildTestScene01(_ scene:Scene) {
    let camera = scene.camera
    camera.position = Vector3(2.0, 1.0, 4.0)
    camera.lookAt(
        look:Vector3(0.0, 0.0, 0.0),
        up:Vector3(0.0, 1.0, 0.0)
    )
    camera.setFoculLengthWithFOV(30.0 * Double.pi / 180.0)
    
    scene.background.texture = LinearGradient(
        Vector3(0.04, 0.02, 0.02),
        Vector3(0.5, 0.5, 0.8),
        direction:.kY
    )
    
    scene.addObject(
        ObjectNode(
            Cube(Vector3(0.0, 0.0, 0.0), Vector3(1.0, 1.0, 1.0)),
            LegacyMaterial(Vector3(0.75, 0.75, 0.75), Vector3(0.0, 0.0, 0.0), .kLambert)
        )
    )
    scene.addObject(
        ObjectNode(
            Sphere(Vector3(1.0, 1.0, -1.0), 0.5),
            LegacyMaterial(Vector3(0.75, 0.75, 0.75), Vector3(4.0, 4.0, 4.0), .kLambert))
    )
    
    scene.addObject(
        ObjectNode(
            Cube(Vector3(0.0, -1.0, 0.0), Vector3(10.0, 0.2, 10.0)),
            LegacyMaterial(Vector3(0.25, 0.25, 0.5), Vector3(0.0, 0.0, 0.0), .kLambert)
        )
    )
}
