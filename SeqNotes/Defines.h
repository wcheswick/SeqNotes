//
//  Defines.h
//  SeqShow
//
//  Created by ches on 12/12/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#ifndef Defines_h
#define Defines_h


#define OEIS_URL            @"https://oeis.org/"

#define SEQUENCES_ARCHIVE   @"./Sequences.archive"   // archived ordered list of apiaries
#define PLAY_OPTIONS_ARCHIVE    @"./PlayOptions.archive"

#define MAX_VALUES  (200*10)    // 200 beats per minute for 10 minutes

// screen layout stuff

#define SMALL_SEP   5.0
#define SEP         10.0
#define LARGE_SEP   25.0

#define BUTTON_TOP  350.0

#define SMALL_BUTTON_FONT_SIZE   14
#define SMALL_BUTTON_H    (SMALL_BUTTON_FONT_SIZE+3)

#define BUTTON_FONT_SIZE     18
#define BUTTON_H    (BUTTON_FONT_SIZE + 4)

#define BUTTON_SEP  SEP

#define TINY_LABEL_FONT_SIZE   10
#define TINY_LABEL_H    (TINY_LABEL_FONT_SIZE + 4)

#define SMALL_LABEL_FONT_SIZE   12
#define SMALL_LABEL_H   (SMALL_LABEL_FONT_SIZE + 5)

#define LABEL_FONT_SIZE 16
#define LABEL_H     (LABEL_FONT_SIZE + 4)

#define LARGE_FONT_SIZE 22
#define LARGE_H (LARGE_FONT_SIZE+9)

#define INSET       3.0
#define SWITCH_H    40.0
#define NAME_HEIGHT (SWITCH_H - 10.0)

#define TOP_LABEL_Y 70
#define SWITCH_W    100.0
#define SEGMENT_BUTTON_H    50.0

#define LINE_H  35          // space for a line on display
#define UPDOWN_BUTTON_W     LINE_H

#define LATER   0   /*later*/

// view tools

#define BELOW(r)    ((r).origin.y + (r).size.height)
#define RIGHT(r)    ((r).origin.x + (r).size.width)

#define SET_VIEW_X(v,nx) {CGRect f = (v).frame; f.origin.x = (nx); (v).frame = f;}
#define SET_VIEW_Y(v,ny) {CGRect f = (v).frame; f.origin.y = (ny); (v).frame = f;}

#define SET_VIEW_WIDTH(v,w)     {CGRect f = (v).frame; f.size.width = (w); (v).frame = f;}
#define SET_VIEW_HEIGHT(v,h)    {CGRect f = (v).frame; f.size.height = (h); (v).frame = f;}

#define CENTER_VIEW(cv, v)  {CGRect f = (cv).frame; \
f.origin.x = ((v).frame.size.width - f.size.width)/2.0; \
(cv).frame = f;}

#endif /* Defines_h */
