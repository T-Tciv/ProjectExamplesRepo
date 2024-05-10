#ifdef _WIN32
#define _CRT_SECURE_NO_WARNINGS
#endif

#include <stdio.h>
#include "AVLheader.h"
#include <stdlib.h>
#include <string.h>

int main(void) 
{
	unsigned int numbers_count;

	if (1 != scanf("%u", &numbers_count)) {
		printf("bad input");
	}

	if (0 == numbers_count) {
		printf("0");
		return 0;
	}

	AVL_node* necessary_memory = (AVL_node*)malloc(numbers_count * sizeof(AVL_node));
	if (NULL == necessary_memory) {
		printf("cannot allocate");
		return 1;
	}

	int cur_number = 0;
	AVL_node* root = NULL;
	int cur_node = 0;

	unsigned int j;
	for (j = 0; j < numbers_count; ++j) {
		if (1 != scanf("%d", &cur_number)) {
			free(necessary_memory);
			printf("error: wrong numbers count");
			return 1;
		}

		root = insert(root, cur_number, necessary_memory, &cur_node);
	}

	printf("%u\n", root->height);

	free(necessary_memory);
	return 0;
}
