module komenci.log;

import std.datetime;
import std.experimental.logger;
import std.stdio;

/**
 * ParanoidLogger tries to log messages to the appropriate place,
 * paying attention to configured limits.
 *
 * ParanoidLogger will not throw exceptions.
 */
class ParanoidLogger : Logger
{
    size_t maxFiles = 5;

    /**
     * The directory to log to.
     * Must not contain unrelated log files.
     */
    string dir = "/var/log/komenci";

    /**
     * The format for logfile names.
     * The parameters for the format will be year, month, day.
     */
    string nameFormat = "komenci_%04d-%02d-%02d.log";

    this(LogLevel lvl)
    {
        super(lvl);
    }

    override void writeLogMsg(ref LogEntry payload) nothrow @trusted
    {
        try
        {
            reallyWriteLogMsg(payload);
        }
        catch (Throwable t)
        {
            try
            {
                writefln("failed to write log message: %s", t);
            }
            catch (Throwable t2)
            {
            }
        }
    }

    private void reallyWriteLogMsg(ref LogEntry payload) @trusted
    {
        if (payload.logLevel < this.logLevel) return;

        auto now = Clock.currTime;
        if (file == File.init || !file.isOpen)
        {
            if (now - lastTried <= 0.seconds)
            {
                return;
            }
            openFile;
        }
        else if (openDate != cast(Date) now)
        {
            file.close;
            deleteExcessFiles;
            openFile;
        }

        file.writefln(
            "%s %s %s",
            payload.timestamp.toISOString(),
            payload.logLevel,
            payload.msg
        );
    }

private:
    void openFile()
    {
        import std.format : format;
        import path = std.path;
        import std.file;

        if (!exists(dir))
        {
            mkdirRecurse(dir);
        }

        auto now = Clock.currTime;
        lastTried = now;
        auto name = nameFormat.format(now.year, now.month, now.day);

        file = File(path.chainPath(dir, name), "a");
        openDate = cast(Date) now;
    }

    void deleteExcessFiles()
    {
        // TODO implement log rotation
    }

    File file;
    SysTime lastTried = SysTime.min;
    Date openDate = Date.min;
}