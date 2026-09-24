shader_type canvas_item;

group_uniforms RGB;
uniform float JPEG_amount:hint_range(0.0, 0.025)=0.025;
uniform float RGB_amount:hint_range(0.0, 0.025)=0.025;
uniform float RGB_color:hint_range(0.0, 1.0)=0.5;
group_uniforms BLUR;
uniform float BLUR_spread:hint_range(0.0, 0.02)=0.02;
uniform float glow_amount:hint_range(0.0, 0.01)=0.01;
group_uniforms BORDER;
uniform float convex_amount:hint_range(-1.0, 1.0)=0.0;
uniform float vignette_amount:hint_range(0.0, 2.0)=0.0;
group_uniforms COLOr;
uniform float saturation:hint_range(0.0, 1.0)=1.0;
uniform float red:hint_range(0.0, 1.0)=1.0;
uniform float green:hint_range(0.0, 1.0)=1.0;
uniform float blue:hint_range(0.0, 1.0)=1.0;


void fragment() {
/*UV DISTORTION FOR CONVEX*/
vec2 center = UV - 0.5; 
float area = dot(center,center); 
vec2 distorted_uv = UV + center * area * convex_amount; 
vec2 vignette_uv = UV + center * area * -1.0; 
/*center pixels (0.5yx) ↓*/
/*0.5-0.5=0.0;*/
/*(0.0x-0.0x).(0.0y-0.0y)=0.0*/
/*0.5+0.0 . 0.0 . -1.0= 0.5 (no changes)*/
/*border pixels↓*/
/*0.0-0.5=-0.5*/
/*(-0.5--0.5).(-0.5--0.5)=1.0*/
/*0.0+-0.5 . 1.0 . -1.0= -0.5*/
/*the vignette also picks the distorted uv, but it's not applied directly to the texture*/

/*apliement*/
vec4 texture_1=texture(TEXTURE,distorted_uv);

/*RGB and JPEG*/
vec4 offset_texture_left= texture(TEXTURE,distorted_uv-vec2(sin(TIME*(JPEG_amount*1000.0))*JPEG_amount-RGB_amount,0));
vec4 offset_texture_right= texture(TEXTURE,distorted_uv+vec2(sin(TIME*(JPEG_amount*1000.0))*JPEG_amount+RGB_amount,0));
/*both variables uses the TIME which changes it values on a settled time, if JPEG is 0.0 then TIME=0.0 (no JPEG move). the offset is made by RGB and JPEG on x, and it depends on both uniforms values*/

/*a color change for both offset RGB textures changing their colors using the uniform*/
vec4 red_offset =vec4(offset_texture_left.r,offset_texture_left.g-RGB_color,RGB_color-offset_texture_left.b,texture_1.a);
vec4 blue_offset =vec4(0.0,RGB_color,RGB_color-offset_texture_right.b,texture_1.a);

/*gamma correction for the normal texture and offset textures to don't destroy the natural aspect */
vec4 texture_2=mix(texture_1/2.0+red_offset/2.0,texture_1/2.0+blue_offset/2.0,0.0);

/*BLUR*/
/*something liked to offset texture copies, but now using 8 of them in different positions with us quite near to the original one*/
vec4 blur_offset_1= texture(TEXTURE,distorted_uv+vec2(0.0,0.0));
vec4 blur_offset_2= texture(TEXTURE,distorted_uv+vec2((glow_amount+BLUR_spread),0.0));
vec4 blur_offset_3= texture(TEXTURE,distorted_uv+vec2((glow_amount+BLUR_spread)*2.0,0.0));
vec4 blur_offset_4= texture(TEXTURE,distorted_uv-vec2((glow_amount+BLUR_spread)*2.0,(glow_amount+BLUR_spread)));
vec4 blur_offset_5= texture(TEXTURE,distorted_uv-vec2((glow_amount+BLUR_spread)*2.0,(glow_amount+BLUR_spread)*2.0));
vec4 blur_offset_6= texture(TEXTURE,distorted_uv-vec2((glow_amount+BLUR_spread),(glow_amount+BLUR_spread)*2.0));
vec4 blur_offset_7= texture(TEXTURE,distorted_uv-vec2(0.0,(glow_amount+BLUR_spread)*2.0));
vec4 blur_offset_8= texture(TEXTURE,distorted_uv+vec2(0.0,(glow_amount+BLUR_spread)));
float BLUR_amount=2.0;

/*gamma correction to don't explode the colors. and the glow effect is in the same system, but it skips this correction with moderation */
blur_offset_1.rgb/=10.0-BLUR_amount;blur_offset_1.rgb+=glow_amount;
blur_offset_2.rgb/=10.0-BLUR_amount;blur_offset_2.rgb+=glow_amount;
blur_offset_3.rgb/=10.0-BLUR_amount;blur_offset_3.rgb+=glow_amount;
blur_offset_4.rgb/=10.0-BLUR_amount;blur_offset_4.rgb+=glow_amount;
blur_offset_5.rgb/=10.0-BLUR_amount;blur_offset_5.rgb+=glow_amount;
blur_offset_6.rgb/=10.0-BLUR_amount;blur_offset_6.rgb+=glow_amount;
blur_offset_7.rgb/=10.0-BLUR_amount;blur_offset_7.rgb+=glow_amount;
blur_offset_8.rgb/=10.0-BLUR_amount;blur_offset_8.rgb+=glow_amount;
/*apliement*/
texture_2=vec4(vec3(texture_2.rgb+blur_offset_1.rgb+blur_offset_2.rgb+blur_offset_3.rgb+blur_offset_4.rgb+blur_offset_5.rgb+blur_offset_6.rgb+blur_offset_7.rgb+blur_offset_8.rgb),texture_2.a);

/*SATURATION*/
/*first we need to create a value to "summarize" the red green and blue amount, then we apply on they*/
float neutre_color=(texture_2.r+texture_2.g+texture_2.b)/3.0;
vec4 texture_pb=vec4(neutre_color,neutre_color,neutre_color,1.0);
/*this calculation makes a summary of the original color and the new PB value, increasing one or other depending of the uniforms*/
texture_2=vec4(texture_2.r*saturation,texture_2.g*saturation,texture_2.b*saturation,texture_2.a*1.0)+vec4(texture_pb.r*(1.0-saturation),texture_pb.g*(1.0-saturation),texture_pb.b*(1.0-saturation),texture_2.a*1.0);

/*vignette apliement */
float vignette=(vignette_uv.x+vignette_uv.y)/2.0;
texture_2-=vec4(vignette*vignette_amount,vignette*vignette_amount,vignette*vignette_amount,0.0);

/*final color set with contrilared RGB amounts by the uniforms*/
COLOR=texture_2*vec4(red,green,blue,1.0);
}
