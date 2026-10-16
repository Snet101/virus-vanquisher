extends Node2D
var health = 1000
var hits = 0
var stunned = false
func take_damage(amount):
	health -= amount
	hits += 1
