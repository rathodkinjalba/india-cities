extends GutTest
## M0 smoke test: proves the headless GUT job runs in CI before any game logic exists.

func test_math_works() -> void:
	assert_eq(2 + 2, 4, "arithmetic sanity")

func test_running_godot_4() -> void:
	var info := Engine.get_version_info()
	assert_eq(info.major, 4, "should run under Godot 4.x")
