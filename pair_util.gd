class_name Pair
## A simple two-value pair for returning multiple values from a function.
## Used in test helpers to return (train, car) tuples.

var a: Variant
## First value in the pair.
var b: Variant
## Second value in the pair.


static func create(first: Variant, second: Variant) -> Pair:
	var p: Pair = Pair.new()
	p.a = first
	p.b = second
	return p
