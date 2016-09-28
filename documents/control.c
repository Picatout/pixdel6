//contrôle pixdel 6
//REF:http://stackoverflow.com/questions/6947413/how-to-open-read-and-write-from-serial-port-in-c

#include <errno.h>
#include <fcntl.h> 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>

int set_interface_attribs(int fd, int speed)
{
    struct termios tty;

    if (tcgetattr(fd, &tty) < 0) {
        printf("Error from tcgetattr: %s\n", strerror(errno));
        return -1;
    }

    cfsetospeed(&tty, (speed_t)speed);
    cfsetispeed(&tty, (speed_t)speed);

    tty.c_cflag |= (CLOCAL | CREAD);    /* ignore modem controls */
    tty.c_cflag &= ~CSIZE;
    tty.c_cflag |= CS8;         /* 8-bit characters */
    tty.c_cflag &= ~PARENB;     /* no parity bit */
    tty.c_cflag &= ~CSTOPB;     /* only need 1 stop bit */
    tty.c_cflag &= ~CRTSCTS;    /* no hardware flowcontrol */

    /* setup for non-canonical mode */
    tty.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
    tty.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
    tty.c_oflag &= ~OPOST;

    /* fetch bytes as they become available */
    tty.c_cc[VMIN] = 1;
    tty.c_cc[VTIME] = 1;

    if (tcsetattr(fd, TCSANOW, &tty) != 0) {
        printf("Error from tcsetattr: %s\n", strerror(errno));
        return -1;
    }
    return 0;
}

void set_mincount(int fd, int mcount)
{
    struct termios tty;

    if (tcgetattr(fd, &tty) < 0) {
        printf("Error tcgetattr: %s\n", strerror(errno));
        return;
    }

    tty.c_cc[VMIN] = mcount ? 1 : 0;
    tty.c_cc[VTIME] = 5;        /* half second timer */

    if (tcsetattr(fd, TCSANOW, &tty) < 0)
        printf("Error tcsetattr: %s\n", strerror(errno));
}


int main()
{
	char *portname = "/dev/ttyS0";
	int fd;
	int wlen;

	fd = open(portname, O_RDWR | O_NOCTTY | O_SYNC);
	if (fd < 0) {
		printf("Error opening %s: %s\n", portname, strerror(errno));
		return -1;
	}
	/*baudrate 115200, 8 bits, no parity, 1 stop bit */
	set_interface_attribs(fd, B115200);
	//set_mincount(fd, 0);                /* set to pure timed read */

	unsigned n;
	unsigned char cmd[]={0,0,255,0,255,0,255};
	while (1){
		printf("id? ");
		scanf("%3u",&n);
		cmd[0]=(unsigned char)(n&255);
		printf("rouge? ");
		scanf("%5u",&n);
		cmd[1]=(unsigned char)((n>>8)&255);
        cmd[2]=(unsigned char)(n&255);
        printf("vert?");
		scanf("%5u",&n);
		cmd[3]=(unsigned char)((n>>8)&255);
        cmd[4]=(unsigned char)(n&255);
		printf("bleu? ");
		scanf("%5u",&n);
		cmd[5]=(unsigned char)((n>>8)&255);
        cmd[6]=(unsigned char)(n&255);

		write(fd,cmd,7);
		tcdrain(fd);    /* delay for output */
        puts("command sent.\n");

		/* simple noncanonical input */
		unsigned char buf[7];
		int rdlen;
		if (cmd[0]>0){
			rdlen = read(fd, buf, sizeof(buf));
			if (rdlen > 0) {
				unsigned char   *p;
				for (p = buf; rdlen-- > 0; p++)
					printf(" 0x%x", *p);
				printf("\n");
			}
		}
	}//while(1)
}
