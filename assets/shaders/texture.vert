#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aTexCoord;
layout (location = 2) in vec4 aColour;

out vec2 ourTexCoord;
out vec4 ourColour;
uniform mat4 MVP;

void main() {
  gl_Position = MVP * vec4(aPos.xy, 0.0, 1.0);
  ourTexCoord = aTexCoord;
  ourColour = aColour;
}