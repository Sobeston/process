usingnamespace @import("std").os.windows;

pub extern "kernel32" fn WriteProcessMemory(
    hProcess: HANDLE,
    lpBaseAddress: *c_void,
    lpBuffer: *const c_void,
    nSize: usize,
    lpNumberOfBytesWritten: ?*usize,
) callconv(.Stdcall) BOOL;

pub extern "kernel32" fn ReadProcessMemory(
    hProcess: HANDLE,
    lpBaseAddress: *const c_void,
    lpBuffer: *c_void,
    nSize: usize,
    lpNumberOfBytesRead: ?*usize,
) callconv(.Stdcall) BOOL;

pub extern "kernel32" fn OpenProcess(
    dwDesiredAccess: DWORD,
    bInheritHandle: bool,
    dwProcessId: DWORD,
) callconv(.Stdcall) ?HANDLE;

pub extern "kernel32" fn CreateToolhelp32Snapshot(
    dwFlags: DWORD,
    th32ProcessID: DWORD,
) callconv(.Stdcall) ?HANDLE;

pub extern "kernel32" fn Process32First(
    hSnapshot: HANDLE,
    lppe: *PROCESSENTRY32,
) callconv(.Stdcall) BOOL;

pub extern "kernel32" fn Process32Next(
    hSnapshot: HANDLE,
    lppe: *PROCESSENTRY32,
) callconv(.Stdcall) BOOL;

pub extern "user32" fn FindWindowA(
    lpClassName: ?[*:0]const u8,
    lpWindowName: ?[*:0]const u8,
) callconv(.Stdcall) ?HWND;

pub extern "user32" fn FindWindowW(
    lpClassName: ?[*:0]const u16,
    lpWindowName: ?[*:0]const u16,
) callconv(.Stdcall) ?HWND;

pub extern "user32" fn GetWindowThreadProcessId(
    hWnd: HWND,
    lpdwProcessId: *u32,
) DWORD;

// zig-fmt: off
pub const AccessRights = packed struct {
    terminate                : bool = false,    //0x1
    create_thread            : bool = false,    //0x2
    set_sessionid            : bool = false,    //0x4
    vm_operation             : bool = false,    //0x8
    vm_read                  : bool = false,    //0x10
    vm_write                 : bool = false,    //0x20
    create_process           : bool = false,    //0x40
    set_quota                : bool = false,    //0x80
    set_information          : bool = false,    //0x100
    query_information        : bool = false,    //0x200
    suspend_resume           : bool = false,    //0x400
    query_limited_information: bool = false,    //0x800
    _unk1                    : bool = false,    //0x1000
    _unk2                    : bool = false,    //0x2000
    _unk3                    : bool = false,    //0x4000
    _unk4                    : bool = false,    //0x8000
    delete                   : bool = false,    //0x10000
    read_control             : bool = false,    //0x20000
    write_dac                : bool = false,    //0x40000
    write_owner              : bool = false,    //0x80000
    synchronize              : bool = false,    //0x100000
    _unk5                    : bool = false,    //0x200000
    _unk6                    : bool = false,    //0x400000
    _unk7                    : bool = false,    //0x800000
    access_system_security   : bool = false,    //0x1000000
    maximum_allowed          : bool = false,    //0x2000000
    _unk8                    : bool = false,    //0x4000000
    _unk9                    : bool = false,    //0x8000000
    generic_all              : bool = false,    //0x10000000
    generic_execute          : bool = false,    //0x20000000
    generic_write            : bool = false,    //0x40000000
    generic_read             : bool = false,    //0x80000000
};
// zig-fmt: on

comptime {
    if (@sizeOf(AccessRights) != 4) unreachable;
    if (@bitSizeOf(AccessRights) != 32) unreachable;
}

pub const all_access = @bitCast(AccessRights, @as(u32, 0xFFFFFFFF));

pub const TH32CS = packed struct {
    pub const SNAPHEAPLIST = 0x1;
    pub const SNAPPROCESS = 0x2;
    pub const SNAPTHREAD = 0x4;
    pub const SNAPMODULE = 0x8;
};



pub const PROCESSENTRY32 = extern struct {
    dwSize: DWORD,
    cntUsage: DWORD,
    th32ProcessID: DWORD,
    th32DefaultHeapID: ULONG_PTR,
    th32ModuleID: DWORD,
    cntThreads: DWORD,
    th32ParentProcessID: DWORD,
    pcPriClassBase: LONG,
    dwFlags: DWORD,
    szExeFile: [MAX_PATH]CHAR,
};

