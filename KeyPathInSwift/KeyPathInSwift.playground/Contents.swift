import UIKit

// KeyPath的使用，swift 4.0

struct User {
  let name: String
}

let user = User(name: "dyl")
print(user[keyPath: \User.name])

struct Article {
  let id: UUID
  let source: URL
  let title: String
  let body: String
}

let articles: [Article] = []

//let articleIDs = articles.map { $0.id }
//let articleSources = articles.map { $0.source }

extension Sequence {
  func map<T>(_ keyPath: KeyPath<Element, T>) -> [T] {
    return map { $0[keyPath: keyPath] }
  }

  func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
    return sorted { a, b in
      return a[keyPath: keyPath] < b[keyPath: keyPath]
    }
  }
}

let articleIDs = articles.map(\.id)
let articleSources = articles.map(\.source)


struct Song {
  let title: String
  let content: String
  let albumArtwork: String
}

struct SongCellConfigurator {
  func config(_ cell: UITableViewCell, for song: Song) {
    cell.textLabel?.text = song.title
    cell.detailTextLabel?.text = song.content
    cell.imageView?.image = UIImage(named: song.albumArtwork)
  }
}

struct CellConfigurator<Model> {
  let titleKeyPath: KeyPath<Model, String>
  let subTitleKeyPath: KeyPath<Model, String>
  let imageKeyPath: KeyPath<Model, String>
  
  func configure(_ cell: UITableViewCell, for model: Model) {
    cell.textLabel?.text = model[keyPath: titleKeyPath]
    cell.detailTextLabel?.text = model[keyPath: subTitleKeyPath]
    cell.imageView?.image = UIImage(named: model[keyPath: imageKeyPath])
  }
}

let songCellConfigurator = CellConfigurator<Song> (
  titleKeyPath: \.title,
  subTitleKeyPath: \.content,
  imageKeyPath: \.albumArtwork
)

class ListViewController {
  private var items = [Song]() {
    didSet {
      // TODO
    }
  }
  
  func loadItems() {
    
  }
}

// ReferenceWritableKeyPath: 继承自WritableKeyPath，可读可写，用于class这种引用类型
func setter<Object: AnyObject, Value>(
  for object: Object,
  keyPath: ReferenceWritableKeyPath<Object, Value>
) -> (Value) -> Void {
  return { [weak object] value in
    object?[keyPath: keyPath] = value
  }
}
