# Roll
Roll is a general purpose command line calculator and dice rolling tool.

## Supported Syntax
| Keywords | Description                    |
| ------------- | ------------------------------ |
| `--help`      | Display the help window.       |
| `[n]d[m]`   |   Create a value from a roll of n dice with m sides.   |
| `n as "s"` | Assign name s to value n. (Optional) |
| `n in c` | Assign color c to n for formatting (Optional) |

| Operators | Description                    |
| ------------- | ------------------------------ |
| `+` | Addition. |
| `-` | Substraction. |
| `*` | Multiplication. |
| `/` | Division. |
| `^` | Maximum. |
| `v` | Minumum. |

Values can either be dice rolls or integer constants.

##### Example
```
roll 1d20 as "Damage" in Red + 2 as "Bonus Damage" in blue
```
