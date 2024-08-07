#include "smtp-address-validator.hpp"
 
using namespace std::literals;

%%{
machine address;

UTF8_tail = 0x80..0xBF;

UTF8_1 = 0x00..0x7F;

UTF8_2 = 0xC2..0xDF UTF8_tail;

UTF8_3 = (0xE0 0xA0..0xBF UTF8_tail)
       | (0xE1..0xEC UTF8_tail{2})
       | (0xED 0x80..0x9F UTF8_tail)
       | (0xEE..0xEF UTF8_tail{2})
       ;

UTF8_4 = (0xF0 0x90..0xBF UTF8_tail{2})
       | (0xF1..0xF3 UTF8_tail{3})
       | (0xF4 0x80..0x8F UTF8_tail{2})
       ;

# UTF8_char = UTF8_1 | UTF8_2 | UTF8_3 | UTF8_4;

UTF8_non_ascii = UTF8_2 | UTF8_3 | UTF8_4;

# various definitions from RFC 5234

Let_dig = alpha | digit;

Ldh_str = (alpha | digit | '-')* Let_dig;

U_Let_dig = alpha | digit | UTF8_non_ascii;

U_Ldh_str = (alpha | digit | '-' | UTF8_non_ascii)* U_Let_dig;

U_label = U_Let_dig U_Ldh_str?;

label = Let_dig Ldh_str?;

sub_domain = label | U_label;

Domain = sub_domain ('.' sub_domain)*;

snum = digit
     | ( '1'..'9' digit )
     | ( '1' digit digit )
     | ( '2' '0'..'4' digit )
     | ( '2' '5' '0'..'5' )
     ;
     # representing a decimal integer
     # value in the range 0 through 255

IPv4_address_literal = snum ('.' snum){3};

IPv6_hex = xdigit{1,4};

IPv6_full = IPv6_hex (':' IPv6_hex){7};

IPv6_comp = (IPv6_hex (':' IPv6_hex){0,5})? '::' (IPv6_hex (':' IPv6_hex){0,5})?;

IPv6v4_full = IPv6_hex (':' IPv6_hex){5} ':' IPv4_address_literal;

IPv6v4_comp = (IPv6_hex (':' IPv6_hex){0,3})? '::' (IPv6_hex (':' IPv6_hex){0,3} ':')? IPv4_address_literal;

IPv6_addr = IPv6_full | IPv6_comp | IPv6v4_full | IPv6v4_comp;

IPv6_address_literal = 'IPv6:' IPv6_addr;

dcontent = graph - '\[' - '\\' - '\]';   # 33..90 | 94..126

standardized_tag = Ldh_str;

General_address_literal = standardized_tag ':' dcontent{1};

# See rfc 5321 Section 4.1.3
address_literal = '[' (IPv4_address_literal |
                  IPv6_address_literal | General_address_literal) ']';

qtextSMTP = print - '"' - '\\' | UTF8_non_ascii;

quoted_pairSMTP = '\\' print;

QcontentSMTP = qtextSMTP | quoted_pairSMTP;

Quoted_string = '"' QcontentSMTP* '"';

atext = alpha | digit |
        '!' | '#' |
        '$' | '%' |
        '&' | "'" |
        '*' | '+' |
        '-' | '/' |
        '=' | '?' |
        '^' | '_' |
        '`' | '{' |
        '|' | '}' |
        '~' | UTF8_non_ascii;

Atom = atext+;

Dot_string = Atom ('.'  Atom)*;

Local_part = Dot_string | Quoted_string;

Mailbox = Local_part '@' (Domain | address_literal);

main := Mailbox @{ result = true; } $err{ result = false; };

}%%

%% write data;

bool is_address(std::string_view s) noexcept
{
    // An insane length, to protect the parsing code from huge input. SMTP line limit, minus command size.
    constexpr auto insane_length = 1000 - "MAIL FROM:<>\r\n"sv.length();

    if (s.length() > insane_length)
      return false;

    int cs = 0;

    const char* p = s.begin();
    const char* pe = s.end();
    const char* eof = pe;

    bool result = false;

    %% write init;
    %% write exec;

    if (!result) // Failure to parse.
      return false;

    const auto at_idx = s.find_last_of("@"sv);
    const auto domain = s.substr(at_idx + 1);

    if (domain[0] == '[')       // An address literal.
      return true;

    // Further domain checks.
    if (domain.length() > 253)
      return false;

    bool tld = false;

    auto e = domain.length();
    for (std::string_view::size_type dot;
         (dot = domain.substr(0, e).find_last_of("."sv)) !=
           std::string_view::npos;
         e = dot) {
      const auto label = domain.substr(dot + 1, e);
      if (label.length() > 63)
        return false;
      if (!tld) {
        if (label.length() < 2)
          return false; // TLD too short
        tld = true;
      }
    }
    if (domain.substr(0, e).length() > 63)
      return false;

    if (!tld)
      return false; // domain not fully qualified

    return result;
}
