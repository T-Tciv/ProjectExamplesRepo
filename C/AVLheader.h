#ifndef AVL_H
#define AVL_H
typedef struct AVL_node_str AVL_node;

struct AVL_node_str {
	long value;
	AVL_node* left;
	AVL_node* right;
	unsigned int height;
};

AVL_node* insert(AVL_node*, int, AVL_node*, int*);

#endif
