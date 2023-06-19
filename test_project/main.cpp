#include "mbed.h"

#include "mbed_trace.h"
#define TRACE_GROUP  "main"

#include "PinNames.h"


DigitalOut led0(LED1);
InterruptIn btn0(BUTTON1);

Thread btn0_thread;

void btn0_thread_task() {
    while (1) {
        ThisThread::flags_wait_any(0x1);
        printf("Button 0 pressed !\n");
    }
}

void btn0_irq() {
    btn0_thread.flags_set(0x1);
}

int main(void) {
    mbed_trace_init();

    btn0.fall(btn0_irq);
    btn0_thread.start(btn0_thread_task);

    led0.write(0);

    char msg[50];

    printf("Bootstrap...\n");

    while (1) {
        led0 = !led0;

        tr_debug("this is debug msg");
        tr_err("this is error msg");
        tr_warn("this is warning msg");
        tr_info("this is info msg");

        printf("Please input some text (max. 50 char) :\n");
        int idx = scanf("%s", msg);
        printf("Your message was : %s\n", msg);

        ThisThread::sleep_for(2s);
    }
}