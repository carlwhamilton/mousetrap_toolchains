#include "tests/say.h"

#include <iostream>

void Say(std::string_view message, std::string_view who) {
  std::cout << message << ", " << who << "!\n";
}
