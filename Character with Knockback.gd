extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var gravity = -9.8

@export var health = 1


var max_knockback_uses: int = 5
var current_knockback_uses: int = 5
var knockback_indicators: Array[OmniLight3D] = []

var collision_shapes: Array[CollisionShape3D] = []
var active_collision_shape: CollisionShape3D = null

func _ready():
	print("Area3D is monitoring:", $"../Area3D".monitoring)
	print("Collision shapes array: ", collision_shapes)
	knockback_indicators = [
		$"Knockback_Indicator 1", $"Knockback_Indicator 2", $"Knockback_Indicator 3", $"Knockback_Indicator 4", $"Knockback_Indicator 5"
	]
	print("Knockback indicators:", knockback_indicators)
	update_knockback_visuals()
	
	collision_shapes = [
		$"../Area3D/CollisionShape3D 1", 
		$"../Area3D/CollisionShape3D 2", 
		$"../Area3D/CollisionShape3D 3", 
		$"../Area3D/CollisionShape3D 4",
	]
	

func _physics_process(delta):
	

# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()	
		
	
var knockback_power = 100.0
var knockback_radius = 50.0

func knockback():
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	# Iterate through each enemy
	for enemy in enemies:
		if enemy is CharacterBody3D:
			# Calculate the distance between the player and the enemy
			var direction = enemy.global_transform.origin - global_transform.origin
			var distance = direction.length()
			
			# Check if the enemy is within the knockback radius
			if distance <= knockback_radius:
				direction = direction.normalized() # Get the direction vector
				# Apply knockback force
				enemy.apply_knockback(direction * knockback_power)
	#if current_knockback_uses > 0:
		## Perform knockback effect
		#current_knockback_uses -= 1
		#print("Knockback used. Remaining:", current_knockback_uses)
	#else:
		#print("No knockback uses left!")
		

func use_knockback():
	if current_knockback_uses > 0:
		knockback()
		current_knockback_uses -= 1
		print("Knockback used. Remaining:", current_knockback_uses)
		print("Calling update_knockback_visuals()...")
		update_knockback_visuals()
	else:
		print("No knockback uses left!")

func _input(event):
		if event.is_action_pressed("Knockback"):
			use_knockback()
			print("knockback pressed")
func replenish_knockback(amount: int = 1):
	print("Replenish knockback called")
	if current_knockback_uses < max_knockback_uses:
		current_knockback_uses = max_knockback_uses
		update_knockback_visuals()
		print("Knockback replenished. Current uses:", current_knockback_uses)


func update_knockback_visuals():
	print("Updating knockback visuals...")
	for i in range(max_knockback_uses):
		if knockback_indicators[i]:
			if i < current_knockback_uses:
				knockback_indicators[i].visible = true
				print("Indicator", i + 1, "visible")
			else:
				knockback_indicators[i].visible = false
				print("Indicator", i + 1, "hidden")
		else:
			print("Knockback indicator", i + 1, "is missing!")


func _on_area_3d_body_entered(body: Node3D) -> void:
	print("body entered")
	if body == self:  
		for shape in collision_shapes:
			if shape and not shape.disabled:  
				replenish_knockback()
				deactivate_collision_shape(shape)
				reactivate_other_collision_shapes(shape)
				break
		
func deactivate_collision_shape(shape: CollisionShape3D):
	if shape and not shape.disabled:
		shape.set_deferred("disabled", true)
		shape.visible = false
		print("Deactivating shape:", shape.name, "Disabled state after call:", shape.disabled)
		active_collision_shape = shape
		shape.set_deferred("disabled", true)
		await get_tree().process_frame
		print("Post-deferred disabled state:", shape.disabled)
	else: 
		print("Error: Shape is null in deactivate_collision_shape")

func reactivate_other_collision_shapes(excluded_shape: CollisionShape3D):
	# Reactivate all other shapes
	for shape in collision_shapes:
		if shape and shape != excluded_shape:
			shape.call_deferred("set", "disabled", false)
			shape.visible = true
			print("Reactivated shape:", shape.name)
