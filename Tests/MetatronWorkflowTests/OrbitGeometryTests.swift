import Testing
import Foundation
import CoreGraphics
import MetatronCore

struct OrbitGeometryTests {
    @Test(arguments:1...12) func bubblesSurroundFileWithSeparateTargets(count:Int) throws {
        let geometry=OrbitGeometry(layout:.bubbles)
        #expect(geometry.hit(.zero,count:count) == .hub)
        for index in 0..<count {
            let p=try #require(geometry.center(for:index,count:count))
            #expect(geometry.hit(p,count:count) == .action(index))
            #expect(abs(p.x)+geometry.nodeRadius < geometry.side/2)
            #expect(abs(p.y)+geometry.nodeRadius < geometry.side/2)
            #expect(hypot(p.x,p.y) > geometry.hubRadius+geometry.nodeRadius)
            for other in (index+1)..<count {
                let q=try #require(geometry.center(for:other,count:count))
                #expect(hypot(p.x-q.x,p.y-q.y) > 2*geometry.nodeRadius)
            }
        }
        #expect(geometry.hit(CGPoint(x:230,y:230),count:count) == .outside)
    }
    @Test func cubeHitsCirclesAndLeavesGapsTransparent() throws {
        let geometry=OrbitGeometry(layout:.metatron)
        for index in 0..<12 {
            let p=try #require(geometry.center(for:index,count:12))
            #expect(geometry.hit(p,count:12) == .action(index))
        }
        #expect(geometry.hit(CGPoint(x:210,y:210),count:12) == .outside)
        #expect(geometry.hit(CGPoint(x:210,y:0),count:12) == .outside)
        #expect(geometry.hit(.zero,count:12) == .hub)
    }
}
