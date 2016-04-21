//
//  kcp_client.c
//  shoot
//
//  Created by 梁清风 on 16/4/8.
//
//

#include "kcp_client.h"


#pragma pack(1)
typedef struct msg_head{
    char	 head;
    short 	versions_id;//版本
    short 	SN; //顺序号
    int 	session_id;
    int		len;
    int 	msg_type;
}Msg_Head;
#pragma pack()


int kcp_client_send(void * netObject, const char* buff, unsigned int len){
    
    KCP* pkcp = (KCP*)netObject;
    int head_len =sizeof(Msg_Head);
    size_t message_raw_len = head_len +len;
    M_Node* send_node = link_new_node(message_raw_len);
    ((Msg_Head*)send_node->data_buffer)->len =len;
    ((Msg_Head*)send_node->data_buffer)->head = '|';
    ((Msg_Head*)send_node->data_buffer)->msg_type = 10000;
    ((Msg_Head*)send_node->data_buffer)->session_id =0 ;
    ((Msg_Head*)send_node->data_buffer)->versions_id=0;//版本
    ((Msg_Head*)send_node->data_buffer)->SN=0; //顺序号
    send_node->data_buffer_use =head_len;
    
    link_append_to_node(send_node, buff, len);
    link_push(pkcp->send_link, send_node);
    pkcp->state |= SENDDATA;
    return 0;
}
M_Node* kcp_client_recv(void * netObject){
    KCP* pkcp = (KCP*)netObject;
    if (pkcp->recv_link->node_count >0) {
        M_Node* recv_node =link_pop(pkcp->recv_link);
        if(recv_node->data_buffer[0] == '|'){
            recv_node->data_buffer_pos =  17;
        }
        return recv_node;
    }
    return NULL;
}

