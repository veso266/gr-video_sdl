INCLUDE(FindPkgConfig)
PKG_CHECK_MODULES(PC_VIDEO_SDL video_sdl)

FIND_PATH(
    VIDEO_SDL_INCLUDE_DIRS
    NAMES video_sdl/api.h
    HINTS $ENV{VIDEO_SDL_DIR}/include
        ${PC_VIDEO_SDL_INCLUDEDIR}
    PATHS ${CMAKE_INSTALL_PREFIX}/include
          /usr/local/include
          /usr/include
)

FIND_LIBRARY(
    VIDEO_SDL_LIBRARIES
    NAMES gnuradio-video_sdl
    HINTS $ENV{VIDEO_SDL_DIR}/lib
        ${PC_VIDEO_SDL_LIBDIR}
    PATHS ${CMAKE_INSTALL_PREFIX}/lib
          ${CMAKE_INSTALL_PREFIX}/lib64
          /usr/local/lib
          /usr/local/lib64
          /usr/lib
          /usr/lib64
)

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(VIDEO_SDL DEFAULT_MSG VIDEO_SDL_LIBRARIES VIDEO_SDL_INCLUDE_DIRS)
MARK_AS_ADVANCED(VIDEO_SDL_LIBRARIES VIDEO_SDL_INCLUDE_DIRS)

