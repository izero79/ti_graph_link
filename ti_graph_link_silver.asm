; Disassembly of TI silver Graph Link program data extracted from
; EEPROM connected to TUSB3410

; TUSB3410 contains 8052 microprocessor. The bootloader in ROM will
; Extract verify valid signature and program header and copy the program
; contents from EEPROM to RAM.

; Build with sdcc toolchain:
; $ make
; sdas8051 -lops ti_graph_link_silver.asm
; sdcc -mmcs51 --code-size 0x1400 ti_graph_link_silver.rel -o ti_graph_link_silver.hex
; makebin -p ti_graph_link_silver.hex ti_graph_link_silver.bin

; definitions of registers
OEPCNF_2   = 0xff10
OEPBBAX_2  = 0xff11
OEPBCTX_2  = 0xff12
OEPSIZXY_2 = 0xff17

IEPCNF_1   = 0xff48
IEPBBAX_1  = 0xff49
IEPBCTX_1  = 0xff4a
IEPSIZXY_1 = 0xff4f

IEPCNFG_0 = 0xff80
IEPBCNT_0 = 0xff81
OEPCNFG_0 = 0xff82
OEPBCNT_0 = 0xff83

WDCSR  = 0xff93
VECINT = 0xff92

I2CSTA  = 0xfff0
I2CDATO = 0xfff1
I2CADR  = 0xfff3

USBCTL = 0xfffc
USBMSK = 0xfffd
USBSTA = 0xfffe
FUNADR = 0xffff

.area PSEG    (PAG,XDATA)

;--------------------------------------------------------
; data
;--------------------------------------------------------
.area DSEG    (DATA)

  .word 0, 0, 0, 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0, 0, 0, 0

dat_20_start:
dat_20_end:

i2c_addr: ; 0x20
  .byte 0

dat_21:
  .byte 0

eeprom_addr:
  .word 0

dat_24:
  .word 0

dat_26:
  .byte 0
dat_27:   ; TODO: sometimes this is word, sometimes byte?
  .word 0

  .byte 0, 0, 0, 0, 0, 0, 0

  .word 0, 0, 0, 0, 0
  .byte 0

bss_start:
i2c_speed: ; 0x3b
  .byte 0

  .word 0

dat_3e:
  .word 0

  .word 0, 0, 0
  .byte 0

dat_47:
  .byte 0

  .byte 0, 0, 0, 0, 0, 0

dat_4e:
  .byte 0

  .byte 0, 0, 0, 0

dat_53:
  .byte 0
  .byte 0, 0, 0, 0, 0

dat_59:
  .byte 0

dat_5a:
  .byte 0

dat_5b:
  .byte 0

dat_5c:
  .byte 0

dat_5d:
  .byte 0

  .byte 0, 0, 0, 0
bss_end:

data_start:
dat_62:
  .word 0

dat_64:
  .byte 0

dat_65:
  .byte 0

  .byte 0, 0

dat_68:
  .byte 0
data_end:

stack_start:

;--------------------------------------------------------
; xdata
;--------------------------------------------------------
.area XSEG    (XDATA)

xdat_0001:

;--------------------------------------------------------
; code
;--------------------------------------------------------
.area HOME    (CODE)

; interrupt vector @ 0x0000
int_vec:
  ljmp  reset_isr  ; 0x0000: Reset
  ljmp  exti_isr   ; 0x0003: External Interrupt 0
  nop
  nop
  nop
  nop
  nop
  ljmp  timer0_isr ; 0x000b: Timer-0 Interrupt

;--------------------------------------------------------
; code
;--------------------------------------------------------
.area CSEG    (CODE)

reset_isr: ; 0x000e
  mov   sp, #stack_start-1
  lcall fcn_02c9
  mov   a, r4
  orl   a, r5
  jz    lbl_0082
  mov   r0, #bss_end-1
  sjmp  lbl_001f
lbl_001c:
  mov   @r0, #0x00
  dec   r0
lbl_001f:
  cjne  r0, #bss_start, lbl_001c
  mov   r0, #0x1f
  sjmp  lbl_0029
lbl_0026:
  mov   @r0, #0x00
  dec   r0
lbl_0029:
  cjne  r0, #0x1f, lbl_0026
  mov   r0, #0x1f
  sjmp  lbl_0033
lbl_0030:
  mov   @r0, #0x00
  dec   r0
lbl_0033:
  cjne  r0, #0x1f, lbl_0030
  mov   dptr, #0x0001
  mov   r6, dph
  mov   r7, dpl
  mov   dptr, #0x0001
lbl_0040:
  lcall ptr_equal
  jz    lbl_004a
  clr   a
  movx  @dptr, a
  inc   dptr
  sjmp  lbl_0040
lbl_004a:
  mov   dptr, #0x0001
  mov   r0, dpl
  mov   dptr, #0x0001
  mov   r1, dpl
lbl_0054:
  mov   a, r0
  clr   c
  subb  a, r1
  jnc   lbl_005e
  mov   @r0, #0x00
  inc   r0
  sjmp  lbl_0054
lbl_005e:
  mov   dptr, #cdat_00e9
  lcall data_copy
  mov   dptr, #cdat_00ed
  lcall data_copy
  mov   dptr, #cdat_00f1
  lcall data_copy
  mov   dptr, #cdat_00f5
  lcall xdata_copy
  mov   dptr, #cdat_00fb
  lcall xdata_copy
  mov   dptr, #cdat_0101
  lcall xdata_copy
lbl_0082:
  mov   psw, #0x00
  lcall fcn_042f
  ljmp  loop_forever

; return 0 if (r7 == dpl) && (r6 == dph)
; else return non-zero
ptr_equal: ; 008b
  mov   a, r7
  xrl   a, dpl
  jnz   lbl_0093
  mov   a, r6
  xrl   a, dph
lbl_0093:
  ret

; memcpy-like
; input: dptr (code) points to array of 3 pointers
;   uint8 dest_start (data)
;   uint8 dest_end (data)
;   uint16 source (code)
data_copy: ; 0094
  clr   a
  movc  a, @a+dptr
  mov   r0, a     ; r0 = dest_start
  mov   a, #0x01
  movc  a, @a+dptr
  mov   r1, a     ; r1 = dest_end
  mov   a, #0x02
  movc  a, @a+dptr
  mov   r6, a
  mov   a, #0x03
  movc  a, @a+dptr
  mov   dpl, a
  mov   dph, r6    ; dptr = source
lbl_00a6:
  mov   a, r0
  xrl   a, r1
  jnz   lbl_00ab   ; if r0 == r1, return
  ret
lbl_00ab:
  clr   a
  movc  a, @a+dptr ; a = *src
  mov   @r0, a     ; *dst = a
  inc   dptr       ; src++
  inc   r0         ; dst++
  sjmp  lbl_00a6

; memcpy-like
; input: dptr (code) points to array of 3 16-bit pointers
;   ptr[0] = dest (xdata)
;   ptr[1] = source_end (code)
;   ptr[2] = source_start (code)
xdata_copy:
  clr   a
  movc  a, @a+dptr
  mov   r4, a       ; r4 = dest.l
  mov   a, #0x01
  movc  a, @a+dptr
  mov   r5, a       ; r5 = dest.h
  mov   a, #0x02
  movc  a, @a+dptr
  mov   r6, a       ; r6 = source_end.l
  mov   a, #0x03
  movc  a, @a+dptr
  mov   r7, a       ; r7 = source_end.h
  mov   a, #0x04
  movc  a, @a+dptr
  mov   r0, a
  mov   a, #0x05
  movc  a, @a+dptr
  mov   dpl, a
  mov   dph, r0     ; dptr = source_start
lbl_00cc:
  lcall ptr_equal
  jnz   lbl_00d2  ; if source == source_end, return
  ret
lbl_00d2:
  clr   a
  movc  a, @a+dptr ; a = *src
  inc   dptr       ; dptr++
  mov   r0, dph
  mov   r1, dpl    ; r0, r1 = dptr (src += 1)
  mov   dph, r4
  mov   dpl, r5
  movx  @dptr, a   ; *dest = a
  inc   dptr
  mov   r4, dph
  mov   r5, dpl
  mov   dph, r0
  mov   dpl, r1    ; dptr = r0, r1
  sjmp  lbl_00cc

cdat_00e9:
  .byte dat_20_start, dat_20_end
  .word cdat_027e
cdat_00ed:
  .byte dat_20_start, dat_20_end
  .word cdat_027e
cdat_00f1:
  .byte data_start, data_end
  .word cdat_027e
cdat_00f5:
  .word xdat_0001, cdat_0285_start, cdat_0285_end
cdat_00fb:
  .word xdat_0001, cdat_0285_start, cdat_0285_end
cdat_0101:
  .word xdat_0001, cdat_02c9_start, cdat_02c9_end

loop_forever: ; 0107
  sjmp  loop_forever

; jump table lookup
; dptr: points to jump table
;   format: u16 jump_addr, u8 value
; a: value to compare
exti_isr_jmp_table_lookup: ; 0109
  pop   dph
  pop   dpl
  mov   b, a
lbl_010f:
  clr   a
  movc  a, @a+dptr
  jnz   lbl_011c
  mov   a, #0x01
  movc  a, @a+dptr
  jnz   lbl_011c
  inc   dptr
  inc   dptr
  sjmp  lbl_0128
lbl_011c:
  mov   a, #0x02
  movc  a, @a+dptr
  xrl   a, b
  jz    lbl_0128
  inc   dptr
  inc   dptr
  inc   dptr
  sjmp  lbl_010f
lbl_0128:
  mov   a, #0x01
  movc  a, @a+dptr
  push  acc
  clr   a
  movc  a, @a+dptr
  push  acc
  ret

; inputs: r5, r6, r7
; output: a
fcn_0132:
  lcall fcn_01ef    ; a = fcn_01ef(r5, r6, r7)
  ljmp  lbl_0138
lbl_0138:
  jnb   acc.0, lbl_0142
  jb    acc.3, lbl_0140
  mov   a, @r0      ; if (a == 0x01) return *r0;
  ret
lbl_0140:
  mov   a, @r1      ; else if (a == 0x09) return *r1;
  ret
lbl_0142:
  jnb   acc.1, lbl_014c
  jb    acc.3, lbl_014a
  movx  a, @r0      ; else if (a == 0x02) return *(xdat)r0;
  ret
lbl_014a:
  movx  a, @r1      ; else if (a == 0x0a) return *(xdat)r1;
  ret
lbl_014c:
  jnb   acc.2, lbl_0151
  movx  a, @dptr    ; else if (a == 0x04) return *(xdat)dptr;
  ret
lbl_0151:
  clr   a
  movc  a, @a+dptr  ; else return *(cdat)dptr;
  ret

fcn_0154:
  lcall fcn_0213
  ljmp  lbl_015a
lbl_015a:
  mov   r3, b
  lcall fcn_0164
  xch   a, r3
  xch   a, b
  xch   a, r3
  ret

fcn_0164:
  jnb   acc.0, lbl_0177
  jb    acc.3, lbl_0170
  mov   a, @r0
  mov   b, a
  inc   r0
  mov   a, @r0     ; if (a == 0x01) return a, b = *(r0+1), *r0;
  ret
lbl_0170:
  mov   a, @r1
  mov   b, a
  inc   r1
  mov   a, @r1
  dec   r1         ; else if (a == 0x09) return a, b = *(r1+1), *r1;
  ret
lbl_0177:
  jnb   acc.1, lbl_018a
  jb    acc.3, lbl_0183
  movx  a, @r0
  mov   b, a
  inc   r0
  movx  a, @r0     ; else if (a == 0x02) return a, b = *(xdata)(r0+1), *(xdata)r0;
  ret
lbl_0183:
  movx  a, @r1
  mov   b, a
  inc   r1
  movx  a, @r1
  dec   r1         ; else if (a == 0x0a) return a, b = *(xdata)(r1+1), *(xdata)r1;
  ret
lbl_018a:
  jnb   acc.2, lbl_0193
  movx  a, @dptr
  mov   b, a
  inc   dptr
  movx  a, @dptr   ; else if (a == 0x04) return a, b = *(xdata)(dptr+1), *(xdata)dptr;
  ret
lbl_0193:
  clr   a
  movc  a, @a+dptr
  mov   b, a
  mov   a, #0x01
  movc  a, @a+dptr ; else return a, b = *(cdat)(dptr+1), *(cdat)dptr;
  ret

; inputs: r1, r2, r3
; return: a
; fcn_019b(r1, r2, r3) {
;   switch (r3) {
;     case 0x00:
;       return 0x09;
;     case 0x01:
;       dptr = r2, r1;
;       return 0x04;
;     case 0x02:
;       dptr = r2, r1;
;       return 0x10;
;     default:
;       return 0x0a;
; }
fcn_019b:
  cjne  r3, #0x00, lbl_01a1
  mov   a, #0x09
  ret
lbl_01a1:
  cjne  r3, #0x01, lbl_01ab
  mov   dpl, r1
  mov   dph, r2
  mov   a, #0x04
  ret
lbl_01ab:
  cjne  r3, #0x02, lbl_01b5
  mov   dpl, r1
  mov   dph, r2
  mov   a, #0x10
  ret
lbl_01b5:
  mov   a, #0x0a
  ret

  ljmp  fcn_unused_01bb ; TODO: why?

; inputs: r1, r2, r3, dptr
; outputs: a, r0, dptr
; fcn_unused_01bb() {
;   switch (r3) {
;     case 0x00:
;       r0 = dpl + r1;
;       return 0x01;
;     case 0x01:
;       dptr += r2, r1;
;       return 0x04;
;     case 0x02:
;       dptr += r2, r1;
;       return 0x10;
;     default:
;       r0 = dpl + r1;
;       return 0x0a;
; }
fcn_unused_01bb:
  cjne  r3, #0x00, lbl_01c5
  mov   a, r1
  add   a, dpl
  mov   r0, a
  mov   a, #0x01
  ret
lbl_01c5:
  cjne  r3, #0x01, lbl_01d5
  mov   a, r1
  add   a, dpl
  mov   dpl, a
  mov   a, r2
  addc  a, dph
  mov   dph, a
  mov   a, #0x04
  ret
lbl_01d5:
  cjne  r3, #0x02, lbl_01e5
  mov   a, r1
  add   a, dpl
  mov   dpl, a
  mov   a, r2
  addc  a, dph
  mov   dph, a
  mov   a, #0x10
  ret
lbl_01e5:
  mov   a, r1
  add   a, dpl
  mov   r0, a
  mov   a, #0x02
  ret

  ljmp  fcn_01ef ; TODO: why?

; switch (r7) {
;   case 0: r0 = r5;       a = 1; break;
;   case 1: dptr = r5, r6; a = 4; break;
;   case 2: dptr = r5, r6; a = 16; break;
;   default: r0 = r5;      a = 2; break;
; }
fcn_01ef:
  cjne  r7, #0x00, lbl_01f7
  mov   a, r5
  mov   r0, a
  mov   a, #0x01
  ret
lbl_01f7:
  cjne  r7, #0x01, lbl_0201
  mov   dpl, r5
  mov   dph, r6
  mov   a, #0x04
  ret
lbl_0201:
  cjne  r7, #0x02, lbl_020b
  mov   dpl, r5
  mov   dph, r6
  mov   a, #0x10
  ret
lbl_020b:
  mov   a, r5
  mov   r0, a
  mov   a, #0x02
  ret

  ljmp  fcn_0213 ; TODO: why?

; inputs: r7, r5, r6, dpl, dph
; switch (r7) {
;   case 0x00:
;     r0 = r5 + dpl;
;     a = 0x01;
;     return;
;   case 0x01:
;     dpl = r5 + dpl;
;     dph = r6 + dph;
;     a = 0x04;
;     return;
;   case 0x02:
;     dpl = r5 + dpl;
;     dph = r6 + dph;
;     a = 0x10;
;     return;
;   default:
;     r0 = r5 + dpl;
;     a = 0x02;
;     return;
; }
fcn_0213:
  cjne  r7, #0x00, lbl_021d
  mov   a, r5
  add   a, dpl
  mov   r0, a
  mov   a, #0x01
  ret
lbl_021d:
  cjne  r7, #0x01, lbl_022d
  mov   a, r5
  add   a, dpl
  mov   dpl, a
  mov   a, r6
  addc  a, dph
  mov   dph, a
  mov   a, #0x04
  ret
lbl_022d:
  cjne  r7, #0x02, lbl_023d
  mov   a, r5
  add   a, dpl
  mov   dpl, a
  mov   a, r6
  addc  a, dph
  mov   dph, a
  mov   a, #0x10
  ret
lbl_023d:
  mov   a, r5
  add   a, dpl
  mov   r0, a
  mov   a, #0x02
  ret

  ljmp  fcn_unused_0247 ; TODO: why?

fcn_unused_0247:
  push  acc
  lcall fcn_019b
  ljmp  lbl_024f
lbl_024f:
  jnb   acc.0, lbl_025d
  jb    acc.3, lbl_0259
  pop   acc
  mov   @r0, a
  ret
lbl_0259:
  pop   acc
  mov   @r1, a
  ret
lbl_025d:
  jnb   acc.1, lbl_026b
  jb    acc.3, lbl_0267
  pop   acc
  movx  @r0, a
  ret
lbl_0267:
  pop   acc
  movx  @r1, a
  ret
lbl_026b:
  pop   acc
  movx  @dptr, a
  ret

; deref dptr from cdat
; dptr = *(u16 cdat*)dptr;
fcn_026f:
  mov   a, #0x01
  movc  a, @a+dptr
  mov   b, a
  clr   a
  movc  a, @a+dptr
  mov   dph, a
  mov   dpl, b
  ret

; jump to dptr
fcn_027c:
  clr   a
  jmp   @a+dptr

cdat_027e:
  .word 0x00fa
  .byte 0x00, 0x00, 0x00, 0x00, 0x00
cdat_0285_start:
cdat_0285_end:
  ; jump table for fcn_064b
  .word lbl_08fd, 0x0020
  .word lbl_0663, 0x0021
  .word lbl_06e5, 0x0027
  .word lbl_072a, 0x002a
  .word lbl_06f7, 0x0028
  .word lbl_07cb, 0x0027
  .word lbl_0807, 0x0028
  .word lbl_07b3, 0x0027
  .word lbl_07f5, 0x0027
  .word lbl_0770, 0x0029
  .word lbl_099d, 0x0020
  .word lbl_08ac, 0x0020
  .word lbl_08cb, 0x0020
  .word lbl_0918, 0x0020
  .word lbl_092c, 0x0021
  .word lbl_0990, 0x0020
  ; jump for fcn_0b67
  .word lbl_0bb1, 0x0029
cdat_02c9_start:
cdat_02c9_end:

; returns 0x01, 0x00
fcn_02c9:
  mov   r4, #0x01
  mov   r5, #0x00
  ret

exti_isr: ; 02ce
  push  acc
  push  b
  push  dpl
  push  dph
  push  psw
  mov   a, r0
  push  acc
  mov   a, r1
  push  acc
  mov   a, r2
  push  acc
  mov   a, r3
  push  acc
  mov   a, r4
  push  acc
  mov   a, r5
  push  acc
  mov   a, r6
  push  acc
  mov   a, r7
  push  acc
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  mov   dptr, #VECINT
  movx  a, @dptr
  lcall exti_isr_jmp_table_lookup
  ; jump table
  .word lbl_0328
  .byte 0x14
  .word lbl_031d
  .byte 0x22
  .word lbl_0346
  .byte 0x32
  .word lbl_0356
  .byte 0x38
  .word lbl_0367
  .byte 0x3a
  .word lbl_0378
  .byte 0x3c
  .word lbl_038c
  .byte 0x3e
  .word lbl_033c
  .byte 0x44
  .word lbl_0332
  .byte 0x46
  .word 0x0000    ; default case
  .word lbl_03a4
lbl_031d: ; 0x22 = Input endpoint 1
  lcall fcn_void_0b5c
  clr   a
  mov   dptr, #VECINT
  movx  @dptr, a
  ljmp  lbl_03aa
lbl_0328: ; 0x14 = Output endpoint 2
  lcall fcn_0b5d
  clr   a
  mov   dptr, #VECINT
  movx  @dptr, a
  sjmp  lbl_03aa
lbl_0332: ; 0x46 = Output endpoint 0
  lcall fcn_0b44
  clr   a
  mov   dptr, #VECINT
  movx  @dptr, a
  sjmp  lbl_03aa
lbl_033c: ; 0x44 = Input endpoint 0
  lcall fcn_0b2c
  clr   a
  mov   dptr, #VECINT
  movx  @dptr, a
  sjmp  lbl_03aa
lbl_0346: ; 0x32 = SETUP packet received
  lcall fcn_0ae0
  mov   a, #0x04
  mov   dptr, #USBSTA
  movx  @dptr, a
  clr   a
  mov   dptr, #VECINT
  movx  @dptr, a
  sjmp  lbl_03aa
lbl_0356: ; 0x38 = RESR interrupt
  mov   r0, #dat_64
  mov   @r0, #0x00
  mov   a, #0x20
  mov   dptr, #USBSTA
  movx  @dptr, a
  clr   a
  mov   dptr, #VECINT
  movx  @dptr, a
  sjmp  lbl_03aa
lbl_0367: ; 0x3a = SUSR interrupt
  mov   r0, #dat_64
  mov   @r0, #0x01
  mov   a, #0x40
  mov   dptr, #USBSTA
  movx  @dptr, a
  clr   a
  mov   dptr, #VECINT
  movx  @dptr, a
  sjmp  lbl_03aa
lbl_0378: ; 0x3c = RSTR interrupt
  mov   r0, #dat_64
  mov   @r0, #0x00
  lcall fcn_048e
  mov   a, #0x80
  mov   dptr, #USBSTA
  movx  @dptr, a
  clr   a
  mov   dptr, #VECINT
  movx  @dptr, a
  sjmp  lbl_03aa
lbl_038c: ; 0x3e = Wakeup
  mov   r0, #dat_64
  mov   @r0, #0x00
  mov   a, #0x02
  mov   dptr, #USBSTA
  movx  @dptr, a
  clr   a
  mov   dptr, #VECINT
  movx  @dptr, a
  mov   dptr, #USBCTL
  movx  a, @dptr
  orl   a, #0x20
  movx  @dptr, a
  sjmp  lbl_03aa
lbl_03a4: ; default
  mov   a, #0xff
  mov   dptr, #VECINT
  movx  @dptr, a
lbl_03aa:
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  pop   acc
  mov   r7, a
  pop   acc
  mov   r6, a
  pop   acc
  mov   r5, a
  pop   acc
  mov   r4, a
  pop   acc
  mov   r3, a
  pop   acc
  mov   r2, a
  pop   acc
  mov   r1, a
  pop   acc
  mov   r0, a
  pop   psw
  pop   dph
  pop   dpl
  pop   b
  pop   acc
  reti

; Timer-0 Interrupt Handler
; * kicks watchdog
; * reloads 0xF830 into th0/tl0
; * decrements 0x63, if 0, reload 0xfa and decrement dat_62
timer0_isr:
  push  acc
  push  dpl
  push  dph
  mov   a, r0
  push  acc
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  mov   th0, #0xf8 ; TH0: Timer0 high
  mov   tl0, #0x30 ; TL0: Timer0 low
  mov   r0, #dat_62
  mov   a, @r0
  jnz   lbl_03f9
  pop   acc
  mov   r0, a
  pop   dph
  pop   dpl
  pop   acc
  reti
lbl_03f9:
  mov   r0, #0x63
  dec   @r0
  mov   r0, #0x63
  mov   a, @r0
  jnz   lbl_0408
  mov   r0, #0x63
  mov   @r0, #0xfa
  mov   r0, #dat_62
  dec   @r0
lbl_0408:
  pop   acc
  mov   r0, a
  pop   dph
  pop   dpl
  pop   acc
  reti

initialize_hardware: ; 0412
  clr   ie.7        ; EA: disable all interrupts
  lcall usb_init
  mov   r4, #0x01
  lcall i2c_set_bus_speed
  anl   tmod, #0xf0 ; TMOD: timer mode
  orl   tmod, #0x01 ; TMOD: Timer0 = 16-bit
  mov   th0, #0xf8  ; TH0: Timer0 high
  mov   tl0, #0x30  ; TL0: Timer0 low
  clr   tcon.5      ; TF0: Timer0 overflow flag
  setb  tcon.4      ; TR0: Timer0 run control bit
  setb  ie.1        ; ET0: Timer0 interrupt enable
  ret

fcn_042f:
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  setb  p3.3
  setb  p3.4
  lcall initialize_hardware
  setb  ie.7       ; EA: enable all interrupts
  setb  ie.0       ; EX0: external interrupt 0 enable
  mov   dptr, #USBCTL
  movx  a, @dptr
  orl   a, #0x80
  movx  @dptr, a
lbl_0448:          ; while (dat_65 != 0x02) {
  mov   r0, #dat_65
  mov   a, @r0
  xrl   a, #0x02
  jz    lbl_0451
  sjmp  lbl_0448   ; }
lbl_0451:
  lcall fcn_0d90
  mov   r0, #dat_5c
  mov   a, @r0
  jnz   lbl_045e
  mov   r0, #dat_5b
  mov   a, @r0
  jz    lbl_0474
lbl_045e:
  mov   r0, #dat_5c
  mov   a, @r0
  mov   r0, #dat_5b
  orl   a, @r0
  mov   r1, #dat_53
  mov   r4, a
  mov   a, @r1
  orl   a, r4
  mov   r0, #dat_53
  mov   @r0, a
  mov   r0, #dat_5c
  mov   @r0, #0x00
  mov   r0, #dat_5b
  mov   @r0, #0x00
lbl_0474:
  mov   r0, #dat_64
  mov   a, @r0
  dec   a
  jnz   lbl_048b
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  orl   pcon, #0x01
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
lbl_048b:
  sjmp  lbl_0448
  ret

fcn_048e:
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  mov   r0, #dat_3e
  mov   a, #0xff
  mov   @r0, a
  inc   r0
  mov   @r0, a
  mov   r0, #0x40
  mov   a, #0xff
  mov   @r0, a
  inc   r0
  mov   @r0, a
  mov   r0, #dat_4e
  mov   @r0, #0x00
  mov   r0, #0x44
  clr   a
  mov   @r0, a
  inc   r0
  mov   @r0, a
  inc   r0
  mov   @r0, a
  mov   r0, #dat_47
  clr   a
  mov   @r0, a
  inc   r0
  mov   @r0, a
  inc   r0
  mov   @r0, a
  mov   r0, #0x3c
  mov   @r0, #0x00
  mov   r0, #0x3d
  mov   @r0, #0x00
  mov   r0, #dat_64
  mov   @r0, #0x00
  mov   a, #0x80
  mov   dptr, #IEPBCNT_0
  movx  @dptr, a
  mov   a, #0x80
  mov   dptr, #OEPBCNT_0
  movx  @dptr, a
  mov   a, #0x8c
  mov   dptr, #IEPCNFG_0
  movx  @dptr, a
  mov   a, #0x8c
  mov   dptr, #OEPCNFG_0
  movx  @dptr, a
  ljmp  fcn_0b67

usb_init: ; 04de
  clr   a
  mov   dptr, #FUNADR
  movx  @dptr, a        ; *FUNADR = 0x00
  mov   r0, #dat_64
  mov   @r0, #0x00
  clr   a
  mov   dptr, #USBCTL
  movx  @dptr, a       ; *USBCTL = 0x00
  clr   a
  mov   dptr, #IEPCNFG_0
  movx  @dptr, a       ; *IEPCNCFG_0 = 0x00
  clr   a
  mov   dptr, #OEPCNFG_0
  movx  @dptr, a       ; *OEPCNFG_0 = 0x00
  clr   a
  mov   dptr, #OEPCNF_2
  movx  @dptr, a       ; *OEPCNF_2 = 0x00
  mov   a, #0xe6
  mov   dptr, #USBMSK
  movx  @dptr, a       ; *USBMSK = RSTR | SUSR | RESR | SETUP | WAKEUP
  ret

; void fcn_0502(void) {
;   kick_watchdog();
;   *IEPCNFG_0 |= 0x08; // USB stall condition
;   *OEPCNFG_0 |= 0x08; // USB stall condition
; }
fcn_0502:
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  mov   dptr, #IEPCNFG_0
  movx  a, @dptr
  orl   a, #0x08   ; STALL
  movx  @dptr, a
  mov   dptr, #OEPCNFG_0
  movx  a, @dptr
  orl   a, #0x08   ; STALL
  movx  @dptr, a
  ret

; void clear_output_byte_count(void) {
;   kick_watchdog();
;   *OEPBCNT_0 = 0x00;
; }
clear_output_byte_count: ; 0518
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  clr   a
  mov   dptr, #OEPBCNT_0
  movx  @dptr, a
  ret

; void fcn_0525(void) {
;   kick_watchdog();
;   *OEPCNFG_0 |= 0x08; // USB stall condition
; }
fcn_0525:
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  mov   dptr, #OEPCNFG_0
  movx  a, @dptr
  orl   a, #0x08
  movx  @dptr, a
  ret

fcn_0534:
  mov   r0, #0x3f
  mov   a, @r0
  inc   a
  jnz   lbl_0542
  dec   r0
  mov   a, @r0
  inc   a
  jnz   lbl_0542
  ljmp  lbl_05e9
lbl_0542:
  setb  c
  mov   r0, #0x3f
  mov   a, @r0
  subb  a, #0x08
  dec   r0
  mov   a, @r0
  subb  a, #0x00
  jc    lbl_0563
  mov   r0, #0x3f
  mov   a, @r0
  add   a, #0xf8
  mov   @r0, a
  dec   r0
  mov   a, @r0
  addc  a, #0xff
  mov   @r0, a
  mov   r0, #dat_4e
  mov   @r0, #0x01
  mov   r0, #0x20
  mov   @r0, #0x08
  sjmp  lbl_05a5
lbl_0563:
  clr   c
  mov   r0, #0x3f
  mov   a, @r0
  subb  a, #0x08
  dec   r0
  mov   a, @r0
  subb  a, #0x00
  jnc   lbl_0582
  mov   r0, #0x3f
  mov   a, @r0
  mov   r0, #0x20
  mov   @r0, a
  mov   r0, #dat_3e
  mov   a, #0xff
  mov   @r0, a
  inc   r0
  mov   @r0, a
  mov   r0, #dat_4e
  mov   @r0, #0x00
  sjmp  lbl_05a5
lbl_0582:
  mov   r0, #0x20
  mov   @r0, #0x08
  mov   r0, #0x43
  mov   a, @r0
  dec   a
  dec   r0
  orl   a, @r0
  jnz   lbl_059a
  mov   r0, #dat_3e
  clr   a
  mov   @r0, a
  inc   r0
  mov   @r0, a
  mov   r0, #dat_4e
  mov   @r0, #0x01
  sjmp  lbl_05a5
lbl_059a:
  mov   r0, #dat_3e
  mov   a, #0xff
  mov   @r0, a
  inc   r0
  mov   @r0, a
  mov   r0, #dat_4e
  mov   @r0, #0x00
lbl_05a5:
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  mov   r0, #0x21
  mov   @r0, #0x00
lbl_05b0:
  mov   r0, #0x21
  mov   a, @r0
  clr   c
  mov   r0, #0x20
  subb  a, @r0
  jnc   lbl_05e0
  mov   r0, #0x44
  mov   a, @r0
  mov   r7, a
  inc   r0
  mov   a, @r0
  mov   r6, a
  inc   r0
  mov   a, @r0
  mov   r5, a
  inc   a
  mov   @r0, a
  dec   r0
  jnz   lbl_05c9
  inc   @r0
lbl_05c9:
  lcall fcn_0132
  mov   r4, a
  mov   r0, #0x21
  mov   a, @r0
  add   a, #0xf8
  mov   dpl, a
  clr   a
  addc  a, #0xfe
  mov   dph, a
  mov   a, r4
  movx  @dptr, a
  mov   r0, #0x21
  inc   @r0
  sjmp  lbl_05b0
lbl_05e0:
  mov   r0, #0x20
  mov   a, @r0
  mov   dptr, #IEPBCNT_0
  movx  @dptr, a
  sjmp  lbl_05ed
lbl_05e9:
  mov   r0, #dat_4e
  mov   @r0, #0x00
lbl_05ed:
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  ret

fcn_05f5:
  mov   r0, #0x44
  mov   a, r7
  mov   @r0, a
  inc   r0
  mov   a, r6
  mov   @r0, a
  inc   r0
  mov   a, r5
  mov   @r0, a
  mov   r0, #0x24
  mov   a, r7
  mov   @r0, a
  inc   r0
  mov   a, r6
  mov   @r0, a
  inc   r0
  mov   a, r5
  mov   @r0, a
  mov   dptr, #0xff07 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  mov   r4, a
  mov   dptr, #0xff06 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  xch   a, r4
  mov   r7, a
  xch   a, r4
  mov   r0, #0x23
  mov   @r0, a
  mov   a, r7
  dec   r0
  mov   @r0, a
  mov   r0, #dat_3e
  mov   a, @r0
  mov   r5, a
  inc   r0
  mov   a, @r0
  mov   r0, #0x23
  clr   c
  subb  a, @r0
  mov   a, r5
  dec   r0
  subb  a, @r0
  jc    lbl_063e
  mov   r0, #0x22
  mov   a, @r0
  mov   r5, a
  inc   r0
  mov   a, @r0
  mov   r0, #0x3f
  mov   @r0, a
  mov   a, r5
  dec   r0
  mov   @r0, a
  mov   r0, #0x42
  clr   a
  mov   @r0, a
  inc   r0
  mov   @r0, a
  sjmp  lbl_0645
lbl_063e:
  mov   r0, #0x42
  clr   a
  mov   @r0, a
  inc   r0
  inc   a
  mov   @r0, a
lbl_0645:
  ljmp  fcn_0534

fcn_0648:
  ljmp  fcn_0525

fcn_064b:
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  mov   r0, #dat_3e
  mov   a, #0xff
  mov   @r0, a
  inc   r0
  mov   @r0, a
  mov   r0, #dat_4e
  mov   @r0, #0x00
  clr   a
  mov   dptr, #IEPBCNT_0
  movx  @dptr, a
  ret
lbl_0663:
  mov   dptr, #0xff04 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  anl   a, #0x0f
  mov   r0, #0x20
  mov   @r0, a
  mov   r0, #0x20
  mov   a, @r0
  jnz   lbl_0676
  lcall fcn_064b
  sjmp  lbl_06dd
lbl_0676:
  mov   r0, #0x20
  dec   @r0
  mov   r0, #0x20
  mov   a, @r0
  add   a, #0xfd
  jc    lbl_06dd
  mov   r0, #0x20
  mov   a, @r0
  jnz   lbl_06ae
  mov   r0, #0x20
  mov   a, @r0
  mov   b, #0x08
  mul   ab
  add   a, #0x48
  mov   dpl, a
  clr   a
  addc  a, #0xff
  mov   dph, a
  movx  a, @dptr
  anl   a, #0xd7
  movx  @dptr, a
  mov   r0, #0x20
  mov   a, @r0
  mov   b, #0x08
  mul   ab
  add   a, #0x4a
  mov   dpl, a
  clr   a
  addc  a, #0xff
  mov   dph, a
  mov   a, #0x80
  movx  @dptr, a
  sjmp  lbl_06da
lbl_06ae:
  mov   r0, #0x20
  mov   a, @r0
  dec   a
  jnz   lbl_06da
  mov   r0, #0x20
  mov   a, @r0
  mov   b, #0x08
  mul   ab
  add   a, #0x08
  mov   dpl, a
  clr   a
  addc  a, #0xff
  mov   dph, a
  movx  a, @dptr
  anl   a, #0xd7
  movx  @dptr, a
  mov   r0, #0x20
  mov   a, @r0
  mov   b, #0x08
  mul   ab
  add   a, #0x0a
  mov   dpl, a
  clr   a
  addc  a, #0xff
  mov   dph, a
  clr   a
  movx  @dptr, a
lbl_06da:
  lcall fcn_064b
lbl_06dd:
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  ret
lbl_06e5:
  lcall clear_output_byte_count
  mov   r0, #dat_3e
  clr   a
  mov   @r0, a
  inc   r0
  inc   a
  mov   @r0, a
  mov   r5, #0x3c
  clr   a
  mov   r6, a
  mov   r7, a
  ljmp  fcn_05f5
lbl_06f7:
  mov   r7, #0x00
lbl_06f9:
  mov   a, r7
  add   a, #0xee
  jc    lbl_0713
  mov   a, r7
  mov   dptr, #cdat_0fb3
  movc  a, @a+dptr
  mov   r4, a
  mov   a, r7
  add   a, #0x40 ; 0xf840 + r7
  mov   dpl, a
  clr   a
  addc  a, #0xf8 ; 0xf840 + r7
  mov   dph, a
  mov   a, r4
  movx  @dptr, a
  inc   r7
  sjmp  lbl_06f9
lbl_0713:
  mov   r0, #dat_27
  mov   a, r7
  mov   @r0, a
  lcall clear_output_byte_count
  mov   r0, #dat_3e
  clr   a
  mov   @r0, a
  inc   r0
  mov   @r0, #0x12
  mov   r5, #0x40
  mov   r6, #0xf8
  mov   r7, #0x01
  ljmp  fcn_05f5
lbl_072a:
  mov   r7, #0x00
lbl_072c:
  mov   a, r7
  add   a, #0xe0
  jc    lbl_0746
  mov   a, r7
  mov   dptr, #cdat_0fc5
  movc  a, @a+dptr
  mov   r4, a
  mov   a, r7
  add   a, #0x40
  mov   dpl, a
  clr   a
  addc  a, #0xf8 ; 0xf840 + r7
  mov   dph, a
  mov   a, r4
  movx  @dptr, a
  inc   r7
  sjmp  lbl_072c
lbl_0746:
  mov   r0, #dat_27
  mov   a, r7
  mov   @r0, a
  mov   a, #0x20
  mov   dptr, #0xf842 ; 0xf800-0xfeef: 2k data
  movx  @dptr, a
  clr   a
  mov   dptr, #0xf843 ; 0xf800-0xfeef: 2k data
  movx  @dptr, a
  lcall clear_output_byte_count
  mov   r0, #dat_3e
  clr   a
  mov   @r0, a
  inc   r0
  mov   @r0, #0x20
  mov   r5, #0x40
  mov   r6, #0xf8     ; r6, r5 = 0xf840
  mov   r7, #0x01
  lcall fcn_05f5
  mov   r0, #0x28
  clr   a
  mov   @r0, a
  inc   r0
  mov   @r0, #0x20
  ret
lbl_0770:
  lcall clear_output_byte_count
  clr   a
  mov   r6, a
  mov   r7, a
lbl_0776:
  mov   dptr, #0xff02 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  mov   r4, a
  dec   a
  movx  @dptr, a
  mov   a, r4
  jz    lbl_0790
  mov   a, r6
  mov   dptr, #cdat_0fe5
  movc  a, @a+dptr
  mov   r5, #0x00
  mov   r4, a
  mov   a, r6
  add   a, r4
  mov   r6, a
  mov   a, r7
  addc  a, r5
  mov   r7, a
  sjmp  lbl_0776
lbl_0790:
  mov   r0, #dat_27
  mov   a, r7
  mov   @r0, a
  inc   r0
  mov   a, r6
  mov   @r0, a
  mov   r0, #0x28
  mov   a, @r0
  mov   dptr, #cdat_0fe5
  movc  a, @a+dptr
  mov   r0, #0x3f
  mov   @r0, a
  clr   a
  dec   r0
  mov   @r0, a
  mov   r0, #0x28
  mov   a, @r0
  add   a, #0xe5
  mov   r5, a
  clr   a
  addc  a, #0x0f
  mov   r6, a
  mov   r7, #0x02
  ljmp  fcn_05f5
lbl_07b3:
  lcall clear_output_byte_count
  mov   r0, #dat_3e
  clr   a
  mov   @r0, a
  inc   r0
  inc   a
  mov   @r0, a
  mov   r0, #0x3d
  mov   a, @r0
  mov   r0, #0x4a
  mov   @r0, a
  mov   r5, #0x4a
  clr   a
  mov   r6, a
  mov   r7, a
  ljmp  fcn_05f5
lbl_07cb:
  mov   dptr, #cdat_0fcc
  clr   a
  movc  a, @a+dptr
  jnb   acc.6, lbl_07d7
  mov   r0, #0x4a
  mov   @r0, #0x01
lbl_07d7:
  mov   r0, #0x4f
  mov   a, @r0
  dec   a
  jnz   lbl_07e3
  mov   r0, #0x4a
  xch   a, @r0
  orl   a, #0x02
  mov   @r0, a
lbl_07e3:
  lcall clear_output_byte_count
  mov   r0, #dat_3e
  clr   a
  mov   @r0, a
  inc   r0
  mov   @r0, #0x02
  mov   r5, #0x4a
  clr   a
  mov   r6, a
  mov   r7, a
  ljmp  fcn_05f5
lbl_07f5:
  lcall clear_output_byte_count
  mov   r0, #dat_3e
  clr   a
  mov   @r0, a
  inc   r0
  mov   @r0, #0x02
  mov   r5, #0x4a
  clr   a
  mov   r6, a
  mov   r7, a
  ljmp  fcn_05f5
lbl_0807:
  mov   dptr, #0xff04 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  anl   a, #0x0f
  mov   r0, #dat_27
  mov   @r0, a
  mov   r0, #dat_27
  mov   a, @r0
  jnz   lbl_084d
  mov   dptr, #0xff04 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  jnb   acc.7, lbl_0827
  mov   dptr, #IEPCNFG_0
  movx  a, @dptr
  anl   a, #0x08
  mov   r0, #0x4a
  mov   @r0, a
  sjmp  lbl_0830
lbl_0827:
  mov   dptr, #OEPCNFG_0
  movx  a, @dptr
  anl   a, #0x08
  mov   r0, #0x4a
  mov   @r0, a
lbl_0830:
  mov   r0, #0x4a
  xch   a, @r0
  rr    a
  rr    a
  rr    a
  anl   a, #0x1f
  mov   @r0, a
  lcall clear_output_byte_count
  mov   r0, #dat_3e
  clr   a
  mov   @r0, a
  inc   r0
  mov   @r0, #0x02
  mov   r5, #0x4a
  clr   a
  mov   r6, a
  mov   r7, a
  lcall fcn_05f5
  sjmp  lbl_08ab
lbl_084d:
  mov   r0, #dat_27
  dec   @r0
  mov   r0, #dat_27
  mov   a, @r0
  add   a, #0xfd
  jc    lbl_0890
  mov   r0, #dat_27
  mov   a, @r0
  jnz   lbl_0874
  mov   r0, #dat_27
  mov   a, @r0
  mov   b, #0x08
  mul   ab
  add   a, #0x48
  mov   dpl, a
  clr   a
  addc  a, #0xff
  mov   dph, a
  movx  a, @dptr
  anl   a, #0x08
  mov   r0, #0x4a
  mov   @r0, a
  sjmp  lbl_0890
lbl_0874:
  mov   r0, #dat_27
  mov   a, @r0
  dec   a
  jnz   lbl_0890
  mov   r0, #dat_27
  mov   a, @r0
  mov   b, #0x08
  mul   ab
  add   a, #0x08
  mov   dpl, a
  clr   a
  addc  a, #0xff
  mov   dph, a
  movx  a, @dptr
  anl   a, #0x08
  mov   r0, #0x4a
  mov   @r0, a
lbl_0890:
  mov   r0, #0x4a
  xch   a, @r0
  rr    a
  rr    a
  rr    a
  anl   a, #0x1f
  mov   @r0, a
  lcall clear_output_byte_count
  mov   r0, #dat_3e
  clr   a
  mov   @r0, a
  inc   r0
  mov   @r0, #0x02
  mov   r5, #0x4a
  clr   a
  mov   r6, a
  mov   r7, a
  lcall fcn_05f5
lbl_08ab:
  ret
lbl_08ac:
  lcall fcn_0525
  mov   dptr, #0xff02 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  rlc   a
  jc    lbl_08c7
  mov   dptr, #0xff02 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  mov   dptr, #FUNADR
  movx  @dptr, a
  mov   r0, #dat_65
  mov   @r0, #0x01
  lcall fcn_064b
  sjmp  lbl_08ca
lbl_08c7:
  lcall fcn_0502
lbl_08ca:
  ret
lbl_08cb:
  lcall fcn_0525
  mov   dptr, #0xff02 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  mov   r0, #0x3c
  mov   @r0, a
  mov   r0, #0x3c
  mov   a, @r0
  jnz   lbl_08ea
  mov   r0, #dat_65
  mov   @r0, #0x01
  clr   a
  mov   dptr, #IEPCNF_1
  movx  @dptr, a
  clr   a
  mov   dptr, #OEPCNF_2
  movx  @dptr, a
  sjmp  lbl_08fa
lbl_08ea:
  mov   r0, #dat_65
  mov   @r0, #0x02
  mov   a, #0x84
  mov   dptr, #IEPCNF_1
  movx  @dptr, a
  mov   a, #0x84
  mov   dptr, #OEPCNF_2
  movx  @dptr, a
lbl_08fa:
  ljmp  fcn_064b
lbl_08fd:
  mov   dptr, #0xff02 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  dec   a
  jnz   lbl_0914
  mov   r0, #0x4f
  mov   @r0, #0x00
  mov   dptr, #USBMSK
  movx  a, @dptr
  anl   a, #0xfd
  movx  @dptr, a
  lcall fcn_064b
  sjmp  lbl_0917
lbl_0914:
  lcall fcn_0502
lbl_0917:
  ret
lbl_0918:
  mov   dptr, #0xff02 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  dec   a
  jnz   lbl_0928
  mov   r0, #0x4f
  mov   @r0, #0x01
  lcall fcn_064b
  sjmp  lbl_092b
lbl_0928:
  lcall fcn_0502
lbl_092b:
  ret
lbl_092c:
  lcall fcn_0525
  mov   dptr, #0xff02 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  jnz   lbl_098c
  mov   dptr, #0xff04 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  anl   a, #0x0f
  mov   r0, #0x20
  mov   @r0, a
  mov   r0, #0x20
  mov   a, @r0
  jnz   lbl_0948
  lcall fcn_064b
  sjmp  lbl_098a
lbl_0948:
  mov   r0, #0x20
  dec   @r0
  mov   r0, #0x20
  mov   a, @r0
  add   a, #0xfd
  jc    lbl_098a
  mov   r0, #0x20
  mov   a, @r0
  jnz   lbl_096d
  mov   r0, #0x20
  mov   a, @r0
  mov   b, #0x08
  mul   ab
  add   a, #0x48
  mov   dpl, a
  clr   a
  addc  a, #0xff
  mov   dph, a
  movx  a, @dptr
  orl   a, #0x08
  movx  @dptr, a
  sjmp  lbl_0987
lbl_096d:
  mov   r0, #0x20
  mov   a, @r0
  dec   a
  jnz   lbl_0987
  mov   r0, #0x20
  mov   a, @r0
  mov   b, #0x08
  mul   ab
  add   a, #0x08
  mov   dpl, a
  clr   a
  addc  a, #0xff
  mov   dph, a
  movx  a, @dptr
  orl   a, #0x08
  movx  @dptr, a
lbl_0987:
  lcall fcn_064b
lbl_098a:
  sjmp  lbl_098f
lbl_098c:
  lcall fcn_0502
lbl_098f:
  ret
lbl_0990:
  lcall fcn_0525
  mov   dptr, #0xff04 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  mov   r0, #0x3d
  mov   @r0, a
  ljmp  fcn_064b
lbl_099d:
  mov   dptr, #USBSTA
  movx  a, @dptr
  jb    acc.0, lbl_09a7
  lcall fcn_0502
lbl_09a7:
  ret

fcn_09a8:
  mov   r7, #0x00
lbl_09aa:
  mov   a, r7
  add   a, #0xf8
  jc    lbl_09c3
  mov   dpl, r7
  mov   r5, #0x00
  mov   a, r5
  add   a, #0xff
  mov   dph, a
  movx  a, @dptr
  mov   r4, a
  mov   a, r7
  add   a, #0x30
  mov   r0, a
  mov   a, r4
  mov   @r0, a
  inc   r7
  sjmp  lbl_09aa
lbl_09c3:
  mov   r0, #0x2c
  mov   a, r7
  mov   @r0, a
  mov   r0, #0x2d
  mov   @r0, #0x02
  inc   r0
  mov   @r0, #0x10
  inc   r0
  mov   @r0, #0x31
lbl_09d1:
  mov   r0, #0x2d
  mov   a, @r0
  mov   r7, a
  inc   r0
  mov   a, @r0
  mov   r6, a
  inc   r0
  mov   a, @r0
  mov   r5, a
  inc   a
  mov   @r0, a
  dec   r0
  jnz   lbl_09e1
  inc   @r0
lbl_09e1:
  lcall fcn_0132
  mov   r4, a
  mov   r0, #0x2d
  mov   a, @r0
  mov   r7, a
  inc   r0
  mov   a, @r0
  mov   r6, a
  inc   r0
  mov   a, @r0
  mov   r5, a
  inc   a
  mov   @r0, a
  dec   r0
  jnz   lbl_09f5
  inc   @r0
lbl_09f5:
  lcall fcn_0132
  mov   r0, #0x39
  mov   @r0, a
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  mov   r0, #0x38
  mov   a, r4
  mov   @r0, a
  inc   a
  jnz   lbl_0a0f
  mov   r0, #0x39
  mov   a, @r0
  inc   a
  jz    lbl_0a1c
lbl_0a0f:
  mov   r0, #0x30
  mov   a, @r0
  xrl   a, #0xc0
  jz    lbl_0a1c
  mov   r0, #0x30
  mov   a, @r0
  cjne  a, #0x40, lbl_0a2a
lbl_0a1c:
  mov   r0, #0x2f
  mov   a, @r0
  add   a, #0xfe
  mov   @r0, a
  dec   r0
  mov   a, @r0
  addc  a, #0xff
  mov   @r0, a
  ljmp  lbl_0abe
lbl_0a2a:
  mov   r0, #0x38
  mov   a, @r0
  mov   r0, #0x30
  xrl   a, @r0
  jnz   lbl_0ab0
  mov   r0, #0x39
  mov   a, @r0
  mov   r0, #0x31
  xrl   a, @r0
  jnz   lbl_0ab0
  mov   r0, #0x2b
  mov   @r0, #0xc0
  mov   r0, #0x2a
  mov   @r0, #0x20
  mov   r0, #0x2c
  mov   @r0, #0x02
lbl_0a46:
  mov   r0, #0x2c
  mov   a, @r0
  add   a, #0xf8
  jc    lbl_0a7f
  mov   r0, #0x2c
  mov   a, @r0
  add   a, #0x30
  mov   r0, a
  mov   a, @r0
  mov   r4, a
  mov   r0, #0x2d
  mov   a, @r0
  mov   r7, a
  inc   r0
  mov   a, @r0
  mov   r6, a
  inc   r0
  mov   a, @r0
  mov   r5, a
  inc   a
  mov   @r0, a
  dec   r0
  jnz   lbl_0a65
  inc   @r0
lbl_0a65:
  lcall fcn_0132
  xrl   a, r4
  jnz   lbl_0a74
  mov   r0, #0x2b
  mov   a, @r0
  mov   r1, #0x2a
  orl   a, @r1
  mov   r1, #0x2b
  mov   @r1, a
lbl_0a74:
  mov   r0, #0x2a
  xch   a, @r0
  clr   c
  rrc   a
  mov   @r0, a
  mov   r0, #0x2c
  inc   @r0
  sjmp  lbl_0a46
lbl_0a7f:
  mov   r0, #0x2d
  mov   a, @r0
  mov   r7, a
  inc   r0
  mov   a, @r0
  mov   r6, a
  inc   r0
  mov   a, @r0
  mov   r5, a
  lcall fcn_0132
  mov   r0, #0x2b
  anl   a, @r0
  mov   r4, a
  lcall fcn_0132
  xrl   a, r4
  jnz   lbl_0aa3
  mov   r0, #0x2f
  mov   a, @r0
  add   a, #0xf8
  mov   @r0, a
  dec   r0
  mov   a, @r0
  addc  a, #0xff
  mov   @r0, a
  sjmp  lbl_0abe
lbl_0aa3:
  mov   r0, #0x2f
  mov   a, @r0
  add   a, #0x03
  mov   @r0, a
  dec   r0
  mov   a, @r0
  addc  a, #0x00
  mov   @r0, a
  sjmp  lbl_0abb
lbl_0ab0:
  mov   r0, #0x2f
  mov   a, @r0
  add   a, #0x09
  mov   @r0, a
  dec   r0
  mov   a, @r0
  addc  a, #0x00
  mov   @r0, a
lbl_0abb:
  ljmp  lbl_09d1
lbl_0abe:
  mov   dptr, #USBSTA
  movx  a, @dptr
  jnb   acc.0, lbl_0ac6
  ret
lbl_0ac6:
  mov   r0, #0x2d
  mov   a, @r0
  mov   r7, a
  inc   r0
  mov   a, @r0
  mov   r6, a
  inc   r0
  mov   a, @r0
  mov   r5, a
  mov   dptr, #0x0009
  lcall fcn_0154
  mov   dpl, a
  mov   dph, r3
  lcall fcn_026f
  ljmp  fcn_027c

fcn_0ae0:
  mov   a, #0x80
  mov   dptr, #IEPBCNT_0
  movx  @dptr, a
  mov   a, #0x80
  mov   dptr, #OEPBCNT_0
  movx  @dptr, a
lbl_0aec:
  mov   dptr, #USBCTL
  movx  a, @dptr
  orl   a, #0x02
  movx  @dptr, a
  mov   dptr, #0xff00 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  jnb   acc.7, lbl_0b03
  mov   dptr, #USBCTL
  movx  a, @dptr
  orl   a, #0x01
  movx  @dptr, a
  sjmp  lbl_0b0a
lbl_0b03:
  mov   dptr, #USBCTL
  movx  a, @dptr
  anl   a, #0xfe
  movx  @dptr, a
lbl_0b0a:
  mov   r0, #dat_4e
  mov   @r0, #0x00
  mov   r0, #0x4a
  mov   r2, #0x04
  clr   a
lbl_0b13:
  mov   @r0, a
  inc   r0
  djnz  r2, lbl_0b13
  mov   r2, #0x04
  lcall fcn_09a8
  mov   dptr, #USBSTA
  movx  a, @dptr
  jnb   acc.0, lbl_0b2b
  mov   a, #0x01
  mov   dptr, #USBSTA
  movx  @dptr, a
  sjmp  lbl_0aec
lbl_0b2b:
  ret

; *OEPBCNT_0 = 0x00;
; if (dat_4e == 0x01) {
;   fcn_0534();
; } else {
;   *IEPCNFG_0 |= 0x08; // USB stall condition
; }
fcn_0b2c:
  clr   a
  mov   dptr, #OEPBCNT_0
  movx  @dptr, a
  mov   r0, #dat_4e
  mov   a, @r0
  dec   a
  jnz   lbl_0b3c
  lcall fcn_0534
  sjmp  lbl_0b43
lbl_0b3c:
  mov   dptr, #IEPCNFG_0
  movx  a, @dptr
  orl   a, #0x08 ; STALL
  movx  @dptr, a
lbl_0b43:
  ret

; *IEPBCNT_0 = 0x00;
; if (dat_4e == 0x02) {
;   fcn_0648();
; } else {
;   *OEPCNFG_0 |= 0x08; // USB stall condition
; }
fcn_0b44:
  clr   a
  mov   dptr, #IEPBCNT_0
  movx  @dptr, a
  mov   r0, #dat_4e
  mov   a, @r0
  cjne  a, #0x02, lbl_0b54
  lcall fcn_0648
  sjmp  lbl_0b5b
lbl_0b54:
  mov   dptr, #OEPCNFG_0
  movx  a, @dptr
  orl   a, #0x08  ; STALL
  movx  @dptr, a
lbl_0b5b:
  ret

fcn_void_0b5c:
  ret

; dat_5a = *OEPBCTX_2 & 0x7f;  // clear NAK bit
fcn_0b5d:
  mov   dptr, #OEPBCTX_2
  movx  a, @dptr
  anl   a, #0x7f
  mov   r0, #dat_5a
  mov   @r0, a
  ret

fcn_0b67:
  clr   a
  mov   dptr, #IEPCNF_1
  movx  @dptr, a
  clr   a
  mov   dptr, #IEPBBAX_1
  movx  @dptr, a
  mov   a, #0x80
  mov   dptr, #IEPBCTX_1
  movx  @dptr, a
  mov   a, #0x20
  mov   dptr, #IEPSIZXY_1
  movx  @dptr, a
  clr   a
  mov   dptr, #OEPCNF_2
  movx  @dptr, a
  mov   a, #0x30
  mov   dptr, #OEPBBAX_2
  movx  @dptr, a
  clr   a
  mov   dptr, #OEPBCTX_2
  movx  @dptr, a
  mov   a, #0x20
  mov   dptr, #OEPSIZXY_2
  movx  @dptr, a
  mov   r0, #0x52
  mov   @r0, #0x00
  mov   r0, #0x51
  mov   @r0, #0xb4
  mov   r0, #0x51
  mov   a, @r0
  mov   b, #0x0a
  div   ab
  mov   r0, #0x55
  mov   @r0, a
  clr   a
  dec   r0
  mov   @r0, a
  mov   r0, #0x50
  mov   @r0, #0x20
  mov   r0, #dat_53
  mov   @r0, #0x00
  ret
lbl_0bb1:
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  mov   dptr, #0xff01 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  cjne  a, #0x81, lbl_0be8
  mov   dptr, #0xff02 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  mov   r0, #0x52
  mov   @r0, a
  mov   dptr, #0xff03 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  mov   r0, #0x56
  mov   @r0, a
  jnb   acc.7, lbl_0bd6
  mov   r0, #dat_53
  xch   a, @r0
  anl   a, #0x80
  mov   @r0, a
lbl_0bd6:
  mov   r0, #0x56
  mov   a, @r0
  jnb   acc.0, lbl_0be2
  mov   r0, #dat_53
  xch   a, @r0
  orl   a, #0x80
  mov   @r0, a
lbl_0be2:
  lcall fcn_064b
  ljmp  lbl_0c9f
lbl_0be8:
  mov   dptr, #0xff01 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  cjne  a, #0x82, lbl_0c32
  mov   dptr, #0xff03 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  add   a, #0xdf
  jnc   lbl_0bfa
  ljmp  fcn_0502
lbl_0bfa:
  mov   dptr, #0xff03 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  jnz   lbl_0c06
  mov   r0, #0x50
  mov   @r0, #0x20
  sjmp  lbl_0c0d
lbl_0c06:
  mov   dptr, #0xff03 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  mov   r0, #0x50
  mov   @r0, a
lbl_0c0d:
  mov   dptr, #0xff02 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  jnz   lbl_0c19
  mov   r0, #0x51
  mov   @r0, #0xb4
  sjmp  lbl_0c20
lbl_0c19:
  mov   dptr, #0xff02 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  mov   r0, #0x51
  mov   @r0, a
lbl_0c20:
  mov   r0, #0x51
  mov   a, @r0
  mov   b, #0x0a
  div   ab
  mov   r0, #0x55
  mov   @r0, a
  clr   a
  dec   r0
  mov   @r0, a
  lcall fcn_064b
  sjmp  lbl_0c9f
lbl_0c32:
  mov   dptr, #0xff01 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  cjne  a, #0x83, lbl_0c4a
  mov   r0, #dat_3e
  clr   a
  mov   @r0, a
  inc   r0
  mov   @r0, #0x04
  mov   r5, #0x50
  clr   a
  mov   r6, a
  mov   r7, a
  lcall fcn_05f5
  sjmp  lbl_0c9f
lbl_0c4a:
  mov   dptr, #0xff01 ; 0xff00-0xff07: setup packet
  movx  a, @dptr
  cjne  a, #0xa2, lbl_0c9c
  mov   a, #0x2a      ; 0b0010_1010: disable watchdog
  mov   dptr, #WDCSR
  movx  @dptr, a
  clr   a
  mov   r0, #0x26
  mov   @r0, a
  inc   r0
  mov   @r0, a
  inc   r0
  mov   @r0, #0x66
  mov   r0, #0x24
  clr   a
  mov   @r0, a
  inc   r0
  mov   @r0, #0x02
  clr   a
  mov   r6, a
  mov   r7, a
  mov   r4, #0x00
  lcall i2c_write_eeprom
  mov   a, r4
  jz    lbl_0c74
lbl_0c72:
  sjmp  lbl_0c72
lbl_0c74:
  mov   r0, #0x57
  mov   @r0, #0x13
  inc   r0
  mov   @r0, #0x88
lbl_0c7b:
  mov   r0, #0x57
  mov   a, @r0
  mov   r5, a
  inc   r0
  mov   a, @r0
  mov   r4, a
  mov   r0, #0x58
  mov   a, @r0
  dec   @r0
  dec   r0
  jnz   lbl_0c8a
  dec   @r0
lbl_0c8a:
  mov   a, r4
  orl   a, r5
  jz    lbl_0c90
  sjmp  lbl_0c7b
lbl_0c90:
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  lcall fcn_064b
  sjmp  lbl_0c9f
lbl_0c9c:
  lcall fcn_0502
lbl_0c9f:
  ret

; set I2C bus speed
; input: r4, 1 = 400kHz, otherwise 100kHz
;
; a = r4
; *(0x3b) = a
; a--
; if (!a) {
;   *I2CSTA |= 0x10;
; } else {
;   *I2CSTA &= 0xEF;
; }
i2c_set_bus_speed: ; 0ca0
  mov   r0, #i2c_speed ; 0x3b some debug byte showing current I2C speed?
  mov   a, r4
  mov   @r0, a
  dec   a
  jnz   lbl_0cb0
  mov   dptr, #I2CSTA
  movx  a, @dptr
  orl   a, #0x10 ; 1/4: 1 = 400kHz
  movx  @dptr, a
  sjmp  lbl_0cb7
lbl_0cb0:
  mov   dptr, #I2CSTA
  movx  a, @dptr
  anl   a, #0xef ; 1/4: 0 = 100kHz
  movx  @dptr, a
lbl_0cb7:
  ret

; wait for I2C TX empty
; return (r4): 0 success, 1 bus error
;
; while (!(*I2CSTA & 0x08)) {  // TXE
;   kick_watchdog();
;   if (*I2CSTA & 0x20) { // I2C_ERR
;     kick_watchdog();
;     *I2CSTA |= 0x20; // I2C_ERR
;     return 1;
;   }
; }
; return 0;
i2c_wait_tx_empty: ; 0cb8
lbl_0cb8:
  mov   dptr, #I2CSTA
  movx  a, @dptr
  jb    acc.3, lbl_0ce7 ; TXE: transmit empty
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  mov   dptr, #I2CSTA
  movx  a, @dptr
  jnb   acc.5, lbl_0ce5 ; ERR: jump if no bus error
lbl_0ccd:
  mov   dptr, #WDCSR
  movx  a, @dptr
  orl   a, #0x01   ; WDT: kick the watchdog
  movx  @dptr, a
  mov   dptr, #I2CSTA
  movx  a, @dptr
  orl   a, #0x20   ; ERR: write to clear
  movx  @dptr, a
  mov   dptr, #I2CSTA
  movx  a, @dptr
  jb    acc.5, lbl_0ccd ; ERR: bus error
  mov   r4, #0x01       ; return 1
  ret
lbl_0ce5:
  sjmp  lbl_0cb8
lbl_0ce7:
  mov   r4, #0x00       ; return 0
  ret

; write to I2C EEPROM
; dat_21: I2C bank
; r7, r6: EEPROM address
; dat_24: length
; dat_26: source and source address
i2c_write_eeprom: ; 0cea
  mov   dptr, #I2CSTA
  movx  a, @dptr
  anl   a, #0xfc
  movx  @dptr, a   ; *I2CSTA &= 0xFC  // clear SRD/SWR
  mov   r0, #eeprom_addr
  mov   a, r7
  mov   @r0, a
  inc   r0
  mov   a, r6
  mov   @r0, a     ; eeprom_addr = r7, r6
  mov   r0, #dat_21
  mov   a, r4
  mov   @r0, a     ; dat_21 = r4
  mov   r0, #dat_24
  mov   a, @r0
  inc   r0
  orl   a, @r0
  jnz   lbl_0d06   ; if (dat_24[0] == 0 && dat_24[1] == 0) return 0;
  mov   r4, #0x00
  ret
lbl_0d06:
  mov   r0, #dat_21
  mov   a, @r0
  anl   a, #0x07
  add   a, acc
  orl   a, #0xa0
  mov   dptr, #I2CADR
  movx  @dptr, a      ; *I2CADR = (2 * (dat_21 & 0x7) | 0xa0)
  mov   r0, #i2c_addr
  mov   @r0, a
  mov   r0, #eeprom_addr
  mov   a, @r0
  mov   dptr, #I2CDATO
  movx  @dptr, a      ; *I2CDATO = eeprom_addr[0]
  lcall i2c_wait_tx_empty
  mov   a, r4
  jz    lbl_0d26
  mov   r4, #0x01     ; if (i2c_wait_tx_empty()) return 1;
  ret
lbl_0d26:
  mov   r0, #eeprom_addr+1
  mov   a, @r0
  mov   dptr, #I2CDATO
  movx  @dptr, a      ; *I2CDATO = eeprom_addr[1]
  lcall i2c_wait_tx_empty
  mov   a, r4
  jz    lbl_0d36
  mov   r4, #0x01     ; if (i2c_wait_tx_empty()) return 1;
  ret
lbl_0d36:           ; while (dat_24 - 1 > 0)
  setb  c
  mov   r0, #dat_24+1
  mov   a, @r0
  subb  a, #0x01
  dec   r0
  mov   a, @r0
  subb  a, #0x00
  jc    lbl_0d6c
  mov   r0, #dat_26
  mov   a, @r0
  mov   r7, a        ; r7 = dat_26
  inc   r0
  mov   a, @r0
  mov   r6, a        ; r6 = dat_26+1
  inc   r0
  mov   a, @r0
  mov   r5, a        ; r5 = dat_26+2
  inc   a
  mov   @r0, a       ; (dat_26+2)++
  dec   r0
  jnz   lbl_0d52
  inc   @r0          ; (dat_26+1)++
lbl_0d52:
  lcall fcn_0132
  mov   dptr, #I2CDATO
  movx  @dptr, a     ; *I2CDATO = fcn_0132()
  lcall i2c_wait_tx_empty
  mov   a, r4
  jz    lbl_0d62
  mov   r4, #0x01    ; if (i2c_wait_tx_empty()) return 1;
  ret
lbl_0d62:
  mov   r0, #dat_24+1
  mov   a, @r0
  dec   @r0
  dec   r0
  jnz   lbl_0d6a
  dec   @r0          ; dat_24--
lbl_0d6a:
  sjmp  lbl_0d36
lbl_0d6c:
  mov   dptr, #I2CSTA
  movx  a, @dptr
  orl   a, #0x01
  movx  @dptr, a     ; *I2CSTA |= 0x01  SWR
  mov   r0, #dat_26
  mov   a, @r0
  mov   r7, a        ; r7 = dat_26
  inc   r0
  mov   a, @r0
  mov   r6, a        ; r6 = dat_26+1
  inc   r0
  mov   a, @r0
  mov   r5, a        ; r5 = dat_26+1
  lcall fcn_0132
  mov   dptr, #I2CDATO
  movx  @dptr, a     ; *I2CDATO = fcn_0132()
  lcall i2c_wait_tx_empty
  mov   a, r4
  jz    lbl_0d8d
  mov   r4, #0x01    ; if (i2c_wait_tx_empty()) return 1;
  ret
lbl_0d8d:
  mov   r4, #0x00    ; return 0;
  ret

fcn_0d90:
  jnb   p3.4, lbl_0d99
  jnb   p3.3, lbl_0d99
  ljmp  lbl_0e95
lbl_0d99:
  mov   r0, #dat_5c
  mov   @r0, #0x00
  mov   r1, #0x00
  mov   r0, #0x60
  mov   @r0, #0x00
lbl_0da3:
  mov   r0, #0x60
  mov   a, @r0
  add   a, #0xf8
  jc    lbl_0e07
  jb    p3.4, lbl_0db7
  jb    p3.3, lbl_0db7
  mov   r0, #dat_5c
  mov   @r0, #0x10
  ljmp  lbl_0e1b
lbl_0db7:
  mov   r0, #dat_62
  mov   @r0, #0x09
lbl_0dbb:
  jnb   p3.4, lbl_0dcc
  jnb   p3.3, lbl_0dcc
  mov   r0, #dat_62
  mov   a, @r0
  jnz   lbl_0dbb
  mov   r0, #dat_5c
  mov   @r0, #0x20
  sjmp  lbl_0e1b
lbl_0dcc:
  mov   a, r1
  mov   c, p3.3
  rrc   a
  mov   r1, a
  jb    p3.3, lbl_0dec
  clr   p3.4
  mov   r0, #dat_62
  mov   @r0, #0x09
lbl_0dda:
  jb    p3.3, lbl_0de8
  mov   r0, #dat_62
  mov   a, @r0
  jnz   lbl_0dda
  mov   r0, #dat_5c
  mov   @r0, #0x20
  sjmp  lbl_0e1b
lbl_0de8:
  setb  p3.4
  sjmp  lbl_0e02
lbl_0dec:
  clr   p3.3
  mov   r0, #dat_62
  mov   @r0, #0x09
lbl_0df2:
  jb    p3.4, lbl_0e00
  mov   r0, #dat_62
  mov   a, @r0
  jnz   lbl_0df2
  mov   r0, #dat_5c
  mov   @r0, #0x30
  sjmp  lbl_0e1b
lbl_0e00:
  setb  p3.3
lbl_0e02:
  mov   r0, #0x60
  inc   @r0
  sjmp  lbl_0da3
lbl_0e07:
  mov   dptr, #IEPBCTX_1
  movx  a, @dptr
  xrl   a, #0x80
  jnz   lbl_0e07
  mov   r0, #dat_59
  mov   a, @r0
  inc   @r0
  mov   dpl, a
  mov   a, #0xf8
  mov   dph, a
  mov   a, r1
  movx  @dptr, a
lbl_0e1b:
  mov   r0, #dat_5c
  mov   a, @r0
  jz    lbl_0e47
  setb  p3.4
  setb  p3.3
  mov   dptr, #IEPCNF_1
  movx  a, @dptr
  orl   a, #0x08
  movx  @dptr, a
  clr   a
  mov   dptr, #IEPBCTX_1
  movx  @dptr, a
  mov   r0, #dat_59
  mov   @r0, #0x00
  mov   r0, #dat_62
  mov   @r0, #0x08
lbl_0e38:
  mov   r0, #dat_62
  mov   a, @r0
  jz    lbl_0e46
  jnb   p3.3, lbl_0e44
  jnb   p3.4, lbl_0e44
  ret
lbl_0e44:
  sjmp  lbl_0e38
lbl_0e46:
  ret
lbl_0e47:
  mov   r0, #dat_59
  mov   a, @r0
  clr   c
  mov   r0, #0x50
  subb  a, @r0
  jc    lbl_0e5b
  mov   r0, #dat_59
  mov   a, @r0
  mov   dptr, #IEPBCTX_1
  movx  @dptr, a
  mov   r0, #dat_59
  mov   @r0, #0x00
lbl_0e5b:
  mov   r0, #0x54
  mov   a, @r0
  mov   r5, a
  inc   r0
  mov   a, @r0
  mov   r0, #0x5e
  xch   a, r5
  mov   @r0, a
  xch   a, r5
  inc   r0
  mov   @r0, a
lbl_0e68:
  mov   r0, #0x5e
  mov   a, @r0
  inc   r0
  orl   a, @r0
  jz    lbl_0e82
  jnb   p3.4, lbl_0e75
  jb    p3.3, lbl_0e78
lbl_0e75:
  ljmp  lbl_0d99
lbl_0e78:
  mov   r0, #0x5f
  mov   a, @r0
  dec   @r0
  dec   r0
  jnz   lbl_0e80
  dec   @r0
lbl_0e80:
  sjmp  lbl_0e68
lbl_0e82:
  mov   dptr, #IEPBCTX_1
  movx  a, @dptr
  xrl   a, #0x80
  jnz   lbl_0e82
  mov   r0, #dat_59
  mov   a, @r0
  mov   dptr, #IEPBCTX_1
  movx  @dptr, a
  mov   r0, #dat_59
  mov   @r0, #0x00
lbl_0e95:
  mov   r0, #dat_68
  mov   a, @r0
  mov   r0, #dat_5d
  mov   @r0, a
lbl_0e9b:
  mov   r0, #dat_5a
  mov   a, @r0
  jnz   lbl_0ea3
  ljmp  lbl_0fa0
lbl_0ea3:
  setb  p3.4
  setb  p3.3
  jb    p3.4, lbl_0ead
  ljmp  lbl_0f74
lbl_0ead:
  jb    p3.3, lbl_0eb3
  ljmp  lbl_0f74
lbl_0eb3:
  mov   r0, #dat_5d
  mov   a, @r0
  inc   @r0
  mov   r5, #0x00
  mov   r4, a
  add   a, #0x80
  mov   dpl, a
  mov   a, r5
  addc  a, #0xf9
  mov   dph, a
  movx  a, @dptr
  mov   r0, #0x61
  mov   @r0, a
  mov   r0, #dat_5b
  mov   @r0, #0x00
  mov   r0, #0x60
  mov   @r0, #0x00
lbl_0ecf:
  mov   r0, #0x60
  mov   a, @r0
  add   a, #0xf8
  jc    lbl_0f1f
  mov   r0, #0x61
  mov   a, @r0
  jnb   acc.0, lbl_0ee0
  clr   p3.4
  sjmp  lbl_0ee2
lbl_0ee0:
  clr   p3.3
lbl_0ee2:
  mov   r0, #0x61
  xch   a, @r0
  clr   c
  rrc   a
  mov   @r0, a
  mov   r0, #dat_62
  mov   @r0, #0x09
lbl_0eec:
  jb    p3.3, lbl_0ef2
  jnb   p3.4, lbl_0efd
lbl_0ef2:
  mov   r0, #dat_62
  mov   a, @r0
  jnz   lbl_0eec
  mov   r0, #dat_5b
  mov   @r0, #0x02
  sjmp  lbl_0f1f
lbl_0efd:
  setb  p3.4
  setb  p3.3
  mov   r0, #dat_62
  mov   @r0, #0x09
lbl_0f05:
  jnb   p3.3, lbl_0f0d
  jnb   p3.4, lbl_0f0d
  sjmp  lbl_0f1a
lbl_0f0d:
  mov   r0, #dat_62
  mov   a, @r0
  jnz   lbl_0f18
  mov   r0, #dat_5b
  mov   @r0, #0x03
  sjmp  lbl_0f1f
lbl_0f18:
  sjmp  lbl_0f05
lbl_0f1a:
  mov   r0, #0x60
  inc   @r0
  sjmp  lbl_0ecf
lbl_0f1f:
  mov   r0, #dat_5a
  dec   @r0
  mov   r0, #dat_5a
  mov   a, @r0
  jnz   lbl_0f3c
  mov   r0, #dat_5b
  mov   a, @r0
  jz    lbl_0f3c
  setb  p3.4
  setb  p3.3
  mov   dptr, #OEPCNF_2
  movx  a, @dptr
  orl   a, #0x08
  movx  @dptr, a
  mov   r0, #dat_68
  mov   @r0, #0x00
  ret
lbl_0f3c:
  mov   r0, #0x52
  mov   a, @r0
  jnz   lbl_0f44
  ljmp  lbl_0e9b
lbl_0f44:
  mov   r0, #0x52
  mov   a, @r0
  mov   b, #0x0a
  div   ab
  mov   r5, #0x00
  mov   r0, #0x5e
  xch   a, r5
  mov   @r0, a
  xch   a, r5
  inc   r0
  mov   @r0, a
lbl_0f54:
  mov   r0, #0x5e
  mov   a, @r0
  inc   r0
  orl   a, @r0
  jz    lbl_0f9d
  mov   r0, #0x5f
  mov   a, @r0
  dec   @r0
  dec   r0
  jnz   lbl_0f63
  dec   @r0
lbl_0f63:
  jnb   p3.4, lbl_0f69
  jb    p3.3, lbl_0f72
lbl_0f69:
  mov   r0, #dat_5d
  mov   a, @r0
  mov   r0, #dat_68
  mov   @r0, a
  ljmp  lbl_0d99
lbl_0f72:
  sjmp  lbl_0f54
lbl_0f74:
  jb    p3.4, lbl_0f97
  jb    p3.3, lbl_0f97
  mov   r0, #dat_62
  mov   @r0, #0x08
lbl_0f7e:
  jnb   p3.3, lbl_0f87
  jnb   p3.4, lbl_0f87
  ljmp  lbl_0eb3
lbl_0f87:
  mov   r0, #dat_62
  mov   a, @r0
  jnz   lbl_0f92
  mov   r0, #dat_5b
  mov   @r0, #0x02
  sjmp  lbl_0f1f
lbl_0f92:
  sjmp  lbl_0f7e
  ljmp  lbl_0e9b
lbl_0f97:
  mov   r0, #dat_5b
  mov   @r0, #0x01
  sjmp  lbl_0f1f
lbl_0f9d:
  ljmp  lbl_0e9b
lbl_0fa0:
  mov   r0, #dat_5d
  mov   a, @r0
  jz    lbl_0fb2
  mov   r0, #dat_68
  mov   @r0, #0x00
  mov   r0, #dat_5a
  mov   @r0, #0x00
  clr   a
  mov   dptr, #OEPBCTX_2
  movx  @dptr, a
lbl_0fb2:
  ret

; USB standard descriptor
cdat_0fb3:
  .byte 0x12        ; bLength
  .byte 0x01        ; bDescriptorType (Device)
  .byte 0x10, 0x01  ; bcdUSB 1.10
  .byte 0x00        ; bDeviceClass (Use class information in the Interface Descriptors)
  .byte 0x00        ; bDeviceSubClass
  .byte 0x00        ; bDeviceProtocol
  .byte 0x08        ; bMaxPacketSize0 8
  .byte 0x51, 0x04  ; idVendor 0x0451
  .byte 0x01, 0xE0  ; idProduct 0xE001
  .byte 0x08, 0x02  ; bcdDevice 2.08
  .byte 0x01        ; iManufacturer (String Index)
  .byte 0x02        ; iProduct (String Index)
  .byte 0x00        ; iSerialNumber (String Index)
  .byte 0x01        ; bNumConfigurations 1

; USB Configuration
cdat_0fc5:
  .byte 0x09        ; bLength
  .byte 0x02        ; bDescriptorType (Configuration)
  .byte 0x00, 0x00  ; wTotalLength 0
  .byte 0x01        ; bNumInterfaces 1
  .byte 0x01        ; bConfigurationValue
  .byte 0x00        ; iConfiguration (String Index)

cdat_0fcc:
  .byte 0x80        ; bmAttributes
  .byte 0x32        ; bMaxPower 100mA

; USB Interfaces
  .byte 0x09        ; bLength
  .byte 0x04        ; bDescriptorType (Interface)
  .byte 0x00        ; bInterfaceNumber 0
  .byte 0x00        ; bAlternateSetting
  .byte 0x02        ; bNumEndpoints 2
  .byte 0xFF        ; bInterfaceClass
  .byte 0x00        ; bInterfaceSubClass
  .byte 0x00        ; bInterfaceProtocol
  .byte 0x00        ; iInterface (String Index)

  .byte 0x07        ; bLength
  .byte 0x05        ; bDescriptorType (Endpoint)
  .byte 0x81        ; bEndpointAddress (IN/D2H)
  .byte 0x02        ; bmAttributes (Bulk)
  .byte 0x20, 0x00  ; wMaxPacketSize 32
  .byte 0x00        ; bInterval 0 (unit depends on device speed)

  .byte 0x07        ; bLength
  .byte 0x05        ; bDescriptorType (Endpoint)
  .byte 0x02        ; bEndpointAddress (OUT/H2D)
  .byte 0x02        ; bmAttributes (Bulk)
  .byte 0x20, 0x00  ; wMaxPacketSize 32
  .byte 0x00        ; bInterval 0 (unit depends on device speed)

cdat_0fe5:
; Serial String
  .byte 0x04       ; bLength
  .byte 0x03       ; bDescriptorType (String)
  .byte 0x09, 0x04
; Manufacturer String
  .byte 0x24       ; bLength
  .byte 0x03       ; bDescrptorType (String)
  .asciz "T"
  .asciz "e"
  .asciz "x"
  .asciz "a"
  .asciz "s"
  .asciz " "
  .asciz "I"
  .asciz "n"
  .asciz "s"
  .asciz "t"
  .asciz "r"
  .asciz "u"
  .asciz "m"
  .asciz "e"
  .asciz "n"
  .asciz "t"
  .asciz "s"
; Product String
  .byte 0x24       ; bLength
  .byte 0x03       ; bDescrptorType (String)
  .asciz "T"
  .asciz "I"
  .asciz "-"
  .asciz "G"
  .asciz "R"
  .asciz "A"
  .asciz "P"
  .asciz "H"
  .asciz " "
  .asciz "L"
  .asciz "I"
  .asciz "N"
  .asciz "K"
  .asciz " "
  .asciz "U"
  .asciz "S"
  .asciz "B"

; TODO: 0x1031
  .byte 0x41, 0x81, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0xcf, 0x02, 0xc5
  .byte 0x41, 0x82, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0xcf, 0x02, 0xc5
  .byte 0xc1, 0x83, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0xff, 0x02, 0xc5
  .byte 0x00, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x02, 0x85
  .byte 0x02, 0x01, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0xf7, 0x02, 0x89
  .byte 0x80, 0x08, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0xff, 0x02, 0x8d
  .byte 0x80, 0x06, 0xff, 0x01, 0xff, 0xff, 0xff, 0xff, 0xd0, 0x02, 0x95
  .byte 0x80, 0x06, 0xff, 0x02, 0xff, 0xff, 0xff, 0xff, 0xd0, 0x02, 0x91
  .byte 0x80, 0x06, 0xff, 0x03, 0xff, 0xff, 0xff, 0xff, 0xd0, 0x02, 0xa9
  .byte 0x81, 0x0a, 0x00, 0x00, 0xff, 0xff, 0x01, 0x00, 0xf3, 0x02, 0xa1
  .byte 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0xff, 0x02, 0x99
  .byte 0x81, 0x00, 0x00, 0x00, 0xff, 0x00, 0x02, 0x00, 0xf7, 0x02, 0xa5
  .byte 0x82, 0x00, 0x00, 0x00, 0xff, 0x00, 0x02, 0x00, 0xf7, 0x02, 0x9d
  .byte 0x00, 0x05, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0xdf, 0x02, 0xb1
  .byte 0x00, 0x09, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0xdf, 0x02, 0xb5
  .byte 0x00, 0x03, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0xdf, 0x02, 0xb9
  .byte 0x02, 0x03, 0xff, 0x00, 0xff, 0x00, 0x00, 0x00, 0xd7, 0x02, 0xbd
  .byte 0x01, 0x0b, 0xff, 0x00, 0xff, 0x00, 0x00, 0x00, 0xd7, 0x02, 0xc1
  .byte 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x02, 0xad

; TODO: 0x1102
  ; .blkb inserts 0xff, so use .rept + .byte
  .rept 0x1400 - 0x1102
    .byte 0x00
  .endm
