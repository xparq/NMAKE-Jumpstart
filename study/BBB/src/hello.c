#include <stdio.h>

const char* banner();
void func2();
void app_init();
const char* app_state();
void log_write(const char* msg);

void main()
{
	app_init();
	log_write(app_state());
	printf(banner());
	func2();
	log_write(app_state());
}
