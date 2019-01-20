//
//  SeqToMIDI.c
//  SeqNotes
//
//  Created by ches on 12/20/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//
//  This is a translation of David Applegate's genmidi.awk to C. David did all
//  the fussy MIDI format details.

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

#include "SeqToMIDI.h"

#define MEMCHUNK    10000

u_char *midi = 0;   // midi assembly buffer
int nmidi = 0;
int allocmidi = 0;

FILE *out;

static void
need(size_t n) {
    if (midi && nmidi + n <= allocmidi)
        return;
    if (!midi) {
        midi = (u_char *)malloc(MEMCHUNK);
        allocmidi = MEMCHUNK;
        return;
    }
    allocmidi += MEMCHUNK;
    midi = (u_char *)realloc(midi, allocmidi);
}

static void
emit(u_char c) {
    need(1);
    assert(nmidi < allocmidi);
    midi[nmidi++] = c;
}

static void
emit_str(const char *s) {
    size_t i, n = strlen(s);
    for (i=0; i<n; i++)
        emit(s[i]);
}

#ifdef UNUSED
static void
emit_int(const int v) {
    emit(v / (256*256*256));
    emit(v / (256*256));
    emit(v / 256);
    emit(v);
}
#endif

static void
emit_3(const int v) {
    emit(v / (256*256));
    emit(v / 256);
    emit(v);
}

static void
emit_short(u_short v) {
    emit(v / 256);
    emit(v);
}

static void
emit_char(const u_char c) {
    emit(c & 0xff);
}

static void
emit_var(int n) {
    if (n)
        n = n;
    if (n >= 2097152) {
        emit(128 + n/2097152);
        n = n % 2097152;
    }
    if (n >= 16384) {
        emit(128 + n/16384);
        n = n % 16384;
    }
    if (n >= 128) {
        emit(128 + n/128);
        n = n % 128;
    }
    emit(n);
}

static void
emit_meta(int delay, u_char code, u_char len) {
    emit_var(delay);
    emit(255);      // FF = meta event
    emit(code);
    emit(len);
}

static void
midiout(char *label) {
    int i;
    fprintf(out, "%s", label);
    fprintf(out, "%c%c%c%c", nmidi/(256*256*256), (nmidi/(256*256))%256, (nmidi/256)%256, nmidi%256);
    for (i=0; i<nmidi; i++)
        putc(midi[i], out);
    nmidi = 0;
}

/*
 * Generates a MIDI file based on a sequence of integers.  The MIDI output file has
 * a header and the music goes on track 1.

 * seqout is an opened file to receive the midi sequence bytes
*/

void
seqToMidi(int ofd, long sequence[], size_t seqLen,
          int dohdr, int dotrk, int ntrk,
          int bpm, char *name, int vol, int voice,
          int velon, int veloff,
          int pmod, int poff, int dmod, int doff, size_t cutoff) {
    out = fdopen(ofd, "w");
    
    // Sanity checks, from Dave
    if (ntrk <= 0 || ntrk > 127) ntrk=1;
    if (bpm <= 0 || bpm >= 1000000) bpm=100;
    if (!name || !strlen(name)) name="Piano\\";
    if (vol <= 0 || vol > 127) vol=100;
    if (voice <= 0 || voice >= 129) voice=1; // XXX need actual max
    if (velon <= 0 || velon >= 128) velon = 80;
    if (veloff <= 0 || veloff >= 128) veloff = 80;
    if (pmod <= 0 || pmod > 128) pmod=88;
    if (poff < 0 || poff + pmod > 128) poff = (128 - pmod)/2;
    if (dmod <= 0 || dmod > 5) dmod=1;
    if (doff < 0 || doff+dmod > 5) doff=0;
    if (cutoff <= 0 || cutoff > seqLen) cutoff=seqLen;
    
    if (dohdr) {
        emit_short(1);                  // 0->single multichannel track,
                                        // 1->simultaneous tracks, 2->sequential tracks
        emit_short(ntrk+1);             // no. of tracks
        emit_char(1); emit_char(224);   // resolution, frames per second (224=30)
        midiout("MThd");
        
        // [time delta, event, event data]*
        // FF = meta event, data = code, len, event data
        
        emit_meta(0,127,3);             // 7F sequencer-specific
        emit_char(0); emit_char(0); emit_char(65);     // 00 00 41
        
        emit_meta(0,84,5);              // 54 SMPTE offset
        emit_char(96); emit_char(0); emit_char(10); emit_char(0); emit_char(0);
        
        emit_meta(0,88,4);                 // 58 Time Signature
        emit_char(4); emit_char(2); emit_char(24); emit_char(8);

        emit_meta(0,81,3);              // 51 Set tempo
        emit_3(60*1000000/bpm);         // microseconds per quarter-note
        
        emit_meta(0,47,0);              // 2F End of track
        midiout("MTrk");
    }
    
    if (dotrk) {
        emit_meta(0,1,strlen(name));
        emit_str(name);                                             // BC 06 chan 12 data entry := 0
        emit_var(0); emit_char(188); emit_char(6); emit_char(0);    // BC 07 chan 12 vol := 100
        emit_var(0); emit_char(188); emit_char(7); emit_char(vol);  // BC 40 chan 12 hold := off
        emit_var(0); emit_char(188); emit_char(64); emit_char(0);   // CC chan 12 to program 1 (piano)
        emit_var(0); emit_char(204); emit_char(voice-1);
    }

    size_t i, j;
    for (i=0; i<cutoff; i++) {
        if (dotrk) {
            int p=0, d=0;
            long s = sequence[i];
            int neg = s < 0;
            if (neg)
                s = -s;
#ifdef equivqm
            for (i=1; i<=length($2); i++) {
                p = (p*10 + substr($2,i,1)) % pmod;
                d = (d*10 + substr($2,i,1)) % dmod;
            }
#endif
            // this is stupid, but modular arithmetic confuses me, and I don't understand exactly
            // what the above is doing.  So I switch to a string and let his code work.  It is better
            // to be right than fast, and fast really doesn't count here, and I want to get this done today.
            char buf[10];
            snprintf(buf, sizeof(buf), "%ld", s);
            for (j=0; j<strlen(buf); j++) {
                p = (p*10 + buf[j] - '0') % pmod;
                d = (d*10 + buf[j] - '0') % dmod;
            }
            // There, that wasn't so bad, was it?
            if (neg) {
                p = (pmod-p) % pmod;
                d = (dmod-d) % dmod;
            }
            p += poff;
            d += doff;
            int x = 120*(1<<d);
//            NSLog(@"p=% d=%d  velon=%d x=%d veloff=%d",
//                  p, d, velon, x, veloff);
            emit_var(0); emit_char(156); emit_char(p); emit_char(velon);
            emit_var(x); emit_char(140); emit_char(p); emit_char(veloff);
        }
    }
    if (dotrk) {
        emit_meta(0,47,0);      // FF 2F End of track
        midiout("MTrk");
        fflush(out);
    }
    if (midi) {
        free(midi);
        midi = 0;
    }
}
