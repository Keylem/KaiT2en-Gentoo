obj-m += t2bce_dma/
obj-m += t2bce_core/
obj-m += t2bce_vhci/
obj-m += t2bce_audio/
obj-m += t2bce_ave/

# Honour externally selected Gentoo kernel release and build tree.
KVERSION ?= $(if $(KERNELRELEASE),$(KERNELRELEASE),$(shell uname -r))
KDIR ?= /lib/modules/$(KVERSION)/build
PWD := $(shell pwd)

.PHONY: all clean

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
