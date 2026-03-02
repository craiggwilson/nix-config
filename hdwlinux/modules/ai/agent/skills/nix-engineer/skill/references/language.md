# Nix Language

## Basic Types

```nix
# Strings
"hello world"
''
  Multi-line
  string
''

# Numbers
42
3.14

# Booleans
true
false

# Null
null

# Paths
./relative/path
/absolute/path
~/home/path

# Lists
[ 1 2 3 ]
[ "a" "b" "c" ]

# Attribute sets
{ name = "value"; }
{ inherit name; }  # Same as: name = name;
```

## Functions

```nix
# Single argument
x: x + 1

# Multiple arguments (curried)
x: y: x + y

# Attribute set argument
{ name, age }: "${name} is ${toString age}"

# With defaults
{ name, age ? 0 }: "${name} is ${toString age}"

# With extra attributes
{ name, ... }: name

# Named attribute set
args@{ name, age }: args.name
```

## Let Bindings

```nix
let
  x = 1;
  y = 2;
  add = a: b: a + b;
in
  add x y
```

## Conditionals

```nix
if condition then
  "yes"
else
  "no"
```

## With Expression

```nix
# Brings attributes into scope
with pkgs; [
  git
  vim
  curl
]

# Equivalent to
[
  pkgs.git
  pkgs.vim
  pkgs.curl
]
```

## Inherit

```nix
let
  name = "Alice";
  age = 30;
in {
  inherit name age;
  # Same as: name = name; age = age;
}

# Inherit from attribute set
{ inherit (pkgs) git vim; }
# Same as: git = pkgs.git; vim = pkgs.vim;
```

## Attribute Access

```nix
# Direct access
set.attribute

# With default
set.attribute or "default"

# Dynamic access
set.${variableName}

# Check existence
set ? attribute
```

## List Operations

```nix
# Concatenation
[ 1 2 ] ++ [ 3 4 ]

# Map
map (x: x * 2) [ 1 2 3 ]

# Filter
filter (x: x > 2) [ 1 2 3 4 ]

# Fold
foldl' (acc: x: acc + x) 0 [ 1 2 3 ]
```

## String Interpolation

```nix
let
  name = "world";
in
  "Hello, ${name}!"

# Multi-line with indentation stripping
''
  {
    "name": "${name}",
    "value": ${toString value}
  }
''
```

## Import

```nix
# Import Nix file
import ./other.nix

# Import with arguments
import ./module.nix { inherit pkgs; }

# Import JSON/TOML
builtins.fromJSON (builtins.readFile ./config.json)
```

## Common Builtins

```nix
# Type checking
builtins.isString x
builtins.isList x
builtins.isAttrs x

# Attribute operations
builtins.attrNames set
builtins.attrValues set
builtins.hasAttr "name" set

# List operations
builtins.length list
builtins.head list
builtins.tail list
builtins.elem x list

# String operations
builtins.stringLength str
builtins.substring start len str
builtins.split regex str
```

## Lib Functions

```nix
# Common lib functions
lib.mkIf condition value
lib.mkOption { type = lib.types.str; }
lib.optionalString condition "string"
lib.optionals condition [ "list" ]
lib.mapAttrs (name: value: ...) set
lib.filterAttrs (name: value: ...) set
lib.recursiveUpdate base override
```
