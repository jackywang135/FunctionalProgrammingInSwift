// Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

//Swift Private Library 

let distance : CGFloat = 2.0

_stdlib_getDemangledTypeName(distance)
_stdlib_getTypeName(distance)
_stdlib_conformsToProtocol(distance, Printable.self)

//Functional Programming

typealias Position = CGPoint
typealias Distance = CGFloat

func inRange(target:Position, range: Distance) -> Bool {
	return sqrt(target.x * target.x + target.y * target.y) <= range
}

let minDistance : Distance = 2.0

func inRange(target:Position, ownPosition:Position, friendly:Position, range:Distance) -> Bool {
	let dx = ownPosition.x - target.x
	let dy = ownPosition.y - target.y
	let targetDistance = sqrt(dx*dx + dy*dy)
	
	let friendlyDX = friendly.x - target.x
	let friendlyDY = friendly.y - target.y
	let friendlyDistance = sqrt(friendlyDX * friendlyDX + friendlyDY * friendlyDY)
	
	return targetDistance <= range && targetDistance >= minDistance && friendlyDistance >= minDistance
}

//First Class Functions - functions are values, no different from structs, integers, or booleans

typealias Region = Position -> Bool

func circle(radius : Distance) -> Region {
	return { point in sqrt(point.x * point.x + point.y * point.y) <= radius }
}

func circle2(radius : Distance, center : Position) -> Region {
	return { point in
		let dx = point.x - center.x
		let dy = point.y - center.y
		return sqrt(dx * dx + dy * dy) <= radius
	}
}

// Each of these functions modifies or combines regions into new regions.
// Instead of writing complex functions to solve a very specific problem, we can now use many small functions that can be assembled to solve a wide variety of problems.

func shift(offset: Position, region: Region) -> Region {
	return { point in
		let shiftedPoint = Position(x: point.x - offset.x, y: point.y - offset.y)
		return region(shiftedPoint)
	}
}

func invert(region : Region) -> Region {
	return { point in !region(point)}
}

func intersection(region1 : Region, region2 : Region) -> Region {
	return { point in region1(point) && region2(point) }
}

func union(region1 : Region, region2 : Region) -> Region {
	return { point in region1(point) || region2(point) }
}

func difference(region1 : Region, minusRegion : Region) -> Region {
	return  intersection(region1, invert(minusRegion))
}

func inRange2(ownPosition : Position, friendlyPosition : Position, target: Position, range: Distance) -> Bool {
	let rangeRegion = difference(circle(range), circle(minDistance))
	let targetRegion = shift(target, circle(minDistance))
	let friendlyRegion = shift(friendlyPosition, circle(minDistance))
	let resultRegion = difference(targetRegion, friendlyRegion)
	return resultRegion(target)
}




// Example for real production code 

import CoreImage


typealias Filter = CIImage -> CIImage
typealias Parameters = Dictionary <String, AnyObject >

extension CIFilter {
	convenience init(name: String, parameters: Parameters) {
		self.init(name: name)
		setDefaults()
		for (key, value: AnyObject) in parameters {
			setValue(value, forKey: key)
		}
	}
	
	var outputImage : CIImage {
		return self.valueForKey(kCIOutputImageKey) as CIImage
	}
}

func blur(radius: Double) -> Filter {
	return { image in
		let blurParameters : Parameters = [kCIInputRadiusKey : radius, kCIInputImageKey : image]
		let filter = CIFilter(name: "CIGaussianBlur", parameters: blurParameters)
		return filter.outputImage
	}
}

func colorGenerator(color: UIColor) -> Filter {
	return { _ in
		let parameters : Parameters = [kCIInputColorKey : color]
		let filter = CIFilter(name: "CIConstantColorGenerator", parameters: parameters)
		return filter.outputImage
	}
}

func compositeSourceOver(overlay : CIImage) -> Filter {
	return { image in
		let parameters : Parameters = [kCIInputBackgroundImageKey: image, kCIInputImageKey: overlay]
		let filter = CIFilter(name: "CISourceOverCompositing", parameters: parameters)
		let cropRect = image.extent()
		return filter.outputImage.imageByCroppingToRect(cropRect)
	}
}

func colorOverlay(color : UIColor) -> Filter {
	return { image in
		let overlay : CIImage = colorGenerator(color)(image)
		return compositeSourceOver(overlay)(image)
	}
}



func add(x: Int, y: Int) -> Int {
	return x + y
}

func add2(x: Int) -> (Int -> Int) {
	return { y in
		return x + y
	}
}

func add3(x: Int)(y: Int) -> Int {
	return x + y
}
add3(1)(y: 2)

add(1,2)
add2(1)(2)
add3(1)(y: 2)
//Add2 is the curry version of add

infix operator >>> { associativity left }

func >>> (filter1: Filter, filter2: Filter) -> Filter {
	return { img in filter2(filter1(img)) }
}

let customFilter2 : Filter = blur(5.0) >>> colorOverlay(UIColor.redColor()) >>> colorGenerator(UIColor.grayColor())


//Map, Filter, Reduce 

func incrementArray(xs: [Int]) -> [Int] {
	var result : [Int] = []
	for x in xs {
		result.append(x + 1)
	}
	return result
}

func computeIntArray(xs:[Int], f: (Int -> Int) ) -> [Int]{
	var result : [Int] = []
	for x in xs {
		result.append(f(x))
	}
	return result
}

func doubleArray(xs:[Int]) -> [Int] {
	return computeIntArray(xs){ x in return x * 2 }
}

func computeBoolArray(xs:[Int], f: (Int -> Bool)) -> [Bool] {
	var result : [Bool] = []
	for x in xs {
		result.append(f(x))
	}
	return result
}

func isEvenArray(xs: [Int]) -> [Bool] {
	return computeBoolArray(xs, { x in x % 2 == 0 })
}

func genericComputeArray<U>(xs:[Int], f:(Int -> U)) -> [U] {
	var result : [U] = []
	for x in xs {
		result.append(f(x))
	}
	return result
}

//Defining the map yourself

func map<U, T>(xs:[U], f:(U -> T)) -> [T] {
	var result : [T] = []
	for x in xs {
		result.append(f(x))
	}
	return result
}

////////////////////////////

func computeIntArray<T>(xs:[Int], f:Int -> T) -> [T] {
	return map(xs, f)
}

let intArray = [1,2,3,4]
let resultArray : [Int] = computeIntArray(intArray, {x in return x + 1})
resultArray

func computeStringArray(xs:[String], f:String -> String) {
	map(xs, f)
}

//func addcom(xs:[String]) -> [String] {
//	return computeStringArray(xs) { x in return x + ".com"}
//}

let boolArray = intArray.map({ x in x > 2})
boolArray

let StringArray = intArray.map({x in "\(x) Bitches"})
StringArray

func filter<T>(xs:[T], check:T -> Bool) -> [T] {
	var result : [T] = []
	for x in xs {
		if check(x) {
			result.append(x)
		}
	}
	return result
}


let stringArray = ["Kareen", "Malone", "Kobe", "Jordan"]
let playerWithE = filter(stringArray) { str in str.hasSuffix("e") }
playerWithE

func sum(xs:[Int]) -> Int{
	var result : Int = 0
	for x in xs {
		result += x
	}
	return result
}

func concatenate(xs:[String]) -> String {
	var result : String = ""
	for x in xs {
		result += x
	}
	return result
}

concatenate(stringArray)
sum(intArray)

//func reduce<T>(xs:[T], f: T->T) -> T {
//	var result : T
//	for x in xs {
//		
//	}
//}

func reduce<A, R>(arr: [A], initialValue: R, combine: (R,A) -> R) -> R {
	var result = initialValue
	for a in arr {
		combine(result, a)
	}
	return result
}

func sumByReduce(xs:[Int]) -> Int {
	return reduce(intArray, 0){result, x in result + x }
}

func concatenateUsingReduce(xs:[String]) -> String {
	return reduce(xs, "", {result, x in result + x})
}

let str1 = "2"
let str2 = "3"
let str3 = str1 + str2

let player = concatenateUsingReduce(stringArray)
player

let reducedPlayer = stringArray.reduce("", combine: +)
println(reducedPlayer)

func mapUsingReduce<T,U>(xs:[T], f:T->U) -> [U]{
	return xs.reduce([], combine: {result, x in result + [f(x)]})
}

func filterUsingReduce<T>(xs:[T], check: T -> Bool) -> [T]{
	return xs.reduce([]){result, x in
		return check(x) ? result + [x] : result }
}

//Reduce - iterating over an array to compute a result 



struct City {
	let name: String
	let population : Int
}

let Paris = City(name: "Paris", population:2243)
let Taipei = City(name: "Taipei", population: 3434)
let SF = City(name: "SF", population: 23224)

let cities = [Paris, Taipei, SF]

func scale(city: City) -> City {
	return City(name: city.name, population: city.population * 1000)
}

let citiesS = cities.filter({ city in city.population > 1000 }).map(scale).reduce(""){result, city in
		return result + "\n" + "\(city.name) : \(city.population)"
}

citiesS

// Using generics allows you to write flexible functions without compro- mising type safety

//Optionals 

var citiesDict = ["Paris":25000, "Taipei":23222, "SF":23242]

let madridPopulation : Int? = citiesDict["Madrid"]

if madridPopulation != nil {
	println(madridPopulation)
} else {
	println("unknown city")
}

// Optional Binding -
// Optional binding encourages you to handle exceptional cases explicitly, thereby avoiding runtime errors.

if let taichungPopulation = citiesDict["TaichungPopulation"] {
	println(taichungPopulation)
} else {
	println("unknown city")
}
//The ?? provides a safer alternative to the forced optional unwrapping, without being as verbose as the optional binding.

func ??<T>(optional:T?, defaultValue:() -> T) -> T {
	if let x = optional {
		return x
	} else {
		return defaultValue()
	}
}


var cityPop : Int? = citiesDict["KaoShung"] ?? {3444}()

cityPop //It only operates 3444 when the result is nil

//AutoClosure allows you to pass an expression without the { } around it for better code readability. 
//Why do you need to pass in { }? Because if you pass in the expression on its own, the compiler would execute it even if the condition to execute whatever is within the { } doesn't qualify. If the expression is an expensive computation, we want to be more efficient and only execute it when the conditions are met. 

//SO in other words, expression is simplified from {expression}(), here's an example:

func complicatdExpression()-> Int {
	return 23929439
}

var cityPop1 : Int? = citiesDict["KaoShung"] ?? 23929439
var cityPop2 : Int? = citiesDict["KaoShung"] ?? complicatdExpression()

//^ 2 are the same thing, However, the complicatedExpression is only evaluated if the cities["Kaoshung"] turns out not to be nil. Without auotclosure, the complicatedExpression would be ran even if the citiesDist isn't nil, which is unnecesary 

//Optional Chaining 

func mapOptionalArray<U,T>(optioinalXS:[U?], f:U -> T) -> [T] {
	var result : [T] = []
	for x in optioinalXS {
		if let y = x {
			result.append(f(y))
		}
	}
	return result
}

let optionalArray : [Int?] = [nil, 12, 32]

let arrayResult = mapOptionalArray(optionalArray){x in
	return "\(x)"}

println(arrayResult)



