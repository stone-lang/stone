# String Properties and Methods

## Overview

Implement a comprehensive set of String properties and methods for Stone. This includes 0-argument properties (computed properties), 1-argument methods, string interpolation, and a StringBuilder API for efficient string construction.

## Prerequisites

- Phase B (Computed Properties) should be completed for 0-argument properties
- Method syntax for 1-argument properties (may require additional language features)

## 0-Argument Properties

These are computed properties that take no arguments beyond `this`.

### Essential Properties

#### `String@empty?`

Returns TRUE if the string has zero bytes.

```stone
String@empty? := λ(this) { this.byte_count == 0 }

# Usage
"".empty?       # TRUE
"hello".empty?  # FALSE
```

**Implementation**: Simple comparison with byte_count.

#### `String@blank?`

Returns TRUE if the string is empty or contains only whitespace characters.

```stone
String@blank? := λ(this) {
  if(this.empty?, { TRUE }, { this.trimmed.empty? })
}

# Usage
"".blank?        # TRUE
"   ".blank?     # TRUE
"hello".blank?   # FALSE
"  hi  ".blank?  # FALSE
```

**Implementation**: Depends on `empty?` and `trimmed`. Could be simplified initially to just check `empty?` until whitespace handling is available.

#### `String@length`

Alias for `byte_count` - returns the number of bytes in the string.

```stone
String@length := λ(this) { this.byte_count }

# Usage
"hello".length  # 5
"λ".length      # 2 (UTF-8 multi-byte)
```

**Implementation**: Simple wrapper around existing `byte_count`.

**Note**: This returns byte count, not character count. For UTF-8 strings with multi-byte characters, this differs from character count. Future work could add `String@char_count` or `String@chars` for true character counting.

### Case Transformation Properties

These return new strings with case modified.

#### `String@upper_case`

Returns a new string with all alphabetic characters converted to uppercase.

```stone
# Usage
"hello".upper_case        # "HELLO"
"Hello World".upper_case  # "HELLO WORLD"
"hello123".upper_case     # "HELLO123"
```

**Implementation**: Iterate over characters, convert each to uppercase if alphabetic.

#### `String@lower_case`

Returns a new string with all alphabetic characters converted to lowercase.

```stone
# Usage
"HELLO".lower_case        # "hello"
"Hello World".lower_case  # "hello world"
"HELLO123".lower_case     # "hello123"
```

**Implementation**: Iterate over characters, convert each to lowercase if alphabetic.

#### `String@capitalized`

Returns a new string with the first character uppercase and all others lowercase.

```stone
# Usage
"hello".capitalized       # "Hello"
"HELLO".capitalized       # "Hello"
"hello world".capitalized # "Hello world"
```

**Implementation**: Convert first character to uppercase, rest to lowercase.

#### `String@title_case`

Returns a new string with the first character of each word capitalized.

```stone
# Usage
"hello world".title_case        # "Hello World"
"the quick brown fox".title_case  # "The Quick Brown Fox"
"HELLO WORLD".title_case        # "Hello World"
```

**Implementation**: Requires word boundary detection (typically spaces), capitalize first letter of each word.

### Whitespace Properties

#### `String@trimmed`

Returns a new string with leading and trailing whitespace removed.

```stone
# Usage
"  hello  ".trimmed      # "hello"
"hello".trimmed          # "hello"
"  hello world  ".trimmed  # "hello world"
"\n\thello\t\n".trimmed  # "hello"
```

**Implementation**: Requires identifying whitespace characters (space, tab, newline, etc.) and finding the first and last non-whitespace positions.

**Aliases**: Could also provide `String@stripped` for Ruby familiarity.

#### `String@trim_start` / `String@trim_left`

Returns a new string with leading whitespace removed.

```stone
# Usage
"  hello  ".trim_start   # "hello  "
"hello".trim_start       # "hello"
```

#### `String@trim_end` / `String@trim_right`

Returns a new string with trailing whitespace removed.

```stone
# Usage
"  hello  ".trim_end     # "  hello"
"hello".trim_end         # "hello"
```

### Structural Properties

#### `String@reversed`

Returns a new string with characters in reverse order.

```stone
# Usage
"hello".reversed         # "olleh"
"".reversed              # ""
"racecar".reversed       # "racecar"
```

**Implementation**: Iterate over characters in reverse order and build new string. For UTF-8, must reverse by character, not by byte.

#### `String@ascii?`

Returns TRUE if all bytes in the string are ASCII (values 0-127).

```stone
# Usage
"hello".ascii?           # TRUE
"hello123!".ascii?       # TRUE
"λ".ascii?               # FALSE (Greek lambda is multi-byte UTF-8)
"hello λ".ascii?         # FALSE
```

**Implementation**: Iterate over bytes, check if any are >= 128.

### Escape Processing

#### `String@unescape` or `String@decode_escapes`

Process C-style backslash escape sequences in the string and return the interpreted result.

```stone
# Usage
"\\u20AC".unescape           # "€" (Euro sign)
"\\n".unescape               # "\n" (newline character)
"\\t".unescape               # "\t" (tab character)
"hello\\nworld".unescape     # "hello\nworld"
"\\x41".unescape             # "A" (hex escape)
"\\101".unescape             # "A" (octal escape)
"\\\\".unescape              # "\" (escaped backslash)
"\\'".unescape               # "'" (escaped quote)
"\\\"".unescape              # '"' (escaped double quote)
```

**Supported escape sequences**:

- `\\n` - newline (0x0A)
- `\\t` - tab (0x09)
- `\\r` - carriage return (0x0D)
- `\\\\` - backslash
- `\\'` - single quote
- `\\"` - double quote
- `\\0` - null byte (0x00)
- `\\xHH` - hexadecimal byte (e.g., `\\x41` → 'A')
- `\\uHHHH` - Unicode code point, 4 hex digits (e.g., `\\u20AC` → '€')
- `\\UHHHHHHHH` - Unicode code point, 8 hex digits
- `\\NNN` - octal byte, 1-3 digits (e.g., `\\101` → 'A')

**Implementation**:

1. Iterate through string looking for backslash characters
2. When found, check the following character(s)
3. Replace escape sequence with corresponding byte(s)
4. For Unicode escapes (`\\u`, `\\U`), convert code point to UTF-8 bytes
5. Build new string with processed escapes

**Error handling**:

- Invalid escape sequences: could error or leave as-is
- Incomplete escapes at end of string: error or leave as-is
- Invalid hex/octal digits: error

**Note**: This processes escape sequences that are already in the string data (not source code escapes, which should be handled by the lexer/parser).

**Alternative names**:

- `String@unescape` - clear and concise
- `String@decode_escapes` - more explicit
- `String@interpret_escapes` - descriptive
- `String@process_escapes` - descriptive

**Example use case**: Processing strings read from files or user input that contain escape sequences.

#### `String@escape`

Inverse operation - convert special characters to escape sequences.

```stone
# Usage
"€".escape                   # "\\u20AC"
"\n".escape                  # "\\n"
"hello\nworld".escape        # "hello\\nworld"
"\"quote\"".escape           # "\\\"quote\\\""
```

**Implementation**: Iterate through string, replace special characters with escape sequences.

**Use case**: Preparing strings for output in formats that require escaping (JSON, C strings, etc.).

## 1-Argument Methods

These methods take one argument in addition to the receiver (`this`).

### Basic Operations

#### `String@concat(other)`

Returns a new string with `other` appended to `this`.

```stone
# Usage
"hello".concat(" world")     # "hello world"
"a".concat("b").concat("c")  # "abc"
"".concat("hello")           # "hello"
```

**Implementation**: Allocate new string with combined length, copy both strings.

**Note**: This provides a method-call alternative to the `+` operator (see String Operators document).

### Searching and Testing

#### `String@starts_with?(prefix)`

Returns TRUE if the string begins with the given prefix.

```stone
# Usage
"hello world".starts_with?("hello")    # TRUE
"hello world".starts_with?("world")    # FALSE
"hello world".starts_with?("")         # TRUE (empty prefix always matches)
"".starts_with?("hello")               # FALSE
```

**Implementation**: Compare the first N bytes of `this` with `prefix`, where N is the length of prefix.

#### `String@ends_with?(suffix)`

Returns TRUE if the string ends with the given suffix.

```stone
# Usage
"hello world".ends_with?("world")      # TRUE
"hello world".ends_with?("hello")      # FALSE
"hello world".ends_with?("")           # TRUE
"".ends_with?("world")                 # FALSE
```

**Implementation**: Compare the last N bytes of `this` with `suffix`.

#### `String@contains?(substring)` or `String@includes?(substring)`

Returns TRUE if the substring appears anywhere in the string.

```stone
# Usage
"hello world".contains?("lo wo")       # TRUE
"hello world".contains?("xyz")         # FALSE
"hello world".contains?("")            # TRUE
"".contains?("hello")                  # FALSE
```

**Implementation**: Requires substring search algorithm (naive or KMP/Boyer-Moore for efficiency).

**Naming**: `contains?` is more intuitive, but `includes?` matches Ruby. Could provide both as aliases.

### Character Access

#### `String@at(index)`

Returns the byte value at the given index, or -1 if index is out of bounds.

```stone
# Usage
"hello".at(0)            # 104 (ASCII 'h')
"hello".at(4)            # 111 (ASCII 'o')
"hello".at(5)            # -1 (out of bounds)
"hello".at(-1)           # Could support negative indexing from end
```

**Implementation**: Bounds check, then return byte at index.

**Future**: Could return a character (single-character string) instead of byte value, or provide both as separate methods.

#### `String@char_at(index)`

Returns a single-character string at the given character index (UTF-8 aware).

```stone
# Usage
"hello".char_at(0)       # "h"
"hello".char_at(4)       # "o"
"λabc".char_at(0)        # "λ"
"λabc".char_at(1)        # "a"
```

**Implementation**: Requires UTF-8 character boundary detection. More complex than `at()`.

### Transformation Methods

#### `String@repeat(count)`

Returns a new string with `this` repeated `count` times.

```stone
# Usage
"ha".repeat(3)           # "hahaha"
"x".repeat(5)            # "xxxxx"
"hello".repeat(0)        # ""
"hello".repeat(1)        # "hello"
```

**Implementation**: Concatenate string to itself count times.

#### `String@pad_start(length, fill_char)` / `String@pad_left`

Returns a new string padded to `length` by prepending `fill_char`.

```stone
# Usage
"5".pad_start(3, "0")     # "005"
"hello".pad_start(10, " ") # "     hello"
"hello".pad_start(3, "x")  # "hello" (already longer than 3)
```

#### `String@pad_end(length, fill_char)` / `String@pad_right`

Returns a new string padded to `length` by appending `fill_char`.

```stone
# Usage
"5".pad_end(3, "0")       # "500"
"hello".pad_end(10, " ")  # "hello     "
```

#### `String@split(delimiter)`

Returns a list of substrings split by the delimiter.

```stone
# Usage
"a,b,c".split(",")        # ["a", "b", "c"]
"hello world".split(" ")  # ["hello", "world"]
"a,b,".split(",")         # ["a", "b", ""]
```

**Implementation**: Requires List/Array type and substring searching.

#### `String@replace(pattern, replacement)`

Returns a new string with all occurrences of `pattern` replaced by `replacement`.

```stone
# Usage
"hello world".replace("world", "universe")  # "hello universe"
"aaa".replace("a", "b")                     # "bbb"
"hello".replace("x", "y")                   # "hello" (no match)
```

**Implementation**: Find all occurrences of pattern and build new string with replacements.

#### `String@replace_first(pattern, replacement)`

Returns a new string with the first occurrence of `pattern` replaced.

```stone
# Usage
"hello hello".replace_first("hello", "hi")  # "hi hello"
```

### Extraction Methods

#### `String@substring(start, length)` or `String@slice`

Returns a substring starting at `start` with `length` characters.

```stone
# Usage
"hello world".substring(0, 5)   # "hello"
"hello world".substring(6, 5)   # "world"
"hello".substring(1, 3)         # "ell"
```

**Alternative signature**: `substring(start, end)` where end is exclusive index.

#### `String@first(count)`

Returns the first `count` characters.

```stone
# Usage
"hello".first(3)         # "hel"
"hello".first(10)        # "hello" (returns whole string if count > length)
```

**Note**: This already exists in Ruby extensions at `lib/extensions/string.rb`! May want to make it available in Stone.

#### `String@last(count)`

Returns the last `count` characters.

```stone
# Usage
"hello".last(3)          # "llo"
"hello".last(10)         # "hello"
```

**Note**: Also exists in Ruby extensions.

## String Interpolation

String interpolation allows embedding expressions within string literals using `$(index)` placeholders.

### Syntax

```stone
# Positional argument interpolation
"$(1): $(2)".interp(key, value)
"Hello, $(1)!".interp("World")      # "Hello, World!"
"$(1) + $(2) = $(3)".interp(2, 3, 5)  # "2 + 3 = 5"
```

### Future: Map-based Interpolation

```stone
# Named argument interpolation (future)
"$(name): $(value)".interp(Map("name" -> "Age", "value" -> 42))
# "Age: 42"
```

### Implementation

#### Grammar Changes

Update string literal grammar to support interpolation:

```ruby
# In grammar, recognize interpolation template strings
# These are strings containing $(N) placeholders
terminal(:interpolation_string) { /"[^"]*\$\([0-9]+\)[^"]*"/ }
```

Or treat it as a regular method call on a string literal.

#### `String@interp(...args)`

The `interp` method is variadic (takes variable number of arguments):

```stone
String@interp := λ(this, ...args) {
  # Find all $(N) patterns in this
  # Replace $(1) with args[0], $(2) with args[1], etc.
  # Convert non-string args to strings (toString?)
}
```

**Implementation steps**:

1. Parse the template string to find `$(N)` patterns
2. For each pattern, extract the index N
3. Look up args[N-1] (1-indexed in template, 0-indexed in args array)
4. Convert argument to string if needed
5. Replace pattern with string value
6. Build and return final string

**Error handling**:

- If $(N) references an out-of-bounds index, could error or leave placeholder
- If argument can't convert to string, error

### Alternative: Template Literal Syntax

Instead of method call, could use syntax like:

```stone
name := "World"
message := `Hello, $(name)!`  # Backticks for templates
# or
message := "Hello, \(name)!"  # Backslash escape
```

This is more ergonomic but requires more grammar/parser work. Start with `.interp()` method first.

## Printf-Style Formatting

### `String@format(...args)`

Format a string using printf-style format specifiers.

```stone
# Basic usage
"Value: %d".format(42)                    # "Value: 42"
"Name: %s, Age: %d".format("Alice", 30)   # "Name: Alice, Age: 30"
"%s + %s = %s".format(2, 3, 5)            # "2 + 3 = 5"

# Floating point (when Float type available)
"Pi: %.2f".format(3.14159)                # "Pi: 3.14"
"%.6f".format(2.718281828)                # "2.718282"

# Width and alignment
"%10s".format("hello")                    # "     hello" (right-aligned)
"%-10s".format("hello")                   # "hello     " (left-aligned)
"%05d".format(42)                         # "00042" (zero-padded)

# Hexadecimal and octal
"%x".format(255)                          # "ff"
"%X".format(255)                          # "FF"
"%o".format(64)                           # "100"

# Percent sign
"100%% complete".format()                 # "100% complete"
```

### Format Specifiers

**Basic specifiers**:

- `%d` or `%i` - signed decimal integer
- `%u` - unsigned decimal integer
- `%x` - hexadecimal (lowercase)
- `%X` - hexadecimal (uppercase)
- `%o` - octal
- `%s` - string
- `%c` - character (single byte or code point)
- `%f` - floating point (when Float available)
- `%e` - scientific notation, lowercase
- `%E` - scientific notation, uppercase
- `%g` - shortest representation (%f or %e)
- `%G` - shortest representation (%f or %E)
- `%%` - literal percent sign

**Flags** (optional):

- `-` - left-align (default is right-align)
- `+` - always show sign for numbers
- ` ` (space) - prefix positive numbers with space
- `0` - zero-pad numbers
- `#` - alternate form (0x for hex, etc.)

**Width** (optional):

- Number specifying minimum field width
- Example: `%10d` - at least 10 characters wide

**Precision** (optional):

- `.number` specifying precision
- For floats: digits after decimal point
- For strings: maximum characters to print
- Example: `%.2f` - two decimal places

**Full syntax**: `%[flags][width][.precision]specifier`

### Examples

```stone
# Integers with width and padding
"%5d".format(42)           # "   42"
"%-5d".format(42)          # "42   "
"%05d".format(42)          # "00042"
"%+d".format(42)           # "+42"
"%+d".format(-42)          # "-42"

# Hexadecimal with prefix
"%#x".format(255)          # "0xff"
"%#X".format(255)          # "0XFF"

# Strings with width and precision
"%10s".format("hi")        # "        hi"
"%-10s".format("hi")       # "hi        "
"%.3s".format("hello")     # "hel" (truncated)
"%10.3s".format("hello")   # "       hel"

# Floats (when available)
"%.2f".format(3.14159)     # "3.14"
"%10.2f".format(3.14159)   # "      3.14"
"%+.2f".format(3.14159)    # "+3.14"
"%e".format(1234.5)        # "1.2345e+03"

# Multiple arguments
"(%d, %d)".format(10, 20)              # "(10, 20)"
"Point(%d, %d, %d)".format(1, 2, 3)    # "Point(1, 2, 3)"

# Mixed types
"Count: %d, Name: %s, Value: %.2f".format(5, "test", 3.14)
# "Count: 5, Name: test, Value: 3.14"
```

### Implementation

**Parsing**:

1. Iterate through format string looking for `%` characters
2. Parse format specifier: flags, width, precision, type
3. Extract corresponding argument from args array
4. Format argument according to specifier
5. Append formatted output to result string

**Type checking**:

- Verify argument type matches format specifier
- `%d`, `%i`, `%u`, `%x`, `%X`, `%o` require Int
- `%s` requires String (or auto-convert with .to_string())
- `%f`, `%e`, `%g` require Float (when available)
- `%c` requires Int (char code) or single-character String

**Error handling**:

- Mismatched argument count: error
- Wrong argument type for specifier: error
- Invalid format specifier: error
- Missing argument for specifier: error

**LLVM/C interop**: Could use C's `snprintf` for implementation:

```c
// Pseudocode
char buffer[256];
snprintf(buffer, sizeof(buffer), format_string, args...);
return string_from_cstr(buffer);
```

Or implement formatting logic directly in Stone/LLVM.

### Variadic Arguments

The `format` method requires variadic arguments support:

```stone
String@format := λ(this, ...args) {
  # this is the format string
  # args is array/list of arguments
  # Process format string and substitute args
}
```

### Comparison with Interpolation

**Printf-style formatting (`format`)**:

- Compact format specifiers
- Fine control over formatting (width, precision, padding)
- Familiar to C/C++/Java/Python programmers
- Type-specific formatters
- Better for numeric formatting

**Positional interpolation (`.interp()`)**:

- Simpler syntax for basic cases
- More readable for simple substitution
- Named placeholders possible with Map
- Less control over formatting

**Use cases**:

- `.format()` - numeric output, aligned tables, precise formatting
- `.interp()` - simple string substitution, templates

### Alternative: Format Function

Instead of a method, could provide a global function:

```stone
# Method form
"Value: %d".format(42)

# Function form
format("Value: %d", 42)

# Or both
```

The function form is slightly more conventional for printf-style formatting.

## StringBuilder API

For efficient string construction when building strings incrementally.

### Overview

String concatenation with `+` or `.concat()` creates a new string each time, which is inefficient for many concatenations. StringBuilder provides a mutable buffer.

### Record Definition

```stone
StringBuilder := Record(
  buffer :: MutableBuffer,  # Internal buffer (implementation detail)
  capacity :: Int,          # Current capacity
  size :: Int               # Current size
)
```

Or define as an opaque type if records don't support mutability yet.

### API Design

#### Constructor

```stone
# Create empty builder with default capacity
sb := StringBuilder.new()

# Create with initial capacity
sb := StringBuilder.with_capacity(100)

# Create with initial string
sb := StringBuilder.from_string("Hello")
```

#### Core Methods

```stone
# Append a string to the builder
sb.append(" World")

# Append multiple strings
sb.append("Hello").append(" ").append("World")

# Append other types (convert to string first)
sb.append(42)
sb.append(TRUE)

# Clear the builder (reset to empty)
sb.clear()

# Get current size
len := sb.size()

# Get current capacity
cap := sb.capacity()

# Build final string
result := sb.to_string()  # or sb.build()
```

#### Optional Methods

```stone
# Append with newline
sb.append_line("Hello")   # Appends "Hello\n"

# Insert at position
sb.insert(5, "XYZ")       # Insert "XYZ" at index 5

# Prepend to beginning
sb.prepend("Start: ")

# Reserve additional capacity
sb.reserve(100)           # Ensure room for 100 more bytes
```

### Usage Example

```stone
# Build a comma-separated list
build_csv := λ(items) {
  sb := StringBuilder.new()
  first := TRUE
  
  for_each(items, λ(item) {
    if(first.not, { sb.append(",") }, {})
    sb.append(item.to_string())
    first := FALSE
  })
  
  sb.to_string()
}

build_csv([1, 2, 3, 4, 5])  # "1,2,3,4,5"
```

### Implementation Notes

**Internal Representation**:

- Use a dynamically-sized buffer (similar to Vec/ArrayList)
- Start with default capacity (e.g., 16 or 32 bytes)
- Double capacity when full (or use 1.5x growth factor)
- Track current size and capacity separately

**Memory Management**:

- Allocate buffer on heap
- Reallocate when capacity exceeded
- Free old buffer after reallocation
- Final `to_string()` can reuse buffer if sized exactly, or copy to exact-size allocation

**LLVM Implementation**:

- Could use `malloc`/`realloc`/`free` for buffer management
- Or implement simple bump allocator for string building
- `memcpy` for copying string data

**Type Considerations**:

- StringBuilder is mutable, but Stone may not have mutable types yet
- Could treat as opaque handle (pointer to internal structure)
- Methods return new StringBuilder handle (technically different instance)
- Or wait for mutable record types

### Alternative: Functional String Building

If mutability is problematic, could use functional approach:

```stone
# Builder state is immutable, operations return new state
sb1 := StringBuilder.new()
sb2 := sb1.append("Hello")
sb3 := sb2.append(" World")
result := sb3.to_string()

# Or chained
result := StringBuilder.new()
  .append("Hello")
  .append(" ")
  .append("World")
  .to_string()
```

This is less efficient (more allocations) but fits purely functional paradigm.

## Implementation Order

Suggested implementation order based on dependencies and usefulness:

### Phase 1: Basic Properties (no dependencies)

1. `empty?` - trivial
2. `length` - trivial alias
3. `ascii?` - byte iteration only
4. `concat(other)` - basic concatenation

### Phase 2: Case Transformations (requires case conversion functions)

1. `upper_case` - return new string
2. `lower_case` - return new string
3. `capitalized` - combines upper/lower

### Phase 3: Whitespace Handling

1. `trimmed` / `stripped` - requires whitespace detection
2. `blank?` - depends on empty? and trimmed
3. `trim_start` / `trim_left`
4. `trim_end` / `trim_right`

### Phase 4: Structural Operations

1. `reversed` - character reversal (UTF-8 aware)
2. `title_case` - depends on word boundary detection

### Phase 5: 1-Argument Search Methods

1. `starts_with?(prefix)` - prefix comparison
2. `ends_with?(suffix)` - suffix comparison
3. `contains?(substring)` - substring search

### Phase 6: 1-Argument Access Methods

1. `at(index)` - byte access
2. `char_at(index)` - character access (UTF-8 aware)
3. `substring(start, length)` - extraction
4. `first(count)` - leverage existing Ruby extension
5. `last(count)` - leverage existing Ruby extension

### Phase 7: 1-Argument Transform Methods

1. `repeat(count)` - string concatenation
2. `pad_start(length, fill)` - padding
3. `pad_end(length, fill)` - padding
4. `replace(pattern, replacement)` - requires substring search
5. `replace_first(pattern, replacement)` - simpler version
6. `split(delimiter)` - requires List/Array type

### Phase 8: Escape Processing

1. `unescape` - process C-style escape sequences
2. `escape` - convert special chars to escapes

### Phase 9: Interpolation and Formatting

1. `interp(...args)` - variadic interpolation method
2. `format(...args)` - printf-style formatting
3. Template literal syntax (optional)

### Phase 10: StringBuilder

1. StringBuilder record/type definition
2. Constructor methods (new, with_capacity, from_string)
3. Core methods (append, to_string, clear)
4. Optional methods (append_line, insert, etc.)

## Additional Ideas

### Comparison Properties

- `String@compare(other)` - lexicographic comparison (-1, 0, 1)
- `String@equals_ignore_case?(other)` - case-insensitive equality

### Unicode Properties

- `String@char_count` - count of UTF-8 characters (vs byte_count)
- `String@chars` - returns list of single-character strings
- `String@bytes` - returns list of byte values

### Formatting Properties

- `String@indent(spaces)` - indent each line
- `String@lines` - split into list of lines
- `String@words` - split into list of words

### Testing Properties

- `String@alphanumeric?` - only letters and digits
- `String@alphabetic?` - only letters
- `String@whitespace?` - only whitespace

## Implementation Notes

### UTF-8 Considerations

Stone strings are UTF-8 encoded (represented as `{ ptr, i64 }` for data pointer and byte length). Several operations must be UTF-8 aware:

- **Byte operations** (safe): `byte_count`, `at(index)`, `ascii?`
- **Character operations** (need UTF-8 handling): `reversed`, `char_at`, `char_count`, `substring` (if character-indexed)

For character-level operations, Stone needs UTF-8 decoding support. This could be:

1. Built-in functions to iterate UTF-8 characters
2. FFI calls to libc functions (`mbrtowc`, etc.)
3. LLVM IR implementations of UTF-8 decoding

### String Building

Many operations return new strings. Stone needs efficient string building:

- Simple concatenation for small operations
- String builder pattern for complex transformations
- Memory allocation and copying

### Performance

Initial implementations can be straightforward. Optimizations for later:

- Inline simple properties
- Use Boyer-Moore for substring search
- Lazy evaluation where possible

## Test Coverage

Each property should have tests covering:

- Basic functionality
- Edge cases (empty strings, single character)
- UTF-8 multi-byte characters (where relevant)
- Usage with constants and variables
- Property chaining where applicable

Example test structure:

```ruby
RSpec.describe "String Properties" do
  describe ".empty?" do
    it "returns TRUE for empty strings"
    it "returns FALSE for non-empty strings"
    it "works on string constants"
  end
  
  describe ".concat" do
    it "concatenates two strings"
    it "concatenates empty strings"
    it "chains multiple concat calls"
    it "handles UTF-8 strings"
  end
  
  describe ".interp" do
    it "interpolates single argument"
    it "interpolates multiple arguments"
    it "handles missing placeholders"
    it "converts non-string arguments"
  end
end
```

## Acceptance Criteria

- [ ] All 0-argument properties parse and compile correctly
- [ ] 1-argument method syntax is supported (may require language changes)
- [ ] String interpolation with .interp() works
- [ ] Printf-style formatting with .format() works
- [ ] Escape processing (.unescape and .escape) works correctly
- [ ] StringBuilder API is functional and efficient
- [ ] All properties have comprehensive tests
- [ ] UTF-8 handling is correct where required (byte-level for ASCII, proper UTF-8 for escapes)
- [ ] Performance is acceptable for basic use cases
- [ ] All existing tests continue to pass
- [ ] Documentation is updated with examples
- [ ] `make test` passes
- [ ] `make lint` passes

## Future Considerations

### Regular Expressions

Eventually, Stone may want regex support:

- `String@matches?(pattern)` - regex matching
- `String@scan(pattern)` - find all matches
- `String@gsub(pattern, replacement)` - regex replace

### Native Template Syntax

Built-in interpolation syntax:

```stone
name := "World"
message := `Hello, $(name)!`  # or "Hello, \(name)!"
```

### Encoding Support

Beyond UTF-8:

- `String@encoding` - return encoding name
- `String@encode(encoding)` - convert to different encoding
- ASCII, ISO-8859-1, UTF-16, etc.

### Format Strings

Printf-style formatting:

```stone
"Value: %d, Name: %s".format(42, "test")
```
