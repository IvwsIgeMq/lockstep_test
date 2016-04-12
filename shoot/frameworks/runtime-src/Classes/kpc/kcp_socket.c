//
//  kcp_socket.c
//  shoot
//
//  Created by 梁清风 on 16/4/8.
//
//

#include "kcp_socket.h"

#ifdef _WIN32

void work_thread_win(void *psock);

#pragma comment(lib,"ws2_32.lib")

#endif

/* get system time */
static inline void itimeofday(long *sec, long *usec)
{
#if defined(__unix)|| defined(__linux__) || defined(__ANDROID__) || defined(__APPLE__)
    struct timeval time;
    gettimeofday(&time, NULL);
    if (sec) *sec = time.tv_sec;
    if (usec) *usec = time.tv_usec;
#else
    static long mode = 0, addsec = 0;
    BOOL retval;
    static IINT64 freq = 1;
    IINT64 qpc;
    if (mode == 0) {
        retval = QueryPerformanceFrequency((LARGE_INTEGER*)&freq);
        freq = (freq == 0) ? 1 : freq;
        retval = QueryPerformanceCounter((LARGE_INTEGER*)&qpc);
        addsec = (long)time(NULL);
        addsec = addsec - (long)((qpc / freq) & 0x7fffffff);
        mode = 1;
    }
    retval = QueryPerformanceCounter((LARGE_INTEGER*)&qpc);
    retval = retval * 2;
    if (sec) *sec = (long)(qpc / freq) + addsec;
    if (usec) *usec = (long)((qpc % freq) * 1000000 / freq);
#endif
}

/* get clock in millisecond 64 */
static inline IINT64 iclock64(void)
{
    long s, u;
    IINT64 value;
    itimeofday(&s, &u);
    value = ((IINT64)s) * 1000 + (u / 1000);
    return value;
}

static inline IUINT32 iclock()
{
    return (IUINT32)(iclock64() & 0xfffffffful);
}

/* sleep in millisecond */
static inline void isleep(unsigned long millisecond)
{
#ifdef __unix 	/* usleep( time * 1000 ); */
    struct timespec ts;
    ts.tv_sec = (time_t)(millisecond / 1000);
    ts.tv_nsec = (long)((millisecond % 1000) * 1000000);
    /*nanosleep(&ts, NULL);*/
    usleep((millisecond << 10) - (millisecond << 4) - (millisecond << 3));
#elif defined(_WIN32)
    Sleep(millisecond);
#endif
}
void* work_thread(void * pkcp);
int udp_output(const char *buf, int len, ikcpcb *kcp, void *user);


#if defined(_WIN32)
void work_thread_win(void *psock) {
    work_thread(psock);
}
#endif

void* work_thread(void * p)
{
    
    KCP* pkcp = (KCP*)p;
    size_t buff_len = 1024;
    char* buff = (char*)malloc(buff_len);
    IUINT32 ts1 = iclock();
    socklen_t addr_len =sizeof(pkcp->addr);
    ssize_t recv_len =0 ;
    int hr = 0;
    while (1) {
        ikcp_update(pkcp->kcp, ts1);
        
        while (pkcp->send_link->node_count) {
            M_Node* node = link_pop(pkcp->send_link);
            if (!node) {
                ikcp_send(pkcp->kcp, node->data_buffer, node->data_buffer_use);
            }
            link_free_node(node);
        }
        recv_len= recvfrom(pkcp->fd, buff, buff_len, 0, (struct sockaddr*)&pkcp->addr, &addr_len);
        ikcp_input(pkcp->kcp, buff , recv_len);
        
        while (1) {
             hr  = ikcp_recv(pkcp->kcp, buff, buff_len);
            if(hr <0 )
                break;
            M_Node* recv_node = link_new_node(hr);
            link_append_to_node(recv_node, buff, hr);
        }
    }
 
}




int udp_output(const char *buf, int len, ikcpcb *kcp, void *user)
{
    KCP* pkcp = (KCP*)user;
    sendto(pkcp->fd,buf,len,0, (const struct sockaddr*)&pkcp->addr, sizeof(struct sockaddr));
    return 0;
}




void * create_kcp(){
    KCP* pkcp = (KCP*)malloc(sizeof(KCP));
    pkcp->kcp =  ikcp_create(1, pkcp);
    pkcp->kcp->output = udp_output;
    ikcp_wndsize(pkcp->kcp, 128, 128);
    ikcp_nodelay(pkcp->kcp, 1, 10, 2, 1);
    pkcp->addr.sin_family = AF_INET;
    //address.sin_addr.s_addr = inet_addr("42.62.64.244");
    pkcp->addr.sin_addr.s_addr = inet_addr("192.168.51.151");
    pkcp->addr.sin_port = htons(9003);
    memset((void*)pkcp->addr.sin_zero, 0, sizeof(pkcp->addr.sin_zero));
    return pkcp;
}

int kcp_connect(void * netObject,const char* ip, unsigned int port){
    
    KCP* pkcp = (KCP*)netObject;
#if defined(_WIN32)
        WSADATA wsa;
        // WinSock Startup
        if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) {
            return 0;
        }
#endif
    
        if (-1 == inet_addr(ip)) {
            struct hostent *hostinfo;
            if ((hostinfo = (struct hostent*)gethostbyname(ip)) == NULL) {
                return 0;
            }
            if (hostinfo->h_addrtype == AF_INET && hostinfo->h_addr_list != NULL) {
#if defined(_WIN32)
                char ipstr[16];
                char * ipbyte = *(hostinfo->h_addr_list);
                sprintf(ipstr, "%d.%d.%d.%d", *ipbyte, *(ipbyte++), *(ipbyte+2), *(ipbyte+3));
                sock->ip = ipstr;
#else
                char ipstr[16];
                inet_ntop(hostinfo->h_addrtype, *(hostinfo->h_addr_list), ipstr, sizeof(ipstr));
#endif
            } else {
                return 0;
            }
        } else {
         
        }

        
        // create socket
        if ((pkcp->fd = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
            return 0;
        }
        int on = 1;
//        setsockopt( pkcp->socket, IPPROTO_TCP, TCP_NODELAY, (void *)&on, sizeof(on));
//#if defined(__linux__) || defined(__ANDROID__)
//        // tcp option set
//        if (sock->keepalive == 1) {
//            if (setsockopt(sock->socket, SOL_SOCKET, SO_KEEPALIVE, (void *)&(sock->keepalive), sizeof(sock->keepalive)) < 0) {
//                return 0;
//            }
//            if (setsockopt(sock->socket, SOL_TCP, TCP_KEEPIDLE, (void *)&(sock->keepidle), sizeof(sock->keepidle)) < 0) {
//                return 0;
//            }
//            if (setsockopt(sock->socket, SOL_TCP, TCP_KEEPINTVL, (void *)&(sock->keepintvl), sizeof(sock->keepintvl)) < 0) {
//                return 0;
//            }
//            if (setsockopt(sock->socket, SOL_TCP, TCP_KEEPCNT, (void *)&(sock->keepcnt), sizeof(sock->keepcnt)) < 0) {
//                return 0;
//            }
//        }
//#endif
    
        // start thread
#if defined(_WIN32)
        _beginthread(work_thread_win, 0, sock);
#else
        int retval = pthread_create(&pkcp->thread, NULL, work_thread, pkcp);
        if (retval != 0) {
            return 0;
        }
#endif
        
        return 1;
}
int kcp_send(void * netObject, const char* buff, unsigned int len){
    KCP* pkcp = (KCP*)netObject;
    M_Node* send_node = link_new_node(len);
    link_append_to_node(send_node, buff, len);
}
M_Node* kcp_recv(void * netObject){
    KCP* pkcp = (KCP*)netObject;
    if (pkcp->recv_link->node_count >0) {
        return link_pop(pkcp->recv_link);
    }
    return NULL;
}
int kcp_close(void * netObject){
    
}

