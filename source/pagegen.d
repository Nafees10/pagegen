module pagegen;

import utils.ds;
import utils.misc;

import std.traits;
import std.algorithm;
import std.conv : to;

debug import std.stdio;

/// A template, from which page can be generated
class Template(T, char VAR_CHAR = '%') if (is(T == enum) && is(OriginalType!(Unqual!T) == uint)){
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
	/// values for variable pieces
	string[T] _vals;
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
	/// sets value for a variable piece
	void valSet(T varId, string val){
		_vals[varId] = val;
	}
	/// resets all values
	void valReset(){
		_vals.clear();
	}
	/// generates string
	string strGen(string errStr = ""){
		string ret;
		foreach (i, piece; _pieces){
			if (piece.type == Piece.Type.String){
				ret ~= piece.str;
				continue;
			}
			if (cast(T)piece.id in _vals)
				ret ~= _vals[cast(T)piece.id];
			else if (errStr.length)
				debug ret ~= errStr;
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
	Template!Parts tmpl = new Template!Parts("<title>%Title%</title><body>%Content%</body>");
	tmpl.valSet(Parts.Title, "some title");
	tmpl.valSet(Parts.Content, "some content");
	string str = tmpl.strGen();
	assert(str == "<title>some title</title><body>some content</body>");
	tmpl.valReset();

	tmpl.valSet(Parts.Title, "title");
	str = tmpl.strGen();
	assert(str == "<title>title</title><body></body>");
	tmpl.valSet(Parts.Content, "content");
	str = tmpl.strGen();
	assert(str == "<title>title</title><body>content</body>");
}