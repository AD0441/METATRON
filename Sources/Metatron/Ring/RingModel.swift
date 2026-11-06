import AppKit
import MetatronCore
import MetatronWorkflow
import SwiftUI

struct RingItem: Identifiable, Equatable {
    let action: KQAction?
    let fileAction: FileActionID?
    let destination: SavedDestination?
    let recipe: Recipe?
    init(action: KQAction) { self.action = action; fileAction = nil; destination = nil; recipe = nil }
    init(fileAction: FileActionID) { action = nil; self.fileAction = fileAction; destination = nil; recipe = nil }
    init(destination: SavedDestination) { action = nil; fileAction = nil; self.destination = destination; recipe = nil }
    init(recipe:Recipe) {action=nil;fileAction=nil;destination=nil;self.recipe=recipe}
    var id: String { recipe.map {"recipe."+$0.id.uuidString} ?? destination.map { "destination." + $0.id.uuidString } ?? action?.id ?? "file." + (fileAction?.rawValue ?? "") }
    var title: String { recipe?.name ?? destination.map { $0.name.isEmpty ? $0.folder.lastPathComponent : $0.name } ?? action?.title ?? fileAction?.title ?? "" }
    var symbol: String { recipe != nil ? "square.stack.3d.up" : destination != nil ? "folder" : action?.symbol ?? fileAction?.symbol ?? "doc" }
}

/// State shared by the ring view (drawing) and the drop view (hit testing).
final class RingModel: ObservableObject {
    enum Mode { case drag, click }

    @Published var pages: [[RingItem]] = [[], []]
    private(set) var allPages:[[RingItem]] = [[],[]]
    @Published var page = 0
    @Published var hovered: Int?
    @Published var files: [URL] = []
    @Published var shown = false
    @Published var chosen: Int?
    /// While an action runs inside the ring: nil when idle, 0...1 when known, -1 while unknown.
    @Published var progress: Double?
    /// Shown briefly when the action finishes: true ✓, false ✕.
    @Published var finished: Bool?
    var mode: Mode = .drag

    static let pageNames=["Convertir","Herramientas","Acciones","Destinos","Recetas","Documentos"]
    var pageTitle:String {Self.pageNames.indices.contains(page) ? Self.pageNames[page] : "Acciones"}
    var items: [RingItem] { pages.indices.contains(page) ? pages[page] : [] }
    var hasTools: Bool { pages.count > 1 && !pages[1].isEmpty }

    func load(files: [URL], settings: SettingsStore = .shared) {
        self.files = files
        let convert = settings.ordered(ActionCatalog.convertActions(for: files).filter(settings.isEnabled)).map(RingItem.init)
        var tools = settings.ordered(ActionCatalog.toolActions(for: files).filter(settings.isEnabled)).map(RingItem.init)
        // ZIP is hidden for images by default, but a ring with no tools at all is never useful.
        if tools.isEmpty, let zip = ActionCatalog.toolActions(for: files).first(where: { $0 == .tool(.zip) }) { tools = [RingItem(action: zip)] }
        pages = [convert, tools, FileActionID.allCases.filter { $0 != .configureDestinations && ($0 != .annotate || (files.count == 1 && ActionCatalog.supports(.tool(.resize), for: files))) }.map { RingItem(fileAction: $0) }, settings.savedDestinations.isEmpty ? [RingItem(fileAction: .configureDestinations)] : settings.savedDestinations.map { RingItem(destination: $0) }]
        let recipes=WorkspaceStore.shared.recipes.map(WorkspaceStore.shared.configuredRecipe).filter { RecipeCompatibility.issue(inputs: files, recipe: $0) == nil }
        pages.append(Array(recipes.filter {!$0.steps.contains { ["documentAdvanced","bundlePDF","research","pdfTables"].contains($0.action) }}).map {RingItem(recipe:$0)})
        pages.append(Array(recipes.filter {$0.steps.contains { ["documentAdvanced","bundlePDF","research","pdfTables"].contains($0.action) }}).map {RingItem(recipe:$0)})
        allPages=pages
        pages=allPages.map {Array($0.prefix(12))}
        page = convert.isEmpty && !tools.isEmpty ? 1 : 0
        hovered = nil
        chosen = nil
        progress = nil
        finished = nil
    }

    func togglePage() {
        guard pages.contains(where: { !$0.isEmpty }) else { return }
        repeat { page = (page + 1) % pages.count } while pages[page].isEmpty
        hovered = nil
    }

    var isEmpty: Bool { pages.allSatisfy(\.isEmpty) }
}

/// Ring measurements, shared by drawing and hit testing.
struct RingGeometry {
    let diameter: CGFloat
    /// The ring's drawing canvas relative to the disc, leaving room for its shadow.
    static let canvasScale: CGFloat = 1.34

    var outerRadius: CGFloat { diameter / 2 }
    var hubRadius: CGFloat { diameter * 0.19 }
    var sliceInner: CGFloat { hubRadius + diameter * 0.025 }
    var sliceOuter: CGFloat { outerRadius - diameter * 0.03 }
    var labelRadius: CGFloat { (sliceInner + sliceOuter) / 2 }

    /// Angle (radians, 0 = 12 o'clock, clockwise) where slice `i` starts.
    func startAngle(_ i: Int, of count: Int) -> Double {
        let step = 2 * Double.pi / Double(count)
        return Double(i) * step - step / 2
    }

    enum Hit: Equatable { case hub, slice(Int), outside }

    /// `point` is relative to the ring's center with y pointing down.
    func hit(_ point: CGPoint, count: Int) -> Hit {
        let d = hypot(point.x, point.y)
        if d < hubRadius { return .hub }
        if d > outerRadius + 24 || count == 0 { return .outside }
        var angle = atan2(Double(point.x), Double(-point.y)) // 0 at top, clockwise
        if angle < 0 { angle += 2 * .pi }
        let step = 2 * Double.pi / Double(count)
        let index = Int(((angle + step / 2) / step).rounded(.down)) % count
        return .slice(index)
    }
}
