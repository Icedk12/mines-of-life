shader_type canvas_item;

uniform float vignette_radius : hint_range(0.0, 2.0) = 1.0;
uniform float vignette_softness : hint_range(0.0, 2.0) = 0.5;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    // Get distance of the current pixel from the screen center (0.5, 0.5)
    float distance_from_center = length(UV - vec2(0.5));
    
    // Calculate the vignette intensity using smoothstep
    float vignette = smoothstep(vignette_radius, vignette_radius - vignette_softness, distance_from_center);
    
    // Apply the color and mix it using the calculated vignette mask
    COLOR = vec4(vignette_color.rgb, (1.0 - vignette) * vignette_color.a);
}
