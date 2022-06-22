module pagegen;

import utils.ds;
import utils.misc;

import std.traits;
import std.algorithm;
import std.conv : to;

debug import std.stdio;

/// Function used to join together two strings.
/// the first string may already be multiple strings joined
/// 
/// Params:
/// 1. the string generated till now. This will be multiple strings glued if >2 strings in total
/// 2. string is the string to glue
/// 3. the index number of string to be glued. starting from 0
/// 
/// Note: it can be called with first string as empty string as well, in case the string to be glued is
/// the first (0th index) string
/// 
/// Returns: the joined string
alias Glue = string function(string, string, uint);

/// A template, from which page can be generated.
/// 
/// Must be used with T as an enum of base uint.
/// Enum members are treated as the variable names in template text
class Template(T, Glue glue = null, char VAR_CHAR = '%') if (is(T == enum) && is(OriginalType!(Unqual!T) == uint)){
private:
	struct Piece{
		enum Type{
			String,
			Variable
		}
		Type type;
		union{
			string str;
			uint id;
		}
		this(string str){
			this.str = str;
			type = Type.String;
		}
		this (uint id){
			this.id = id;
			type = Type.Variable;
		}
	}
	/// pieces, in the order they are to be assembled
	Piece[] _pieces;
public:
	/// Constructor
	/// will treat enum member names as variable names. The enum must have
	/// int base type.
	this(string raw){
		uint[] vals;
		string[] names;
		foreach (i; [EnumMembers!T]){
			vals ~= i; // get the uint corresponding to enum member
			names ~= to!string(i); // this should get enum member name
		}
		while (raw.length){
			int indexStart = cast(int)countUntil(raw, VAR_CHAR);
			// if no more, or this is the last character in raw
			if (indexStart == -1 || indexStart + 1 == raw.length){
				_pieces ~= Piece(raw.dup);
				break;
			}
			if (indexStart > 0)
				_pieces ~= Piece(raw[0 .. indexStart]);
			// find next VAR_CHAR
			int indexEnd = cast(int)countUntil(raw[indexStart + 1 .. $], VAR_CHAR);
			if (indexEnd == -1){
				_pieces ~= Piece(raw[indexStart .. $].dup);
				break;
			}
			indexEnd += indexStart + 1;
			string varName = raw[indexStart + 1 .. indexEnd];
			int index = cast(int)countUntil(names, varName);
			if (index >= 0){
				_pieces ~= Piece(index);
			}else{
				_pieces ~= Piece(raw[indexStart .. indexEnd + 1].dup);
			}
			raw = raw[indexEnd + 1 .. $];
		}
	}
	/// generates string, for a single set of values
	string strGen(string[T] vals, string errStr = ""){
		string ret;
		foreach (i, piece; _pieces){
			if (piece.type == Piece.Type.String){
				ret ~= piece.str;
				continue;
			}
			if (cast(T)piece.id in vals)
				ret ~= vals[cast(T)piece.id];
			else if (errStr.length)
				debug ret ~= errStr;
		}
		return ret;
	}
	/// generates string, for multiple sets of values, using glue function to join
	/// if glue function is not provided, they are simply appended
	string strGen(string[T][] vals, string errStr = ""){
		string ret;
		if (!vals.length)
			return ret;
		foreach (i, valSet; vals){
			static if (glue)
				ret = glue(ret, strGen(valSet), i);
			else
				ret ~= strGen(valSet);
		}
		return ret;
	}
}
/// 
unittest{
	enum Parts : uint{
		Title,
		Content
	}
	auto tmpl = new Template!Parts("<title> %Title% </title><body> %Content% </body>");
	string str = tmpl.strGen([
		Parts.Title : "some title",
		Parts.Content : "some content"
	]);
	assert(str == "<title> some title </title><body> some content </body>");

	str = tmpl.strGen([
		Parts.Title : "title"
	]);
	assert(str == "<title> title </title><body>  </body>");


	enum ContentParts : uint{
		Heading,
		Body
	}
	auto tmplC = new Template!ContentParts("<h1>%Heading%</h1><p>%Body%</p>");
	str = tmpl.strGen([
		Parts.Title : "title",
		Parts.Content : tmplC.strGen([
			ContentParts.Heading : "content title",
			ContentParts.Body : "blablabla"
		])
	]);
	assert(str == "<title> title </title><body> <h1>content title</h1><p>blablabla</p> </body>");

	enum Cell : uint{
		First,
		Second
	}

	auto tableGen = new Template!Cell("<tr><td> %First% </td><td> %Second% </td></tr>");
	str = tableGen.strGen([
		[
			Cell.First  : "top left",
			Cell.Second : "top right"
		],[
			Cell.First  : "bottom left",
			Cell.Second : "bottom right"
		]
	]);
	writeln (str);
	assert(str ==
		"<tr><td> top left </td><td> top right </td></tr><tr><td> bottom left </td><td> bottom right </td></tr>");
}