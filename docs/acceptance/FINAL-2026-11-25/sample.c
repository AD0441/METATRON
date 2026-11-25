#include <libproc.h>
#include <sys/resource.h>
#include <stdio.h>
#include <stdlib.h>
#include <mach/mach_time.h>
int main(int argc,char **argv){struct rusage_info_v4 r; if(argc!=2||proc_pid_rusage(atoi(argv[1]),RUSAGE_INFO_V4,(rusage_info_t*)&r))return 2;mach_timebase_info_data_t tb;mach_timebase_info(&tb);uint64_t cpu=(uint64_t)(((__uint128_t)r.ri_user_time+r.ri_system_time)*tb.numer/tb.denom);printf("{\"rss_bytes\":%llu,\"footprint_bytes\":%llu,\"cpu_ns\":%llu,\"max_footprint_bytes\":%llu}\n",(unsigned long long)r.ri_resident_size,(unsigned long long)r.ri_phys_footprint,(unsigned long long)cpu,(unsigned long long)r.ri_lifetime_max_phys_footprint);return 0;}
