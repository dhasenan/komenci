module komenci.app;

import core.thread;
import core.time;
import dyaml;
import komenci.log;
import std.algorithm.searching : any, canFind;
import std.algorithm.iteration : splitter;
import std.datetime;
import std.experimental.logger;
import std.file;
import std.process;
import std.stdio;

enum CONF_PATH = "/etc/komenci/komenci.yaml";
enum INIT_PATH = "/etc/komenci/init";

int main(string[] args)
{
    auto multi = new MultiLogger(LogLevel.all);
    multi.insertLogger("stdout", new FileLogger(stderr, LogLevel.all));
    multi.insertLogger("var", new ParanoidLogger(LogLevel.all));
    sharedLog = multi;

    info("initd start");

    // Read our config file
    Node confNode;
    try
    {
        confNode = Loader(CONF_PATH).load();
    }
    catch (Throwable e)
    {
        errorf("error reading conf file %s. We'll try continuing on with defaults. Error was: %s",
            CONF_PATH, e);
    }

    // Find our scripts.
    auto services = loadServices();

    // If the kernel command line contains "single", we should boot in single-user mode.
    auto cmd = File("/proc/cmdline", "r").readln();
    bool multiuser = true;
    if (cmd.splitter().canFind("single"))
    {
        multiuser = false;
    }

    // Actually try to get into single-user mode -- and then, if appropriate, multi-user mode.
    converge(services, RunLevel.Single);
    if (multiuser)
    {
        converge(services, RunLevel.Multiuser);
    }

    execv("/bin/bash", []);

    // TODO: keep running, keep our services running, wait for a shutdown request
    converge(services, RunLevel.Shutdown);
    return 0;
}

/**
 * Load services from yaml definitions in INIT_PATH.
 */
InitScript[string] loadServices()
{
    // A failure here is actually panic-worthy, but dumping the person to a shell is slightly nicer.
    if (!exists(INIT_PATH) || !isDir(INIT_PATH))
    {
        writefln("No init files found in %s.", INIT_PATH);
        writeln("We don't know how to recover from this. Your installation is horribly broken.");
        writeln("We're putting you in bash for now. Best of luck!");
        auto res = execv("/bin/bash", []);
        import core.stdc.stdlib : exit;
        exit(res);
    }

    InitScript[string] services;
    foreach (file; dirEntries(INIT_PATH, "*.{yml,yaml}", SpanMode.depth, true))
    {
        Node node;
        try
        {
            node = Loader(file.name).load();
        }
        catch (Throwable t)
        {
            // TODO should this push us out into bash?
            // TODO log this better (we can't actually log to disk yet)
            errorf("error reading init script %s: %s", file.name, t);
            continue;
        }
        foreach (string key, Node value; node)
        {
            try
            {
                // TODO duplicate definitions
                services[key] = new InitScript(key, value);
            }
            catch (Throwable t)
            {
                errorf("error reading service definition %s from file %s: %s", key, file.name, t);
            }
        }
    }
    return services;
}

/**
 * A RunLevel is a target status for our system.
 */
enum RunLevel
{
    Single,
    Multiuser,
    Shutdown,
}

/**
 * An InitScript is a script that we should run.
 */
class InitScript
{
    /// Runlevel this script applies to
    RunLevel level;
    /// Name of the script / service
    string name;
    /// Names of dependencies
    string[] depends;
    /// Script content. Bash script.
    string script;
    /// Whether it's started or not.
    bool started;

    /// Build me an InitScript worthy of Mordor.
    this(string name, Node yaml)
    {
        this.name = name;

        auto rl = yaml["runlevel"].as!string;
        switch (rl)
        {
        case "multiuser":
            level = RunLevel.Multiuser;
            break;
        case "single":
            level = RunLevel.Single;
            break;
        case "shutdown":
            level = RunLevel.Shutdown;
            break;
        default:
            throw new Exception("unrecognized runlevel for service " ~ name ~ ": " ~ rl);
        }

        if ("depends" in yaml)
        {
            foreach (Node value; yaml["depends"])
            {
                depends ~= value.as!string;
            }
        }

        if ("script" in yaml)
        {
            script = yaml["script"].as!string;
        }
    }
}

/**
 * Get the system to the target runlevel, running scripts and starting services in dependency order.
 */
void converge(InitScript[string] services, RunLevel runlevel)
{
    bool[string] started;
    size_t toStart = 0;
    foreach (name, value; services)
    {
        if (value.level == runlevel)
        {
            toStart++;
        }
    }

    while (started.length < toStart)
    {
        auto before = started.length;
        foreach (name, value; services)
        {
            if (value.level != runlevel)
                continue;
            if (value.started)
                continue;
            if (value.depends.any!(x => !services[x].started))
                continue;
            started[name] = true;
            value.started = true;
            infof("starting service %s", name);
            auto result = executeShell(value.script);
            if (result.status != 0)
            {
                errorf("service %s failed with exit code %s; output:\n%s", name, result.status, result.output);
            }
            else
            {
                infof("service %s: success; output: %s", name, result.output);
            }
        }
        if (before != started.length)
        {
            // We made progress!
            continue;
        }
        break;
    }
}
