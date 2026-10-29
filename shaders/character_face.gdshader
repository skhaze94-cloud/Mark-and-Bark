shader_type canvas_item;
uniform bool face_enabled = false;
uniform sampler2D face_paint : filter_linear, repeat_disable;
uniform vec4 eye_near;
uniform vec4 eye_far;
uniform vec4 mouth;
uniform float blink_near = 0.0;
uniform float blink_far = 0.0;
uniform vec2 gaze_near = vec2(0.0);
uniform vec2 gaze_far = vec2(0.0);
uniform float jaw_scale = 1.0;
uniform float brow_near = 0.0;
uniform float brow_far = 0.0;
varying vec4 item_tint;
void vertex() { item_tint = COLOR; }
float oval(vec2 at, vec4 shape) {
	return 1.0 - smoothstep(0.72, 1.0, length((at-shape.xy)/max(shape.zw, vec2(0.0001))));
}
vec4 eyelid(vec4 colour, vec2 at, vec4 eye, float amount, vec2 pixel) {
	float mask = oval(at, vec4(eye.xy,eye.zw*1.13));
	float edge = eye.y-eye.w+2.1*eye.w*amount;
	float cover = mask*(1.0-smoothstep(edge-pixel.y,edge+pixel.y,at.y))*smoothstep(0.02,0.18,amount);
	vec2 skin_at = vec2(at.x,eye.y+eye.w*1.45+(at.y-eye.y)*0.05);
	vec4 skin = texture(face_paint,skin_at);
	colour.rgb=mix(colour.rgb,skin.rgb,cover*skin.a);
	float x = (at.x-eye.x)/max(eye.z,0.0001);
	float curve = eye.y+eye.w*(0.09+0.12*x*x);
	float line = (1.0-smoothstep(0.6,1.5,abs(at.y-curve)/pixel.y))*mask*smoothstep(0.82,0.98,amount);
	colour.rgb=mix(colour.rgb,skin.rgb*0.43,line);
	return colour;
}
void fragment() {
	vec2 sample_at=UV;
	if (face_enabled) {
		sample_at-=gaze_near*oval(UV,eye_near)*(1.0-blink_near);
		sample_at-=gaze_far*oval(UV,eye_far)*(1.0-blink_far);
		vec4 brow_a=vec4(eye_near.x,eye_near.y-eye_near.w*1.5,eye_near.z*1.5,eye_near.w*0.5);
		vec4 brow_b=vec4(eye_far.x,eye_far.y-eye_far.w*1.5,eye_far.z*1.5,eye_far.w*0.5);
		sample_at.y+=brow_near*oval(UV,brow_a)+brow_far*oval(UV,brow_b);
		sample_at.y=mix(sample_at.y,mouth.y+(sample_at.y-mouth.y)/max(0.8,jaw_scale),oval(UV,mouth)*0.75);
	}
	vec4 colour=texture(TEXTURE,sample_at);
	if (face_enabled) {
		colour=eyelid(colour,UV,eye_near,blink_near,TEXTURE_PIXEL_SIZE);
		colour=eyelid(colour,UV,eye_far,blink_far,TEXTURE_PIXEL_SIZE);
	}
	COLOR=colour*item_tint;
}
