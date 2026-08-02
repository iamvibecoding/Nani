import Foundation
let bundlePath = ".build/apple/Products/Release/Nani_Nani.bundle"
guard let bundle = Bundle(path: bundlePath) else { fatalError("Bundle not found") }
let url = bundle.url(forResource: "anime_wow", withExtension: "mp3")
print("URL:", url ?? "nil")
