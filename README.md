# Fully documented source code for Elite on the BBC Micro with a disc drive

This repository contains the original source code for Elite on the BBC Micro with a disc drive, with every single line documented and (for the most part) explained.

It is a companion to the [bbcelite.com website](https://www.bbcelite.com), which contains all the code from this repository, but laid out in a much more human-friendly fashion. There are two sister repositories, one for the [cassette version of Elite](https://github.com/markmoxon/elite-beebasm) and another for the [6502 Second Processor version of Elite](https://github.com/markmoxon/6502sp-elite-beebasm).

* If you want to browse the source and read about how Elite works under the hood, you will probably find [the website](https://www.bbcelite.com) is a better place to start than this repository.

* If you would rather explore the source code in your favourite IDE, then the [annotated source](sources/elite-source.asm) is what you're looking for. It contains the exact same content as the website, so you won't be missing out (the website is generated from the source files, so they are guaranteed to be identical). You might also like to read the section on [Browsing the source in an IDE](#browsing-the-source-in-an-ide) for some tips.

* If you want to build Elite from the source on a modern computer, to produce a working game disc that can be loaded into a BBC Micro or an emulator, then you want the section on [Building Elite from the source](#building-elite-from-the-source).

My hope is that this repository and the [accompanying website](https://www.bbcelite.com) will be useful for those who want to learn more about Elite and what makes it tick. It is provided on an educational and non-profit basis, with the aim of helping people appreciate one of the most iconic games of the 8-bit era.


## Contents

* [Acknowledgements](#acknowledgements)

  * [A note on licences, copyright etc.](#user-content-a-note-on-licences-copyright-etc)

* [Browsing the source in an IDE](#browsing-the-source-in-an-ide)

* [Building Elite from the source](#building-elite-from-the-source)

  * [Requirements](#requirements)
  * [Build targets](#build-targets)
  * [Windows](#windows)
  * [Mac and Linux](#mac-and-linux)
  * [Verifying the output](#verifying-the-output)
  * [Log files](#log-files)

* [Building different release versions of Elite](#building-different-release-versions-of-elite)


## Acknowledgements

Elite was written by Ian Bell and David Braben and is copyright &copy; Acornsoft 1984.

The code on this site has been disassembled from the version released on [Ian Bell's personal website](http://www.elitehomepage.org/).

The commentary is copyright &copy; Mark Moxon. Any misunderstandings or mistakes in the documentation are entirely my fault.

Huge thanks are due to the original authors for not only creating such an important piece of my childhood, but also for releasing the source code for us to play with; to Paul Brink for his annotated disassembly; and to Kieran Connell for his [BeebAsm version](https://github.com/kieranhj/elite-beebasm), which I forked as the original basis for this project. You can find more information about this project in the [accompanying website's project page](https://www.bbcelite.com/about_site/about_this_project.html).

The following archive from Ian Bell's site forms the basis for this project:

* [BBC Elite, disc version](http://www.elitehomepage.org/archive/a/a4100000.zip)

### A note on licences, copyright etc.

This repository is _not_ provided with a licence, and there is intentionally no `LICENSE` file provided.

According to [GitHub's licensing documentation](https://docs.github.com/en/free-pro-team@latest/github/creating-cloning-and-archiving-repositories/licensing-a-repository), this means that "the default copyright laws apply, meaning that you retain all rights to your source code and no one may reproduce, distribute, or create derivative works from your work".

The reason for this is that my commentary is intertwined with the original Elite source code, and the original source code is copyright. The whole site is therefore covered by default copyright law, to ensure that this copyright is respected.

Under GitHub's rules, you have the right to read and fork this repository... but that's it. No other use is permitted, I'm afraid.

My hope is that the educational and non-profit intentions of this repository will enable it to stay hosted and available, but the original copyright holders do have the right to ask for it to be taken down, in which case I will comply without hesitation. I do hope, though, that along with the various other disassemblies and commentaries of this source, it will remain viable.


## Browsing the source in an IDE

If you want to browse the source in an IDE, you might find the following useful.

* The most interesting files are in the [sources](sources) folder:

  * The main game's source code is in the [elite-source-flight.asm](sources/elite-source-flight.asm) and [elite-source-docked.asm](sources/elite-source-docked.asm) files (for when we're in-flight or docked) - this is the motherlode and probably contains all the stuff you're interested in.

  * The game's loader is in the [elite-loader1.asm](sources/elite-loader1.asm), [elite-loader2.asm](sources/elite-loader2.asm) and [elite-loader3.asm](sources/elite-loader3.asm) files - these are mainly concerned with setup and copy protection.

* It's probably worth skimming through the [notes on terminology and notations](https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html) on the accompanying website, as this explains a number of terms used in the commentary, without which it might be a bit tricky to follow at times (in particular, you should understand the terminology I use for multi-byte numbers).

* The accompamying website contains [a number of "deep dive" articles](https://www.bbcelite.com/deep_dives/), each of which goes into an aspect of the game in detail. Routines that are explained further in these articles are tagged with the label `Deep dive:` and the relevant article name.

* There are loads of routines and variables in Elite - literally hundreds. You can find them in the source files by searching for the following: `Type: Subroutine`, `Type: Variable`, `Type: Workspace` and `Type: Macro`.

* If you know the name of a routine, you can find it by searching for `Name: <name>`, as in `Name: SCAN` (for the 3D scanner routine) or `Name: LL9` (for the ship-drawing routine).

* The entry point for the [main game code](sources/elite-source-t.asm) is routine `TT170`, which you can find by searching for `Name: TT170`. If you want to follow the program flow all the way from the title screen around the main game loop, then you can find a number of [deep dives on program flow](https://www.bbcelite.com/deep_dives/) on the accompanying website.

* The source code is designed to be read at an 80-column width and with a monospaced font, just like in the good old days.

I hope you enjoy exploring the inner-workings of BBC Elite as much as I have.


## Building Elite from the source

### Requirements

You will need the following to build Elite from the source:

* BeebAsm, which can be downloaded from the [BeebAsm repository](https://github.com/stardot/beebasm). Mac and Linux users will have to build their own executable with `make code`, while Windows users can just download the `beebasm.exe` file.

* Python. Both versions 2.7 and 3.x should work.

* Mac and Linux users may need to install `make` if it isn't already present (for Windows users, `make.exe` is included in this repository).

For details of how the build process works, see the [build documentation on bbcelite.com](https://www.bbcelite.com/about_site/building_elite.html).

Let's look at how to build Elite from the source.

### Build targets

There are two main build targets available. They are:

* `build` - An unencrypted version
* `encrypt` - An encrypted version that exactly matches the released version of the game

The unencrypted version should be more useful for anyone who wants to make modifications to the game code. It includes a default commander with lots of cash and equipment, which makes it easier to test the game. As this target produces unencrypted files, the binaries produced will be quite different to the binaries on the original source disc, which are encrypted.

The encrypted version produces the released version of Elite, along with the standard default commander.

Builds are supported for both Windows and Mac/Linux systems. In all cases the build process is defined in the `Makefile` provided.

Note that the build ends with a warning that there is no `SAVE` command in the source file. You can ignore this, as the source file contains a `PUTFILE` command instead, but BeebAsm still reports this as a warning.

### Windows

For Windows users, there is a batch file called `make.bat` to which you can pass one of the build targets above. Before this will work, you should edit the batch file and change the values of the `BEEBASM` and `PYTHON` variables to point to the locations of your `beebasm.exe` and `python.exe` executables. You also need to change directory to the repository folder (i.e. the same folder as `make.exe`).

All being well, doing one of the following:

```
make.bat build
```

```
make.bat encrypt
```

will produce a file called `elite-disc.ssd`, which you can then load into an emulator, or into a real BBC Micro using a device like a Gotek.

### Mac and Linux

The build process uses a standard GNU `Makefile`, so you just need to install `make` if your system doesn't already have it. If BeebAsm or Python are not on your path, then you can either fix this, or you can edit the `Makefile` and change the `BEEBASM` and `PYTHON` variables in the first two lines to point to their locations. You also need to change directory to the repository folder (i.e. the same folder as `Makefile`).

All being well, doing one of the following:

```
make build
```

```
make encrypt
```

will produce a file called `elite-disc.ssd`, which you can then load into an emulator, or into a real BBC Micro using a device like a Gotek.

### Verifying the output

The build process also supports a verification target that prints out checksums of all the generated files, along with the checksums of the files extracted from the original sources.

You can run this verification step on its own, or you can run it once a build has finished. To run it on its own, use the following command on Windows:

```
make.bat verify
```

or on Mac/Linux:

```
make verify
```

To run a build and then verify the results, you can add two targets, like this on Windows:

```
make.bat encrypt verify
```

or this on Mac/Linux:

```
make encrypt verify
```

The Python script `crc32.py` does the actual verification, and shows the checksums and file sizes of both sets of files, alongside each other, and with a Match column that flags any discrepancies. If you are building an unencrypted set of files then there will be lots of differences, while the encrypted files should mostly match (see the Differences section below for more on this).

The binaries in the `extracted` folder were taken straight from the [cassette sources disc image](http://www.elitehomepage.org/archive/a/a4080602.zip) (though see the [notes on `ELTB`](#eltb) below), while those in the `output` folder are produced by the build process. For example, if you don't make any changes to the code and build the project with `make encrypt verify`, then this is the output of the verification process:

```
[--extracted--]  [---output----]
Checksum   Size  Checksum   Size  Match  Filename
-----------------------------------------------------------
a9ee9d74  17437  a9ee9d74  17437   Yes   D.CODE.bin
dad7d3a3  17437  dad7d3a3  17437   Yes   D.CODE.unprot.bin
9f4a04fd   2560  9f4a04fd   2560   Yes   D.MOA.bin
d9eb34f9   2560  d9eb34f9   2560   Yes   D.MOB.bin
93fe2e13   2560  93fe2e13   2560   Yes   D.MOC.bin
64e8ebb4   2560  64e8ebb4   2560   Yes   D.MOD.bin
80afbff9   2560  80afbff9   2560   Yes   D.MOE.bin
b86fe100   2560  b86fe100   2560   Yes   D.MOF.bin
72f99614   2560  72f99614   2560   Yes   D.MOG.bin
29b6ce81   2560  29b6ce81   2560   Yes   D.MOH.bin
0eeab415   2560  0eeab415   2560   Yes   D.MOI.bin
7911181d   2560  7911181d   2560   Yes   D.MOJ.bin
851d789f   2560  851d789f   2560   Yes   D.MOK.bin
3025e5d8   2560  3025e5d8   2560   Yes   D.MOL.bin
d6c01098   2560  d6c01098   2560   Yes   D.MOM.bin
6930e1c7   2560  6930e1c7   2560   Yes   D.MON.bin
43caddc7   2560  43caddc7   2560   Yes   D.MOO.bin
ac1d57b2   2560  ac1d57b2   2560   Yes   D.MOP.bin
14c1e8f6    256  14c1e8f6    256   Yes   ELITE2.bin
6f90769a   2816  6f90769a   2816   Yes   ELITE3.bin
ec04b4d2   5376  ec04b4d2   5376   Yes   ELITE4.bin
42f42f63  19997  42f42f63  19997   Yes   T.CODE.bin
8819c78b  19997  8819c78b  19997   Yes   T.CODE.unprot.bin
```

All the compiled binaries match the extracts, so we know we are producing the same final game as the release version.

### Log files

During compilation, details of every step are output in a file called `compile.txt` in the `output` folder. If you have problems, it might come in handy, and it's a great reference if you need to know the addresses of labels and variables for debugging (or just snooping around).


## Building different release versions of Elite

This repository contains the source code for two different versions of Disc Elite:

* The version from the Stairway to Hell archive

* The version from the game disc on Ian Bell's website

By default the build process builds the Stairway to Hell version, but you can build the Ian Bell disc version by appending `release-disc=ib-disc` to the `make` command, like this on Windows:

```
make.bat encrypt verify release-disc=ib-disc
```

or this on a Mac or Linux:

```
make encrypt verify release-disc=ib-disc
```

You can also add `release-disc=sth`, though that's the default value so it isn't necessary.

You can see the differences between the versions by searching the source code for `_STH_DISC` (for features in the Stairway to Hell version) or `_IB_DISC` (for features in the Ian Bell game disc). There are only a few differences:

* The Ian Bell version contains the refund bug, which has been fixed in the Stairway to Hell version

* The Ian Bell version never spawns asteroids, which has been fixed in the Stairway to Hell version

* The Ian Bell version sets bit 2 of the competition flag in the commander file, while the Stairway to Hell version sets bit 5

In other words, the Ian Bell version is the very first release of the disc version of Elite, while the Stairway to Hell version has both bugs fixed and a bumped-up version number.

Note that the differences between the versions implemented in this project only extend those in the main game code. The version on Ian Bell's site also contains a whole load of copy protection that differs from the disabled copy protection code in the Stairway to Hell version, and it also contains two more binary files (`ELITE5` and `ELITE6`), plus a `!BOOT` file that contains even more copy protection code. I haven't disassembled the loader files from this version as that's a whole different rabbit hole, so if you build the Ian Bell version with `make encrypt verify`, the compiled loader binaries will not match those extracted from the original disc. The main binaries will match, however, which is the interesting part from a digital archaeology perspective, as that's where the bug fixes live.

---

Right on, Commanders!

_Mark Moxon_