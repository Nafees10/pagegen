module pagegen.pagegen;

import utils.ds;
import utils.misc;

import std.traits;
import std.algorithm;

private enum char VAR_CHAR = '%';
private enum string ERR_STR = "%%ERR%%";

/// A template, from which page can be generated
class Template(T) if (is(T == enum) && is(OriginalType!(Unqual!T) == uint)){
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
			type = Tye.String;
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
			int indexStart = countUntil(raw, VARV_CHAR);
			// if no more, or this is the last character in raw
			if (indexStart == -1 || indexStart + 1 == raw.length){
				_pieces ~= Piece(raw.dup);
				break;
			}
			// find next VAR_CHAR
			int indexEnd = countUntil(raw[indexStart + 1 .. $]);
			if (indexEnd == -1){
				_pieces ~= Piece(raw[indexStart .. $].dup);
				break;
			}
			string varName = raw[indexStart + 1 .. indexEnd];
			int index = countUntil(names, varName);
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
	string strGen(){
		string ret;
		foreach (i, piece; _pieces){
			if (piece.type == Piece.Type.String){
				ret ~= piece.str;
				continue;
			}
			if (piece.id in _vals)
				ret ~= _vals[piece.id];
			else
				debug ret ~= ERR_STR;
		}
	}
}