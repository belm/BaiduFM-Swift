import PlaygroundSupport
import UIKit

let greeting = "Hello, playground"

// Optional binding and Boolean conditions use commas in modern Swift.
let weather: String? = "rain"
let cityWeather: String? = "sun"
let temperature: Int? = 20

if let weather,
   weather == "rain",
   let cityWeather,
   let temperature {
    print("Weather: \(weather), city: \(cityWeather), temperature: \(temperature)°")
}

// Native Set operations.
var people: Set<String> = ["hair", "nose", "ears"]
let dog: Set<String> = ["nose", "ears", "tail"]

people.insert("feet")
people.remove("feet")
people.intersection(dog)
people.subtracting(dog)
people.union(dog)
people.symmetricDifference(dog)

struct Point {
    var x: Int
    var y: Int
}

// Closure-based notification observation avoids obsolete selector strings.
let updateNotification = Notification.Name("playground.update")
let observer = NotificationCenter.default.addObserver(
    forName: updateNotification,
    object: nil,
    queue: .main
) { notification in
    guard let message = notification.object as? String else { return }
    print("Update UI: \(message)")
}

NotificationCenter.default.post(name: updateNotification, object: "hello")
NotificationCenter.default.removeObserver(observer)
PlaygroundPage.current.needsIndefiniteExecution = false
