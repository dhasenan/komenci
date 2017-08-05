/**
  * ptrace estas linuksa sistemo, ke ebligas vin vidi en aliajn procedojn.
  *
  * Ĉi tiu dokumentaro estas en la angan, ĉar ni ĵus kopiis la linuksan dokumentaron.
  */
module initd.ptrace;

import core.stdc.config : c_long;
import core.sys.posix.sys.types : pid_t;

void afiksu(int pido)
{
    import core.stdc.errno : errno;
    import core.stdc.string : strerror;

    auto rezulto = ptrace(PtraceRequest.ATTACH, cast(pid_t) pido, null, null);
    if (rezulto == -1)
    {
        import std.string : fromStringz;
        import std.format : format;

        auto eraro = errno;
        auto ĉeno = strerror(eraro);
        auto eraroĈeno = ĉeno.fromStringz.idup;
        free(ĉeno);
        throw new PtraceException(
                "malplenumis afiksi al pido %s: %s".format(
                    pido, eraroĈeno));
    }
}

class PtraceException : Exception
{
    this(string mensaĝo) { super(mensaĝo); }
}

extern(C) c_long ptrace(PtraceRequest request, pid_t pid, void* address, void* data);

enum PtraceRequest
{
    /** Indicate that the process making this request should be traced.
      All signals received by this process can be intercepted by its
      parent, and its parent can use the other `ptrace' requests.  */
    TRACEME = 0,

    /** Return the word in the process's text space at address ADDR.  */
    PEEKTEXT = 1,

    /** Return the word in the process's data space at address ADDR.  */
    PEEKDATA = 2,

    /** Return the word in the process's user area at offset ADDR.  */
    PEEKUSER = 3,

    /** Write the word DATA into the process's text space at address ADDR.  */
    POKETEXT = 4,

    /** Write the word DATA into the process's data space at address ADDR.  */
    POKEDATA = 5,

    /** Write the word DATA into the process's user area at offset ADDR.  */
    POKEUSER = 6,

    /** Continue the process.  */
    CONT = 7,

    /** Kill the process.  */
    KILL = 8,

    /** Single step the process.
      This is not supported on all machines.  */
    SINGLESTEP = 9,

    /** Get all general purpose registers used by a processes.
      This is not supported on all machines.  */
    GETREGS = 12,

    /** Set all general purpose registers used by a processes.
      This is not supported on all machines.  */
    SETREGS = 13,

    /** Get all floating point registers used by a processes.
      This is not supported on all machines.  */
    GETFPREGS = 14,

    /** Set all floating point registers used by a processes.
      This is not supported on all machines.  */
    SETFPREGS = 15,

    /** Attach to a process that is already running. */
    ATTACH = 16,

    /** Detach from a process attached to with ATTACH.  */
    DETACH = 17,

    /** Get all extended floating point registers used by a processes.
      This is not supported on all machines.  */
    GETFPXREGS = 18,

    /** Set all extended floating point registers used by a processes.
      This is not supported on all machines.  */
    SETFPXREGS = 19,

    /** Continue and stop at the next (return from) syscall.  */
    SYSCALL = 24,

    /** Set ptrace filter options.  */
    SETOPTIONS = 0x4200,

    /** Get last ptrace message.  */
    GETEVENTMSG = 0x4201,

    /** Get siginfo for process.  */
    GETSIGINFO = 0x4202,

    /** Set new siginfo for process.  */
    SETSIGINFO = 0x4203,

    /** Get register content.  */
    GETREGSET = 0x4204,

    /** Set register content.  */
    SETREGSET = 0x4205,

    /** Like ATTACH, but do not force tracee to trap and do not affect
      signal or group stop state.  */
    SEIZE = 0x4206,

    /** Trap seized tracee.  */
    INTERRUPT = 0x4207,

    /** Wait for next group event.  */
    LISTEN = 0x4208,

    PEEKSIGINFO = 0x4209,

    GETSIGMASK = 0x420a,

    SETSIGMASK = 0x420b,

    SECCOMP_GET_FILTER = 0x420c
}


/** Flag for LISTEN.  */
enum Flags
{
    SEIZE_DEVEL = 0x80000000
}

/** Options set using SETOPTIONS.  */
enum Options
{
    TRACESYSGOOD = 0x00000001,
    TRACEFORK = 0x00000002,
    TRACEVFORK   = 0x00000004,
    TRACECLONE = 0x00000008,
    TRACEEXEC = 0x00000010,
    TRACEVFORKDONE = 0x00000020,
    TRACEEXIT = 0x00000040,
    TRACESECCOMP = 0x00000080,
    EXITKILL = 0x00100000,
    SUSPEND_SECCOMP = 0x00200000,
    MASK  = 0x003000ff
}

/** Wait extended result codes for the above trace options.  */
enum __ptrace_eventcodes
{
    EVENT_FORK = 1,
    EVENT_VFORK = 2,
    EVENT_CLONE = 3,
    EVENT_EXEC = 4,
    EVENT_VFORK_DONE = 5,
    EVENT_EXIT = 6,
    EVENT_SECCOMP  = 7
}

/** Arguments for PEEKSIGINFO.  */
struct PeekSigInfoArgs
{
    ulong off; /** From which siginfo to start.  */
    PeekSigInfoFlags flags; /** Flags for peeksiginfo.  */
    int nr;  /** How many siginfos to take.  */
}

enum PeekSigInfoFlags
{
    /** Read signals from a shared (process wide) queue.  */
    PEEKSIGINFO_SHARED = (1 << 0)
}
