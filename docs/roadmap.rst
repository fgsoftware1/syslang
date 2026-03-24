v1 Roadmap: Syslang Experimental Compiler
=======================================

Goal: E2E PoC for "mid-level" language with first-class asm functions

Language Design
---------------

- ``@`` prefix = registers + name disambiguation
- ``asm`` keyword for lowlevel functions
- ``fn`` keyword for regular functions
- ``module`` keyword for module declaration
- ``import`` keyword for module import
- ``pub`` keyword for exports
- Direct emit to GAS assembly (AT&T syntax)
- SysV ABI implicit for ``asm`` parameter placement
- Intrinsics cannot be shadowed inside ``asm`` functions
- ``rep(@reg?, n)`` - repetition (ecx implicit if @reg omitted)
- ``unroll(n)`` - SIMD hint (n = width, e.g. 8 -> xmm)

Phase 1: Core Infrastructure
-----------------------------

- [x] Project scaffolding
- [x] Lexer/parser
- [x] Codegen to GAS (AT&T syntax)

Phase 2: Intrinsics
--------------------

**Opcodes**

- [x] ``mov(src, dst)``
- [x] ``add(src, dst)``
- [x] ``syscall``
- [x] ``ret`` (implicit)
- [ ] ``preserve[reg, ...]`` contract (auto-generates push/pop)

**Reserved Keywords**

- [x] ``asm``
- [x] ``fn``
- [x] ``module``
- [x] ``import``
- [x] ``pub``

Phase 3: Type System & Signatures
---------------------------------

**Types**

- [x] ``int`` primitive type
- [x] ``a: int`` parameter syntax

**Signatures**

- [x] ``-> @reg`` output declarations (optional)
- [x] ``name(params)`` function parameters

**Contracts**

- [ ] ``preserve[...]`` contract (trailing, array syntax)

**ABI**

- [ ] SysV ABI parameter placement (implicit)

Phase 4: Functions
------------------

**``asm`` functions**

- [x] Parse asm keyword
- [x] Parse function body with opcodes
- [x] Codegen for asm functions

**``fn`` functions (minimal v1)**

- [x] Parse fn keyword
- [x] Function call support
- [x] Return statement
- [x] No parameters for v1 fn
- [ ] Fn call arguments
- [ ] Full parameter support

Phase 5: Module System
----------------------

**File-based modules**

- [x] Module declaration
- [x] Module import
- [x] Stdlib search path
- [ ] Prefix disambiguation (``module::fn``)

**Visibility**

- [x] ``pub`` keyword

Phase 6: Stdlib
----------------

**stdlib/system.sl**

- [x] ``exit`` syscall
- [ ] ``write`` syscall

**stdlib/io.sl**

- [ ] ``print()`` basic output

Phase 7: Testing
-----------------

- [x] Compile asm function to GAS
- [x] Call asm from fn
- [x] Import stdlib module
- [ ] E2E verification

NOT PLANNED
-----------

- GC
- OOP-style features
- Local variables in ``fn``
- Control flow (if/while) - v2+

FUTURE PHASES (v2+)
-------------------

**Control Flow**

- ``if/elif/else``
- ``match`` with guards
- ``rep(@reg?, n)`` - repetition control flow
- ``unroll(n)`` - SIMD hint
- ``for in range`` loops

**Types & Data**

- struct / enum / union
- struct-tied functions (namespace-like)
- bit-tied struct members (bitfields)

**Other**

- Error handling
- Full ``fn`` with parameters, locals, ABI
- unsafe blocks
