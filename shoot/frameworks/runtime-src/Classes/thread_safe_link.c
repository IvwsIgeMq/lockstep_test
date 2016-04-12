//
//  thread_safe_queue.c
//  shoot
//
//  Created by 梁清风 on 16/4/1.
//
//

#include "thread_safe_link.h"

Link* link_new(){
    Link* link = (Link*)malloc(sizeof(Link));
    link->front = NULL;
    link->rear = NULL;
    link->node_count = 0;
    link->size = 0 ;
    pthread_mutex_init(&link->mutex,NULL);
    return link;
}

void link_push(Link* link ,M_Node* node){
    pthread_mutex_lock(&link->mutex);
    if (!link->rear) {
        link->front = link->rear = node;
    }else{
        link->rear->next = node;
        link->rear = node;
    }
    link->node_count ++;
    link->size += node->data_buffer_size;
    pthread_mutex_unlock(&link->mutex);
    
}

M_Node* link_pop(Link* link){
    pthread_mutex_lock(&link->mutex);
    M_Node* node = link->front;
    
    if(node){
        link->front = node->next;
        if(!link->front) link->rear = link->front;
        node->next = NULL;
        link->node_count --;
        link->size -= node->data_buffer_size;
    }
    pthread_mutex_unlock(&link->mutex);
    return node;
}

M_Node* link_new_node(int data_len){
    int buff_len =sizeof(M_Node)+data_len;
    M_Node* node = (M_Node*)malloc(buff_len+1);
    node->data_buffer = ((char*)node)+(buff_len-data_len);
    node->data_buffer_size =buff_len;
    node->data_buffer_use = 0;
    node->data_buffer_len = 0;
    node->next = NULL;
    ((char*)node)[buff_len]='\0';
    return node;
}
void link_append_to_node(M_Node* node,const char * buff,unsigned int len)
{
    if (!node || !buff || len <= 0) {
        return ;
    }
    if (node->data_buffer_size-node->data_buffer_use < len) {
        return;
    }
    
    memcpy((void*)(node->data_buffer +node->data_buffer_use), (const void*)buff, len);
    node->data_buffer_use += len;
    
}

void link_reset_node(M_Node* node)
{
    node->data_buffer_use = 0;
    node->data_buffer_len = 0;
    node->next = NULL;
    ((char*)node)[node->data_buffer_size]='\0';


}
void link_free_node(M_Node* node)
{
    link_reset_node(node);
    free(node);
}

M_Node* link_get_rear(Link* link){
    return link->rear;
}

void link_free(Link* link){
    M_Node* node = link->front;
    M_Node* tem = NULL;
    free(link);
    while (node) {
        tem = node;
        free(tem);
        node = node->next;
    }
}
