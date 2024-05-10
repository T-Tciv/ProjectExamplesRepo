#include "AVLheader.h"
#include <stdlib.h>

unsigned int height(AVL_node * node) 
{
	if (NULL == node)
		return 0;

	return node->height;
}

unsigned int max_height(unsigned int h1, unsigned int h2) 
{
	return (h1 > h2) ? h1 : h2;
}

AVL_node* make_right_rotate(AVL_node * node) 
{
	AVL_node* left_child = node->left;
	node->left = left_child->right;
	left_child->right = node;

	node->height = max_height(height(node->right), height(node->left)) + 1;
	left_child->height = max_height(node->height, height(left_child->left)) + 1;

	return left_child;
}

AVL_node* make_left_rotate(AVL_node* node) 
{
	AVL_node* right_child = node->right;
	node->right = right_child->left;
	right_child->left = node;
	
	node->height = max_height(height(node->right), height(node->left)) + 1;
	right_child->height = max_height(node->height, height(right_child->right)) + 1;

	return right_child;
}

AVL_node* insert(AVL_node* node, int in_value, AVL_node* necessary_memory, int * cur_node) 
{
	if (NULL == node) {
		node = &necessary_memory[*cur_node];
		++*cur_node;
		
		node->height = 1;
		node->value = in_value;
		node->left = NULL;
		node->right = NULL;

		return node;
	}
	
	if (in_value > node->value)
		node->right = insert(node->right, in_value, necessary_memory, cur_node);
	else
		node->left = insert(node->left, in_value, necessary_memory, cur_node);

	unsigned int left_hight = height(node->left);
	unsigned int right_hight = height(node->right);
	node->height = max_height(left_hight, right_hight) + 1;

	if (2 == left_hight - right_hight) {
		if (height(node->left->left) > height(node->left->right))
			return make_right_rotate(node);

		node->left = make_left_rotate(node->left);
		return make_right_rotate(node);
	}
	else if (2 == right_hight - left_hight) {
		if (height(node->right->right) > height(node->right->left))
			return make_left_rotate(node);

		node->right = make_right_rotate(node->right);
		return make_left_rotate(node);
	}

	return node;
}
