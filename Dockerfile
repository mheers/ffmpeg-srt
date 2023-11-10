ARG base="alpine:3.18.4"

FROM --platform=$BUILDPLATFORM ${base} as builder

RUN apk add wget git tcl cmake make g++ libressl-dev linux-headers

WORKDIR /src

# install libsrt
ENV srtVersion="1.5.3"
RUN cd /src && git clone --branch v${srtVersion} https://github.com/Haivision/srt.git libsrt && \
    cd libsrt/ && \
    # ./configure && \
    cmake ./ -DENABLE_SHARED=OFF -DENABLE_STATIC=ON && \
    make && \
    make install

# install ffmpeg
ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN apk add tar xz
RUN wget -q https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-$(echo $TARGETPLATFORM  | cut -d/ -f2)-static.tar.xz
RUN tar -xJf ffmpeg-release-$(echo $TARGETPLATFORM  | cut -d/ -f2)-static.tar.xz && cd ffmpeg-6.*-static && mv ffmpeg ffprobe /usr/local/bin/

FROM ${base}

COPY --from=builder /usr/local/lib/libsrt.a /usr/local/lib/
COPY --from=builder /usr/local/include/srt/version.h /usr/local/include/srt/
COPY --from=builder /usr/local/include/srt/srt.h /usr/local/include/srt/
COPY --from=builder /usr/local/include/srt/logging_api.h /usr/local/include/srt/
COPY --from=builder /usr/local/include/srt/access_control.h /usr/local/include/srt/
COPY --from=builder /usr/local/include/srt/platform_sys.h /usr/local/include/srt/
COPY --from=builder /usr/local/include/srt/udt.h /usr/local/include/srt/
COPY --from=builder /usr/local/lib/pkgconfig/haisrt.pc /usr/local/lib/pkgconfig/
COPY --from=builder /usr/local/lib/pkgconfig/srt.pc /usr/local/lib/pkgconfig/
COPY --from=builder /usr/local/bin/srt-live-transmit /usr/local/bin/
COPY --from=builder /usr/local/bin/srt-file-transmit /usr/local/bin/
COPY --from=builder /usr/local/bin/srt-tunnel /usr/local/bin/
COPY --from=builder /usr/local/bin/srt-ffplay /usr/local/bin/

COPY --from=builder /usr/local/bin/ffmpeg /usr/local/bin/
COPY --from=builder /usr/local/bin/ffprobe /usr/local/bin/


RUN apk add libstdc++ libressl3.7-libcrypto bash
