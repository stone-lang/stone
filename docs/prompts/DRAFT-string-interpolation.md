# String Interpolation (DRAFT)

I want to add String interpolation to Stone, but I want to make it explicit.
Something like `"Hello, $(name)".interpolate(name: name)`.
But that's too verbose, and I want help figuring out what the parameter(s) should be.
I'm thinking we could pass `this` often, and it would read the property with the given name.
Or maybe it should/could take a Map. I'm open to ideas and suggestions.
