# AI model assets

## Purpose

Describe the typed local model and image-model asset declarations, their source metadata, and their generated paths. These requirements cover configuration evaluation; realizing the paths may fetch model files and is not required for ordinary validation.

## Requirements

### Requirement: Local LLM assets are declared as GGUF models

The local LLM option SHALL accept named `gguf` models with categories, priority, settings, and files. Each file SHALL identify its name, repository, and content hash; its URL SHALL derive from those fields and the optional subdirectory. Generated model paths SHALL be read-only.

#### Scenario: Declare a model file

- WHEN a model uses the supported GGUF type and declares a file with repository and hash metadata
- THEN the file URL and read-only model path are derived from the declaration

#### Scenario: Unsupported local model type

- WHEN a local LLM model uses a type other than `gguf`
- THEN module evaluation rejects the model

#### Scenario: File in a repository subdirectory

- WHEN a file declares a subdirectory
- THEN that subdirectory appears between the repository path and filename in its derived URL

### Requirement: Image-generation model assets have supported formats

Image-generation models SHALL support `safetensors`, `ckpt`, and `gguf` formats, plus a separate LoRA collection. Model names SHALL default to attribute names, and model/LoRA paths SHALL be read-only values derived from declared files. The module SHALL use its declared service tag.

#### Scenario: Declare an image model and LoRA

- WHEN an image model uses a supported format and model or LoRA files are declared
- THEN generated read-only paths correspond to the declared file names, including any declared subdirectories

#### Scenario: Unsupported image model format

- WHEN an image model uses a format outside `safetensors`, `ckpt`, or `gguf`
- THEN module evaluation rejects the model

#### Scenario: Image generation service is not selected

- WHEN the module's `service:ai:image-generation` tag is not selected
- THEN the image-generation options and their asset paths are not contributed by this module

### Requirement: Asset evaluation does not require realizing model downloads

Evaluation of model path options SHALL not require realizing the asset derivations. Building a selected asset derivation MAY download the declared file and SHALL be treated separately from evaluation-only checks.

#### Scenario: Evaluate configured asset paths

- WHEN the configuration is evaluated without building asset derivations
- THEN generated path values can be inspected without downloading model weights

#### Scenario: Realize a selected asset

- WHEN a generated asset derivation is explicitly built
- THEN Nix fetches the declared file and validates it against its declared hash

## Sources

- [LLM model options and generated paths](../../../modules/ai/llm/default.nix#L14-L75)
- [Shared file source schema and URL derivation](../../../lib/types.nix#L13-L53)
- [Image generation tag and path helper](../../../modules/ai/image/default.nix#L6-L26) · [model and LoRA options](../../../modules/ai/image/default.nix#L29-L94)
