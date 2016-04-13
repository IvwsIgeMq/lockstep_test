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
    socklen_t buff_len = 1024;
    char* buff = (char*)malloc(buff_len);

    while (1) {

        ikcp_update(pkcp->kcp, iclock());
        while (pkcp->send_link->node_count) {
            M_Node* send_node = link_pop(pkcp->send_link);
            ikcp_send(pkcp->kcp, send_node->data_buffer, send_node->data_buffer_use);
        }
        while (1) {
            unsigned int addr_len =sizeof(pkcp->addr);
            int recv_len = recvfrom(pkcp->fd, buff, 1024, 0, (struct sockaddr*)&pkcp->addr, &addr_len);
            if (recv_len <0) {
                break;
            }
            ikcp_input(pkcp->kcp, buff , recv_len);
        }
        int hr  = 0;
        while (1) {
            hr = ikcp_recv(pkcp->kcp,buff, buff_len);
            if (hr<0) {
                break;
            }
            M_Node* recv_node = link_new_node(hr);
            link_append_to_node(recv_node, buff, hr);
        }
    }
    return NULL;
}


void* server_thread(void * p)
{

    KCP_Server* kcp_s = (KCP_Server*)p;
    socklen_t buff_len = 1024;
    char* buff = (char*)malloc(buff_len);

    while (1) {
        isleep(1);
        IUINT32 t = iclock();
        IUINT32 t_update = 0;
        while (kcp_s->kcp_link->node_count) {
            M_Node* kcp_node = link_pop(kcp_s->kcp_link);
            KCP* pkcp  = (KCP*)kcp_node->data_buffer;
             t_update = ikcp_check(pkcp, t);
            if (t>= t_update) {
                ikcp_update(pkcp->kcp, t);
            }
            link_push(kcp_s->kcp_link, kcp_node);
        }


        while (kcp_s->send_kcp_link->node_count) {
              M_Node* kcp_node = link_pop(kcp_s->send_kcp_link);
              KCP* pkcp  = (KCP*)kcp_node->data_buffer;
              while (pkcp->send_link->node_count) {
                  M_Node* send_node = link_pop(pkcp->send_link);
                  ikcp_send(pkcp->kcp, send_node->data_buffer, send_node->data_buffer_use);
                  ikcp_update(pkcp->kcp,t);
              }
              link_push(kcp_s->free_kcp_link, kcp_node);
        }
        while (1) {
            unsigned int addr_len =sizeof(kcp_s->addr);
            int recv_len = recvfrom(kcp_s->fd, buff, 1024, 0, (struct sockaddr*)&kcp_s->addr, &addr_len);
            if (recv_len <0) {
                break;
            }
            unsigned int kcp_fd = *((unsigned int *)(buff));
            if (kcp_s->kcp_array[kcp_fd]) {
                KCP* pkcp =kcp_s->kcp_array[kcp_fd];
                ikcp_input(pkcp->kcp, buff , recv_len);
                ikcp_update(pkcp->kcp,t);
                M_Node* node = NULL;
                if (kcp_s->free_kcp_link->node_count>0) {
                    node = link_pop(kcp_s->free_kcp_link);
                }else{
                    node = link_new_node(sizeof(KCP*));
                }
                link_append_to_node(node, (const char *)pkcp, sizeof(KCP*));
                link_push(kcp_s->recv_kcp_link, node);
            }else{
                int fd = 0;
                for (fd; fd< kcp_s->kcp_array_len; fd++) {
                  if (!kcp_s->kcp_array[fd])
                  {
                      break;
                  }
                }
                KCP * pkcp =(KCP*)create_kcp_client(fd);
                pkcp->kcp_server = kcp_s;
                pkcp->fd = kcp_s->fd;
                ikcp_create(fd, pkcp);
            }
        }
        int hr  = 0;
        while (kcp_s->recv_kcp_link->node_count) {
            M_Node* kcp_node = link_pop(kcp_s->recv_kcp_link);
            KCP* pkcp  = (KCP*)kcp_node->data_buffer;
            while (1) {
                hr = ikcp_recv(pkcp->kcp,buff, buff_len);
                if (hr<0) {
                    break;
                }
                M_Node* recv_node = link_new_node(hr);
                link_append_to_node(recv_node, buff, hr);
                link_push(pkcp->recv_link, recv_node);
            }
            link_push(kcp_s->free_kcp_link, kcp_node);
        }
    }
    return NULL;
}



int udp_output(const char *buf, int len, ikcpcb *kcp, void *user)
{
    KCP* pkcp = (KCP*)user;
    sendto(pkcp->fd,buf,len,0, (const struct sockaddr*)&pkcp->addr, sizeof(struct sockaddr));
    return 0;
}




void * create_kcp_client(unsigned int kcp_fd){
    KCP* pkcp = (KCP*)malloc(sizeof(KCP));
    pkcp->kcp =  ikcp_create(kcp_fd, pkcp);
    ikcp_wndsize(pkcp->kcp, 128, 128);
    ikcp_nodelay(pkcp->kcp, 1, 10, 2, 1);
    pkcp->kcp->output = udp_output;
    pkcp->kcp_server = NULL;
    return pkcp;
}
void * create_kcp_server(unsigned int maxClient)
{
    KCP_Server* kcp_s = (KCP_Server*)malloc(sizeof(KCP_Server));
    kcp_s->kcp_array_len = maxClient;
    kcp_s->kcp_array = (KCP**)malloc(sizeof(KCP*)*maxClient);
    kcp_s->kcp_count = 0;
    memset(kcp_s->kcp_array, 0,sizeof(KCP*)*maxClient);
    kcp_s->send_kcp_link = link_new();
    kcp_s->recv_kcp_link = link_new();
    kcp_s->free_kcp_link = link_new(0);
    kcp_s->kcp_link = link_new(0);

    return kcp_s;
}

int kcp_connect(void * netObject,const char* ip, unsigned int port){

    KCP* pkcp = (KCP*)netObject;
    pkcp->addr.sin_family = AF_INET;
    pkcp->addr.sin_addr.s_addr = inet_addr(ip);
    pkcp->addr.sin_port = htons(port);
    memset((void*)pkcp->addr.sin_zero, 0, sizeof(pkcp->addr.sin_zero));


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
        int reuse=1024*1024;
        setsockopt(pkcp->fd , SOL_SOCKET, SO_RCVBUF,(void*)& reuse, sizeof(reuse));
        setsockopt(pkcp->fd , SOL_SOCKET, SO_SNDBUF,(void*)& reuse, sizeof(reuse));
    //        int on = 1;
//    setsockopt( pkcp->fd ,IPPROTO_UDP, TCP_NODELAY, (void *)&on, sizeof(on));
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

int kcp_listen(void * netObject, unsigned int port )
{
    KCP_Server* kcp_s = (KCP_Server* )netObject;
    kcp_s->fd =socket(AF_INET,SOCK_DGRAM,0);
    kcp_s->addr.sin_family=AF_INET;
    kcp_s->addr.sin_port=port;
    bind(kcp_s->fd ,(struct sockaddr *)&kcp_s->addr,sizeof(struct sockaddr));
    

    int retval = pthread_create(&pkcp->thread, NULL, server_thread, kcp_s);
    if (retval != 0) {
        return 0;
    }
    return 0 ;
}


int kcp_send(void * netObject, const char* buff, unsigned int len){

    KCP* pkcp = (KCP*)netObject;
    M_Node* send_node = link_new_node(len);
    link_append_to_node(send_node, buff, len);
    link_push(pkcp->send_link, send_node);

    if (pkcp->kcp_server) {
        KCP_Server* kcp_s = (KCP_Server*)pkcp->kcp_server;
        M_Node* node = NULL;
        if (kcp_s->free_kcp_link->node_count>0) {
            node = link_pop(kcp_s->free_kcp_link);
        }else{
            node = link_new_node(sizeof(KCP*));
        }
        link_append_to_node(node, (const char *)pkcp, sizeof(KCP*));
        link_push(kcp_s->send_kcp_link, node);
    }
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
