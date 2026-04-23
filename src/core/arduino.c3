module std::core::arduino;

<*
 @param #x : "The variable or dereferenced pointer to load."
 @return "The value of the variable"

 @require $defined(&#x) : "This must be a variable or dereferenced pointer"
*>
macro @volatile_load(#x) @builtin
{
	return $$volatile_load(&#x);
}

<*
 @param #x : "The variable or dereferenced pointer to store to."
 @param value : "The value to store."
 @return "The value stored"

 @require $defined(&#x) : "This must be a variable or dereferenced pointer"
 @require $defined(#x = value) : "The value doesn't match the variable"
*>
macro @volatile_store(#x, value) @builtin
{
	return $$volatile_store(&#x, ($typeof(#x))value);
}
