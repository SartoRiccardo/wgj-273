shader_type canvas_item;
uniform float crop : hint_range(0.0, 1.0, 0.05);
uniform int rows;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float row_height = 1.0/float(rows);
	int row = int(UV.y / row_height);
	if(row >= rows) row = rows-1;
	
	float px_alpha = 1.0;
	if(row_height*float(row)+(1.0-crop)*row_height < UV.y &&
			UV.y < row_height*float(row+1))
		px_alpha = 0.0;
	COLOR = vec4(color.rgb, color.a*px_alpha);
}