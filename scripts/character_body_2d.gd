extends CharacterBody2D

# ====================================
# PARAMÈTRES EXPORTÉS
# ====================================

@export_group("Physique")
@export var gravity := 980.0
@export var max_fall_speed := 1200.0
@export var coyote_time := 0.1  # Temps après avoir quitté le sol où on peut encore sauter

@export_group("Saut - Base")
@export var jump_force := -600.0
@export var min_jump_force := -300.0  # Force minimale pour un tap ultra court

@export_group("Saut - Contrôle")
@export var tap_time_threshold := 0.15  # Temps max pour considérer un "tap"
@export var jump_cut_multiplier := 0.5  # Réduction si relâché tôt
@export var hold_gravity_multiplier := 1  # Gravité réduite pendant maintien (plus flottant)

@export_group("Game Feel")
@export var jump_buffer_time := 0.1  # Temps avant d'atterrir où un input est mémorisé
@export var landing_freeze_duration := 0.05  # Micro-pause à l'atterrissage

@export_group("Limites")
@export var death_zone_offset := 200.0  # Distance sous l'écran avant game over

@export_group("Debug")
@export var show_debug := false
@export var show_jump_arc := false

# On cherche le bouton dans la scène (adapte le chemin si nécessaire)
@onready var jump_button: TextureButton = get_node_or_null("../UI/TextureButton") 

# Référence pour la gestion des animations
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


# ====================================
# VARIABLES INTERNES
# ====================================

# États
var is_dead := false
var is_grounded := false
var was_grounded := false

# Saut
var jump_held := false
var jump_press_time := 0.0
var time_since_grounded := 999.0  # Pour coyote time
var jump_buffered := false
var jump_buffer_timer := 0.0

# Landing
var landing_freeze_timer := 0.0

# ====================================
# PROCESS
# ====================================

func _ready():
	if show_jump_arc:
		set_process(true)

func _physics_process(delta):
	if is_dead:
		return
	
	# Sauvegarde l'état précédent
	was_grounded = is_grounded
	
	# ====================================
	# GESTION DES ANIMATIONS
	# ====================================
	if animated_sprite:
		if is_on_floor():
			if animated_sprite.animation != "Run":
				animated_sprite.play("Run")
		else:
			if animated_sprite.animation != "Jump":
				animated_sprite.play("Jump")
	
	# --- TEST : Désactivation temporaire du freeze pour vérification ---
	# if landing_freeze_timer > 0:
	# 	landing_freeze_timer -= delta
	# 	return
	
	# ====================================
	# GRAVITÉ
	# ====================================
	if not is_on_floor():
		var gravity_multiplier = 1.0
		
		# Gravité réduite si on maintient pendant la montée
		if jump_held and velocity.y < 0:
			gravity_multiplier = hold_gravity_multiplier
		
		velocity.y += gravity * gravity_multiplier * delta
		velocity.y = min(velocity.y, max_fall_speed)
		
		time_since_grounded += delta
	else:
		time_since_grounded = 0.0
	
	# ====================================
	# INPUT DETECTION
	# ====================================
	
	# Appui saut
	if Input.is_action_just_pressed("ui_accept"):
		jump_held = true
		jump_press_time = 0.0
		jump_buffered = true
		jump_buffer_timer = jump_buffer_time
		
		# Saut immédiat si au sol ou coyote time actif
		if is_on_floor() or time_since_grounded < coyote_time:
			perform_jump()
	
	# Relâchement saut
	if Input.is_action_just_released("ui_accept"):
		jump_held = false
		
		# Jump cut : si relâché tôt et qu'on monte encore
		if jump_press_time < tap_time_threshold and velocity.y < 0:
			velocity.y *= jump_cut_multiplier
			
			if show_debug:
				print("✂️ Jump cut! Temps: %.2fs" % jump_press_time)
	
	# Incrément du timer de maintien
	if jump_held:
		jump_press_time += delta
	
	# ====================================
	# JUMP BUFFER
	# ====================================
	if jump_buffered:
		jump_buffer_timer -= delta
		
		# Si on atterrit pendant le buffer, on saute
		if is_on_floor() and not was_grounded:
			perform_jump()
			jump_buffered = false
		
		# Expiration du buffer
		if jump_buffer_timer <= 0:
			jump_buffered = false
	
	# ====================================
	# MOUVEMENT
	# ====================================
	move_and_slide()
	
	# Mise à jour de l'état au sol
	is_grounded = is_on_floor()
	
	# Détection atterrissage (pour le landing freeze)
	if is_grounded and not was_grounded:
		on_landed()
	
	# ====================================
	# GAME OVER
	# ====================================
	if global_position.y > get_viewport_rect().size.y + death_zone_offset:
		trigger_game_over()

# ====================================
# FONCTIONS PRINCIPALES
# ====================================

func perform_jump():
	"""Exécute le saut"""
	if is_dead:
		return
	
	velocity.y = jump_force
	time_since_grounded = 999.0  # Désactive le coyote time
	jump_buffered = false
	
	if show_debug:
		print("🚀 Saut! Force: %.0f | Temps maintien: %.2fs" % [jump_force, jump_press_time])

func on_landed():
	"""Appelé quand le personnage atterrit"""
	if landing_freeze_duration > 0:
		landing_freeze_timer = landing_freeze_duration
	
	if show_debug:
		print("⬇️ Atterrissage")

func trigger_game_over():
	"""Déclenche le game over"""
	if is_dead:
		return
	
	is_dead = true
	
	GameState.update_best_score()
	
	# ON MASQUE ET DESACTIVE LE BOUTON ICI
	if jump_button:
		jump_button.hide()
		jump_button.disabled = true
		
	
	get_tree().paused = true
	
	var game_over_node = get_node_or_null("../UI/GameOver")
	if game_over_node:
		game_over_node.visible = true
	
	if show_debug:
		print("💀 GAME OVER")

# ====================================
# FONCTIONS UTILITAIRES
# ====================================

func reset():
	"""Reset le personnage"""
	is_dead = false
	velocity = Vector2.ZERO
	jump_held = false
	jump_press_time = 0.0
	time_since_grounded = 999.0
	jump_buffered = false
	
	# ON REAFFICHE LE BOUTON POUR LA PROCHAINE PARTIE
	if jump_button:
		jump_button.show()
		jump_button.disabled = false

func get_jump_height() -> float:
	"""Calcule la hauteur de saut approximative"""
	var time_to_apex = abs(jump_force) / gravity
	return abs(jump_force) * time_to_apex - 0.5 * gravity * time_to_apex * time_to_apex

# ====================================
# DEBUG
# ====================================

func _process(_delta):
	if show_jump_arc:
		queue_redraw()

func _draw():
	if not show_jump_arc:
		return
	
	# Dessine l'arc de saut prévu
	var steps = 50
	var time_step = 0.02
	var last_pos = Vector2.ZERO
	
	for i in range(steps):
		var t = i * time_step
		var sim_velocity_y = jump_force + gravity * t
		var pos = Vector2(0, sim_velocity_y * t + 0.5 * gravity * t * t)
		
		if i > 0:
			draw_line(last_pos, pos, Color.CYAN, 2.0)
		
		last_pos = pos
		
		if pos.y > 0:
			break


# ====================================
# CONNEXION DES BOUTONS UI
# ====================================

func _on_button_down() -> void:
	# Sécurité : si on est mort, le bouton ne simule rien
	if is_dead:
		return
	# On crée un faux événement d'action pressée
	var a = InputEventAction.new()
	a.action = "ui_accept"
	a.pressed = true
	Input.parse_input_event(a)

func _on_button_up() -> void:
	# On crée un faux événement d'action relâchée
	var a = InputEventAction.new()
	a.action = "ui_accept"
	a.pressed = false
	Input.parse_input_event(a)
