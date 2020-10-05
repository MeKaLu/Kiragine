#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec4 aColour;
out vec4 ourColour;
uniform mat4 MVP;

void main() {
  gl_Position = MVP * vec4(aPos.xy, 0.0, 1.0);
  ourColour = aColour;
}