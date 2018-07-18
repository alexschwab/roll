# Roll
Roll is a general purpose command line calculator and dice rolling tool.

## Supported Syntax
| Keywords     | Description                                           |
| ------------ | ----------------------------------------------------- |
| `--help`     | Display the help window.                              |
| `[n]d[m]`    | Create a value from a roll of n dice with m sides.    |
| `n as s`     | Assign name s to value n. (Optional)                  |
| `n as "s b"` | Quotes around the name are optional, and allow spaces |
| `n in c`     | Assign color c to n for formatting (Optional)         |

| Operators | Description      |
| --------- | ---------------- |
|    `+`    | Addition.        |
|    `-`    | Substraction.    |
|    `*`    | Multiplication.  |
|    `/`    | Division.        |
|    `^`    | Maximum.         |
|    `v`    | Minumum.         |

Values can either be dice rolls or integer constants.

##### Examples
```
roll 1d20 as "Damage" in Red + 2 as "Bonus Damage" in blue

roll d6 as Sword in blue *2 as "Critical Hit!" in yellow - 1 as "Str Mod"
```

## Macros

Roll attempts to read `roll.ini` for macros, which can take the place of expressions, allowing you to keep repetitive typing to a minimum.

Many macros can be in the file, and are separated by being within `{` `}` braces. 

Macros are case insensitive, begin with an identifier, a descriptor (optionally in quotes), an optional value to multiply specified arguments by if the identifier is followed by an exclimation when rolled, followed by an equal sign (`=`) and then the expression. Multiplied values are marked with a trailing `%` sign.

For example, in the file:
```
{
  sword, "Flaming Longsword", 3 = 2d6% as Sword in blue + 1d6% as Fire in red + 2 as Strength in blue
}
```
Called with `roll sword` would result in
```
Flaming Longsword (2d6 + 1d6 + 2): (sum of everything)
  Sword (result of 2d6 in blue) + Fire (result of 1d6 in red) + Strength (2 in blue)
```
If the macro you're using supports it, you can call the identifier with a trailing exclamation mark to indicate you want to use the critical multiplier.

`roll sword!`
```
Flaming Longsword (2d6x3 + 1d6x3 + 2): (sum of everything)
  Sword (result of 2d6x3 in blue) + Fire (result of 1d6x3 in red) + Strength (2 in blue)
```
