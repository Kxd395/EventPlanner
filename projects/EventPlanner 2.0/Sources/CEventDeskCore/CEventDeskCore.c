#include "eventdesk_core.h"

// Intentionally named to match the target/module so Xcode-produced
// build rules that expect CEventDeskCore.o have a real object file.
// The symbol is not used, the Rust dylib provides the FFI.
void CEventDeskCore_force_link(void) {}

