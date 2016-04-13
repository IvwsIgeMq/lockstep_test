//
//  thread_safe_queue.h
//  shoot
//
//  Created by 梁清风 on 16/4/1.
//
//

#ifndef thread_safe_link_h
#define thread_safe_link_h

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <string.h>

typedef struct node{
    int data_buffer_size;
    int data_buffer_len;
    int data_buffer_use;
    struct node * next;
    char *data_buffer;
}M_Node;


typedef struct link{
    M_Node* front;
    M_Node* rear;
    int node_count;
    int size;
    pthread_mutex_t mutex;
    int useLock;
}Link;


Link* link_new(int useLock = 1);

void  link_lock(Link* link);
void  link_unlock(Link* link);

void link_push(Link* link ,M_Node* node);

M_Node* link_pop(Link* link);

M_Node* link_new_node(int data_len);

M_Node* link_get_rear(Link* link);

void link_free(Link* link);
void link_append_to_node(M_Node* node,const char * buff,unsigned int len);
void link_reset_node(M_Node* node);
void link_free_node(M_Node* node);

#endif /* thread_safe_queue_h */
