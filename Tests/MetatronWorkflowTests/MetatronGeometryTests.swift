import Testing
import CoreGraphics
import MetatronCore

struct MetatronGeometryTests {
    @Test func thirteenDistinctCentersAndSeventyEightConnections() {
        #expect(MetatronGeometry.centers.count == 13)
        #expect(MetatronGeometry.edges.count == 78)
        for a in 0..<13 { for b in (a+1)..<13 {
            let p=MetatronGeometry.centers[a], q=MetatronGeometry.centers[b]
            #expect(hypot(p.x-q.x,p.y-q.y) > 0.49)
        } }
    }
    @Test func everyActionHasASeparateReachableCircle() throws {
        let center=CGPoint(x:220,y:220)
        for index in 0..<12 {
            let p=try #require(MetatronGeometry.actionCenter(index,radius:166,center:center))
            #expect(p.x >= 37 && p.x <= 403 && p.y >= 37 && p.y <= 403)
            for other in (index+1)..<12 {
                let q=try #require(MetatronGeometry.actionCenter(other,radius:166,center:center))
                #expect(hypot(p.x-q.x,p.y-q.y) >= 82)
            }
        }
        #expect(MetatronGeometry.actionCenter(12,radius:166,center:center) == nil)
    }
}
