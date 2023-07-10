How to use C2Z to integrate Dear IMGUI into a Zig application

## 1. Why is C2Z?

- Binding generator for C++, but it can also transpile some inline functions and template classes
- It has a zig implementation for `std::vector` and `std::string`, so no opaque pointers

## 2. Setup

- `zig 0.11.0-dev.3220+447a30299` is the only requirement
- clone from https://github.com/lassade/c2z, here I'm using the commit `3d0a7c9`
- build it using `zig build`
- copy `zig-out\c2z.exe` to your path or program folder

## 3. Basic usage

- run `c2z -- -DIMGUI_DISABLE_OBSOLETE_KEYIO -DIMGUI_DISABLE_OBSOLETE_FUNCTIONS .\lib\imgui\imgui.h` to generate the first set of bindings
- `c2z` is meant automate 90% of the work, the other 10% is with you

## 4. How to maintain and upgrade bindings

- regenerate bindings for the current version
- generate a bindings for newest version
- compare both of them (I like to use `WinMerge`)
- copy the relevant data