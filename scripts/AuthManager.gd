extends Node
class_name AuthManager

var supabase

var is_logged := false
var user_id := ""

const SUPABASE_URL := "https://gcybobosgzsqnjvqvuqz.supabase.co"
const SUPABASE_KEY := "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdjeWJvYm9zZ3pzcW5qdnF2dXF6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5NDQ2MDEsImV4cCI6MjA5NDUyMDYwMX0.-qQN69mtVW_o1XKyq1bWZ1I5FPVVKIZfHC4fS-qnQOE"

func _ready():
	supabase = Supabase.create_client(
	SUPABASE_URL,
	SUPABASE_KEY
)


func register_user(email: String, password: String):
	var result = await supabase.auth.sign_up(
		email,
		password
	)

	if result:
		print("Compte créé")


func login_user(email: String, password: String):
	var result = await supabase.auth.sign_in_with_password(
		email,
		password
	)

	if result:
		is_logged = true
		user_id = result.user.id

		print("Connecté :", user_id)


func logout():
	await supabase.auth.sign_out()

	is_logged = false
	user_id = ""
