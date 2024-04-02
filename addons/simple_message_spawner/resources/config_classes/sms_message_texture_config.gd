extends Resource
class_name SMSMessageTextureConfig

## Texture to change to. Using Stylebox as it contains settings better suited for UI
@export var target_texture: StyleBox

## Whether to use the shader or not if it is set either here or on the node
@export var use_shader: bool = true

## Material for the texture. This will not overwrite the material if it is already
## set
@export var texture_shader_material: ShaderMaterial

## Shader for the texture. This will not overwrite the shader if it is already
## set
@export var texture_shader: Shader

## Target modulation of the texture
@export var target_texture_modulation: Color = Color.WHITE

## Time it takes to change to this texture.
@export var change_time: float = 0
