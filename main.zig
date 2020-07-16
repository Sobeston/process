const std = @import("std");
const os = std.os;
const os_tag = std.Target.current.os.tag;
usingnamespace if (os_tag == .windows) @import("windows-externs.zig") else {};

pub const ProcessWindows = struct {
    handle: os.windows.HANDLE,
    id: u32,

    pub fn write(self: ProcessWindows, buffer: []const u8, location: [*c]u8) !void {
        var written: usize = undefined;
        if (WriteProcessMemory(self.handle, location, buffer.ptr, buffer.len, &written) == 0) return error.BadWrite;
        return written;
    }

    pub fn read(self: ProcessWindows, buffer: []u8, location: [*c]const u8) !void {
        if (ReadProcessMemory(self.handle, location, buffer.ptr, buffer.len, null) == 0) return error.BadRead;
    }

    pub fn deinit(self: ProcessWindows) void {
        _ = os.windows.CloseHandle(self.handle);
    }

    pub const Extra = struct {
        pub const Encoding = enum { ascii, unicode };

        pub fn initID(pid: u32, inherit_handle: bool, desired_access: AccessRights) !Process {
            return Process{
                .native = .{
                    .handle = OpenProcess(
                        @bitCast(u32, desired_access),
                        inherit_handle,
                        pid,
                    ) orelse return error.CouldntOpen,
                    .id = pid,
                },
            };
        }
        /// uses the first matching process it finds
        pub fn initExeName(name: []const u8, inherit_handle: bool, desired_access: AccessRights) !Process {
            const snapshot = blk: {
                const x = CreateToolhelp32Snapshot(TH32CS.SNAPPROCESS, 0) orelse
                    return error.CouldNotOpenSnapshot;
                if (x == os.windows.INVALID_HANDLE_VALUE) return error.CouldNotOpenSnapshot;
                break :blk x;
            };

            var entry = std.mem.zeroInit(PROCESSENTRY32, .{ .dwSize = @sizeOf(PROCESSENTRY32) });

            if (Process32First(snapshot, &entry) == 0) return error.FirstEntryNotCopied;
            while (Process32Next(snapshot, &entry) != 0) {
                if (std.mem.eql(
                    u8,
                    std.mem.span(@ptrCast([*:0]u8, &entry.szExeFile)),
                    name,
                ))
                    return Process{
                        .native = .{
                            .handle = OpenProcess(
                                @bitCast(u32, desired_access),
                                inherit_handle,
                                entry.th32ProcessID,
                            ) orelse return error.CouldntOpen,
                            .id = entry.th32ProcessID,
                        },
                    };
            }
            return error.ProcessNotFound;
        }

        /// If class_name is null, it finds any window whose title matches the window_name parameter.
        /// If window_name is null, all window names match.
        pub fn initWindow(
            comptime encoding: Encoding,
            window_name: ?[:0]const if (encoding == .ascii) u8 else u16,
            class_name: ?[:0]const if (encoding == .ascii) u8 else u16,
            inherit_handle: bool,
            desired_access: AccessRights,
        ) !Process {
            const window = if (encoding == .ascii)
                FindWindowA(
                    if (class_name) |c| c else null,
                    if (window_name) |w| w else null,
                ) orelse return error.WindowNotFound
            else
                FindWindowW(
                    if (class_name) |c| c else null,
                    if (window_name) |w| w else null,
                ) orelse return error.WindowNotFound;

            var pid: u32 = undefined;
            _ = GetWindowThreadProcessId(window, &pid);

            return Process{
                .native = .{
                    .handle = OpenProcess(
                        @bitCast(u32, desired_access),
                        inherit_handle,
                        pid,
                    ) orelse return error.CouldntOpen,
                    .id = pid,
                },
            };
        }
    };
};

pub const Process = struct {
    native: Native,

    pub const Native = switch (os_tag) {
        .windows => ProcessWindows,
        else => @compileError("unimplemented :("),
    };

    pub fn read(self: Process, comptime T: type, location: [*c]const u8) !T {
        if (@sizeOf(T) == 0) @compileError("zero sized type supplied");
        var data: T = undefined;
        try self.native.read(std.mem.asBytes(&data), location);
        return data;
    }

    pub fn readSlice(self: Process, buffer: anytype, location: [*c]const u8) !void {
        try self.native.read(std.mem.sliceAsBytes(std.mem.span(buffer)), location);
    }

    pub fn write(self: Process, data: anytype, location: [*c]u8) !void {
        if (@typeInfo(@TypeOf(data)) == .Pointer) {
            return self.native.write(std.mem.sliceAsBytes(std.mem.span(data)), location);
        }
        return self.native.write(std.mem.asBytes(&data), location);
    }

    pub fn deinit(self: Process) void {
        self.native.deinit();
    }

    pub usingnamespace Process.Native.Extra;
};