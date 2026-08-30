shader_type canvas_item;

uniform float speed = 2.0;
uniform float frequency = 5.0;

void vertex() {
	VERTEX.y += sin(TIME * speed) * frequency;
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
