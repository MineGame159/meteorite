#version 460

layout(location = 0) in vec4 v_Color;

layout(location = 0) out vec4 color;

void main() {
    color = v_Color;
}