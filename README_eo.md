initd
=====

Kion faras initd?

initd komencas procedojn en via komputilo, kiel SysV init aŭ systemd, en la D programlingvo. Ĝi
pravalizoras vin komputilon per uzo. Malkiel systemd, initd nur komencas procedojn kaj TTYojn.

initd konsistas el du partoj: la monitoro kaj la komencanto. La monitoro monitoras per morto en la
komencanto kaj rekomencas ĝin. La komencanto certigas, ke alia procedoj funkciigas, kiam ili devus.

Kiel ĉiam, initd havas unikan formaton per pravalizoroskribojn.


Funkcioj
--------

initd kontrolas:

* kill/killall: mortigi procedojn
* shutdown/reboot/halt: elŝalti/rekomenci la komputilon
* svc: ebligi/malebligi/komenci/elŝalti procedojn
* telinit: ŝangi kurnevilo


Stilo kaj gramatiko
-------------------

Ni uzas la nominativo anstataŭ la akuzativo por funkciaj parametroj, ĉar ili aspekti en multe da
lokoj.
