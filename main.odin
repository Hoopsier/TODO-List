package main
import "core:encoding/json"
import "core:fmt"
import "core:os"
import strings "core:strings"
import rl "vendor:raylib"
main :: proc() {
	tasks: [dynamic]Checkbox
	read_json(&tasks)

	rl.InitWindow(1920, 1080, "TODO List")
	rl.SetTargetFPS(60)
	for !rl.WindowShouldClose() {
		mx := rl.GetMouseX()
		my := rl.GetMouseY()
		rl.BeginDrawing()
		rl.ClearBackground(Indigo())
		for i in 0 ..< len(tasks) {
			x := tasks[i].x
			y := tasks[i].y
			tasks[i].checked = check(hover(x, y, mx, my), tasks[i].checked)
			checked := tasks[i].checked
			drawCheckbox(x, y, checked, hover(x, y, mx, my), tasks[i].title)
		}
		rl.EndDrawing()
	}
	write_json(tasks)
	return
}
CreateTask :: proc(
	tasks: ^[dynamic]Checkbox,
	title: cstring,
	x: i32,
	y: i32,
	checked: bool,
) {
	append(tasks, Checkbox{title, x, y, checked})
}

drawCheckbox :: proc(x, y: i32, checked, hover: bool, title: cstring) {
	rl.DrawCircle(x, y, 15, rl.WHITE)
	rl.DrawCircle(x, y, 13, Indigo())
	if checked {
		rl.DrawCircle(x, y, 13, rl.WHITE)
	}
	if hover {
		rl.DrawCircle(x, y, 13, rl.Color{0, 0, 255, 64})
	}
	rl.DrawText(title, x + 30, y - 15, 30, rl.WHITE)
}
Checkbox :: struct {
	title:   cstring,
	x:       i32,
	y:       i32,
	checked: bool,
}

Indigo :: proc() -> rl.Color {
	return rl.Color({33, 0, 100, 255})
}

hover :: proc(x, y, mx, my: i32) -> bool {
	if (mx - x > 15 || mx - x < -15) {return false} 	// 
	if (my - y > 15 || my - y < -15) {return false}
	return true
}

check :: proc(hover, checked: bool) -> bool {
	if !hover {return checked}
	if !rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {return checked}
	return !checked
}

read_json :: proc(tasks: ^[dynamic]Checkbox) {
	data, read_err := os.read_entire_file("tasks.json", context.allocator)
	if read_err != nil {
		fmt.eprintfln("Failed to load the file: %v", read_err)
		return
	}
	defer delete(data)

	// Parse JSON
	json_data, err := json.parse(data)
	if err != .None {
		fmt.eprintln("Failed to parse the json file.")
		fmt.eprintln("Error:", err)
		return
	}
	defer json.destroy_value(json_data)

	// Ensure root is an object
	root, ok1 := json_data.(json.Object)
	if !ok1 {
		fmt.eprintln("JSON root is not an object")
		return
	}

	// Get "tasks" field
	tasks_value, exists := root["tasks"]
	if !exists {
		fmt.eprintln("No 'tasks' field found in JSON")
		return
	}

	// Ensure it's an array
	tasks_array, ok := tasks_value.(json.Array)
	if !ok {
		fmt.eprintln("'tasks' is not an array")
		return
	}

	j: i32 = 1
	// Iterate safely
	for i in 0 ..< len(tasks_array) {
		obj, ok2 := tasks_array[i].(json.Object)
		str, exists := obj["title"].(json.String)
		if !exists {
			continue
		}
		val, exists2 := obj["done"].(json.Boolean)
		if !exists2 {
			continue
		}
		if !ok2 {
			fmt.eprintf("Task at index %d is not a string\n", i)
			continue
		}
		cstr, err := strings.clone_to_cstring(str)
		CreateTask(tasks, cstr, 100, 100 * j, val)
		j += 1
	}
}

write_json :: proc(tasks: [dynamic]Checkbox) {
	arr := make(json.Array, 0, len(tasks))

	for task in tasks {
		obj := make(json.Object)
		obj["title"] = string(task.title)
		obj["done"] = task.checked
		append(&arr, obj)
	}
	fmt.print(arr)

	root := make(json.Object)
	root["tasks"] = arr

	data, err := json.marshal(root)
	if err != nil {
		fmt.eprintln("Failed to marshal JSON:", err)
		return
	}
	defer delete(data)

	err2 := os.write_entire_file("tasks.json", transmute([]byte)data)
	if err2 != nil {
		fmt.eprintfln("Failed to write file: %v", err2)
	}
}
