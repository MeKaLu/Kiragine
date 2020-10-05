#version 330 core

out vec4 final;
in vec2 ourTexCoord;
in vec4 ourColour;
uniform sampler2D uTexture;

void main() {
  vec4 texelColour = texture(uTexture, ourTexCoord);
  final = ourColour * texelColour;
}