shader_type canvas_item;
uniform vec4 ink : source_color = vec4(0.149,0.235,0.231,1.0);
uniform vec4 coat : source_color;
uniform vec4 hair : source_color;
uniform vec4 linen : source_color = vec4(0.953,0.910,0.800,1.0);
uniform vec4 skin : source_color;
uniform vec4 trousers : source_color = vec4(0.216,0.341,0.286,1.0);
uniform vec4 scarf : source_color;
uniform vec4 trim : source_color = vec4(0.973,0.953,0.906,1.0);
varying vec4 vertex_tint;
void vertex() { vertex_tint=COLOR; }
void fragment() {
    vec4 texel = texture(TEXTURE,UV);
    int index = int(step(0.5,texel.r)*4.0+step(0.5,texel.g)*2.0+step(0.5,texel.b));
    vec4 result = ink;
    if(index==1) result=coat;
    if(index==2) result=hair;
    if(index==3) result=linen;
    if(index==4) result=skin;
    if(index==5) result=trousers;
    if(index==6) result=scarf;
    if(index==7) result=trim;
    COLOR = vec4(result.rgb,result.a*texel.a)*vertex_tint;
}
