
# Coding style of Silica

#### The case of variables and methods.

Variables should be camel case, starting with a lower case letter.

```lua
Object.variable
Object.variableTwo
```

Methods should follow the same pattern, and use colon syntax.

```lua
Object:method()
Object:methodTwo()
```

Enums should be capitalised and words should be separated using underscores.

```lua
Enum.VARIABLE
Enum.VARIABLE_TWO
```

Classes should be camel case and start with a capital letter.

```lua
class "Class"
class "ClassTwo"
```

In source files, locals should be defined at the top, followed by classes, then the class' methods. Class methods should be defined using colon syntax. For example,

```lua
local function printInfo( ... )
	print( "Info: ", ... )
end

class "MyClass" {
	name = "Object";
}

function MyClass:printInfo()
	printInfo( self.name )
end
```

`"` should be used to define strings, not `'`