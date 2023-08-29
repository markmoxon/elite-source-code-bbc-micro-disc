# Annotated source code for the BBC Micro disc version of Elite

This folder contains the annotated source code for the BBC Micro disc version of Elite.

* [elite-disc.asm](elite-disc.asm) builds the SSD disc image from the assembled binaries and other source files

* [elite-loader1.asm](elite-loader1.asm) contains the source for the first stage of the loader

* [elite-loader2.asm](elite-loader2.asm) contains the source for the second stage of the loader

* [elite-loader3.asm](elite-loader3.asm) contains the source for the third stage of the loader

* [elite-missile.asm](elite-missile.asm) contains the source for the missile's ship blueprint

* [elite-readme.asm](elite-readme.asm) generates a README file for inclusion on the SSD disc image

* [elite-ships-a.asm](elite-ships-a.asm) through [elite-ships-p.asm](elite-ships-p.asm) generate the ship blueprint files D.MOA to D.MOP

* [elite-source-docked.asm](elite-source-docked.asm) contains the main source for the docked portion of the game

* [elite-source-flight.asm](elite-source-flight.asm) contains the main source for the flight portion of the game

* [elite-text-tokens.asm](elite-text-tokens.asm) contains the source for the game's text

It also contains the following file that is generated during the build process:

* [elite-build-options.asm](elite-build-options.asm) stores the make options in BeebAsm format so they can be included in the assembly process

---

Right on, Commanders!

_Mark Moxon_