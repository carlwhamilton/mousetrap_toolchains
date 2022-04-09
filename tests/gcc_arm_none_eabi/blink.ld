MEMORY {
 FLASH(rx) : ORIGIN = 0x00000000, LENGTH = 256K
 RAM(rw)   : ORIGIN = 0x20000000, LENGTH = 32K
}

SECTIONS {
  .text : {
    LONG(ORIGIN(RAM) + LENGTH(RAM))
    KEEP(*(.vector_table))
    *(.text .text.*)
  } >FLASH
}
