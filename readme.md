# pagegen

A minimal template based page generation library

## How to use:

### Generating Strings from a template

```D
// Create an enum, listing all "variables" in a template:
enum Vars{
	First, // this name will be used in the template string
	Second
}

// get a template string, read it from file or whatever
string templateStr = "<tr> <td> %First% </td> <td> %Second% </td> </tr>";

// create a Template class based on that enum
auto rowGen = new Template!Vars(templateStr);

// generate strings from it
string str = rowGen.strGen([
	Vars.First : "foo",
	Vars.Second : "bar"
]);
writeln(str); // <tr> <td> foo </td> <td> bar </td> </tr>
```

### Generating string, with multiple sets of data

In case you want to just append the same template string, you can just pass an array of associative arrays like:
```D
// continued from above code
str = rowGen.strGen([
	[
		Vars.First : "foo",
		Vars.Second : "bar",
	],[
		Vars.First : "foobar",
		Vars.Second : "barfoo"
	]
]);
writeln(str); // <tr> <td> foo </td> <td> bar </td> </tr><tr> <td> foobar </td> <td> barfoo </td> </tr>
```

Or in case you want to merge the string any other way, use the Glue function:
```D
// continued from above code
// must be a function, not a delagate
void merge(ref string a, string toApp, uint i){
	a ~= (i + 1).to!string ~ " is: " ~ toApp;
}
rowGen.glue = &merge;

str = rowGen.strGen([
	[
		Vars.First : "foo",
		Vars.Second : "bar",
	],[
		Vars.First : "foobar",
		Vars.Second : "barfoo"
	]
]);
writeln(str); // 1 is: <tr> <td> foo </td> <td> bar </td> </tr>2 is: <tr> <td> foobar </td> <td> barfoo </td> </tr>
```

## `%` character

You can use any other character to enclose variable names in template string like:
```D
auto rowGen = new Template!(someEnum, '$')(" $Foo$ ");
```