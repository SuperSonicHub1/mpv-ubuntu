# A way to build mpv for Ubuntu in a container
# since my repo managers nor mpv can be bothered.
# Heavy inspiration from https://github.com/jessfraz/dockerfiles/blob/master/atom/Dockerfile

FROM ubuntu:20.04

LABEL maintainer "Kyle Williams <kyle.anthony.williams2@gmail.com>"

# Can be a tag/branch/commit
# Use ./build.bash "v0.34.0"
ARG VERSION="v0.34.0"

### STARTUP ###

# No Debian, I don't want to configure my timezone.
ARG DEBIAN_FRONTEND=noninteractive

# Standard update and upgrade
RUN apt-get update -y && apt-get upgrade -y

# Need Git to download all this junk
RUN apt-get install -y git

### MPV-BUILD DEPENDENCIES ###

# Basic packaging tools
RUN apt-get install -y devscripts equivs

# gcc or clang, yasm
RUN apt-get install -y build-essential yasm

# autoconf/autotools (for libass)
RUN apt-get install -y autoconf autotools-dev

# X development headers

## https://github.com/mpv-player/mpv#compilation
RUN apt-get install -y \
	libx11-dev \
	libxrandr-dev \
	libxext-dev \
	libxss-dev \
	libxinerama-dev \
	libvdpau-dev \
	libgl-dev \
	libglx-dev \
	libegl-dev \
	libxv-dev

## https://www.x.org/wiki/guide/extensions/
RUN apt-get install -y libxcb-xkb-dev libxcb-xinput-dev

# Audio output development headers
RUN apt-get install -y libasound2-dev libpulse-dev

# fribidi, freetype, fontconfig development headers (for libass)
RUN apt-get install -y \
	libfribidi-dev \
	libfreetype-dev \
	libfontconfig-dev

# harfbuzz is also required for libass
RUN apt-get install -y libharfbuzz-dev

# libjpeg (optional (for *normal* MPV compilation), used
# for screenshots only)
RUN apt-get install -y libjpeg-dev

# OpenSSL or GnuTLS development headers if you want to
# open https links (this is also needed to make youtube-dl
# interaction work)
RUN apt-get -y install libssl-dev

# libx264/libmp3lame/libfdk-aac if you want to use encoding
RUN apt-get install -y libx264-dev libmp3lame-dev libfdk-aac-dev

### MPV DEPENDENCIES ###
# zlib
RUN apt-get install -y zlib1g-dev

# Lua (optional, required for the OSC pseudo-GUI and youtube-dl integration) 
# 5.3 currently not supported, see https://github.com/mpv-player/mpv/issues/5205
RUN apt-get install -y liblua5.2-dev

# uchardet (optional, for subtitle charset detection)
RUN apt-get install -y libuchardet-dev

# ~~nvdec~~ and vaapi libraries for hardware decoding on Linux (optional) 
# Eventually follow this nonsensical tutorial for nvdec:
# https://github.com/omen23/ffmpeg-ffnvcodec-explanation
RUN apt-get install -y libva-dev

### MPV EXTRA DEPENDENCIES ###
# Found by analyzing wscript

# Checking for programs 'rst2html', 'rst2man'
# Checking for program 'rst2pdf'
RUN apt-get install -y python-docutils rst2pdf

# Checking for Javascript (MuJS backend) ('mujs >= 1.0.0') 
# Only on 20.10 and above
# libmujs-dev \

# Checking for Bluray support ('libbluray >= 0.3.0')
# Checking for dvdnav support ('dvdnav >= 4.2.0', 'dvdread >= 4.1.0')
# Checking for cdda support (libcdio)
RUN apt-get install -y \
	libbluray-dev \
	libdvdread-dev \
	libdvdnav-dev \
	libcdio-paranoia-dev

# Checking for librubberband support ('rubberband >= 1.8.0')
RUN apt-get install -y librubberband-dev

# Checking for libzimg support (high quality software scaler) ('zimg >= 2.9')
# Only on 21.10
# libzimg-dev \

# Checking for LCMS2 support ('lcms2 >= 2.6')
RUN apt-get install -y liblcms2-dev

# Checking for SDL2, SDL2 gamepad input
RUN apt-get install -y libsdl2-dev

# Checking for libarchive wrapper for reading zip files and more ('libarchive >= 3.4.0')
RUN apt-get install -y libarchive-dev

# Checking for JACK audio output
RUN apt-get install -y libjack-dev

# Checking for DRM ('libdrm >= 2.4.74')
RUN apt-get install -y libdrm-dev

# Checking for CACA ('caca >= 0.99.beta18')
RUN apt-get install -y libcaca-dev

# Checking for libplacebo support ('libplacebo >= 1.18.0')
# 20.10 or greater
# libplacebo-dev \

# Checking for Sixel ('libsixel >= 1.5')
# Requires a static build
RUN apt-get install -y libsixel-dev

### BUILDING ###

RUN git clone https://github.com/mpv-player/mpv-build.git
WORKDIR mpv-build/

# Cannot use dav1d, must use libaom instead
# Use --no-commit to avoid `git config` harrassment
# See https://github.com/mpv-player/mpv-build/issues/169#issuecomment-962475013
RUN git revert --no-commit 8709a84

# delete all local changes and checkout
# the desired version of mpv
RUN ./use-mpv-custom "$VERSION"
RUN ./update

# Enabling optional FFmpeg dependencies for encoding
RUN echo --enable-libx264 >> ffmpeg_options
RUN echo --enable-libmp3lame >> ffmpeg_options
RUN echo --enable-libfdk-aac >> ffmpeg_options
RUN echo --enable-nonfree >> ffmpeg_options

## Enabling optional MPV dependencies
RUN echo --enable-html-build >> mpv_options
RUN echo --enable-pdf-build >> mpv_options
RUN echo --enable-dvdnav >> mpv_options
RUN echo --enable-cdda >> mpv_options
RUN echo --enable-sdl2 >> mpv_options

# create and install a dummy build dependency package
# use --tool to avoid APT auto-aborting due to DEBAIN_FRONTEND
RUN mk-build-deps --install --tool "apt-get --no-install-recommends -y"

# build the mpv Debian package
RUN dpkg-buildpackage -uc -us -b -j4
