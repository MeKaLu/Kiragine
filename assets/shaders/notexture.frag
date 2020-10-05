#version 330 core

out vec4 final;
in vec4 ourColour;

void main() {
  final = ourColour;
}