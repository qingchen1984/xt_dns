#
#	xt_dns Makefile
#       Copyright (c) Ondrej Caletka, 2017
#	based on xt_dns Makefile (c) Bartlomiej Korupczynski, 2011
#
#	This file is distributed under the terms of the GNU General Public
#	License (GPL). Copies of the GPL can be obtained from gnu.org/gpl.
#

NAME = xt_dns
VERSION = 1.5
DISTFILES = *.[ch] Makefile ChangeLog

KVERSION = $(shell uname -r)
KDIR = /lib/modules/$(KVERSION)/build
MDIR = /lib/modules/$(KVERSION)/local/
XDIR = `pkg-config xtables --variable xtlibdir`
IPTABLES = iptables
IP6TABLES = ip6tables

obj-m = $(NAME).o

build: config.h module userspace
install: module-install userspace-install
module: $(NAME).ko
userspace: lib$(NAME).so


config.h: Makefile
	@echo "making config.h"
	@echo "/* generated by Makefile */" >config.h
	@echo "#define VERSION \"$(VERSION)\"" >>config.h
	@if grep -q 'xt_match_param' $(KDIR)/include/linux/netfilter/x_tables.h; then \
		echo "#define HAVE_XT_MATCH_PARAM" >>config.h ;\
	fi

xt_dns.ko: xt_dns.c xt_dns.h config.h
	$(MAKE) -C $(KDIR) M=$(PWD) modules

# in case of problems add path to iptables sources like:
# -I/usr/src/sources/iptables-1.4.2/include/
libxt_dns.so: libxt_dns.c xt_dns.h config.h
	$(CC) -fPIC -Wall -shared -o libxt_dns.so libxt_dns.c

module-install: xt_dns.ko
	sync
	mkdir -p $(MDIR) || :
	install *.ko $(MDIR)
	depmod -a
	sync

userspace-install: libxt_dns.so
	install libxt_dns.so $(XDIR)

clean:
	rm -f libxt_dns.so config.h
	$(MAKE) -C $(KDIR) M=$(PWD) clean

dist:
	rm -f $(NAME)-$(VERSION).tar.gz
	mkdir -p tmp/$(NAME)-$(VERSION)
	cp -a $(DISTFILES) tmp/$(NAME)-$(VERSION)
	cd tmp && tar zcf ../$(NAME)-$(VERSION).tar.gz $(NAME)-$(VERSION)/
	rm -rf tmp/$(NAME)-$(VERSION)
	rmdir --ignore-fail-on-non-empty tmp
	@echo OK: dist

distcheck: dist
	mkdir -p tmp
	rm -rf tmp/$(NAME)-$(VERSION)
	cd tmp && tar zxf ../$(NAME)-$(VERSION).tar.gz
	cd tmp/$(NAME)-$(VERSION) && $(MAKE) build
	rm -rf tmp/$(NAME)-$(VERSION)
	rmdir --ignore-fail-on-non-empty tmp
	@echo OK: distcheck
