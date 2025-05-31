//! cozcli.termcolor is a set of color code for terminal
//! It's setup at compile time
//! Supported code colors:
//!  -
//!
//!

const debug = @import("std").debug;
const builtin = @import("builtin");
pub const colors = if (builtin.os.tag == .windows) 1 else  0;


comptime {
   debug.assert(colors == 0);
}
