;; Test that merging independent secondary modules ('second' and 'third'),
;; running --duplicate-function-elimination, and splitting them back up with
;; wasm-split preserves the ability to load and execute each secondary module
;; independently.
;;
;; 'second' and 'third' do not depend on each other, but they define identical
;; internal helper functions ($helper_second and $helper_third). If
;; --duplicate-function-elimination merges $helper_third into $helper_second,
;; $helper_second is placed in 'second', so loading 'primary' + 'third' without
;; 'second' and calling 'run_third' traps on an uninitialized table element
;; instead of returning 62.

;; RUN: wasm-merge -all %s first %s.second second %s.third third --output-manifest %t.manifest -o %t.merged.wasm
;; RUN: wasm-opt -all --duplicate-function-elimination -g %t.merged.wasm -o %t.opt.wasm
;; RUN: wasm-split -all %t.opt.wasm --multi-split --no-placeholders --manifest %t.manifest -g -o %t.primary.wasm --out-prefix %t.
;; RUN: wasm-opt %t.primary.wasm -all --fuzz-exec-before --fuzz-exec-second=%t.second.wasm -q -o /dev/null 2>&1 | filecheck %s --check-prefix SECOND_ONLY
;; RUN: wasm-opt %t.primary.wasm -all --fuzz-exec-before --fuzz-exec-second=%t.third.wasm -q -o /dev/null 2>&1 | filecheck %s --check-prefix THIRD_ONLY

;; SECOND_ONLY:      [fuzz-exec] export first_func
;; SECOND_ONLY-NEXT: [fuzz-exec] note result: first_func => 1
;; SECOND_ONLY-NEXT: [fuzz-exec] export run_second
;; SECOND_ONLY-NEXT: [fuzz-exec] note result: run_second => 52
;; SECOND_ONLY-NEXT: [fuzz-exec] export run_third
;; SECOND_ONLY-NEXT: [trap null target in call_indirect]

;; THIRD_ONLY:      [fuzz-exec] export first_func
;; THIRD_ONLY-NEXT: [fuzz-exec] note result: first_func => 1
;; THIRD_ONLY-NEXT: [fuzz-exec] export run_second
;; THIRD_ONLY-NEXT: [trap null target in call_indirect]
;; THIRD_ONLY-NEXT: [fuzz-exec] export run_third
;; THIRD_ONLY-NEXT: [fuzz-exec] note result: run_third => 62

(module
  (func $first_func (export "first_func") (result i32)
    (i32.const 1)
  )
)
