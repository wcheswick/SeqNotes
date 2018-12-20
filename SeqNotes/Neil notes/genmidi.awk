#!/bin/gawk
function midistr(s) {
  for (i=1; i<=length(s); i++) {
    midi[++nmidi] = substr(s,i,1);
  }
}
function midiint(n) {
  midi[nmidi+4] = n % 256;
  n /= 256;
  midi[nmidi+3] = n % 256;
  n /= 256;
  midi[nmidi+2] = n % 256;
  n /= 256;
  midi[nmidi+1] = n;
  nmidi+=4;
}
function midithree(n) {
  midi[nmidi+3] = n % 256;
  n /= 256;
  midi[nmidi+2] = n % 256;
  n /= 256;
  midi[nmidi+1] = n;
  nmidi+=3;
}
function midishort(n) {
  midi[nmidi+2] = n % 256;
  n /= 256;
  midi[nmidi+1] = n;
  nmidi+=2;
}
function midichar(n) {
  midi[++nmidi] = n;
}
function midivar(n) {
  if (n >= 2097152) {
    midi[++nmidi] = 128 + n/2097152;
    n = n % 2097152;
  }
  if (n >= 16384) {
    midi[++nmidi] = 128 + n/16384;
    n = n % 16384;
  }
  if (n >= 128) {
    midi[++nmidi] = 128 + n/128;
    n = n % 128;
  }
  midi[++nmidi] = n;
}
function midimeta(delay,code,len) {
  midivar(delay);
  midi[++nmidi] = 255; # FF = meta event
  midi[++nmidi] = code;
  midi[++nmidi] = len;
}
function midiout(lbl) {
  printf ("%s", lbl);
  printf ("%c%c%c%c", nmidi/(256*256*256), (nmidi/(256*256))%256, (nmidi/256)%256, nmidi%256);
  for (i=1; i<=nmidi; i++) {
    printf ("%c", midi[i]);
  }
}
BEGIN{
  # vars:
  # dohdr: output header (default 1)
  # dotrk: output sequence track (default 1)
  # ntrk: number of sequence tracks (default 1)
  # bpm: quarter-notes per minute (default 100)
  # name: text string to output (default "OEIS sequence")
  # vol: volume (default 100)
  # voice: voice (aka program), (default 1 = Piano)
  # velon: velocity striking note (default 80)
  # veloff: velocity releasing note (default 80)
  # pmod: pitch modulus (default 88)
  # poff: pitch offset (default center around 64)
  # dmod: duration modulus (default 1)
  # doff: duration offset (default 0)
  # cutoff: truncate sequence after n entries, (default -1 = no cutoff)

  if (ENVIRON["FORM_bpm"] != "") bpm = ENVIRON["FORM_bpm"];
  if (ENVIRON["FORM_vol"] != "") vol = ENVIRON["FORM_vol"];
  if (ENVIRON["FORM_voice"] != "") voice = ENVIRON["FORM_voice"];
  if (ENVIRON["FORM_velon"] != "") velon = ENVIRON["FORM_velon"];
  if (ENVIRON["FORM_veloff"] != "") veloff = ENVIRON["FORM_veloff"];
  if (ENVIRON["FORM_pmod"] != "") pmod = ENVIRON["FORM_pmod"];
  if (ENVIRON["FORM_poff"] != "") poff = ENVIRON["FORM_poff"];
  if (ENVIRON["FORM_dmod"] != "") dmod = ENVIRON["FORM_dmod"];
  if (ENVIRON["FORM_doff"] != "") doff = ENVIRON["FORM_doff"];
  if (ENVIRON["FORM_cutoff"] != "") cutoff = ENVIRON["FORM_cutoff"];

  if (dohdr=="") dohdr=1;
  if (dotrk=="") dotrk=1;
  if (ntrk=="" || ntrk+0 <= 0 || ntrk+0 > 127) ntrk=1;
  if (bpm=="" || bpm+0 <= 0 || bpm+0 >= 1000000) bpm=100;
  if (name=="") name="Piano\\";
  if (vol=="" || vol+0 <= 0 || vol+0 > 127) vol=100;
  if (voice=="" || voice+0 <= 0 || voice+0 >= 129) voice=1;
  if (velon=="" || velon+0 <= 0 || velon+0 >= 128) velon = 80;
  if (veloff=="" || veloff+0 <= 0 || veloff+0 >= 128) veloff = 80;
  if (pmod=="" || pmod+0 <= 0 || pmod+0 > 128) pmod=88;
  if (poff=="" || poff+0 < 0 || poff + pmod > 128) poff = (128 - pmod)/2;
  if (dmod=="" || dmod+0 <= 0 || dmod+0 > 5) dmod=1;
  if (doff=="" || doff+0 < 0 || doff+dmod > 5) doff=0;
  if (cutoff=="" || cutoff+0 <= 0) cutoff=0;

  if (dohdr) {
    nmidi=0;

    midishort(1);          # 0->single multichannel track,
		           # 1->simultaneous tracks, 2->sequential tracks
    midishort(ntrk+1);     # no. of tracks
    midichar(1); midichar(224); # resolution, frames per second (224=30)

    midiout("MThd");

    nmidi = 0;
    # [time delta, event, event data]*
    # FF = meta event, data = code, len, event data

    midimeta(0,127,3); # 7F sequencer-specific
    midichar(0); midichar(0); midichar(65); # 00 00 41

    midimeta(0,84,5);  # 54 SMPTE offset
    midichar(96); midichar(0); midichar(10); midichar(0); midichar(0);

    midimeta(0,88,4);  # 58 Time Signature
    midichar(4); midichar(2); midichar(24); midichar(8);

    midimeta(0,81,3);  # 51 Set tempo
    midithree(60*1000000/bpm); # microseconds per quarter-note

    midimeta(0,47,0);  # 2F End of track
    midiout("MTrk");
  }

  if (dotrk) {
    nmidi=0;
    midimeta(0,1,length(name));
    midistr(name);
    # BC 06 chan 12 data entry := 0
    midivar(0); midichar(188); midichar(6); midichar(0);
    # BC 07 chan 12 vol := 100
    midivar(0); midichar(188); midichar(7); midichar(vol);
    # BC 40 chan 12 hold := off
    midivar(0); midichar(188); midichar(64); midichar(0);
    # CC chan 12 to program 1 (piano)
    midivar(0); midichar(204); midichar(voice-1);
  }
}
cutoff==0 || NR <= cutoff {
  if (dotrk) {
    p=0;
    d=0;
    if (substr($2,1,1) == "-") {neg=1; $2 = substr($2,2);}
    else neg = 0;
    for (i=1; i<=length($2); i++) {
      p = (p*10 + substr($2,i,1)) % pmod;
      d = (d*10 + substr($2,i,1)) % dmod;
    }
    if (neg) {
      p = (pmod-p) % pmod;
      d = (dmod-d) % dmod;
    }
    p += poff;
    d += doff;
    midivar(0); midichar(156); midichar(p); midichar(velon);
    midivar(120*2^d); midichar(140); midichar(p); midichar(veloff);
  }
}
END{
  if (dotrk) {
    midimeta(0,47,0); # FF 2F End of track
    midiout("MTrk");
  }
}

