shader_type spatial;
render_mode specular_disabled;
uniform vec4 pigment : source_color = vec4(1.0);
uniform bool vertex_pigment = false;
varying vec3 paper_position;
void vertex() { paper_position = VERTEX; }
void fragment() {
 float wash = sin(paper_position.x*29.0+paper_position.y*9.0)*sin(paper_position.y*23.0+paper_position.z*17.0);
 float grain = sin(paper_position.x*109.0+paper_position.y*67.0+paper_position.z*43.0);
 ALBEDO = pigment.rgb * (vertex_pigment ? COLOR.rgb : vec3(1.0)) * (0.975+wash*0.020+grain*0.008);
 ROUGHNESS = 1.0;
 SPECULAR = 0.0;
}
