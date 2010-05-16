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

std::map <std::string, Instruction> lang;

int str2int (const string &str) {
	stringstream ss(str);
	int n;
	ss >> n;
	if (ss.fail())
		throw str + " is not a valid integer value";

	return n;
}

std::string str2bin8(const std::string & str) {
	int n = str2int(str);
	if ( (n > 127) || (n < -128) ) {
		throw str + ": out of range (should be [-128..127])";
	}

	std::string s;
	for (int i = 0; i < 8; ++i) {
		if (i & 1)
			s = "1" + s;
		else
			s = "0" + s;

		n >> 1;
	}

	return s;
}

struct upper {
  int operator()(int c)
  {
    return std::toupper((unsigned char)c);
  }
};

std::string uppercase(std::string s) {
	std::transform(s.begin(), s.end(), s.begin(), upper());
	return s;
}

std::string strip(std::string line) {
	int f = line.find_first_not_of(" \t");
	int l = line.find_last_not_of(" \t");
	return line.substr(f, l-f+1);
}

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
}

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

/*!
	Assmebly given tokens into instruction.
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
		std::cout << "\t=: " << tokens[i] << " :=\n";
	}

	switch (ins.type) {
		case 0:
			return type0(ins, tokens);
		case 1:
			return type1(ins, tokens);
		case 2:
//			return type2(ins, tokens);
		case 3:
			//return type3(ins, tokens);
		case 4:
			//return type4(ins, tokens);
			break;
	}

	return ret;
}

/*!
	Assembly given file.
*/
void assembly(const char * fname) {
	std::ifstream f(fname);
	std::string line;
	int cnt = 0;
	int wrd = 0;
	std::vector<std::string> tokens;
	std::vector<std::string> codes;

	if (!f.good()) {
		throw "No such file";
	}

	try {

		while(!f.eof()) {
			cnt++;
			tokens.clear();
			getline(f, line);
			std::cout << cnt << ": [" << line << "]\n";
			Tokenizer s(line, " \t,");
			while (s.NextToken()) {
				tokens.push_back(s.GetToken());
			}
			if (tokens.size()) {
				codes = assemblyLine(tokens);
				for (int i = 0; i < codes.size(); ++i) {
					std::cout << wrd << " :\t" << codes[i] << "\n";
					wrd++;
				}
			}
		}

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

    //std::cout << "[" << strip(uppercase(" \ttest asdf kjg   \t")) << "]" << std::endl;

    return 0;
}
