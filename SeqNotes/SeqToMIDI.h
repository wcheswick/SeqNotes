//
//  SeqToMIDI.h
//  SeqNotes
//
//  Created by ches on 12/20/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#ifndef SeqToMIDI_h
#define SeqToMIDI_h

#include <stdio.h>


#define PIANO   1   // piano
#define MARIMBA   13
#define ALTOSAX     65

// Dave's defaults

//midi=1&SAVE=SAVE&seq=%@&bpm=100&vol=100&voice=%d&velon=80&veloff=80&pmod=88&poff=20&dmod=1&doff=0&cutoff=4096

#define BPM     100
#define VOL     100
#define VOICE   ALTOSAX
#define VELON   80
#define VELOFF  80
#define PMOD    88
#define POFF    20
#define DMOD    1
#define DOFF    0
#define CUTOFF  4096

void seqToMidi(int ofd, long sequence[], size_t seqLen,
          int dohdr, int dotrk, int ntrk,
          int bpm, char *name, int vol, int voice,
          int velon, int veloff,
          int pmod, int poff, int dmod, int doff, size_t cutoff);

#endif /* SeqToMIDI_h */
