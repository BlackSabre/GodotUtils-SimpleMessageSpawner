extends Resource
class_name SMSMessageTextureConfig

## Texture to change to. Using Stylebox as it contains settings better suited for UI
@export var target_texture: StyleBox

## Whether to use the shader or not if it is set either here or on the node
@export var use_shader: bool = false

## Material for the texture. This will not overwrite the material if it is already
## set.
@export var texture_shader_material: ShaderMaterial

## Parameters for the shader. You'll need to add these yourself in the inspector and 
## ensure that the parameter_name in each SMSMessageShaderParameter property 
## matches the uniform variable value in the shader
@export var shader_parameters: SMSMessageShaderParameters

## Target modulation of the texture. If you're using a shader, this won't change
## the modulation and you'll need to use a shader script to change colour.
@export var target_texture_modulation: Color = Color.WHITE

## Time it takes to change to this texture.
@export var change_time: float = 0
