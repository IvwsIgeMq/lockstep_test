//
//  kcp_server.c
//  shoot
//
//  Created by 梁清风 on 16/4/16.
//
//

#include "kcp_server.h"


void* kcp_server_wroker(void * p)
{
    
    KCP_Server* kcp_s = (KCP_Server*)p;
    socklen_t buff_len = 1024;
    char* buff = (char*)malloc(buff_len);
    struct sockaddr_in client_addr;
    unsigned int addr_len =sizeof(client_addr);
    while (1) {
        usleep(1000);
        IUINT32 t = iclock();
        IUINT32 t_update = 0;
        M_Node* kcp_node = kcp_s->send_kcp_link->front;
        while (kcp_node) {
            KCP* pkcp  = *((KCP**)kcp_node->data_buffer);
            t_update = ikcp_check(pkcp->kcp, t);
            if (t>= t_update) {
                ikcp_update(pkcp->kcp, t);
            }
            kcp_node = kcp_node->next;
        }
        while (kcp_s->send_kcp_link->node_count) {
            M_Node* kcp_node = link_pop(kcp_s->send_kcp_link);
            KCP* pkcp  = *((KCP**)kcp_node->data_buffer);
            while (pkcp->send_link->node_count) {
                M_Node* send_node = link_pop(pkcp->send_link);
                ikcp_send(pkcp->kcp, send_node->data_buffer, send_node->data_buffer_use);
                ikcp_update(pkcp->kcp,t);
            }
            pkcp->state ^= SENDDATA;
            link_push(kcp_s->free_kcp_link, kcp_node);
        }
        while (1) {
            unsigned int addr_len =sizeof(kcp_s->addr);
            int recv_len = recvfrom(kcp_s->fd, buff, 1024, 0, (struct sockaddr*)&client_addr, &addr_len);
            if (recv_len <0) {
                break;
            }
            printf("server recv_len = %d\n",recv_len);
            unsigned int kcp_fd = *((unsigned int *)(buff));
            KCP * pkcp =kcp_s->kcp_array[kcp_fd];
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
                *((unsigned int *)(buff)) = kcp_fd;
                printf("创建新联接 kcp_fd =%d \n",kcp_fd);
                ikcp_update(pkcp->kcp,t);
                pkcp->state |= CONNECTED;
                pkcp->state ^= CONNECTING;
                
            }
            M_Node* node = NULL;
            if (kcp_s->free_kcp_link->node_count>0) {
                node = link_pop(kcp_s->free_kcp_link);
            }else{
                node = link_new_node(sizeof(KCP*));
            }
            if ((pkcp->state & KCPRECV) == 0) {
                printf("add client to recv recv_kcp_link  %d\n",kcp_fd);
                link_append_to_node(node, (const char *)&pkcp, sizeof(KCP*));
                link_push(kcp_s->recv_kcp_link, node);
            }
            
            ikcp_input(pkcp->kcp, buff , recv_len);
            ikcp_update(pkcp->kcp,t);
        }
        int hr  = 0;
        kcp_node = kcp_s->recv_kcp_link->front;
        while (kcp_node) {
            KCP* pkcp  = *((KCP**)kcp_node->data_buffer);
            while (1) {
                hr = ikcp_recv(pkcp->kcp,buff, buff_len);
                if (hr<0) {
                    break;
                }
                printf("server recv %s\n",buff);
                M_Node* recv_node = link_new_node(hr);
                link_append_to_node(recv_node, buff, hr);
                link_push(pkcp->recv_link, recv_node);
            }
            
            pkcp->state ^= KCPRECV;
            pkcp->state |= RECVDATA;
            kcp_node = kcp_node->next;
        }
        if (kcp_s->use_thread <=  0 ) {
            break;
        }
    }
    return NULL;
}

void * kcp_create_server(unsigned int maxClient)
{
    KCP_Server* kcp_s = (KCP_Server*)malloc(sizeof(KCP_Server));
    kcp_s->kcp_array_len = maxClient;
    kcp_s->kcp_array = (KCP**)malloc(sizeof(KCP*)*maxClient);
    kcp_s->kcp_count = 0;
    kcp_s->use_thread  =0 ;
    memset(kcp_s->kcp_array, 0,sizeof(KCP*)*maxClient);
    kcp_s->send_kcp_link = link_new(1);
    kcp_s->recv_kcp_link = link_new(1);
    kcp_s->free_kcp_link = link_new(0);
    kcp_s->kcp_link = link_new(0);
    struct timeval tv_out;
    tv_out.tv_sec = 0;//�ȴ�10��
    tv_out.tv_usec = 0;
    kcp_s->fd = socket(AF_INET, SOCK_DGRAM, 0);
    setsockopt(kcp_s->fd, SOL_SOCKET, SO_RCVTIMEO, (char *)&tv_out, sizeof(tv_out));
    setsockopt(kcp_s->fd, SOL_SOCKET, SO_SNDTIMEO, (char *)&tv_out, sizeof(tv_out));
#ifdef WIN32
    unsigned long ul = 1;
    ioctlsocket(kcp_s->fd, FIONBIO, (unsigned long *)&ul);//���óɷ�����ģʽ��
#else
    fcntl(kcp_s->fd, F_SETFL, O_NONBLOCK);
#endif    //
    return kcp_s;
}

