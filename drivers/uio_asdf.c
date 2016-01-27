#include <linux/platform_device.h>
#include <linux/uio_driver.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/printk.h>
#include <linux/irqdomain.h>
typedef struct uio_info uio_info;

static const int FPGA_INTERRUPT_BASE=72;
#define MAXIRQS ((int)64)

static int irqs[MAXIRQS];
static int irqCount=0;
static uio_info* arr=NULL;

static struct uio_info myfpga_uio_info = {
   .name = "uio_myfpga",
   .version = "0.1",
   .irq=72,
   .irq_flags=IRQF_TRIGGER_RISING,
};

static struct platform_device *myfpga_uio_pdev[MAXIRQS];

static int __init myfpga_init(void)
{
	int maxStrLen=32;
	int succeedCount=0;
	int sizeTotal,i;
	
	char* strs;
	
	if(irqCount<=0) {
		printk(KERN_ERR "uio_asdf: you must specify at least one irq to listen on\n");
		return -EINVAL;
	}
	
	//allocate a chunk of memory for the uio_info structs and some strings
	sizeTotal=sizeof(uio_info)*irqCount+maxStrLen*irqCount;
	arr=kzalloc(sizeTotal,GFP_USER);	//allocate zero-filled chunk
	if(arr==NULL)
		return -ENOMEM;
	strs=(char*)(arr+irqCount);
	//fill in the structs
	for(i=0;i<irqCount;i++) {
		char* s=strs+i*maxStrLen;
		uio_info* inf=arr+i;
		snprintf(s,maxStrLen,"uio_asdf_irq_%d",irqs[i]);
		inf->name=s;
		inf->version="0.1";
		inf->irq=irq_find_mapping(NULL,(irq_hw_number_t)irqs[i]);
		inf->irq_flags=IRQF_TRIGGER_RISING;
		//rest of the fields are zero-filled
		
		if(inf->irq==0) {
			printk(KERN_WARNING "uio_asdf: can not find irq %d\n", irqs[i]);
			continue;
		}
		
		printk(KERN_INFO "uio_asdf: registering irq %d (logical irq %d)...\n",irqs[i],(int)inf->irq);
		myfpga_uio_pdev[i] = platform_device_register_resndata
			(NULL, "uio_pdrv_genirq",  -1, NULL, 0, inf,
				sizeof(struct uio_info));
		if (IS_ERR(myfpga_uio_pdev[i])) {
			printk(KERN_WARNING "uio_asdf: error registering irq %d: %d\n",
				irqs[i],(int)PTR_ERR(myfpga_uio_pdev));
			myfpga_uio_pdev[i]=NULL;
		} else succeedCount++;
	}
	if(succeedCount==0) {
		kfree(arr);
		return -ENXIO;
	}
    return 0;
}
static void __exit myfpga_exit(void)
{
	int i;
	for(i=0;i<irqCount;i++) {
		if(myfpga_uio_pdev[i]!=NULL)
			platform_device_unregister(myfpga_uio_pdev[i]);
	}
	kfree(arr);
	arr=NULL;
}
module_init(myfpga_init);
module_exit(myfpga_exit);
module_param_array(irqs,int,&irqCount,S_IRUGO);
MODULE_PARM_DESC(irqs,"the list of irq numbers to listen on.");

MODULE_LICENSE("GPL");
MODULE_AUTHOR("xaxaxa");
MODULE_DESCRIPTION("generic irq bridge for cyclone V SoC");

