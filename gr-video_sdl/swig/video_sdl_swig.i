/* -*- c++ -*- */

#define VIDEO_SDL_API

%include "gnuradio.i"			// the common stuff

//load generated python docstrings
%include "video_sdl_swig_doc.i"

%{
#include "video_sdl/sink_s.h"
#include "video_sdl/sink_uc.h"
%}


%include "video_sdl/sink_s.h"
GR_SWIG_BLOCK_MAGIC2(video_sdl, sink_s);
%include "video_sdl/sink_uc.h"
GR_SWIG_BLOCK_MAGIC2(video_sdl, sink_uc);
