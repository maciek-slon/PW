#include <iostream>
#include <fstream>
#include <map>
#include <string>
#include <vector>
#include <string>
#include <algorithm>
#include <sstream>

using namespace std;

/*
 * Tokenizer
 */

 class Tokenizer
{
    public:
        static const std::string DELIMITERS;
        Tokenizer(const std::string& str);
        Tokenizer(const std::string& str, const std::string& delimiters);
        bool NextToken();
        bool NextToken(const std::string& delimiters);
        const std::string GetToken() const {
			return m_token;
		}
        void Reset();
    protected:
        const std::string m_string;
        size_t m_offset;
        std::string m_delimiters;
        std::string m_token;
};

const string Tokenizer::DELIMITERS(" \t\n\r");

Tokenizer::Tokenizer(const std::string& s) :
    m_string(s),
    m_offset(0),
    m_delimiters(DELIMITERS) {}

Tokenizer::Tokenizer(const std::string& s, const std::string& delimiters) :
    m_string(s),
    m_offset(0),
    m_delimiters(delimiters) {}

bool Tokenizer::NextToken()
{
    return NextToken(m_delimiters);
}

bool Tokenizer::NextToken(const std::string& delimiters)
{
    size_t i = m_string.find_first_not_of(delimiters, m_offset);
    if (string::npos == i)
    {
        m_offset = m_string.length();
        return false;
    }

    size_t j = m_string.find_first_of(delimiters, i);
    if (string::npos == j)
    {
        m_token = m_string.substr(i);
        m_offset = m_string.length();
        return true;
    }

    m_token = m_string.substr(i, j - i);
    m_offset = j;
    return true;
}

/*
 *
 */

struct Instruction {
	// binary opcode
	std::string opcode;
	// mnemonic
	std::string mnemo;
	// length in bytes
	int length;
	// instruction type
	int type;
};

// list of language instructions
std::map <std::string, Instruction> lang;
// list of definitions (mapping registers to its numeric representations)
std::map <std::string, std::string> defs;

// convert string to integer
int str2int (const string &str) {
	stringstream ss(str);
	int n;
	ss >> n;
	if (ss.fail())
		throw str + " is not a valid integer value";

	return n;
}

// convert integer to its binary form (8 bit, U2 form)
std::string int2bin8(int n) {
	std::string s;
	for (int i = 0; i < 8; ++i) {
		if (n & 1)
			s = "1" + s;
		else
			s = "0" + s;

		n >>= 1;
	}

	return s;
}

// convert string to its binary form (8 bit, U2 form)
std::string str2bin8(const std::string & str) {
	int n = str2int(str);
	if ( (n > 127) || (n < -128) ) {
		throw str + ": out of range (should be [-128..127])";
	}

	return int2bin8(n);
}

// convert integer to its binary form (16 bit, U2 form)
std::string int2bin16(int n) {
	std::string s;
	for (int i = 0; i < 16; ++i) {
		if (n & 1)
			s = "1" + s;
		else
			s = "0" + s;

		n >>= 1;
	}

	return s;
}

// convert string to its binary form (16 bit, U2 form)
std::string str2bin16(const std::string & str) {
	int n = str2int(str);
	if ( (n > 32767) || (n < -32768) ) {
		throw str + ": out of range (should be [-32768..32767])";
	}

	return int2bin16(n);
}

// convert char to uppercase
struct upper {
  int operator()(int c)
  {
    return std::toupper((unsigned char)c);
  }
};

// convert integer to uppercase
std::string uppercase(std::string s) {
	std::transform(s.begin(), s.end(), s.begin(), upper());
	return s;
}

// strip whitespaces from begining and end of string
std::string strip(const std::string & line) {
	int f = line.find_first_not_of(" \t\r\n");
	int l = line.find_last_not_of(" \t\r\n");
	//std::cout << f << "." << l << std::endl;
	if (f >= l)
		return "";

	return line.substr(f, l-f+1);
}

// load language description from file
void loadLanguageDesc(const char * fname = NULL) {
	// language description file
    std::ifstream f;
    // instruction count
    int cnt;
    // temporary
    Instruction ins;

    if (!fname)
        f.open ("lang.txt", std::ifstream::in);
    else
        f.open (fname, std::ifstream::in);

	f >> cnt;

	for (int i = 0; i < cnt; ++i) {
		f >> ins.opcode >> ins.mnemo >> ins.length >> ins.type;
		lang[ins.mnemo] = ins;
	}

	f >> cnt;

	string s1, s2;
	for (int i = 0; i < cnt; ++i) {
		f >> s1 >> s2;
		defs[s1] = s2;
	}
}

/*
 * Convert each type of instruction to its binary form
 */
std::vector<std::string> type0(Instruction ins, std::vector<std::string> tokens) {
	if (tokens.size() != 1)
		throw tokens[0] + " should have no arguments";

	std::vector<std::string> ret;
	std::string s;
	s = ins.opcode;
	s += "000";
	ret.push_back(s);
	return ret;
}

std::vector<std::string> type1(Instruction ins, std::vector<std::string> tokens) {
	if (tokens.size() != 2)
		throw tokens[0] + " should have one argument";

	std::vector<std::string> ret;
	std::string s;
	s = ins.opcode;
	s += "000";
	ret.push_back(s);
	s = str2bin8(tokens[1]);
	ret.push_back(s);
	return ret;
}

std::vector<std::string> type2(Instruction ins, std::vector<std::string> tokens) {
	if (tokens.size() != 3)
		throw tokens[0] + " should have two arguments";

	if (defs.count(tokens[1]) < 1)
		throw tokens[1] + " unknown. Should be register name R0..R7";

	std::vector<std::string> ret;
	std::string s;
	s = ins.opcode;
	s += defs[tokens[1]];
	ret.push_back(s);
	s = str2bin8(tokens[2]);
	ret.push_back(s);
	return ret;
}

std::vector<std::string> type3(Instruction ins, std::vector<std::string> tokens) {
	if (tokens.size() != 4)
		throw tokens[0] + " should have three arguments";

	if (defs.count(tokens[1]) < 1)
		throw tokens[1] + " unknown. Should be register name R0..R7";

	if (defs.count(tokens[2]) < 1)
		throw tokens[2] + " unknown. Should be register name R0..R7";

	if (defs.count(tokens[3]) < 1)
		throw tokens[3] + " unknown. Should be register name R0..R7";

	std::vector<std::string> ret;
	std::string s;
	s = ins.opcode;
	s += defs[tokens[1]];
	ret.push_back(s);
	s = "0" + defs[tokens[2]] + "0" + defs[tokens[3]];
	ret.push_back(s);
	return ret;
}

std::vector<std::string> type4(Instruction ins, std::vector<std::string> tokens) {
	if (tokens.size() != 3)
		throw tokens[0] + " should have three arguments";

	if (defs.count(tokens[1]) < 1)
		throw tokens[1] + " unknown. Should be register name R0..R7";

	std::vector<std::string> ret;
	std::string s;
	s = ins.opcode;
	s += defs[tokens[1]];
	ret.push_back(s);
	s = str2bin16(tokens[2]);
	ret.push_back(s.substr(0, 8));
	ret.push_back(s.substr(8, 8));
	return ret;
}

/*
 * Assmebly given tokens into instruction.
 */
std::vector<std::string> assemblyLine(std::vector<std::string> tokens) {
	Instruction ins;

	if (tokens.size() < 1)
		throw "Empty line";

	std::string mnemo = uppercase(tokens[0]);

	std::vector<std::string> ret;
	std::string s;

	if (lang.count(mnemo) < 1) {
		throw mnemo + " - unknown instruction";
	}

	ins = lang[mnemo];

	for (size_t i = 0; i < tokens.size(); ++i) {
		//std::cout << "\t-- " << tokens[i] << "\n";
	}

	switch (ins.type) {
		case 0:
			return type0(ins, tokens);
		case 1:
			return type1(ins, tokens);
		case 2:
			return type2(ins, tokens);
		case 3:
			return type3(ins, tokens);
		case 4:
			return type4(ins, tokens);
			break;
	}

	return ret;
}

/*
 * Assembly given file.
 */
void assembly(const char * fname) {
	std::ifstream f(fname);
	std::string line;
	int cnt = 0;
	int wrd = 0;
	std::vector<std::string> tokens;
	std::vector<std::string> codes;
	bool first = true;

	if (!f.good()) {
		throw "No such file";
	}

	try {
		while(!f.eof()) {
			cnt++;
			tokens.clear();
			getline(f, line);
			//std::cout << "[" << line << "]\n";
			line = strip(line);
			//std::cout << "[" << line << "]\n";

			if (line.length() < 1) {
				if (first) {
					std::cout << "WIDTH = 8;\n"
								 "DEPTH = 32;\n"
								 "ADDRESS_RADIX = DEC;\n"
								 "DATA_RADIX = BIN;\n"
								 "\n"
								 "CONTENT BEGIN\n";

					first = false;
				}
				continue;
			}

			// comment
			if (line[0] == ';') {
				line[0] = '-';
				line = "-" + line;
				std::cout << line << std::endl;
				continue;
			}

			if (first) {
				std::cout << "WIDTH = 8;\n"
							 "DEPTH = 32;\n"
							 "ADDRESS_RADIX = DEC;\n"
							 "DATA_RADIX = BIN;\n"
							 "\n"
							 "CONTENT BEGIN\n";

				first = false;
			}

			Tokenizer s(line, " \t,");
			while (s.NextToken()) {
				tokens.push_back(s.GetToken());
			}
			if (tokens.size()) {
				std::cout << "-- " << cnt << ": " << line << "\n";
				codes = assemblyLine(tokens);
				for (size_t i = 0; i < codes.size(); ++i) {
					std::cout << "\t" << wrd << " :\t" << codes[i] << ";\n";
					wrd++;
				}
			}
		}

		std::cout << "END;\n";

	}
    catch (string s) {
    	std::cout << "Error: " << cnt << ": " << s << std::endl;
    }
    catch (const char * s) {
    	std::cout << "Error: " << cnt << ": "  << s << std::endl;
    }
    catch (...) {
		std::cout << "Error: " << cnt << ": "  "Unknown error\n";
    }
}

int main(int argc, char * argv[]) {
    if (argc < 2) {
	    std::cout << "Usage: " << argv[0] << " file\n";
        return 0;
    }

    try {
    	loadLanguageDesc();
		assembly(argv[1]);
    }
    catch (string s) {
    	std::cout << "Error: " << s << std::endl;
    }
    catch (const char * s) {
    	std::cout << "Error: " << s << std::endl;
    }
    catch (...) {
		std::cout << "Unknown error\n";
    }

    return 0;
}
