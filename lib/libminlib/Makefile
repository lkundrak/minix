.include <bsd.own.mk>
.PATH: 	${.CURDIR} ${.CURDIR}/${MACHINE}
INCSDIR= /usr/include
LIB=	minlib

USE_SHLIBDIR= yes

CPPFLAGS.fslib.c+= -I${MINIXSRCDIR}/servers
CPPFLAGS.fsversion.c+= -I${MINIXSRCDIR}/servers
SRCS+= 	fslib.c fsversion.c

# DHCP get/set tags.
SRCS+= dhcp_gettag.c dhcp_settag.c

# Gcov support.
SRCS+= gcov.c gcov_flush.c

# Various utils
SRCS+= itoa.c u64util.c

# svrctl
SRCS+= svrctl.c

# servxcheck
SRCS+= servxcheck.c

# queryparam
SRCS+= paramvalue.c

# Minix servers/drivers syscall.
SRCS+= 	getngid.c getnpid.c getnprocnr.c getnucred.c getnuid.c getprocnr.c \
	mapdriver.c vm_memctl.c vm_set_priv.c vm_query_exit.c vm_update.c

INCS+= tools.h

.include "${MACHINE}/Makefile.inc"

.include <bsd.own.mk>
SUBDIR+= pkgconfig
.include <bsd.subdir.mk>

.include <bsd.lib.mk>
