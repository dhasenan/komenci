module init.procedoj;

import init.ptrace;

class Procedestro
{
    void rigardu(int pido, Rigardisto rigardisto, bool estasNiaKnabo)
    {
        if (!estasNiaKnabo)
        {
            afikso(pido);
        }
        pidoAlRigardisto[pido] = rigardisto;
    }

    private Rigardisto[int] pidoAlRigardisto;
}

/* Ni uzas interfaco ĉar ni povas eviti kvotigi. */
interface Rigardisto
{
    void ŝanĝonRigardita(int pido, int statuso);
}
