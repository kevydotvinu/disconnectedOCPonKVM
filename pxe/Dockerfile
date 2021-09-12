FROM alpine

MAINTAINER Vinu K <vinu@gnulinuxmate.com>

RUN apk add --update dnsmasq alpine-ipxe syslinux && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /var/lib/tftpboot && \
    mkdir -p /var/lib/tftpboot/pxelinux.cfg && \
    ln -sfv /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/ && \
    ln -sfv /usr/share/syslinux/menu.c32 /var/lib/tftpboot/ && \
    ln -sfv /usr/share/syslinux/ldlinux.c32 /var/lib/tftpboot/ && \
    ln -sfv /usr/share/syslinux/libutil.c32 /var/lib/tftpboot/ && \
    ln -sfv /usr/share/syslinux/libmenu.c32 /var/lib/tftpboot/ && \
    ln -sfv /usr/share/syslinux/memdisk /var/lib/tftpboot/ && \
    ln -sfv /usr/share/alpine-ipxe/ipxe.lkrn /var/lib/tftpboot/ && \
    ln -sfv /usr/share/alpine-ipxe/ipxe.efi /var/lib/tftpboot/

ENTRYPOINT ["/usr/sbin/dnsmasq", "--no-daemon"]
