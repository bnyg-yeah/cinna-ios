import Foundation
import Combine

fileprivate struct OrderedSet<Element: Hashable>: RandomAccessCollection, MutableCollection {
    private var array: [Element] = []
    private var set: Set<Element> = []

    init() {}
    init(_ elements: [Element]) {
        for e in elements { append(e) }
    }

    var startIndex: Int { array.startIndex }
    var endIndex: Int { array.endIndex }
    subscript(position: Int) -> Element {
        get { array[position] }
        set { let old = array[position]; if old != newValue { remove(old); append(newValue) } }
    }

    mutating func append(_ newElement: Element) {
        guard !set.contains(newElement) else { return }
        set.insert(newElement)
        array.append(newElement)
    }

    mutating func remove(at index: Int) { set.remove(array[index]); array.remove(at: index) }
    mutating func remove(_ element: Element) { if let i = firstIndex(of: element) { remove(at: i) } }

    func firstIndex(of element: Element) -> Int? { array.firstIndex(of: element) }
    func contains(_ element: Element) -> Bool { set.contains(element) }

    var count: Int { array.count }
    var isEmpty: Bool { array.isEmpty }
}

/// A class responsible for persisting and observing a small set of favorite theater IDs (max 3).
public final class FavoriteTheater: ObservableObject {
    /// Shared singleton instance.
    public static let shared = FavoriteTheater()
    
    private static let singleKey = "favoriteTheaterID" // legacy
    private static let multiKey = "favoriteTheaterIDs"
    
    /// The current favorite theater IDs, max 3.
    @Published public private(set) var favoriteIDs: [String] = []
    
    private init() {
        if let ids = UserDefaults.standard.array(forKey: Self.multiKey) as? [String] {
            favoriteIDs = Array(ids.prefix(3))
        } else if let legacy = UserDefaults.standard.string(forKey: Self.singleKey) {
            favoriteIDs = [legacy]
            UserDefaults.standard.set(favoriteIDs, forKey: Self.multiKey)
            UserDefaults.standard.removeObject(forKey: Self.singleKey)
        } else {
            favoriteIDs = []
        }
    }
    
    /// Replaces the entire favorites list (max 3). Extra items are dropped.
    public func setFavorites(ids: [String]) {
        let trimmed = Array(Array(ids).prefix(3))
        UserDefaults.standard.set(trimmed, forKey: Self.multiKey)
        publishFavoriteIDs(trimmed)
    }
    
    /// Adds an ID to favorites if capacity allows (max 3). If already present, this is a no-op.
    public func addFavorite(id: String) {
        var set = OrderedSet(favoriteIDs)
        if !set.contains(id) {
            if set.count >= 3 { return }
            set.append(id)
            persist(set)
        }
    }
    
    /// Removes an ID from favorites if present.
    public func removeFavorite(id: String) {
        var set = OrderedSet(favoriteIDs)
        if let idx = set.firstIndex(of: id) {
            set.remove(at: idx)
            persist(set)
        }
    }
    
    public func isFavorite(id: String) -> Bool { favoriteIDs.contains(id) }
    
    public func toggleFavorite(id: String) {
        if isFavorite(id: id) {
            removeFavorite(id: id)
        } else {
            addFavorite(id: id)
        }
    }
    
    /// Persists the given ordered set and publishes change.
    private func persist(_ set: OrderedSet<String>) {
        let array = Array(set)
        UserDefaults.standard.set(array, forKey: Self.multiKey)
        publishFavoriteIDs(array)
    }
    
    /// Publishes the favorites list safely on the main thread.
    private func publishFavoriteIDs(_ ids: [String]) {
        if Thread.isMainThread {
            self.favoriteIDs = ids
        } else {
            DispatchQueue.main.async {
                self.favoriteIDs = ids
            }
        }
    }
}
