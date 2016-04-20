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
    struct sockaddr_in server_addr;
    unsigned int addr_len =sizeof(server_addr);
    char* buff = (char*)malloc(buff_len);
    
    while (1) {
        usleep(2000);
        
        IUINT32 t = iclock();
        ikcp_update(pkcp->kcp, iclock());
        while (pkcp->send_link->node_count) {
            M_Node* send_node = link_pop(pkcp->send_link);
//            printf("client send %s %d\n",send_node->data_buffer,send_node->data_buffer_use);      
            ikcp_send(pkcp->kcp, send_node->data_buffer, send_node->data_buffer_use);
            ikcp_update(pkcp->kcp, t);
        }
        pkcp->state ^= SENDDATA;
        while (1) {
            
            int recv_len = recvfrom(pkcp->fd, buff, 1024, 0, (struct sockaddr*)&server_addr, &addr_len);
            if (recv_len <0) {
                break;
            }
//            printf("client recv_len = %d\n",recv_len);
            unsigned int kcp_fd = *((unsigned int *)(buff));
            if (pkcp->kcp->conv != kcp_fd){
                if( pkcp->addr.sin_port ==server_addr.sin_port &&
                   pkcp->addr.sin_addr.s_addr==server_addr.sin_addr.s_addr) { ///接到服务器消息，如果fd与本地不同就将地本设为服务端fd
                    pkcp->kcp->conv = kcp_fd; //重设 标志
                    M_Node* new_node = link_new_node(strlen("connected"));
                    link_append_to_node(new_node, "connected", strlen("connected"));
                    printf("client send len = %d\n",strlen("connected"));
                    link_push(pkcp->recv_link,new_node);
                }else{ //如果不是服务器发来的，就丢掉
                    break;
                }
            }
            ikcp_input(pkcp->kcp, buff , recv_len);
            ikcp_update(pkcp->kcp, t);
        }
        int hr  = 0;
        while (1) {
            hr = ikcp_recv(pkcp->kcp,buff, buff_len);
            if (hr<0) {
                break;
            }
            if((pkcp->state & CONNECTED) == 0){
                if (memcmp(buff, "server_connect",strlen("server_connect")) == 0 ) {
                    pkcp->state |= CONNECTED;
                    break;
                }
            }
            M_Node* recv_node = link_new_node(hr);
            link_append_to_node(recv_node, buff, hr);
            link_push(pkcp->recv_link, recv_node);
        }
    }
    free(buff);
    return NULL;
}


void kcp_server_update(void * p )
{
    KCP_Server* kcp_s = (KCP_Server*)p;
    IUINT32 t = iclock();
    IUINT32 t_update = 0;
    M_Node* kcp_node = kcp_s->kcp_link->front;
    while (kcp_node) {
        KCP* pkcp  = *((KCP**)kcp_node->data_buffer);
        if (t>= pkcp->update_time) {
            ikcp_update(pkcp->kcp, t);
            pkcp->update_time = ikcp_check(pkcp->kcp, t);
            if (pkcp->kcp->state< 0 ) {
                printf("超过重发限制认为断开\n");
            }
        }
        kcp_node = kcp_node->next;
    }

}

void kcp_server_send(void * p)
{
    KCP_Server* kcp_s = (KCP_Server*)p;
    while (kcp_s->send_kcp_link->node_count) {
        M_Node* kcp_node = link_pop(kcp_s->send_kcp_link);
        KCP* pkcp  = *((KCP**)kcp_node->data_buffer);
        while (pkcp->send_link->node_count) {
            M_Node* send_node = link_pop(pkcp->send_link);
            ikcp_send(pkcp->kcp, send_node->data_buffer, send_node->data_buffer_use);
            pkcp->update_time = ikcp_check(pkcp->kcp, iclock());
        }
        pkcp->state ^= SENDDATA;
        link_push(kcp_s->free_kcp_link, kcp_node);
    }
}



void* kcp_server_recv(void * p)
{
    KCP_Server* kcp_s = (KCP_Server*)p;
    M_Node* kcp_node = NULL;
    struct sockaddr_in client_addr;
    unsigned int addr_len =sizeof(client_addr);
    while (1) {
        unsigned int addr_len =sizeof(kcp_s->addr);
        int recv_len = recvfrom(kcp_s->fd, kcp_s->recv_buff, kcp_s->recv_buff_len, 0, (struct sockaddr*)&client_addr, &addr_len);
        if (recv_len <0) {
            break;
        }
        printf("server recv_len = %d\n",recv_len);
        unsigned int kcp_fd = *((unsigned int *)(kcp_s->recv_buff));
        KCP * pkcp =kcp_s->kcp_array[kcp_fd];
         M_Node* node = NULL;
        if (!pkcp) {
            for (kcp_fd = 1; kcp_fd< kcp_s->kcp_array_len; kcp_fd++) {
                if (!kcp_s->kcp_array[kcp_fd])
                {
                    break;
                }
            }
            pkcp=(KCP*)kcp_create_client(kcp_fd);
            pkcp->kcp_server = kcp_s;
            pkcp->fd = kcp_s->fd;
            memcpy(&pkcp->addr, &client_addr, addr_len);
            ikcp_send(pkcp->kcp, "server_connect", sizeof("server_connect"));
            kcp_s->kcp_array[kcp_fd] = pkcp;
            if (kcp_s->free_kcp_link->node_count>0) {
                node = link_pop(kcp_s->free_kcp_link);
            }else{
                node = link_new_node(sizeof(KCP*));
            }
            link_append_to_node(node, (const char *)&pkcp, sizeof(KCP*));
            link_push(kcp_s->kcp_link, node);
            *((unsigned int *)(kcp_s->recv_buff)) = kcp_fd;
            printf("创建新联接 kcp_fd =%d \n",kcp_fd);
            pkcp->state |= CONNECTED;
            pkcp->state ^= CONNECTING;
           
        }
       
        if (kcp_s->free_kcp_link->node_count>0) {
            node = link_pop(kcp_s->free_kcp_link);
        }else{
            node = link_new_node(sizeof(KCP*));
        }
        if ((pkcp->state & KCPRECV) == 0) {
            printf("add client to recv recv_kcp_link  %d\n",kcp_fd);
            link_append_to_node(node, (const char *)&pkcp, sizeof(KCP*));
            link_push(kcp_s->recv_kcp_link, node);
            pkcp->state |= KCPRECV;
        }
        ikcp_input(pkcp->kcp, kcp_s->recv_buff , recv_len);
        pkcp->update_time = ikcp_check(pkcp->kcp, iclock());
    }
    int hr  = 0;
    kcp_node = kcp_s->recv_kcp_link->front;
    while (kcp_node) {
        KCP* pkcp  = *((KCP**)kcp_node->data_buffer);
        while (1) {
            hr = ikcp_recv(pkcp->kcp,kcp_s->recv_buff, kcp_s->recv_buff_len);
            if (hr<0) {
                break;
            }
            printf("server recv %s\n",kcp_s->recv_buff);
            M_Node* recv_node = link_new_node(hr);
            link_append_to_node(recv_node, kcp_s->recv_buff, hr);
            link_push(pkcp->recv_link, recv_node);
        }
        pkcp->state ^= KCPRECV;
        pkcp->state |= RECVDATA;
        kcp_node = kcp_node->next;
    }
    return NULL;
}

void kcp_log(const char *log, struct IKCPCB *kcp, void *user){
    printf("%s kcp_fd = %d\n",log,kcp->conv);
}

int udp_output(const char *buf, int len, ikcpcb *kcp, void *user)
{
    KCP* pkcp = (KCP*)user;
    sendto(pkcp->fd,buf,len,0, (const struct sockaddr*)&pkcp->addr, sizeof(struct sockaddr));
    return 0;
}

void * kcp_create_client(unsigned int kcp_fd){
    KCP* pkcp = (KCP*)malloc(sizeof(KCP));
    pkcp->kcp =  ikcp_create(kcp_fd, pkcp);
    ikcp_wndsize(pkcp->kcp, 128, 128);
    ikcp_nodelay(pkcp->kcp, 1, 10, 2, 1);
    pkcp->kcp->output = udp_output;
    pkcp->kcp->writelog = kcp_log;
    pkcp->kcp_server = NULL;
    pkcp->send_link = link_new(1);
    pkcp->recv_link = link_new(1);
    pkcp->state = 0;
    pkcp->update_time = ikcp_check(pkcp->kcp, iclock());
    struct timeval tv_out;
    tv_out.tv_sec = 0;
    tv_out.tv_usec = 0;
    pkcp->fd = socket(AF_INET, SOCK_DGRAM, 0);
    setsockopt(pkcp->fd, SOL_SOCKET, SO_RCVTIMEO, (char *)&tv_out, sizeof(tv_out));
    setsockopt(pkcp->fd, SOL_SOCKET, SO_SNDTIMEO, (char *)&tv_out, sizeof(tv_out));
#ifdef WIN32
    unsigned long ul = 1;
    ioctlsocket(pkcp->fd, FIONBIO, (unsigned long *)&ul);
#else
    fcntl(pkcp->fd, F_SETFL, O_NONBLOCK);
#endif    //        int on = 1;
    return pkcp;
}


void * kcp_create_server(unsigned int maxClient)
{
    KCP_Server* kcp_s = (KCP_Server*)malloc(sizeof(KCP_Server));
    kcp_s->kcp_array_len = maxClient;
    kcp_s->kcp_array = (KCP**)malloc(sizeof(KCP*)*maxClient);
    kcp_s->kcp_count = 0;
    memset(kcp_s->kcp_array, 0,sizeof(KCP*)*maxClient);
    kcp_s->send_kcp_link = link_new(1);
    kcp_s->recv_kcp_link = link_new(1);
    kcp_s->free_kcp_link = link_new(0);
    kcp_s->kcp_link = link_new(0);
    kcp_s->recv_buff = (char*)malloc(2048);
    kcp_s->recv_buff_len = 2048;
    struct timeval tv_out;
    tv_out.tv_sec = 0;
    tv_out.tv_usec = 0;
    kcp_s->fd = socket(AF_INET, SOCK_DGRAM, 0);
    setsockopt(kcp_s->fd, SOL_SOCKET, SO_RCVTIMEO, (char *)&tv_out, sizeof(tv_out));
    setsockopt(kcp_s->fd, SOL_SOCKET, SO_SNDTIMEO, (char *)&tv_out, sizeof(tv_out));
#ifdef WIN32
    unsigned long ul = 1;
    ioctlsocket(kcp_s->fd, FIONBIO, (unsigned long *)&ul);
#else
    fcntl(kcp_s->fd, F_SETFL, O_NONBLOCK);
#endif    //
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

    int reuse=1024*1024;
    setsockopt(pkcp->fd , SOL_SOCKET, SO_RCVBUF,(void*)& reuse, sizeof(reuse));
    setsockopt(pkcp->fd , SOL_SOCKET, SO_SNDBUF,(void*)& reuse, sizeof(reuse));

    ikcp_send(pkcp->kcp, "client_connect", strlen("client_connect"));
//    ikcp_update(pkcp->kcp, iclock());
    pkcp->state |=CONNECTING;
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

int kcp_listen(void * netObject, unsigned int port)
{
    KCP_Server* kcp_s = (KCP_Server* )netObject;
    //  kcp_s->fd =socket(AF_INET,SOCK_DGRAM,0);
    kcp_s->addr.sin_family=AF_INET;
    kcp_s->addr.sin_port= htons(port);
    kcp_s->addr.sin_addr.s_addr = INADDR_ANY;
    bind(kcp_s->fd ,(struct sockaddr *)&kcp_s->addr,sizeof(struct sockaddr));
    return 0 ;
}


int kcp_send(void * netObject, const char* buff, unsigned int len ){
    
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
        if ((pkcp->state & SENDDATA) ==0 ) {
            link_append_to_node(node, (const char *)&pkcp, sizeof(KCP*));
            link_push(kcp_s->send_kcp_link, node);
            pkcp->state |= SENDDATA;
        }
    }
    return 0;
}
M_Node* kcp_recv(void * netObject){
    KCP* pkcp = (KCP*)netObject;
    if (pkcp->recv_link->node_count >0) {
        return link_pop(pkcp->recv_link);
    }else{
        pkcp->state ^= RECVDATA;
    }
    return NULL;
}
int kcp_close(void * netObject){
    return 0 ;
}
