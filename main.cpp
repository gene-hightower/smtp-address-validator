#include "smtp-address-validator.hpp"

#include <stdio.h>

int main(int argc, char* argv[])
{
  const char* good_addresses[] = {
    "simple@example.com",
    "very.common@example.com",
    "disposable.style.email.with+symbol@example.com",
    "\" \"@example.org",
    "\"john..doe\"@example.org",
    "\"<john-doe>\"@example.org",
    "\"\\<john-doe\\>\"@example.org",
    "\"john\\@doe\"@example.org",
    "\"<john@doe>\"@example.org",
    "\"john.doe@example.com\"@example.org",
    "name-@example.org",
    "simple@[127.0.0.1]",
    "simple@[IPv6:::1]",
    "我買@屋企.香港"
  };

  for (auto good: good_addresses) {
    if (!is_address(good)) {
      fprintf(stderr, "Good address failed: \"%s\"\n", good);
      return 1;
    }
  }

  const char* bad_addresses[] = {
    "admin@mailserver1",        // used to be okay, now domain not fully qualified
    "\"john\\\\\"doe\"@example.org",
    "user@[300.0.0.1]",
    "user@[127.0.0.0.1]",
    "user@[127.0.1]",
    "user@[127.00.0.1]",
    "user@example.com#",
    "<user@example.com>",
    "user@example.com.",
    ".user@example.com",
    "user.@example.com",
    "john..doe@example.com",
    "foo bar@example.com",
    "foo.bar@bad=domain.com",
    "domain-too-long@XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.xyz",
    "tld-too-short@foo.x",
    "local-part@label_too_long_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.xyz"
  };

  for (auto bad: bad_addresses) {
    if (is_address(bad)) {
      fprintf(stderr, "Bad address should fail: \"%s\"\n", bad);
      return 2;
    }
  }

  return 0;
}
