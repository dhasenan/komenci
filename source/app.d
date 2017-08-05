module initd.ĉefa;

import core.sys.posix.unistd;
import std.experimental.logger;
import std.path;
import std.stdio;

int main(string[] parametroj)
{
    switch (parametroj[0].baseName)
    {
        case "init":
        case "pravalizori":
            return kuruPravalizoro(parametroj);
        case "svc":
        case "servilo":
            return kuruServilo(parametroj);
        case "kill":
        case "mortigi":
            return kuruMortigi(parametroj);
        case "killall":
        case "mortigimultojn":
            return kuruMortigiMultojn(parametroj);
        default:
            writefln(
                    "Oni kurus ĉi tiu programo, kiel " ~
                    "pravalizori, servilo, mortigi, aŭ mortigimultojn");
            return 1;
    }
}

int kuruPravalizoro(string[] parametroj)
{
    bool havasPid1 = getpid() == 1;
    if (!havasPid1)
    {
        warningf("initd estus komencada kiel init (pid 1). " ~
                "Ni faros kion povas, sed kelkaj aferoj povus esti rompadoj.");
    }
    auto kuruNevilo = 0;
    auto celoNevilo = 5;
    while (true)
    {
        break;
    }
    return 0;
}


class Pravalizoro
{
    void kuru(string[] parametroj)
    {
        this.parametroj = parametroj;
        pravalizoruMem();
        startuAliajnProcedojn;
    }

private:
    string[] parametroj;

    int kuroNevilo = 0;
    int celoNevilo = 5;

    void pravalizoruMem()
    {
        leguAgordojn;
    }

    void leguAgordojn()
    {
    }

    void startuAliajnProcedojn()
    {
    }
}

int kuruServilo(string[] parametroj)
{
    return 0;
}

int kuruMortigi(string[] parametroj)
{
    return 0;
}

int kuruMortigiMultojn(string[] parametroj)
{
    return 0;
}
