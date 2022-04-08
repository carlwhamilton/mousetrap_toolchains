#include <cstdint>

void start() {
  volatile uint32_t* portb_dir_set = reinterpret_cast<volatile uint32_t*>(0x41004488UL);
  volatile uint32_t* portb_out_toggle = reinterpret_cast<volatile uint32_t*>(0x4100449CUL);

  constexpr uint32_t pin_mask = (1 << 2);

  *portb_dir_set = pin_mask;
  while (true) {
    *portb_out_toggle = pin_mask;
    for (int i = 0; i < 25000; ++i);
  }
}

[[gnu::used, gnu::section(".vector_table")]]
void (* const reset_handler)() = start;
