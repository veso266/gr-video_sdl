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


#ifndef INCLUDED_VIDEO_SDL_SINK_UC_H
#define INCLUDED_VIDEO_SDL_SINK_UC_H

#include <video_sdl/api.h>
#include <gnuradio/sync_block.h>

namespace gr {
  namespace video_sdl {

    /*!
     * \brief <+description of block+>
     * \ingroup video_sdl
     *
     */
    class VIDEO_SDL_API sink_uc : virtual public gr::sync_block
    {
     public:
      typedef boost::shared_ptr<sink_uc> sptr;

      /*!
       * \brief Return a shared_ptr to a new instance of video_sdl::sink_uc.
       *
       * To avoid accidental use of raw pointers, video_sdl::sink_uc's
       * constructor is in a private implementation
       * class. video_sdl::sink_uc::make is the public interface for
       * creating new instances.
       */
      static sptr make(double framerate, int width, int height, unsigned int format, int dst_width, int dst_height);
    };

  } // namespace video_sdl
} // namespace gr

#endif /* INCLUDED_VIDEO_SDL_SINK_UC_H */

