#Prerequieremts
Boost
	Download Boost from here: https://deac-ams.dl.sourceforge.net/project/boost/boost-binaries/1.67.0/boost_1_67_0-msvc-14.0-64.exe
	Copy from ``C:\local\boost_1_67_0\`` to ``C:\Program Files\PothosSDR\boost\``
	
	Set your SYSTEM VARIABLES using Rapid Enviroment Editor for example
	```
	BOOST_INCLUDEDIR    C:\Program Files\PothosSDR\boost
    	BOOST_LIBRARYDIR    C:\Program Files\PothosSDR\boost\lib64-msvc-14.0
    	BOOST_ROOT          C:\Program Files\PothosSDR\boost\boost
	```
SDL1.2
	Get it here: http://web.archive.org/web/20191227232250if_/http://libsdl.org/release/SDL-devel-1.2.15-VC.zip
	Extraxt it somewhere (``C:\Program Files\PothosSDR\libsdl`` for example)
	

So you can use gr_modtool you need readline module, you install this with: ```pip install pyreadline``` (if using linux) or ```pip install readline``` if using windows

Then you create your OOT module with: gr_modtool nm video_sdl

If it fails like this: Could not find gr-newmod source dir.

then your gr_modtool is broken so you first need to fix it

the problem is that ``gr.prefs().get_string('modtool', 'newmod_path', options.srcdir)`` points to ``C:\PothosSDR\share\gnuradio\modtool\gr-newmod`` 
while it should point to ``C:\Program Files\PothosSDR\share\gnuradio\modtool\gr-newmod``

Go here: C:\Program Files\PothosSDR\lib\python2.7\site-packages\gnuradio\modtool\modtool_newmod.py

change ``self._srcdir = gr.prefs().get_string('modtool', 'newmod_path', options.srcdir)``
to ``self._srcdir = os.environ['GR_PREFIX'].split(os.pathsep)[0] + '\share\gnuradio\modtool\gr-newmod'``


Then we need to add our block to this module so we do this like this

```
gr_modtool add sink_s
```
you should see something like this

```
C:\Users\Mitja\Documents\Visual Studio 2017\Projects\SDR\GNURadio blocks\new oot
 module\gr-SDLVideo>gr_modtool add sink_s
GNU Radio module name identified: SDLVideo
Block/code identifier: sink_s
('sink', 'source', 'sync', 'decimator', 'interpolator', 'general', 'tagged_strea
m', 'hier', 'noblock')
Enter block type: sink
Language (python/cpp):
Language (python/cpp): cpp
Language: C++
Please specify the copyright holder: GNURadio
Enter valid argument list, including default arguments: double framerate, int width, int height, unsigned int format, int dst_width, int dst_height
Add Python QA code? [Y/n] n
Add C++ QA code? [y/N] n
Adding file 'lib\sink_s_impl.h'...
Adding file 'lib\sink_s_impl.cc'...
Adding file 'include\SDLVideo\sink_s.h'...
Editing swig\SDLVideo_swig.i...
Adding file 'python\qa_sink_s.py'...
Editing python/CMakeLists.txt...
Adding file 'grc\SDLVideo_sink_s.xml'...
Editing grc/CMakeLists.txt...
```

then goto ``gr-video_sdl\lib\sink_s_impl.h`` and add
```
/* -*- c++ -*- */
/* 
 * Copyright 2022 GNURadio.
 * 
 * This is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 * 
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street,
 * Boston, MA 02110-1301, USA.
 */

#ifndef INCLUDED_VIDEO_SDL_SINK_S_IMPL_H
#define INCLUDED_VIDEO_SDL_SINK_S_IMPL_H

#include <video_sdl/sink_s.h>
#include <SDL.h>

namespace gr {
namespace video_sdl {

/*  fourcc (four character code) */
#define vid_fourcc(a, b, c, d)                                             \
    (((unsigned)(a) << 0) | ((unsigned)(b) << 8) | ((unsigned)(c) << 16) | \
     ((unsigned)(d) << 24))
#define IMGFMT_YV12 vid_fourcc('Y', 'V', '1', '2') /* 12  YVU 4:2:0 */

class sink_s_impl : public sink_s
{
private:
    int d_chunk_size;

protected:
    void copy_line_pixel_interleaved(unsigned char* dst_pixels_u,
                                     unsigned char* dst_pixels_v,
                                     const short* src_pixels,
                                     int src_width);
    void copy_line_line_interleaved(unsigned char* dst_pixels_u,
                                    unsigned char* dst_pixels_v,
                                    const short* src_pixels,
                                    int src_width);
    void copy_line_single_plane(unsigned char* dst_pixels,
                                const short* src_pixels,
                                int src_width);
    void copy_line_single_plane_dec2(unsigned char* dst_pixels,
                                     const short* src_pixels,
                                     int src_width);
    int copy_plane_to_surface(int plane, int noutput_items, const short* src_pixels);

    float d_framerate;
    int d_wanted_frametime_ms;
    int d_width;
    int d_height;
    int d_dst_width;
    int d_dst_height;
    int d_format;
    int d_current_line;
    SDL_Surface* d_screen;
    SDL_Overlay* d_image;
    SDL_Rect d_dst_rect;
    float d_avg_delay;
    unsigned int d_wanted_ticks;

public:
    sink_s_impl(double framerate,
                int width,
                int height,
                unsigned int format,
                int dst_width,
                int dst_height);
    ~sink_s_impl();

    int work(int noutput_items,
             gr_vector_const_void_star& input_items,
             gr_vector_void_star& output_items);
};

} /* namespace video_sdl */
} /* namespace gr */

#endif /* INCLUDED_VIDEO_SDL_SINK_S_IMPL_H */
```

also goto ``gr-video_sdl\lib\sink_s_impl.cc`` and replace everything with this
```
/* -*- c++ -*- */
/*
 * Copyright 2006,2010,2012 Free Software Foundation, Inc.
 *
 * This file is part of GNU Radio
 *
 * GNU Radio is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 *
 * GNU Radio is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with GNU Radio; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street,
 * Boston, MA 02110-1301, USA.
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "sink_s_impl.h"
#include <gnuradio/io_signature.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <iostream>
#include <stdexcept>


namespace gr {
namespace video_sdl {


sink_s::sptr sink_s::make(double framerate,
                          int width,
                          int height,
                          unsigned int format,
                          int dst_width,
                          int dst_height)
{
    return gnuradio::get_initial_sptr(
        new sink_s_impl(framerate, width, height, format, dst_width, dst_height));
}

sink_s_impl::sink_s_impl(double framerate,
                         int width,
                         int height,
                         unsigned int format,
                         int dst_width,
                         int dst_height)
    : sync_block("video_sdl_sink_s",
                 io_signature::make(1, 3, sizeof(short)),
                 io_signature::make(0, 0, 0)),
      d_chunk_size(width * height),
      d_framerate(framerate),
      d_wanted_frametime_ms(0),
      d_width(width),
      d_height(height),
      d_dst_width(dst_width),
      d_dst_height(dst_height),
      d_format(format),
      d_current_line(0),
      d_screen(NULL),
      d_image(NULL),
      d_avg_delay(0.0),
      d_wanted_ticks(0)
{
    if (framerate <= 0.0)
        d_wanted_frametime_ms = 0; // Go as fast as possible
    else
        d_wanted_frametime_ms = (int)(1000.0 / framerate);

    if (dst_width < 0)
        d_dst_width = d_width;
    if (dst_height < 0)
        d_dst_height = d_height;
    if (0 == format)
        d_format = IMGFMT_YV12;

    atexit(SDL_Quit); // check if this is the way to do this
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::cerr << "video_sdl::sink_s: Couldn't initialize SDL:" << SDL_GetError()
                  << " \n SDL_Init(SDL_INIT_VIDEO) failed\n";
        throw std::runtime_error("video_sdl::sink_s");
    };

    /* accept any depth */
    d_screen = SDL_SetVideoMode(
        dst_width,
        dst_height,
        0,
        SDL_SWSURFACE | SDL_RESIZABLE |
            SDL_ANYFORMAT); // SDL_DOUBLEBUF |SDL_SWSURFACE| SDL_HWSURFACE||SDL_FULLSCREEN

    if (d_screen == NULL) {
        std::cerr << "Unable to set SDL video mode: " << SDL_GetError()
                  << "\n SDL_SetVideoMode() Failed \n";
        exit(1);
    }
    if (d_image) {
        SDL_FreeYUVOverlay(d_image);
    }

    /* Initialize and create the YUV Overlay used for video out */
    if (!(d_image =
              SDL_CreateYUVOverlay(d_width, d_height, SDL_YV12_OVERLAY, d_screen))) {
        std::cerr << "SDL: Couldn't create a YUV overlay: \n" << SDL_GetError() << "\n";
        throw std::runtime_error("video_sdl::sink_s");
    }

    printf("SDL screen_mode %d bits-per-pixel\n", d_screen->format->BitsPerPixel);
    printf("SDL overlay_mode %i \n", d_image->format);

    d_chunk_size = (std::min)(1, 16384 / width); // width*16;
    d_chunk_size = d_chunk_size * width;
    // d_chunk_size = (int) (width);
    set_output_multiple(d_chunk_size);

    /* Set the default playback area */
    d_dst_rect.x = 0;
    d_dst_rect.y = 0;
    d_dst_rect.w = d_dst_width;
    d_dst_rect.h = d_dst_height;
    // clear the surface to grey

    if (SDL_LockYUVOverlay(d_image)) {
        std::cerr << "SDL: Couldn't lock YUV overlay: \n" << SDL_GetError() << "\n";
        throw std::runtime_error("video_sdl::sink_s");
    }

    memset(d_image->pixels[0], 128, d_image->pitches[0] * d_height);
    memset(d_image->pixels[1], 128, d_image->pitches[1] * d_height / 2);
    memset(d_image->pixels[2], 128, d_image->pitches[2] * d_height / 2);
    SDL_UnlockYUVOverlay(d_image);
}

sink_s_impl::~sink_s_impl() { SDL_Quit(); }

void sink_s_impl::copy_line_pixel_interleaved(unsigned char* dst_pixels_u,
                                              unsigned char* dst_pixels_v,
                                              const short* src_pixels,
                                              int src_width)
{
    for (int i = 0; i < src_width; i++) {
        dst_pixels_u[i] = (unsigned char)src_pixels[i * 2];
        dst_pixels_v[i] = (unsigned char)src_pixels[i * 2 + 1];
    }
}

void sink_s_impl::copy_line_line_interleaved(unsigned char* dst_pixels_u,
                                             unsigned char* dst_pixels_v,
                                             const short* src_pixels,
                                             int src_width)
{
    for (int i = 0; i < src_width; i++) {
        dst_pixels_u[i] = (unsigned char)src_pixels[i];
        dst_pixels_v[i] = (unsigned char)src_pixels[i + src_width];
    }

    for (int i = src_width; i < src_width * 2; i++) {
        dst_pixels_v[i] = (unsigned char)src_pixels[i];
    }
}

void sink_s_impl::copy_line_single_plane(unsigned char* dst_pixels,
                                         const short* src_pixels,
                                         int src_width)
{
    for (int i = 0; i < src_width; i++) {
        dst_pixels[i] = (unsigned char)src_pixels[i];
    }
}

void sink_s_impl::copy_line_single_plane_dec2(unsigned char* dst_pixels,
                                              const short* src_pixels,
                                              int src_width)
{
    for (int i = 0, j = 0; i < src_width; i += 2, j++) {
        dst_pixels[j] = (unsigned char)src_pixels[i];
    }
}

int sink_s_impl::copy_plane_to_surface(int plane,
                                       int noutput_items,
                                       const short* src_pixels)
{
    const int first_dst_plane = (12 == plane || 1122 == plane) ? 1 : plane;
    const int second_dst_plane = (12 == plane || 1122 == plane) ? 2 : plane;
    int current_line = (0 == plane) ? d_current_line : d_current_line / 2;

    unsigned char* dst_pixels = (unsigned char*)d_image->pixels[first_dst_plane];
    dst_pixels = &dst_pixels[current_line * d_image->pitches[first_dst_plane]];

    unsigned char* dst_pixels_2 = (unsigned char*)d_image->pixels[second_dst_plane];
    dst_pixels_2 = &dst_pixels_2[current_line * d_image->pitches[second_dst_plane]];

    int src_width = (0 == plane || 12 == plane || 1122 == plane) ? d_width : d_width / 2;
    int noutput_items_produced = 0;
    int max_height = (0 == plane) ? d_height - 1 : d_height / 2 - 1;

    for (int i = 0; i < noutput_items; i += src_width) {
        // output one line at a time
        if (12 == plane) {
            copy_line_pixel_interleaved(dst_pixels, dst_pixels_2, src_pixels, src_width);
            dst_pixels_2 += d_image->pitches[second_dst_plane];
        } else if (1122 == plane) {
            copy_line_line_interleaved(dst_pixels, dst_pixels_2, src_pixels, src_width);
            dst_pixels_2 += d_image->pitches[second_dst_plane];
            src_pixels += src_width;
        } else if (0 == plane)
            copy_line_single_plane(dst_pixels, src_pixels, src_width);
        else /* 1==plane || 2==plane*/
            copy_line_single_plane_dec2(
                dst_pixels, src_pixels, src_width); // decimate by two horizontally

        src_pixels += src_width;
        dst_pixels += d_image->pitches[first_dst_plane];
        noutput_items_produced += src_width;
        current_line++;
        if (current_line > max_height) {
            // Start new frame
            // TODO, do this all in a separate thread
            current_line = 0;
            dst_pixels = d_image->pixels[first_dst_plane];
            dst_pixels_2 = d_image->pixels[second_dst_plane];
            if (0 == plane) {
                SDL_DisplayYUVOverlay(d_image, &d_dst_rect);
                // SDL_Flip(d_screen);
                unsigned int ticks = SDL_GetTicks(); // milliseconds
                d_wanted_ticks += d_wanted_frametime_ms;
                float avg_alpha = 0.1;
                int time_diff = d_wanted_ticks - ticks;
                d_avg_delay = time_diff * avg_alpha + d_avg_delay * (1.0 - avg_alpha);
            }
        }
    }

    if (0 == plane)
        d_current_line = current_line;

    return noutput_items_produced;
}

int sink_s_impl::work(int noutput_items,
                      gr_vector_const_void_star& input_items,
                      gr_vector_void_star& output_items)
{
    short *src_pixels_0, *src_pixels_1, *src_pixels_2;
    int noutput_items_produced = 0;
    int plane;
    int delay = (int)d_avg_delay;

    if (0 == d_wanted_ticks)
        d_wanted_ticks = SDL_GetTicks();
    if (delay > 0)
        SDL_Delay((unsigned int)delay); // compensate if running too fast

    if (SDL_LockYUVOverlay(d_image)) {
        return 0;
    }

    switch (input_items.size()) {
    case 3: // first channel=Y, second channel is  U , third channel is V
        src_pixels_0 = (short*)input_items[0];
        src_pixels_1 = (short*)input_items[1];
        src_pixels_2 = (short*)input_items[2];
        for (int i = 0; i < noutput_items; i += d_chunk_size) {
            copy_plane_to_surface(1, d_chunk_size, src_pixels_1);
            copy_plane_to_surface(2, d_chunk_size, src_pixels_2);
            noutput_items_produced +=
                copy_plane_to_surface(0, d_chunk_size, src_pixels_0);
            src_pixels_0 += d_chunk_size;
            src_pixels_1 += d_chunk_size;
            src_pixels_2 += d_chunk_size;
        }
        break;
    case 2:
        if (1) { // if(pixel_interleaved_uv)
            // first channel=Y, second channel is alternating pixels U and V
            src_pixels_0 = (short*)input_items[0];
            src_pixels_1 = (short*)input_items[1];
            for (int i = 0; i < noutput_items; i += d_chunk_size) {
                copy_plane_to_surface(12, d_chunk_size / 2, src_pixels_1);
                noutput_items_produced +=
                    copy_plane_to_surface(0, d_chunk_size, src_pixels_0);
                src_pixels_0 += d_chunk_size;
                src_pixels_1 += d_chunk_size;
            }
        } else {
            // first channel=Y, second channel is alternating lines U and V
            src_pixels_0 = (short*)input_items[0];
            src_pixels_1 = (short*)input_items[1];
            for (int i = 0; i < noutput_items; i += d_chunk_size) {
                copy_plane_to_surface(1222, d_chunk_size / 2, src_pixels_1);
                noutput_items_produced +=
                    copy_plane_to_surface(0, d_chunk_size, src_pixels_0);
                src_pixels_0 += d_chunk_size;
                src_pixels_1 += d_chunk_size;
            }
        }
        break;
    case 1: // grey (Y) input
        /* Y component */
        plane = 0;
        src_pixels_0 = (short*)input_items[plane];
        for (int i = 0; i < noutput_items; i += d_chunk_size) {
            noutput_items_produced +=
                copy_plane_to_surface(plane, d_chunk_size, src_pixels_0);
            src_pixels_0 += d_chunk_size;
        }
        break;
    default: // 0 or more then 3 channels
        std::cerr << "video_sdl::sink_s: Wrong number of channels: ";
        std::cerr
            << "1, 2 or 3 channels are supported.\n  Requested number of channels is "
            << input_items.size() << "\n";
        throw std::runtime_error("video_sdl::sink_s");
    }

    SDL_UnlockYUVOverlay(d_image);
    return noutput_items_produced;
}

} /* namespace video_sdl */
} /* namespace gr */
```

then add another block
```
gr_modtool add sink_uc
```
you should see something like this
```
C:\Users\Mitja\Documents\Visual Studio 2017\Projects\SDR\GNURadio blocks\new oot
 module\gr-video_sdl>gr_modtool add sink_uc
GNU Radio module name identified: video_sdl
Block/code identifier: sink_uc
('sink', 'source', 'sync', 'decimator', 'interpolator', 'general', 'tagged_strea
m', 'hier', 'noblock')
Enter block type: sink
Language (python/cpp): cpp
Language: C++
Please specify the copyright holder: GNURadio
Enter valid argument list, including default arguments: double framerate, int width, int height, unsigned int format, int dst_width, int dst_height
Add Python QA code? [Y/n] n
Add C++ QA code? [Y/n] n
Adding file 'lib\sink_uc_impl.h'...
Adding file 'lib\sink_uc_impl.cc'...
Adding file 'include\video_sdl\sink_uc.h'...
Editing swig\video_sdl_swig.i...
Adding file 'grc\video_sdl_sink_uc.xml'...
Editing grc/CMakeLists.txt...
```

then goto ``gr-video_sdl\lib\sink_uc_impl.h`` and add
```cpp
#include <SDL.h>

namespace gr {
namespace video_sdl {

/*  fourcc (four character code) */
#define vid_fourcc(a, b, c, d)                                             \
    (((unsigned)(a) << 0) | ((unsigned)(b) << 8) | ((unsigned)(c) << 16) | \
     ((unsigned)(d) << 24))
#define IMGFMT_YV12 vid_fourcc('Y', 'V', '1', '2') /* 12  YVU 4:2:0 */

class sink_uc_impl : public sink_uc
{
private:
    int d_chunk_size;

protected:
    void copy_line_pixel_interleaved(unsigned char* dst_pixels_u,
                                     unsigned char* dst_pixels_v,
                                     const unsigned char* src_pixels,
                                     int src_width);
    void copy_line_line_interleaved(unsigned char* dst_pixels_u,
                                    unsigned char* dst_pixels_v,
                                    const unsigned char* src_pixels,
                                    int src_width);
    void copy_line_single_plane(unsigned char* dst_pixels,
                                const unsigned char* src_pixels,
                                int src_width);
    void copy_line_single_plane_dec2(unsigned char* dst_pixels,
                                     const unsigned char* src_pixels,
                                     int src_width);
    int
    copy_plane_to_surface(int plane, int noutput_items, const unsigned char* src_pixels);

    float d_framerate;
    int d_wanted_frametime_ms;
    int d_width;
    int d_height;
    int d_dst_width;
    int d_dst_height;
    int d_format;
    int d_current_line;
    SDL_Surface* d_screen;
    SDL_Overlay* d_image;
    SDL_Rect d_dst_rect;
    float d_avg_delay;
    unsigned int d_wanted_ticks;

public:
    sink_uc_impl(double framerate,
                 int width,
                 int height,
                 unsigned int format,
                 int dst_width,
                 int dst_height);
    ~sink_uc_impl();

    int work(int noutput_items,
             gr_vector_const_void_star& input_items,
             gr_vector_void_star& output_items);
};

} /* namespace video_sdl */
} /* namespace gr */

#endif /* INCLUDED_VIDEO_SDL_SINK_UC_IMPL_H */
```

also goto ``gr-video_sdl\lib\sink_uc_impl.cc`` and replace everything with this
```cpp
/* -*- c++ -*- */
/*
 * Copyright 2006,2010,2012 Free Software Foundation, Inc.
 *
 * This file is part of GNU Radio
 *
 * GNU Radio is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 *
 * GNU Radio is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with GNU Radio; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street,
 * Boston, MA 02110-1301, USA.
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "sink_uc_impl.h"
#include <gnuradio/io_signature.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <iostream>
#include <stdexcept>


namespace gr {
namespace video_sdl {

sink_uc::sptr sink_uc::make(double framerate,
                            int width,
                            int height,
                            unsigned int format,
                            int dst_width,
                            int dst_height)
{
    return gnuradio::get_initial_sptr(
        new sink_uc_impl(framerate, width, height, format, dst_width, dst_height));
}

sink_uc_impl::sink_uc_impl(double framerate,
                           int width,
                           int height,
                           unsigned int format,
                           int dst_width,
                           int dst_height)
    : sync_block("video_sdl_sink_uc",
                 io_signature::make(1, 3, sizeof(unsigned char)),
                 io_signature::make(0, 0, 0)),
      d_chunk_size(width * height),
      d_framerate(framerate),
      d_wanted_frametime_ms(0),
      d_width(width),
      d_height(height),
      d_dst_width(dst_width),
      d_dst_height(dst_height),
      d_format(format),
      d_current_line(0),
      d_screen(NULL),
      d_image(NULL),
      d_avg_delay(0.0),
      d_wanted_ticks(0)
{
    if (framerate <= 0.0)
        d_wanted_frametime_ms = 0; // Go as fast as possible
    else
        d_wanted_frametime_ms = (int)(1000.0 / framerate);

    if (dst_width < 0)
        d_dst_width = d_width;

    if (dst_height < 0)
        d_dst_height = d_height;

    if (0 == format)
        d_format = IMGFMT_YV12;

    atexit(SDL_Quit); // check if this is the way to do this
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::cerr << "video_sdl::sink_uc: Couldn't initialize SDL:" << SDL_GetError()
                  << " \n SDL_Init(SDL_INIT_VIDEO) failed\n";
        throw std::runtime_error("video_sdl::sink_uc");
    }

    /* accept any depth */
    d_screen = SDL_SetVideoMode(
        dst_width,
        dst_height,
        0,
        SDL_SWSURFACE | SDL_RESIZABLE |
            SDL_ANYFORMAT); // SDL_DOUBLEBUF |SDL_SWSURFACE| SDL_HWSURFACE||SDL_FULLSCREEN

    if (d_screen == NULL) {
        std::cerr << "Unable to set SDL video mode: " << SDL_GetError()
                  << "\n SDL_SetVideoMode() Failed \n";
        exit(1);
    }

    if (d_image) {
        SDL_FreeYUVOverlay(d_image);
    }

    /* Initialize and create the YUV Overlay used for video out */
    if (!(d_image =
              SDL_CreateYUVOverlay(d_width, d_height, SDL_YV12_OVERLAY, d_screen))) {
        std::cerr << "SDL: Couldn't create a YUV overlay: \n" << SDL_GetError() << "\n";
        throw std::runtime_error("video_sdl::sink_uc");
    }

    printf("SDL screen_mode %d bits-per-pixel\n", d_screen->format->BitsPerPixel);
    printf("SDL overlay_mode %i \n", d_image->format);

    d_chunk_size = (std::min)(1, 16384 / width); // width*16;
    d_chunk_size = d_chunk_size * width;
    // d_chunk_size = (int)(width);
    set_output_multiple(d_chunk_size);

    /* Set the default playback area */
    d_dst_rect.x = 0;
    d_dst_rect.y = 0;
    d_dst_rect.w = d_dst_width;
    d_dst_rect.h = d_dst_height;
    // clear the surface to grey

    if (SDL_LockYUVOverlay(d_image)) {
        std::cerr << "SDL: Couldn't lock YUV overlay: \n" << SDL_GetError() << "\n";
        throw std::runtime_error("video_sdl::sink_uc");
    }

    memset(d_image->pixels[0], 128, d_image->pitches[0] * d_height);
    memset(d_image->pixels[1], 128, d_image->pitches[1] * d_height / 2);
    memset(d_image->pixels[2], 128, d_image->pitches[2] * d_height / 2);
    SDL_UnlockYUVOverlay(d_image);
}

sink_uc_impl::~sink_uc_impl() { SDL_Quit(); }

void sink_uc_impl::copy_line_pixel_interleaved(unsigned char* dst_pixels_u,
                                               unsigned char* dst_pixels_v,
                                               const unsigned char* src_pixels,
                                               int src_width)
{
    for (int i = 0; i < src_width; i++) {
        dst_pixels_u[i] = src_pixels[i * 2];
        dst_pixels_v[i] = src_pixels[i * 2 + 1];
    }
}

void sink_uc_impl::copy_line_line_interleaved(unsigned char* dst_pixels_u,
                                              unsigned char* dst_pixels_v,
                                              const unsigned char* src_pixels,
                                              int src_width)
{
    memcpy(dst_pixels_u, src_pixels, src_width);
    memcpy(dst_pixels_v, src_pixels + src_width, src_width);
}

void sink_uc_impl::copy_line_single_plane(unsigned char* dst_pixels,
                                          const unsigned char* src_pixels,
                                          int src_width)
{
    memcpy(dst_pixels, src_pixels, src_width);
}

void sink_uc_impl::copy_line_single_plane_dec2(unsigned char* dst_pixels,
                                               const unsigned char* src_pixels,
                                               int src_width)
{
    for (int i = 0, j = 0; i < src_width; i += 2, j++) {
        dst_pixels[j] = (unsigned char)src_pixels[i];
    }
}

int sink_uc_impl::copy_plane_to_surface(int plane,
                                        int noutput_items,
                                        const unsigned char* src_pixels)
{
    const int first_dst_plane = (12 == plane || 1122 == plane) ? 1 : plane;
    const int second_dst_plane = (12 == plane || 1122 == plane) ? 2 : plane;
    int current_line = (0 == plane) ? d_current_line : d_current_line / 2;

    unsigned char* dst_pixels = (unsigned char*)d_image->pixels[first_dst_plane];
    dst_pixels = &dst_pixels[current_line * d_image->pitches[first_dst_plane]];

    unsigned char* dst_pixels_2 = (unsigned char*)d_image->pixels[second_dst_plane];
    dst_pixels_2 = &dst_pixels_2[current_line * d_image->pitches[second_dst_plane]];

    int src_width = (0 == plane || 12 == plane || 1122 == plane) ? d_width : d_width / 2;
    int noutput_items_produced = 0;
    int max_height = (0 == plane) ? d_height - 1 : d_height / 2 - 1;

    for (int i = 0; i < noutput_items; i += src_width) {
        // output one line at a time
        if (12 == plane) {
            copy_line_pixel_interleaved(dst_pixels, dst_pixels_2, src_pixels, src_width);
            dst_pixels_2 += d_image->pitches[second_dst_plane];
        } else if (1122 == plane) {
            copy_line_line_interleaved(dst_pixels, dst_pixels_2, src_pixels, src_width);
            dst_pixels_2 += d_image->pitches[second_dst_plane];
            src_pixels += src_width;
        } else if (0 == plane)
            copy_line_single_plane(dst_pixels, src_pixels, src_width);
        else /* 1==plane || 2==plane*/
            copy_line_single_plane_dec2(
                dst_pixels, src_pixels, src_width); // decimate by two horizontally

        src_pixels += src_width;
        dst_pixels += d_image->pitches[first_dst_plane];
        noutput_items_produced += src_width;
        current_line++;

        if (current_line > max_height) {
            // Start new frame
            // TODO, do this all in a separate thread
            current_line = 0;
            dst_pixels = d_image->pixels[first_dst_plane];
            dst_pixels_2 = d_image->pixels[second_dst_plane];
            if (0 == plane) {
                SDL_DisplayYUVOverlay(d_image, &d_dst_rect);
                // SDL_Flip(d_screen);
                unsigned int ticks = SDL_GetTicks(); // milliseconds
                d_wanted_ticks += d_wanted_frametime_ms;
                float avg_alpha = 0.1;
                int time_diff = d_wanted_ticks - ticks;
                d_avg_delay = time_diff * avg_alpha + d_avg_delay * (1.0 - avg_alpha);
            }
        }
    }

    if (0 == plane)
        d_current_line = current_line;

    return noutput_items_produced;
}

int sink_uc_impl::work(int noutput_items,
                       gr_vector_const_void_star& input_items,
                       gr_vector_void_star& output_items)
{
    unsigned char *src_pixels_0, *src_pixels_1, *src_pixels_2;
    int noutput_items_produced = 0;
    int plane;
    int delay = (int)d_avg_delay;

    if (0 == d_wanted_ticks)
        d_wanted_ticks = SDL_GetTicks();

    if (delay > 0)
        SDL_Delay((unsigned int)delay); // compensate if running too fast

    if (SDL_LockYUVOverlay(d_image)) {
        return 0;
    }

    switch (input_items.size()) {
    case 3: // first channel=Y, second channel is  U , third channel is V
        src_pixels_0 = (unsigned char*)input_items[0];
        src_pixels_1 = (unsigned char*)input_items[1];
        src_pixels_2 = (unsigned char*)input_items[2];
        for (int i = 0; i < noutput_items; i += d_chunk_size) {
            copy_plane_to_surface(1, d_chunk_size, src_pixels_1);
            copy_plane_to_surface(2, d_chunk_size, src_pixels_2);
            noutput_items_produced +=
                copy_plane_to_surface(0, d_chunk_size, src_pixels_0);
            src_pixels_0 += d_chunk_size;
            src_pixels_1 += d_chunk_size;
            src_pixels_2 += d_chunk_size;
        }
        break;
    case 2:
        if (1) { // if(pixel_interleaved_uv)
            // first channel=Y, second channel is alternating pixels U and V
            src_pixels_0 = (unsigned char*)input_items[0];
            src_pixels_1 = (unsigned char*)input_items[1];
            for (int i = 0; i < noutput_items; i += d_chunk_size) {
                copy_plane_to_surface(12, d_chunk_size / 2, src_pixels_1);
                noutput_items_produced +=
                    copy_plane_to_surface(0, d_chunk_size, src_pixels_0);
                src_pixels_0 += d_chunk_size;
                src_pixels_1 += d_chunk_size;
            }
        } else {
            // first channel=Y, second channel is alternating lines U and V
            src_pixels_0 = (unsigned char*)input_items[0];
            src_pixels_1 = (unsigned char*)input_items[1];
            for (int i = 0; i < noutput_items; i += d_chunk_size) {
                copy_plane_to_surface(1222, d_chunk_size / 2, src_pixels_1);
                noutput_items_produced +=
                    copy_plane_to_surface(0, d_chunk_size, src_pixels_0);
                src_pixels_0 += d_chunk_size;
                src_pixels_1 += d_chunk_size;
            }
        }
        break;
    case 1: // grey (Y) input
        /* Y component */
        plane = 0;
        src_pixels_0 = (unsigned char*)input_items[plane];
        for (int i = 0; i < noutput_items; i += d_chunk_size) {
            noutput_items_produced +=
                copy_plane_to_surface(plane, d_chunk_size, src_pixels_0);
            src_pixels_0 += d_chunk_size;
        }
        break;
    default: // 0 or more then 3 channels
        std::cerr << "video_sdl::sink_uc: Wrong number of channels: ";
        std::cerr
            << "1, 2 or 3 channels are supported.\n  Requested number of channels is "
            << input_items.size() << "\n";
        throw std::runtime_error("video_sdl::sink_uc");
    }

    SDL_UnlockYUVOverlay(d_image);
    return noutput_items_produced;
}

} /* namespace video_sdl */
} /* namespace gr */
```

then edit ``gr-video_sdl\lib\CMakeLists.txt`` and replace with
```cmake
# Copyright 2011,2012,2016 Free Software Foundation, Inc.
#
# This file was generated by gr_modtool, a tool from the GNU Radio framework
# This file is a part of gr-video_sdl
#
# GNU Radio is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# GNU Radio is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GNU Radio; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street,
# Boston, MA 02110-1301, USA.

########################################################################
# Setup library
########################################################################
include(GrPlatform) #define LIB_SUFFIX

include_directories(${Boost_INCLUDE_DIR} ${SDL_INCLUDE_DIR})
link_directories(${Boost_LIBRARY_DIRS} ${SDL_LIBRARY})

list(APPEND video_sdl_sources
    sink_s_impl.cc
    sink_uc_impl.cc
)

set(video_sdl_sources "${video_sdl_sources}" PARENT_SCOPE)
if(NOT video_sdl_sources)
	MESSAGE(STATUS "No C++ sources... skipping lib/")
	return()
endif(NOT video_sdl_sources)

add_library(gnuradio-video_sdl SHARED ${video_sdl_sources})
target_link_libraries(gnuradio-video_sdl ${Boost_LIBRARIES} ${GNURADIO_ALL_LIBRARIES})
set_target_properties(gnuradio-video_sdl PROPERTIES DEFINE_SYMBOL "gnuradio_video_sdl_EXPORTS")

if(APPLE)
    set_target_properties(gnuradio-video_sdl PROPERTIES
        INSTALL_NAME_DIR "${CMAKE_INSTALL_PREFIX}/lib"
    )
endif(APPLE)

########################################################################
# Install built library files
########################################################################
include(GrMiscUtils)
GR_LIBRARY_FOO(gnuradio-video_sdl RUNTIME_COMPONENT "video_sdl_runtime" DEVEL_COMPONENT "video_sdl_devel")

########################################################################
# Build and register unit test
########################################################################
include(GrTest)

include_directories(${CPPUNIT_INCLUDE_DIRS})

list(APPEND test_video_sdl_sources
    ${CMAKE_CURRENT_SOURCE_DIR}/test_video_sdl.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/qa_video_sdl.cc
)

add_executable(test-video_sdl ${test_video_sdl_sources})

target_link_libraries(
  test-video_sdl
  ${GNURADIO_RUNTIME_LIBRARIES}
  ${Boost_LIBRARIES}
  ${CPPUNIT_LIBRARIES}
  gnuradio-video_sdl
)

GR_ADD_TEST(test_video_sdl test-video_sdl)

########################################################################
# Print summary
########################################################################
message(STATUS "Using install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "Building for version: ${VERSION} / ${LIBVER}")
```

Then we need to add the UI to our block so 

go to ``gr-video_sdl\grc\video_sdl_sink_s.xml`` and replace with
```xml
<?xml version='1.0'?>
<block>
    <name>Video SDL Sink</name>
    <key>video_sdl_sink_s</key>
	<category>[Video]</category>
    <import>from gnuradio import video_sdl</import>
    <make>video_sdl.sink_$(type.fcn)($fps, $width, $height, 0, $display_width, $display_height)</make>
    <param>
        <name>Input Type</name>
        <key>type</key>
        <type>enum</type>
        <option>
            <name>Byte</name>
            <key>byte</key>
            <opt>fcn:uc</opt>
        </option>
        <option>
            <name>Short</name>
            <key>short</key>
            <opt>fcn:s</opt>
        </option>
    </param>
    <param>
        <name>Input Width</name>
        <key>width</key>
        <value>640</value>
        <type>int</type>
    </param>
    <param>
        <name>Input Height</name>
        <key>height</key>
        <value>480</value>
        <type>int</type>
    </param>
    <param>
        <name>Display Width</name>
        <key>display_width</key>
        <value>640</value>
        <type>int</type>
    </param>
    <param>
        <name>Display Height</name>
        <key>display_height</key>
        <value>480</value>
        <type>int</type>
    </param>
    <param>
        <name>Framerate</name>
        <key>fps</key>
        <value>0</value>
        <type>float</type>
    </param>
    <param>
        <name>Channels</name>
        <key>num_channels</key>
        <type>enum</type>
        <option>
            <name>1 (Grayscale)</name>
            <key>1</key>
        </option>
        <option>
            <name>2 (Y, alternating pixels U and V)</name>
            <key>2</key>
        </option>
        <option>
            <name>3 (YUV)</name>
            <key>3</key>
        </option>
    </param>
    <sink>
        <name>in</name>
        <type>$type</type>
        <vlen>1</vlen>
        <nports>$num_channels</nports>
    </sink>
    <doc>
Provides a rudimentary on-screen video display using libsdl.

A framerate of zero means video will be displayed as quickly as possible.

In 1-channel mode, input data is assumed to be grayscale, with each input item mapping to a single pixel.

In 2-channel mode, the first channel is Y for every pixel while the second channel alternates between pixels values for U and V.

In 3-channel mode, input channels are assumed to be matching triples of YUV values, one byte per pixel, per channel.
    </doc>
</block>
```

the last steps
```
cd gr-video_sdl
mkdir windows
git clone https://github.com/robinrowe/libunistd.git
```

edit your main CMakeLists.txt and add under include this
```
${CMAKE_SOURCE_DIR}/windows/libunistd/unistd
```
so your include looks something like this
```
########################################################################
# Setup the include and linker paths
########################################################################
include_directories(
    ${CMAKE_SOURCE_DIR}/lib
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_BINARY_DIR}/lib
    ${CMAKE_BINARY_DIR}/include
    ${Boost_INCLUDE_DIRS}
    ${CPPUNIT_INCLUDE_DIRS}
    ${GNURADIO_ALL_INCLUDE_DIRS}
	${CMAKE_SOURCE_DIR}/windows/libunistd/unistd
)
```

then we build our block like this
```
cd gr-video_sdl
mkdir build
cd build
cmake ../ -G "Visual Studio 16 2019" -DSDL_LIBRARY="C:\Program Files\PothosSDR\libsdl\lib\x64" -DSDL_INCLUDE_DIR="C:\Program Files\PothosSDR\libsdl\include" -DBOOST_ROOT=${BOOST_ROOT} -DBOOST_LIBRARYDIR=${BOOST_LIBRARYDIR} -DCPPUNIT_INCLUDE_DIRS=${CPPUNIT_INCLUDE_DIRS} -DCPPUNIT_LIBRARIES=${CPPUNIT_LIBRARIES}
msbuild gr-video_sdl.sln 
Pray it will work.....

```

and Hopefully you can enjoy using your new block now
