//
//  main.c
//  kcp_server
//
//  Created by 梁清风 on 16/4/21.
//  Copyright © 2016年 梁清风. All rights reserved.
//

#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include "kcp_socket.h"


void * _work_thread(void * p)
{
    KCP_Server* kcp_s = (KCP_Server*)p ;
    int num = 0;
    while (1) {
        usleep(10000);
        int kcp_fd = 0;
        for (kcp_fd = 1; kcp_fd< kcp_s->kcp_array_len; kcp_fd++) {
            if (kcp_s->kcp_array[kcp_fd]) {
                KCP* pkcp =kcp_s->kcp_array[kcp_fd];
                M_Node* recv_node =  kcp_recv(pkcp);
                if (recv_node) {
                    link_free_node(recv_node);
                }
                if (num >= 60) {
                    char * data = "{'tyoe':1}";
                    kcp_send(pkcp, data, strlen(data));
                }
            }
        }
        if (num >= 60) {
            num = 0;
        }
        else
            num ++;
    }
    
    
    return NULL;
}

int main(int argc, const char * argv[]) {
   
    pthread_t thread;
    KCP_Server* kcp_s = (KCP_Server*)kcp_create_server(500);
    kcp_listen(kcp_s, 8010);
    printf("runing kcp_server\n");
    pthread_create(&thread, NULL, _work_thread, kcp_s);
    
    while (1) {
        usleep(10000);
        kcp_server_recv(kcp_s);
        kcp_server_send(kcp_s);
        kcp_server_update(kcp_s);
        
    }
    
    
    return 0;
}
