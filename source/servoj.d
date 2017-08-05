module initd.servoj;

import std.file : readText;
import std.process;
import core.sys.posix.sys.wait;

enum Farto
{
    Neniu,
    Komencanta,
    Kuranta,
    Haltita,
    Fajita,
}

/**
  * Servo povas kuri kiel:
  *  * norma procedo (kiel povas ni scii, se ĝi estas komencita?)
  *  * dajmono kun pid-dosiero
  *  * komenci/halti skriboj
  */
abstract class Servo
{
    string nomo;
    int[] kuruNiveloj;
    Farto farto;
    int pido;
    ProcessPipes pipoj;

    abstract void startu();
    abstract Farto ĉekuFarton();

    protected ProcessPipes startuProcedon(string komandlino)
    {
        return pipeShell(komandlino);
    }

    Farto ĉekuFartonElPido(int pido, Farto lastaFarto)
    {
        if (!pido) return Farto.Neniu;
        int statuso;
        auto w = waitpid(pido, &statuso, WNOHANG);
        if (w == 0)
        {
            return lastaFarto;
        }
        if (WIFSTOPPED(statuso))
        {
            auto elirStatuso = WEXITSTATUS(statuso);
            if (elirStatuso == 0)
            {
                return Farto.Haltita;
            }
            return Farto.Fajita;
        }
        return Farto.Kuranta;
    }
}

/**
  * Servo kun unua skribo.
  *
  * La skribo haltas. Dependaj idoj povas komenci post kiam ĉi skribo haltas.
  */
class UnuaSkriboServo : Servo
{
    string komandlino;

    override void startu()
    {
        pipoj = startuProcedon(komandlino);
        pido = pipoj.pid;
    }

    override Farto ĉekuFarton()
    {
        return ĉekuFartonElPido(pido, farto);
    }
}

/**
  * Servo, ke kuras kaj ne devas halti.
  *
  * Ni restartus ĝin, se ĝi haltus.
  */
class SimplaServo : Servo
{
    string komandlino;

    override void startu()
    {
        pipoj = startuProcedon(komandlino);
        pido = pipoj.pid;
    }

    override Farto ĉekuFarton()
    {
        return ĉekuFartonElPido(pido, farto);
    }
}

/**
  * Dajmono.
  *
  * Ĝi havas pid dosiero kaj ĝi haltas, kiam ĝi estas komencita.
  */
class DajmonaServo : Servo
{
    string pidDosierindiko;
    string komandlino;
    ProcessPipes komencantaPipoj;

    override void startu()
    {
        komencantaPipoj = startuProcedon(komandlino);
    }

    override Farto ĉekuFarton()
    {
        auto f = ĉekuFartonElPido(komencantaPipoj.pid, farto);
        if (f != Farto.Haltita)
        {
            return f;
        }
        if (!pido)
        {
            pido = leguPidonElDosiero();
            if (!pido)
            {
                return Farto.Haltita;
            }
            ptrace(PtraceRequest.ATTACH, pido, null, null);
        }

        return ĉekuFartonElPido(pido, farto);
    }

    int leguPidonElDosiero()
    {
        import std.conv : to;
        import std.string : strip;
        try
        {
            auto teksto = pidDosierindiko.readText;
            return teksto.strip.to!int;
        }
        catch (Exception e)
        {
            return null;
        }
    }
}

Servo legu(string dosierindikon)
{
    import std.json : parseJSON;
    auto teksto = dosierindikon.readText;
    // FARU pli bona formato
    auto js = teksto.parseJSON;

    /*
    if (js["pidDosierindiko"])
    {
    }
    */
    return null;
}
